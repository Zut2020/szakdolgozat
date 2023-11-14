import socket
import os
import ocr
import boto3
from flask import Flask, flash, request, redirect, url_for
from werkzeug.utils import secure_filename

dynamodb_resource = boto3.resource('dynamodb', region_name='us-east-1')

dynamodb_client = boto3.client('dynamodb', region_name='us-east-1')

s3_client = boto3.client('s3')

app = Flask(__name__)

@app.route('/', methods=['GET'])
def recognize():
    table = dynamodb_resource.Table('Parking')

    response = table.scan(ProjectionExpression='picture_name, CarID')
    data = response['Items']

    for item in data:
        picture_name = item['picture_name']
        print(picture_name)
        s3_client.download_file('cars-g1t1sz', picture_name, picture_name)
        plate_number = ocr.license_plate_detect(picture_name)
        dynamodb_client.update_item(
            TableName="Parking", 
            Key={
                'CarID': {'N': str(item['CarID'])}
            },
            UpdateExpression='SET plate_number = :val1',
            ExpressionAttributeValues={
                ':val1': {'S': plate_number}
            }
        )
        os.remove(picture_name)
    return "Recognition complete"

if __name__ == '__main__':
	app.run(host='0.0.0.0', port=8081)