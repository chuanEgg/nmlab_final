import time
import RPi.GPIO as GPIO
from utils import angle_to_duty_cycle, setup_servo
from detector import FaceDetector

import cv2
from picamera2 import Picamera2
from libcamera import Transform
import asyncio

class FaceTracker:
    def __init__(self):
        self.pan_pwm, self.tilt_pwm = setup_servo()
        self.pan_angle = 90  # Initial angle
        self.tilt_angle = 60  # Initial angle
        # self.move_to(self.pan_angle, self.tilt_angle)
        self.pan_pwm.ChangeDutyCycle(angle_to_duty_cycle(self.pan_angle))
        self.tilt_pwm.ChangeDutyCycle(angle_to_duty_cycle(self.tilt_angle))
        self.detector = FaceDetector(
            model_path='detector.tflite',
            min_detection_confidence=0.5,
            min_suppression_threshold=0.5,
            frame_width=1280,
            frame_height=720
        )
        
    def smooth_move(self, current, target, pwm, steps=5, delay=0.05):
        if current == target:
            return current
        delta = (target - current) / steps
        for _ in range(steps):
            current += delta
            pwm.ChangeDutyCycle(angle_to_duty_cycle(current))
            # await asyncio.sleep(delay)
            time.sleep(delay)
        pwm.ChangeDutyCycle(0)  # Stop pulse to avoid jitter
        return target

    def move_to(self, target_pan, target_tilt):
        target_pan = max(0, min(180, target_pan))
        target_tilt = max(0, min(180, target_tilt))
        if target_pan != self.pan_angle:
            self.pan_angle = self.smooth_move(self.pan_angle, target_pan, self.pan_pwm)
        if target_tilt != self.tilt_angle:
            self.tilt_angle = self.smooth_move(self.tilt_angle, target_tilt, self.tilt_pwm)

    def cleanup(self):
        self.pan_pwm.stop()
        self.tilt_pwm.stop()
        GPIO.cleanup()

    def track(self, image):
        detection_result = self.detector.detect(image)
        if detection_result.detections:
            bbox = detection_result.detections[0].bounding_box # defaults to the first detected face
            center_x = bbox.origin_x + bbox.width // 2
            center_y = bbox.origin_y + bbox.height // 2
            print(f"face center: {center_x}, {center_y}")
            # Calculate target angles based on face position
            # target_pan = 90 + (center_x - self.detector.frame_width / 2) * (90 / (self.detector.frame_width / 2))
            # target_tilt = 90 - (center_y - self.detector.frame_height / 2) * (90 / (self.detector.frame_height / 2))
            error_x = center_x - (self.detector.frame_width / 2)
            error_y = center_y - (self.detector.frame_height / 2)
            
            if abs(error_x) > 100 or abs(error_y) > 50:
                target_pan = self.pan_angle + (error_x * 0.04)
                target_tilt = self.tilt_angle - (error_y * 0.04)
                self.move_to(target_pan, target_tilt)
            
            # Clamp angles to valid range
            # target_pan = max(0, min(180, target_pan))
            # target_tilt = max(0, min(180, target_tilt))
        else:
            print("No face detected.")

if __name__ == '__main__':
    tracker = None
    
    try:
        tracker = FaceTracker()
        time.sleep(2)  # Allow time for the servos to initialize
        
        picamera2 = Picamera2()
        config = picamera2.create_preview_configuration(
            main={"format": "RGB888", "size": (1280, 720)},
        )
        picamera2.configure(config)
        picamera2.start()
        while True:
            frame = picamera2.capture_array()
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            tracker.track(rgb_frame)
        
    except KeyboardInterrupt:
        pass
    finally:
        if tracker:
            tracker.cleanup()
