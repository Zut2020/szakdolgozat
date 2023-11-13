import base64
import io
from textwrap import indent
from shapely.geometry import Polygon as shapely_poly
from shapely.geometry import box
import argparse
import pickle
from pathlib import Path
from mrcnn.model import MaskRCNN
import mrcnn.utils
import mrcnn.config
import cv2
import numpy as np
#import git
import os
import json
import boto3
import ocr

#if not os.path.exists("Mask_RCNN"):
#    print("Cloning M-RCNN repository...")
#    git.Git("./").clone("https://github.com/matterport/Mask_RCNN.git")


class Config(mrcnn.config.Config):
    NAME = "model_config"
    IMAGES_PER_GPU = 1
    GPU_COUNT = 1
    NUM_CLASSES = 81


config = Config()
config.display()

ROOT_DIR = os.getcwd()
MODEL_DIR = os.path.join(ROOT_DIR, "logs")
COCO_MODEL_PATH = os.path.join(ROOT_DIR, "mask_rcnn_coco.h5")

s3_client = boto3.client('s3')

dynamodb = boto3.client('dynamodb', region_name='us-east-1')

print(COCO_MODEL_PATH)
if not os.path.exists(COCO_MODEL_PATH):
    mrcnn.utils.download_trained_weights(COCO_MODEL_PATH)

def get_cars(boxes, class_ids):
    cars = []
    for i, box in enumerate(boxes):
        if class_ids[i] in [3, 8, 6]:
            cars.append(box)
    return np.array(cars)


def compute_overlaps(parked_car_boxes, car_boxes):
    new_car_boxes = []
    for box in car_boxes:
        y1 = box[0]
        x1 = box[1]
        y2 = box[2]
        x2 = box[3]

        p1 = (x1, y1)
        p2 = (x2, y1)
        p3 = (x2, y2)
        p4 = (x1, y2)
        new_car_boxes.append([p1, p2, p3, p4])

    overlaps = np.zeros((len(parked_car_boxes), len(new_car_boxes)))
    for i in range(len(parked_car_boxes)):
        for j in range(car_boxes.shape[0]):
            pol1_xy = parked_car_boxes[i]
            pol2_xy = new_car_boxes[j]
            polygon1_shape = shapely_poly(pol1_xy)
            polygon2_shape = shapely_poly(pol2_xy)

            polygon_intersection = polygon1_shape.intersection(
                polygon2_shape).area
            polygon_union = polygon1_shape.union(polygon2_shape).area
            IOU = polygon_intersection / polygon_union
            overlaps[i][j] = IOU
    return overlaps

    

model = MaskRCNN(mode="inference", model_dir=MODEL_DIR, config=Config())
model.load_weights(COCO_MODEL_PATH, by_name=True)
model.keras_model._make_predict_function()
regions = "regions.p"
with open(regions, 'rb') as f:
    parked_car_boxes = pickle.load(f)

def detect():
    print("Downloading image...")
    s3_client.download_file('parking-g1t1sz', 'parking_cars.png', "parking_cars.png")
    print("Download complete.")
    VIDEO_SOURCE = "parking_cars.png"
    alpha = 0.6
    im = cv2.imread(VIDEO_SOURCE)
    video_size = (im.shape[0], im.shape[1])
    #    h, w, _ = im.shape
    rgb_image = im[:, :, ::-1]
    results = model.detect([rgb_image], verbose=0)
    overlay = im.copy()

    cars = get_cars(results[0]['rois'], results[0]['class_ids'])
    overlaps = compute_overlaps(parked_car_boxes, cars)

    free_spaces = 0
    for parking_area, overlap_areas in zip(parked_car_boxes, overlaps):
        max_IoU_overlap = np.max(overlap_areas)
        if max_IoU_overlap < 0.15:
            cv2.fillPoly(overlay, [np.array(parking_area)], (71, 27, 92))
            free_space = True
            free_spaces = free_spaces + 1
    cv2.addWeighted(overlay, alpha, im, 1 - alpha, 0, im)
    cv2.imwrite("parking_result.png", im)

    
    for index, car_box in enumerate(cars):
        y1 = car_box[0]
        x1 = car_box[1]
        y2 = car_box[2]
        x2 = car_box[3]
        crop_img = im[y1:y2, x1:x2]
        car_pic_name = "car" + str(index) + ".png"
        cv2.imwrite(car_pic_name, crop_img)

        s3_client.upload_file(car_pic_name, "parking-g1t1sz", car_pic_name)
        dynamodb.put_item(TableName="Parking", Item={
        'CarID': {'N': str(index)},
        'picture_name': {'S': car_pic_name},
        'y1': {'N': str(y1)},
        'x1': {'N': str(x1)},
        'y2': {'N': str(y2)},
        'x2': {'N': str(x2)}
        })

        plate_number = ocr.license_plate_detect(car_pic_name)
        dynamodb.update_item(
            TableName="Parking", 
            Key={
                'CarID': {'N': str(index)}
            },
            UpdateExpression='SET plate_number = :val1',
            ExpressionAttributeValues={
                ':val1': {'S': plate_number}
            }
        )
        
        os.remove(car_pic_name)


    print("Uploading result...")
    s3_client.upload_file("parking_result.png", "parking-g1t1sz", "parking_result.png")
    os.remove("parking_result.png")
    print("Upload complete.")
    return free_spaces