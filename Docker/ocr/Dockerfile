FROM ubuntu:jammy

WORKDIR /server

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install tesseract-ocr -y
RUN apt-get install libtesseract-dev -y
RUN apt-get update && apt-get install ffmpeg libsm6 libxext6  -y


RUN apt-get install python3 -y

RUN apt-get install python3-pip -y
RUN python3 -m pip install --upgrade pip

COPY requirements.txt .

RUN python3 -m pip install -r requirements.txt

COPY server.py .
COPY ocr.py .

WORKDIR /server
ENTRYPOINT ["python3", "/server/server.py"]