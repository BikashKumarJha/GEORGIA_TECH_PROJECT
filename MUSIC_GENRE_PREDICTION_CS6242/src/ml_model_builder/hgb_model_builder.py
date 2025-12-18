import pandas as pd
import numpy as np
import time
from scipy.spatial.distance import pdist
from sklearn.model_selection import train_test_split, RandomizedSearchCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.datasets import load_iris
from tensorflow import lite
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense
import tensorflow as tf
import joblib
import psycopg2
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType
from sklearn.experimental import enable_hist_gradient_boosting  # noqa
from sklearn.ensemble import HistGradientBoostingClassifier
import seaborn as sns
import matplotlib.pyplot as plt
from sklearn.metrics import precision_score, recall_score, f1_score, classification_report


def fetch_data_from_database(query):
    # Connection parameters
    conn_params = {
        'host': 'musicbrainz.postgres.database.azure.com',
        'port': 5432,
        'database': 'musicbrainz',
        'user': 'musicbrainz',
        'password': 'Git62036242',
    }

    # Connect to the database
    conn = psycopg2.connect(**conn_params)

    # Create a cursor
    cur = conn.cursor()

    # Execute the query and fetch data
    cur.execute(query)
    data = cur.fetchall()

    # Close the cursor and connection
    cur.close()
    conn.close()

    # Convert the fetched data to a DataFrame
    columns = [desc[0] for desc in cur.description]
    df = pd.DataFrame(data, columns=columns)

    return df

# Read the dataframes from the Excel files
query_df1 = 'SELECT * FROM pta_mta;'
query_df2 = 'SELECT * FROM mta;'

# Fetch data from the database
og_pta = fetch_data_from_database(query_df1)
df_mta = fetch_data_from_database(query_df2)

df_mta.fillna(-1, inplace=True)

df_mta = df_mta.drop(['id','gid','name','type','area','gender'], axis=1)


df_pta = og_pta.drop(columns=['id','gid', 'name','type','area','gender'], axis=1)

df_pta_summary = df_pta.describe()

# Binning 'gross_revenue'
revenue_range = [0, np.percentile(df_pta['gross_revenue'], 33), np.percentile(df_pta['gross_revenue'], 66), df_pta_summary.loc['max', 'gross_revenue']]
df_pta['revenue_success'] = pd.cut(df_pta['gross_revenue'], revenue_range, labels=[1, 2, 3])

# Binning 'tickets_sold'
tickets_range = [0, np.percentile(df_pta['tickets_sold'], 33), np.percentile(df_pta['tickets_sold'], 66), df_pta_summary.loc['max', 'tickets_sold']]
df_pta['tickets_success'] = pd.cut(df_pta['tickets_sold'], tickets_range, labels=[1, 2, 3])

# Creating 'success_score' by summing the bins
df_pta['success_score'] = df_pta['tickets_success'].astype(int) + df_pta['revenue_success'].astype(int)

# Define score range for 'success_rate'
score_range = [0, 2, 3, 6]

# Binning 'success_score' to create 'success_rate'
df_pta['success_rate'] = pd.cut(df_pta['success_score'], score_range, labels=["low", "medium", "high"])

df_pta = df_pta.drop(["tickets_success","revenue_success","success_score","gross_revenue", "tickets_sold"],axis=1)

def calculate_euclidean_distance(input_row, row):
    # Convert input_row and row to numeric and fill NaN with 0
    input_array = pd.to_numeric(input_row, errors='coerce').fillna(0).values.reshape(1, -1)
    row_array = pd.to_numeric(row, errors='coerce').fillna(0).values.reshape(1, -1)
    distance = pdist(np.concatenate([input_array, row_array]))[0]
    return distance


def find_matching_row_and_success_rate(df, input_row):
    # Calculate Euclidean distances between input row and all rows in df
    distances = []
    for index, df_pta_row in df.iterrows():
        df_pta_row = df_pta_row[:-1].astype("int64")
        input_row = input_row.astype("int64")
        distance = calculate_euclidean_distance(input_row, df_pta_row)
        distances.append((distance, index))

    # Sort distances in ascending order
    distances.sort()

    # Extract the index of the closest row
    closest_row_index = distances[0][1]

    # Get the success rate of the closest row
    closest_row_success_rate = df_pta.loc[closest_row_index, 'success_rate']

    return closest_row_success_rate


# Create a new column 'SuccessRate' in df_mta to store the success rates
df_mta['success_rate'] = 0.0

# Select the first 100,000 rows of df_mta as a separate variable
subset_df_mta = df_mta.head(100000)

vals = []
#from new_feature_similarity import *
for i in range(len(subset_df_mta)):
    
    mta_row = (subset_df_mta.iloc[i]).drop(['success_rate'])

    # Calculate success rate using find_matching_row_and_success_rate function
    success_rate = find_matching_row_and_success_rate(df_pta, mta_row)

    # Assign the success rate to the corresponding row in 'SuccessRate' column in the subset
    vals.append(success_rate)
    # Report progress every 5000 rows
    if i % 5000 == 0 and i > 0:
        current_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        print(f"{current_time}: Processed {i} rows")

df_mta_copy = df_mta.copy()
df_mta_copy['success_rate'] = vals

# Split the labeled data into features (X) and target (y)
X = df_mta_copy.drop(['success_rate'], axis=1)
y = df_mta_copy['success_rate']

# Split the data into training, validation, and testing sets
X_train, X_temp, y_train, y_temp = train_test_split(X, y, test_size=0.4, random_state=42)
X_val, X_test, y_val, y_test = train_test_split(X_temp, y_temp, test_size=0.5, random_state=42)

# Hyperparameter tuning for HistGradientBoostingClassifier
param_dist_hgb = {
    'learning_rate': [0.001, 0.01, 0.1, 0.2],
    'max_iter': [100, 200, 300],
    'max_depth': [3, 4, 5],
    'min_samples_leaf': [1, 2, 4],
    'max_leaf_nodes': [15, 31, 63],
    'random_state': [42]
}

hgb_model = HistGradientBoostingClassifier()
random_search_hgb = RandomizedSearchCV(estimator=hgb_model, param_distributions=param_dist_hgb, n_iter=10, cv=3, scoring='accuracy', random_state=42)
random_search_hgb.fit(X_train, y_train)

# Evaluate the model on the validation set or test set
val_accuracy = random_search_hgb.score(X_val, y_val)
y_val_pred = random_search_hgb.predict(X_val)
test_accuracy = random_search_hgb.score(X_test, y_test)
y_test_pred = random_search_hgb.predict(X_test)

# Confusion matrix
conf_matrix = confusion_matrix(y_test, y_test_pred, labels=['low', 'medium', 'high'])


# Create a confusion matrix heatmap
plt.figure(figsize=(8, 6))
sns.heatmap(conf_matrix, annot=True, fmt="d", cmap="Blues", xticklabels=['low', 'medium', 'high'], yticklabels=['low', 'medium', 'high'])
plt.title('Confusion Matrix')
plt.xlabel('Predicted Label')
plt.ylabel('True Label')
pair_plot.savefig('Confusion_Matrix.png')

# plt.show()

# Plotting the effects of hyperparameters on model performance

# Extract relevant columns
hyperparameters_columns = ['param_learning_rate', 'param_max_iter', 'param_max_depth', 'param_min_samples_leaf', 'param_max_leaf_nodes']
results_columns = ['mean_test_score']

# Combine hyperparameters with results
hyperparameters_and_results = results_df[hyperparameters_columns + results_columns]

# Create a pair plot
pair_plot = sns.pairplot(hyperparameters_and_results, diag_kind='kde')
plt.suptitle('Pair Plot of Hyperparameters and Mean Test Score', y=1.02)

# Save the pair plot as an image
pair_plot.savefig('hyperparams_pair_plot.png')

# Calculate precision, recall, and F1-score
report = classification_report(y_test, y_test_pred)

# Plot the classification metrics
# Set the font scale for seaborn
sns.set(font_scale=2.0)

# Create a DataFrame from the classification report
df_classification = pd.DataFrame.from_dict(classification_report(y_test, y_test_pred, output_dict=True))

# Plot the classification report with Viridis color scheme
plt.figure(figsize=(14, 6))
sns.heatmap(df_classification.iloc[:-1, :].T, annot=True, cmap='viridis', cbar=True, fmt=".0%", linewidths=0.5, linecolor='black')  # Adjust fmt to control percentage display

# Adjust layout to prevent y-axis label cutoff
# plt.tight_layout()

# Save the figure
plt.savefig('classification_report.png')

# Display the plot
# plt.show()

# Export the trained model to ONNX format
initial_type = [('float_input', FloatTensorType([None, X_train.shape[1]]))]
onnx_model = convert_sklearn(random_search_hgb.best_estimator_, initial_types=initial_type)
# Save the ONNX model to a file
onnx_filename = 'hgb_model.onnx'
with open(onnx_filename, 'wb') as f:
    f.write(onnx_model.SerializeToString())


print("Model has been built and evaluated!")