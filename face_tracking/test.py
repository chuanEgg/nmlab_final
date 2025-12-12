from picamera2 import Picamera2
import cv2
picamera2 = Picamera2()
config = picamera2.create_preview_configuration(main={"format": "RGB888", "size":
    (800, 600)})
picamera2.configure(config)
picamera2.start()
frame = picamera2.capture_array()
cv2.imwrite("latest.jpg", cv2.flip(frame,0))