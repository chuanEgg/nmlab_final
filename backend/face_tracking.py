import cv2
from picamera2 import Picamera2
from libcamera import Transform
import numpy as np

# 初始化 Picamera2
picam2 = Picamera2()
config = picam2.create_preview_configuration(
    main={"format": "RGB888", "size": (4608, 2592)},  # 最大解析度
    transform=Transform(hflip=0, vflip=True)      # 如果鏡頭倒置
)
picam2.configure(config)
picam2.start()

# 載入 DNN 模型
net = cv2.dnn.readNetFromCaffe("deploy.prototxt", "res10_300x300_ssd_iter_140000.caffemodel")
import RPi.GPIO as GPIO
import time

PAN_PIN = 17
TILT_PIN = 27

GPIO.setmode(GPIO.BCM)
GPIO.setup(PAN_PIN, GPIO.OUT)
GPIO.setup(TILT_PIN, GPIO.OUT)

pan_pwm = GPIO.PWM(PAN_PIN, 50)
tilt_pwm = GPIO.PWM(TILT_PIN, 50)

pan_pwm.start(7.5)
tilt_pwm.start(7.5)

def angle_to_duty(angle):
    return 2.5 + (angle / 180.0) * 10

# 初始角度
pan_angle = 90
tilt_angle = 70

def smooth_move(current, target, pwm, steps=1, delay=0.05):
    # 如果角度沒改變，直接返回
    if current == target:
        return current

    delta = (target - current) / steps
    for _ in range(steps):
        current += delta
        pwm.ChangeDutyCycle(angle_to_duty(current))
        time.sleep(delay)
    pwm.ChangeDutyCycle(0)  # 停止輸出脈衝，避免伺服機抖動

    return target
def move_pan(angle):
    """設定 Pan 角度，只更新一次 PWM"""
    angle = max(0, min(180, angle))  # 限制角度
    pan_pwm.ChangeDutyCycle(angle_to_duty(90))
    tilt_pwm.ChangeDutyCycle(angle_to_duty(70))
move_pan(90)
ppp=-1
while True:
    # 拍最大解析度影像
    frame = picam2.capture_array()
    h, w = frame.shape[:2]

    # DNN 輸入 600x600
    dnn_input = cv2.resize(frame, (600, 600))
    blob = cv2.dnn.blobFromImage(dnn_input, 1.0, (600, 600), (104.0, 177.0, 123.0))
    net.setInput(blob)
    detections = net.forward()
    ppp=ppp+1
    for i in range(detections.shape[2]):
        confidence = detections[0, 0, i, 2]
        if confidence > 0.5:
            # DNN 輸出的座標對應 600x600，需要映射回原始 4608x2592
            box = detections[0, 0, i, 3:7] * np.array([600, 600, 600, 600])
            x1, y1, x2, y2 = box.astype("int")

            # 映射到原始 frame
            scale_x = w / 600
            scale_y = h / 600
            x1 = int(x1 * scale_x)
            x2 = int(x2 * scale_x)
            y1 = int(y1 * scale_y)
            y2 = int(y2 * scale_y)

            # 臉中心
            cx = (x1 + x2) // 2
            cy = (y1 + y2) // 2
            print(f"Face center: ({cx}, {cy})")

            # 畫矩形與中心點
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cv2.circle(frame, (cx, cy), 5, (0, 0, 255), -1)
            lb = 2304-250
            rb = 2304+250
            print(str(ppp)+"frame")
            if ppp%5==0:
                
                if cx < 4600 and (cx < lb or cx > rb):
                    print(pan_angle)
                    target_angle = 45+cx/4600*90
                    target_angle = max(60, min(120, target_angle))  # 限制角度
                    smooth_move(pan_angle, target_angle,pan_pwm)
                    pan_angle = target_angle
                if cx < 4600 and (cx < lb or cx > rb):
                    print(pan_angle)
                    target_angle = 45+cx/4600*90
                    target_angle = max(60, min(120, target_angle))  # 限制角度
                    smooth_move(pan_angle, target_angle,pan_pwm)
                    pan_angle = target_angle
                
                
                if cy < 2600 and (cy < 1100 or cy > 1500):
                    print(tilt_angle)
                    target_angle = 70+  (cy-1300)/1300*15
                    target_angle = max(50, min(90, target_angle))  # 限制角度
                    smooth_move(tilt_angle, target_angle,tilt_pwm)
                    tilt_angle = target_angle
                if cy < 2600 and (cy < 1100 or cy > 1500):
                    print(tilt_angle)
                    target_angle = 70+  (cy-1300)/1300*15
                    target_angle = max(50, min(90, target_angle))  # 限制角度
                    smooth_move(tilt_angle, target_angle,tilt_pwm)
                    tilt_angle = target_angle
                else:
                    pass
                
            time.sleep(0.1)






    # 顯示輸出縮小到 1920x1080
    display_frame = cv2.resize(frame, (1770,1000 ))
    cv2.imshow("DNN Face Detection", display_frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cv2.destroyAllWindows()
picam2.close()