# Adapted from MediaPipe sample code (https://github.com/google-ai-edge/mediapipe-samples/blob/main/examples/face_detector/raspberry_pi/utils.py)

import cv2
import numpy as np
import time

from mediapipe.tasks import python
from mediapipe.tasks.python import vision

import RPi.GPIO as GPIO
from gpiozero import Servo

MARGIN = 10  # pixels
ROW_SIZE = 30  # pixels
FONT_SIZE = 1
FONT_THICKNESS = 1
TEXT_COLOR = (0, 0, 0)  # black

PAN_PIN = 17
TILT_PIN = 27
PAN_FREQ = 50
TILT_FREQ = 50


def visualize(
    image,
    detection_result
) -> np.ndarray:
  """Draws bounding boxes on the input image and return it.
  Args:
    image: The input RGB image.
    detection_result: The list of all "Detection" entities to be visualized.
  Returns:
    Image with bounding boxes.
  """
  center_x, center_y = None, None
  for detection in detection_result.detections:
    # Draw bounding_box
    bbox = detection.bounding_box
    start_point = bbox.origin_x, bbox.origin_y
    end_point = bbox.origin_x + bbox.width, bbox.origin_y + bbox.height
    # Use the orange color for high visibility.
    cv2.rectangle(image, start_point, end_point, (0, 165, 255), 3)

    # Draw crosshair at the center of the bounding box
    center_x = bbox.origin_x + bbox.width // 2
    center_y = bbox.origin_y + bbox.height // 2

    try:
      cv2.drawMarker(image, (center_x, center_y), (255, 0, 0), markerType=cv2.MARKER_CROSS, 
                    markerSize=20, thickness=2)
    except Exception as e:
      print(f"Error drawing marker: {e}")
    
    # Draw crosshair at the center of the image
    img_center_x = image.shape[1] // 2
    img_center_y = image.shape[0] // 2
    cv2.drawMarker(image, (img_center_x, img_center_y), (0, 255, 0), markerType=cv2.MARKER_CROSS, 
                    markerSize=20, thickness=2)
    # Draw label and score
    category = detection.categories[0]
    category_name = (category.category_name if category.category_name is not
                     None else '')
    probability = round(category.score, 2)
    result_text = category_name + ' (' + str(probability) + ')'
    text_location = (MARGIN + bbox.origin_x,
                     MARGIN + ROW_SIZE + bbox.origin_y)
    cv2.putText(image, result_text, text_location, cv2.FONT_HERSHEY_DUPLEX,
                FONT_SIZE, TEXT_COLOR, FONT_THICKNESS, cv2.LINE_AA)

  return image, center_x, center_y

def setup_servo():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(PAN_PIN, GPIO.OUT)
    GPIO.setup(TILT_PIN, GPIO.OUT)
    pan_pwm = GPIO.PWM(PAN_PIN, PAN_FREQ)
    tilt_pwm = GPIO.PWM(TILT_PIN, TILT_FREQ)
    pan_pwm.start(7.5)  # Neutral position
    tilt_pwm.start(7.5)  # Neutral position
    return pan_pwm, tilt_pwm

def setup_servo_gpiozero():
    servo_pan = Servo(PAN_PIN)
    servo_tilt = Servo(TILT_PIN)
    servo_pan.mid()
    servo_tilt.mid()
    return servo_pan, servo_tilt

def angle_to_duty_cycle(angle):
    return 2.5 + (angle / 180.0) * 10

def angle_to_gpiozero_value(angle):
    return (angle - 90) / 90 + 0.1 # Maps 0-180 to -1 to 1