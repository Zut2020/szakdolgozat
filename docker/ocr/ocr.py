import cv2
import os
import pytesseract
import numpy as np


def license_plate_detect(path_to_image):
    image_cv2 = cv2.imread(path_to_image)

    grayscale_image = cv2.cvtColor(image_cv2, cv2.COLOR_BGR2GRAY)
    gaussian_blur_image = cv2.GaussianBlur(grayscale_image, (5, 5), 0)
    result_text = pytesseract.image_to_string(gaussian_blur_image, lang ='eng+tha')
    if result_text == '':
        result_text = "NotRecognizable"
    filter_result_text = "".join(result_text.split()).replace(":", "").replace("-", "")

    return filter_result_text