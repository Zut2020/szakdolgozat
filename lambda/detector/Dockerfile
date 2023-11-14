FROM public.ecr.aws/lambda/python:3.7

#RUN apt-get update && apt-get install ffmpeg libsm6 libxext6  -y

COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN python3.7 -m pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

RUN yum install git -y
WORKDIR ${LAMBDA_TASK_ROOT}
RUN git clone https://github.com/matterport/Mask_RCNN.git

WORKDIR ${LAMBDA_TASK_ROOT}/Mask_RCNN
RUN python -m pip install -r requirements.txt
RUN python setup.py install

COPY regions.p ${LAMBDA_TASK_ROOT}
COPY detection.py ${LAMBDA_TASK_ROOT}

CMD ["detection.lambda_handler"]