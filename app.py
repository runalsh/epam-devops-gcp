#!/usr/bin/python3

import psycopg2
# import urllib.request as req
import os
from dotenv import load_dotenv
import sys
import json
import requests
import logging
# import pandas as pd
# import sqlalchemy
# from psycopg2 import Error
from flask import Flask,request,render_template
# from prettytable import PrettyTable
# from prettytable import from_db_cursor
import datetime

load_dotenv()

currtime = datetime.datetime.now()
current_time = currtime.strftime("%H:%M:%S")


# вариант под docker compose
# db= {"user": "pypostgres","password": "pypostgres","host": "10.70.0.3","port": "5432","database": "pydb"}
db = {
      "user": os.getenv('DB_USER'),
      "password": os.getenv('DB_PASSWORD'),
      "host": os.getenv('DB_HOST'),
      "port": "5432",
      "database": os.getenv('DB_NAME')
}
# некрасиво с хостом, надо так: terraform output > var > host 
# TODO

def storedata():
    connection = psycopg2.connect(**db)
    connection.autocommit = True
    # print('Connected')
    cursor = connection.cursor()
    create_clean = '''
        DROP table IF exists weather;
        CREATE table if not exists weather(id bigint PRIMARY KEY, weather_state_name varchar(16),wind_direction_compass varchar(5),created timestamp,applicable_date date, max_temp real, min_temp real, the_temp real);
        '''
    cursor.execute(create_clean)

    for day in range(1,2):
        response = requests.get("https://www.metaweather.com/api/location/2122265/"+str(currtime.year)+"/"+str(currtime.month)+"/"+str(day)+"/")
        for data in response.json():
            id = data['id']
            weather_state_name = data['weather_state_name'].strip('"')
            wind_direction_compass = data['wind_direction_compass'].strip('"')            
            created = data['created'].strip('"')
            applicable_date = data['applicable_date'].strip('"')
            max_temp = data['max_temp']
            min_temp = data['min_temp']
            the_temp = data['the_temp']
            
            cursor.execute("INSERT into weather values( %s, %s, %s, %s, %s, %s, %s, %s)", (id, weather_state_name, wind_direction_compass, created, applicable_date, max_temp, min_temp, the_temp))
    cursor.close()
    # connection.commit()
    connection.close()

def tablewipe():
    connection = psycopg2.connect(**db)
    connection.autocommit = True
    # print('Connected')
    cursor = connection.cursor()
    clean = '''
        DROP table IF exists weather;
        '''
    cursor.execute(clean)
    cursor.close()
    # connection.commit()
    connection.close()
    
# def allweather():
    # connection = psycopg2.connect(**db)
    # cursor = connection.cursor()
    # getalldata = '''
        # SELECT * FROM weather ORDER BY created;
        # '''
    # cursor.execute(getalldata)

    # record = cursor.fetchall()
    # columns = cursor.description
    # rows = '<tr>'
    # for row1 in columns:
       # rows += f'<td>{row1[0]}</td>'
    # rows += '</tr>'

    # for row in record:
      # rows += f"<tr>"
      # for col in row:
        # rows += f"<td>{col}</td>"
      # rows += f"</tr>"
    # data = '''
    # <html>
    # <style> table,  td {border:1px solid black; }td</style><body><table>%s</table></body></html>'''%(rows)
    # with open("index.html", "w") as file:
        # file.write(data)
    # file.close()
    # # print(data)
    # cursor.close()
    # # connection.commit()
    # connection.close()
    
# убрал к херам, мб понадобится для дебага



app = Flask(__name__)
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0

@app.route('/ping')
def ping():
    return "PONG! im SNAKE and im alive! now "+current_time
    
@app.route('/getdata')
def getdata():
    storedata()
    return "update completed at "+current_time

@app.route('/cleandata')
def cleandata():
    tablewipe()
    return "table wiping completed at "+current_time

# @app.route('/showmeallweather')
# def showmeallweather():
    # allweather()
    # return "indexhtml ready at"+current_time

@app.route('/')    
def homepage():
    return render_template('fill.html')
    
@app.route('/showmeweather')
def showmeweather():
    date = request.args.get('date')
    # print(date)

    # logger.info(type(resp_weather))
    
    connection = psycopg2.connect(**db)
    cursor = connection.cursor()
    getalldata = '''SELECT * FROM weather WHERE applicable_date = '%s' ORDER BY created; '''% date
    # print (getalldata)
    cursor.execute(getalldata)

    record = cursor.fetchall()
    columns = cursor.description
    rows = '<tr>'
    for row1 in columns:
       rows += f'<td>{row1[0]}</td>'
    rows += '</tr>'

    for row in record:
      rows += f"<tr>"
      for col in row:
        rows += f"<td>{col}</td>"
      rows += f"</tr>"
    data = '''
    <html> <style> table,  td {border:1px solid black; }td</style><body><table>%s</table></body></html>'''%(rows)
    # print(data)
    cursor.close()
    # connection.commit()
    connection.close()
    # return "indexhtml ready at"+current_time
    return render_template('shooooooooooooow.html', text=data)

# TODO ДОБАВИТЬ STRESS в базу

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
    app.run(debug=True)
