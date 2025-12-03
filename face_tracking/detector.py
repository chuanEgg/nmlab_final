import argparse
import sys
import time
from picamera2 import Picamera2
from libcamera import Transform

import cv2
import mediapipe as mp

from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from utils import visualize

class FaceDetector:
    def __init__(self, model_path: str, \
                 min_detection_confidence: float, \
                 min_suppression_threshold: float, \
                 frame_width: int, \
                 frame_height: int, 
                 ):
        # Create a FaceDetector object.
        base_options = python.BaseOptions(model_asset_path=model_path)
        options = vision.FaceDetectorOptions(
            base_options=base_options,
            min_detection_confidence=min_detection_confidence,
            min_suppression_threshold=min_suppression_threshold,
        )
        self.frame_width = frame_width
        self.frame_height = frame_height
        self.detector = vision.FaceDetector.create_from_options(options)

    def detect(self, image):
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=image)
        detection_result = self.detector.detect(mp_image)
        return detection_result
    
if __name__ == '__main__':
    parser = argparse.ArgumentParser(
      formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        '--model',
        help='Path of the face detection model.',
        required=False,
        default='detector.tflite')
    parser.add_argument(
        '--minDetectionConfidence',
        help='The minimum confidence score for the face detection to be '
            'considered successful..',
        required=False,
        type=float,
        default=0.5)
    parser.add_argument(
        '--minSuppressionThreshold',
        help='The minimum non-maximum-suppression threshold for face detection '
            'to be considered overlapped.',
        required=False,
        type=float,
        default=0.5)
    parser.add_argument(
        '--frameWidth',
        help='Width of frame to capture from camera.',
        required=False,
        type=int,
        default=1280)
    parser.add_argument(
        '--frameHeight',
        help='Height of frame to capture from camera.',
        required=False,
        type=int,
        default=720)
    args = parser.parse_args()

    detector = FaceDetector(
        model_path=args.model,
        min_detection_confidence=args.minDetectionConfidence,
        min_suppression_threshold=args.minSuppressionThreshold,
        frame_width=args.frameWidth,
        frame_height=args.frameHeight,
    )

    picam2 = Picamera2()
    config = picam2.create_preview_configuration(
        main={"format": "RGB888", "size": (args.frameWidth, args.frameHeight)},
        transform=Transform(hflip=0, vflip=1)  # If the camera is upside down
    )
    picam2.configure(config)
    picam2.start()

    COUNTER, FPS = 0, 0
    START_TIME = time.time()
    DETECTION_RESULT = None

    while True:
        frame = picam2.capture_array()
        image = cv2.flip(frame, 1)
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        detection_result = detector.detect(rgb_image)
        if detection_result:
            image, center_x, center_y = visualize(image, detection_result)

        cv2.imshow('MediaPipe Face Detection', image)
        print(f"Face center: ({center_x}, {center_y})")
        if cv2.waitKey(5) & 0xFF == 27:
            break
        
    picam2.stop()
    cv2.destroyAllWindows()