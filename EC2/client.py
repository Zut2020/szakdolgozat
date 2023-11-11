import os
import socket
import boto3

s = socket.socket()

aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"]
aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"]
aws_session_token=os.environ["AWS_SESSION_TOKEN"]

client = boto3.client(
        's3',
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        aws_session_token=aws_session_token
    )

print("Uploading parking lot image...")
client.upload_file("parking_cars.png", "parking-g1t1sz", "parking_cars.png")
print("Upload complete.")

# Define the port on which you want to connect
port = 40674

# connect to the server on local computer
s.connect(('localhost', port))

# receive data from the server
print(s.recv(1024).decode())
print("Free spaces: " + s.recv(1024).decode())

print("Downloading results...")
client.download_file('parking-g1t1sz', 'parking_result.png', "parking-result.png")
print("Download complete.")

# close the connection
s.close()
