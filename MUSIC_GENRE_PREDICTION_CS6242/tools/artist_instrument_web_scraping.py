import os
import psycopg2
import pandas as pd
import requests

# define global variables to store our DB credentials
os.environ['PYTHONIOENCODING'] = 'utf-8'
PGHOST = 'musicbrainz.postgres.database.azure.com'
PGDATABASE = os.environ.get('PGDATABASE', 'musicbrainz')
PGUSER = os.environ.get('PGUSER', 'musicbrainz')
PGPASSWORD = os.environ.get('PGPASSWORD', 'Git62036242')
cnx = psycopg2.connect(host=PGHOST,database=PGDATABASE, 
                      user=PGUSER, password=PGPASSWORD)



sql_instruments = """
SELECT 
    instrument.id as instrument_id ,
    instrument.gid as instrument_gid,
    instrument.name as instrument_name,    
    instrument_type.name AS instrument_type
FROM 
    musicbrainz.instrument
JOIN 
    musicbrainz.instrument_type
ON 
    musicbrainz.instrument.type = musicbrainz.instrument_type.id;
"""

cnx = psycopg2.connect(host=PGHOST,database=PGDATABASE, 
                      user=PGUSER, password=PGPASSWORD)
crs = cnx.cursor()
crs.execute(sql_instruments)
csv_file = open('artist_instrument_relation.csv', 'w', newline='',encoding='utf-8')
csv_file.write('artist_name,artist_gender,artist_area,instrument_id,instrument_gid,instrument_name,instrument_type\n')
for result in crs:    
    url = 'https://musicbrainz.org/instrument/' + result[1]+'/artists'
    print(url)
    try:    
        response = requests.get(url)
    except:
        continue
    try:
        dfs = pd.read_html(response.text)    
    except ValueError:
        continue
    if (len(dfs) > 0): 
        artist_instrument_table_chunk = dfs[0][["Artist","Gender","Area"]]
        artist_instrument_table_chunk["instrument_id"] = result[0]
        artist_instrument_table_chunk["instrument_gid"] = result[1]
        artist_instrument_table_chunk["instrument_name"] = result[2]
        artist_instrument_table_chunk["instrument_type"] = result[3]
        try:
            artist_instrument_table_chunk.to_csv(csv_file, index=False, header=False, mode='a',encoding='utf-8')      
        except UnicodeEncodeError as e:        
            pass
        #artist_instrument_table_chunk.to_csv(csv_file, index=False, header=False, mode='a',encoding='utf-8')  

csv_file.close()
crs.close()
cnx.close()