import socket
import os
import ocr
import boto3

dynamodb_resource = boto3.resource('dynamodb')

dynamodb_client = boto3.client('dynamodb')

s3_client = boto3.client('s3')

s = socket.socket()
print ("Socket successfully created")
 
port = 40675
 
s.bind(('', port))
print ("socket binded to %s" %(port))

s.listen(5)    
print ("socket is listening")

while True:
 
    # Establish connection with client.
    c, addr = s.accept()

    table = dynamodb_resource.Table('Parking')

    response = table.scan(ProjectionExpression='picture_name, CarID')
    data = response['Items']

    for item in data:
        picture_name = item['picture_name']
        print(picture_name)
        s3_client.download_file('parking-g1t1sz', picture_name, picture_name)
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
 
    c.close()