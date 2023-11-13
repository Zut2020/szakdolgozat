import socket
import detection

# next create a socket object
s = socket.socket()
print ("Socket successfully created")
 
# reserve a port on your computer in our
# case it is 40674 but it can be anything
port = 40674
 
# Next bind to the port
# we have not typed any ip in the ip field
# instead we have inputted an empty string
# this makes the server listen to requests
# coming from other computers on the network
s.bind(('', port))
print ("socket binded to %s" %(port))
 
# put the socket into listening mode
s.listen(5)    
print ("socket is listening")
 
# a forever loop until we interrupt it or
# an error occurs
while True:
 
    # Establish connection with client.
    c, addr = s.accept()
    print ('Got connection from', addr )
 
    # send a thank you message to the client.
    c.send(b'Starting detection...')

    free_spaces = detection.detect()

    s2 = socket.socket()
    # connect to the server on local computer
    s2.connect(("localhost", 40675))
    # close the connection
    s2.close()

    c.send(str(free_spaces).encode())
 
    # Close the connection with the client
    c.close()