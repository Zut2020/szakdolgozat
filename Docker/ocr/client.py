import os
import sys
import socket

s = socket.socket()


# Define the port on which you want to connect
port = 40675

# connect to the server on local computer
s.connect((sys.argv[1], port))
# close the connection
s.close()
