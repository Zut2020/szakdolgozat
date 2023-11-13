import os
import sys
import socket
import boto3

s = socket.socket()

client = boto3.client('s3')

print("Uploading parking lot image...")
client.upload_file("parking_cars.png", "parking-g1t1sz", "parking_cars.png")
print("Upload complete.")

# Define the port on which you want to connect
port = 40674

# connect to the server on local computer
s.connect((sys.argv[1], port))

# receive data from the server
print(s.recv(1024).decode())
print("Free spaces: " + s.recv(1024).decode())

print("Downloading results...")
client.download_file('parking-g1t1sz', 'parking_result.png', "parking-result.png")
print("Download complete.")

# close the connection
s.close()
