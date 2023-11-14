FROM public.ecr.aws/lambda/python:3.11

# RUN yum install tesseract-ocr -y
# RUN yum install libtesseract-dev -y0
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -y update
RUN yum install mesa-libGL -y
RUN yum -y install tesseract tesseract-langpack-tha


COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN python -m pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

COPY ocr.py ${LAMBDA_TASK_ROOT}

CMD ["ocr.lambda_handler"]