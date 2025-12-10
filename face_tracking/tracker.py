import time
import RPi.GPIO as GPIO
from utils import angle_to_duty_cycle, angle_to_gpiozero_value, setup_servo, setup_servo_gpiozero
from detector import FaceDetector
from controller import PIDController

import cv2
from picamera2 import Picamera2
from libcamera import Transform
import asyncio
import os

class FaceTracker:
    def __init__(self):
        self.pan_pwm, self.tilt_pwm = setup_servo()
        self.pan_angle = 90  # Initial angle
        self.tilt_angle = 60  # Initial angle
        self.move_to(self.pan_angle, self.tilt_angle)
        self.pan_pwm.ChangeDutyCycle(angle_to_duty_cycle(self.pan_angle))
        self.tilt_pwm.ChangeDutyCycle(angle_to_duty_cycle(self.tilt_angle))
        # self.pan_servo, self.tilt_servo = setup_servo_gpiozero()
        # self.pan_servo.value = angle_to_gpiozero_value(self.pan_angle)
        # self.tilt_servo.value = angle_to_gpiozero_value(self.tilt_angle)
        current_path = os.path.dirname(os.path.abspath(__file__))
        model_path = os.path.join(current_path, 'detector.tflite')
        self.detector = FaceDetector(
            model_path=model_path,
            min_detection_confidence=0.5,
            min_suppression_threshold=0.5,
            frame_width=640,
            frame_height=480
        )
        self.controller = PIDController(kp=0.006, ki=0.0003, kd=0.001)
        self.sliding_window = []
        
    def smooth_move(self, current, target, pwm, steps=20, delay=0.01):
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
    
    def move(self, current, target, pwm):
        if current != target:
            pwm.ChangeDutyCycle(angle_to_duty_cycle(target))
            # time.sleep(0.5)  # Wait for servo to reach position
            # pwm.ChangeDutyCycle(0)  # Stop pulse to avoid jitter
        return target

    def move_gpiozero(self, current, target, servo):
        if current != target:
            servo.value = angle_to_gpiozero_value(target)
            # time.sleep(0.5)  # Wait for servo to reach position
        return target
    def move_to(self, target_pan, target_tilt):
        target_pan = max(0, min(180, target_pan))
        target_tilt = max(0, min(180, target_tilt))
        if target_pan != self.pan_angle:
            # self.pan_angle = self.smooth_move(self.pan_angle, target_pan, self.pan_pwm)
            self.pan_angle = self.move(self.pan_angle, target_pan, self.pan_pwm)
            # self.pan_angle = self.move_gpiozero(self.pan_angle, target_pan, self.pan_servo)
        if target_tilt != self.tilt_angle:
            # self.tilt_angle = self.smooth_move(self.tilt_angle, target_tilt, self.tilt_pwm)
            self.tilt_angle = self.move(self.tilt_angle, target_tilt, self.tilt_pwm)
            # self.tilt_angle = self.move_gpiozero(self.tilt_angle, target_tilt, self.tilt_servo)

    def cleanup(self):
        self.pan_pwm.stop()
        self.tilt_pwm.stop()
        GPIO.cleanup()
        Picamera2().stop()

    def track(self, image):
        detection_result = self.detector.detect(image)
        if detection_result.detections:
            bbox = detection_result.detections[0].bounding_box # defaults to the first detected face
            face_x = bbox.origin_x + bbox.width // 2
            face_y = bbox.origin_y + bbox.height // 2
            self.sliding_window.append((face_x, face_y))
            if len(self.sliding_window) > 5:
                self.sliding_window.pop(0)
            face_x = sum([pos[0] for pos in self.sliding_window]) // len(self.sliding_window)
            face_y = sum([pos[1] for pos in self.sliding_window]) // len(self.sliding_window)
            print(f"face center: {face_x}, {face_y}")
        else:
            face_x = self.sliding_window[-1][0] if self.sliding_window else self.detector.frame_width // 2
            face_y = self.sliding_window[-1][1] if self.sliding_window else self.detector.frame_height // 2
            print("No face detected.")
        # Calculate target angles based on face position
        # target_pan = 90 + (center_x - self.detector.frame_width / 2) * (90 / (self.detector.frame_width / 2))
        # target_tilt = 90 - (center_y - self.detector.frame_height / 2) * (90 / (self.detector.frame_height / 2))
        # error_x = face_x - (self.detector.frame_width / 2)
        # error_y = face_y - (self.detector.frame_height / 2)
        output_x, output_y = self.controller.compute((self.detector.frame_width / 2, self.detector.frame_height / 2), (face_x, face_y))
        
        # if abs(error_x) > 100 or abs(error_y) > 50:
        target_pan = self.pan_angle - output_x
        target_tilt = self.tilt_angle + output_y
        self.move_to(target_pan, target_tilt)
        
        # Clamp angles to valid range
        # target_pan = max(0, min(180, target_pan))
        # target_tilt = max(0, min(180, target_tilt))

if __name__ == '__main__':
    tracker = None
    
    try:
        tracker = FaceTracker()
        time.sleep(2)  # Allow time for the servos to initialize
        
        picamera2 = Picamera2()
        config = picamera2.create_preview_configuration(
            main={"format": "RGB888", "size": (640, 480)},
        )
        picamera2.configure(config)
        picamera2.start()
        
        frame_count = 0
        while True:
            frame = picamera2.capture_array()
            
            # Skip frames to reduce load
            frame_count += 1
            if frame_count % 3 != 0:
                continue
                
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            tracker.track(rgb_frame)
        
    except KeyboardInterrupt:
        pass
    finally:
        if tracker:
            tracker.cleanup()

def init_camera(retries=5):
    for i in range(retries):
        try:
            picamera2 = Picamera2()
            config = picamera2.create_preview_configuration(main={"format": "RGB888", "size": (640, 480)})
            picamera2.configure(config)
            picamera2.start()
            return picamera2
        except RuntimeError as e:
            print(f"Camera busy, retry {i+1}/{retries}")
            time.sleep(1)
    raise RuntimeError("Failed to initialize camera after retries")
def tracker_task(stop_event):
    """Thread loop, controlled by stop_event"""
    tracker = FaceTracker()
    time.sleep(2)

    picamera2 = init_camera()


    frame_count = 0
    try:
        while not stop_event.is_set():
            frame = picamera2.capture_array()

            frame_count += 1
            if frame_count % 3 != 0:
                continue

            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            tracker.track(frame_rgb)

    finally:
        tracker.cleanup()