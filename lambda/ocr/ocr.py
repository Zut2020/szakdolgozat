import cv2
import os
import pytesseract
import numpy as np
import boto3
import json

dynamodb_client = boto3.client('dynamodb', region_name='us-east-1')
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    key  = event['Records'][0]['s3']['object']['key']

    response = s3_client.get_object(
        Bucket=bucket_name,
        Key=key)
    image = response['Body'].read()
    image_cv2 = cv2.imdecode(np.asarray(bytearray(image)), cv2.IMREAD_COLOR)

    text = pytesseract.image_to_string(image_cv2, lang ='tha+eng')

    id = os.path.splitext(key)[0]

    dynamodb_client.update_item(
            TableName="Parking", 
            Key={
                'CarID': {'N': id}
            },
            UpdateExpression='SET plate_number = :val1',
            ExpressionAttributeValues={
                ':val1': {'S': text}
            }
        )

    return {
    'statusCode': 200,
        'body': json.dumps("OK")
    }