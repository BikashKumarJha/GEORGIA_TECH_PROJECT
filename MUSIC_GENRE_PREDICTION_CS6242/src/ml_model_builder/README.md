## Music Event Success Prediction

# Overview
This Python script aims to predict the success rate of music events using machine learning techniques. The prediction is based on features obtained from two datasets: 'pta_mta' and 'mta.' The script leverages popular Python libraries such as pandas, numpy, scikit-learn, tensorflow, seaborn, and matplotlib.

# Prerequisites
Before running the script, make sure you have the required Python libraries installed. You can install them using the following command:

bash
pip install pandas numpy scikit-learn tensorflow seaborn matplotlib psycopg2 onnxruntime skl2onnx

# Data Retrieval
The script fetches data from a PostgreSQL database hosted on Azure. The connection parameters are specified within the fetch_data_from_database function. Ensure that you have the necessary credentials and adjust the connection parameters accordingly.

# Data Preprocessing
The datasets undergo extensive preprocessing, including:

Removing irrelevant columns
Handling missing values
Binning numerical features
Calculating success scores
Creating a 'success_rate' column

# Machine Learning Model
The script employs a Histogram-based Gradient Boosting Classifier for predicting success rates. The model is trained using hyperparameter tuning via RandomizedSearchCV. Evaluation metrics, such as accuracy, precision, recall, and F1-score, are computed, and a confusion matrix heatmap is generated.

# Visualization
The script includes visualizations of model performance, including:

Confusion matrix heatmap
Pair plot of hyperparameters and mean test score
Classification report heatmap

# Model Export
The trained model is exported to the ONNX format for portability and can be found in the 'hgb_model.onnx' file.

Running the Script
Execute the script in a Python environment with the necessary dependencies installed. Ensure that the PostgreSQL server is accessible, and database credentials are correct.

bash
python hgb_model_builder.py
