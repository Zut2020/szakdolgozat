FROM ubuntu:jammy

WORKDIR /server

RUN apt update
RUN apt upgrade -y

RUN apt-get install software-properties-common -y
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get install python3.7 -y
RUN apt-get install python3.7-distutils -y

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1
RUN update-alternatives --set python /usr/bin/python3.7

RUN apt-get update && apt-get install ffmpeg libsm6 libxext6  -y

RUN apt-get install python3-pip -y
RUN python -m pip install --upgrade pip

COPY requirements.txt .
RUN python -m pip install -r requirements.txt

COPY regions.p .
RUN apt-get install git -y
RUN git clone https://github.com/matterport/Mask_RCNN.git

WORKDIR /server/Mask_RCNN
RUN python -m pip install -r requirements.txt
RUN python setup.py install

WORKDIR /server
COPY server.py .
COPY detection.py .
ENTRYPOINT ["python", "/server/server.py"]