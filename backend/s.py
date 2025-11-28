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
tilt_angle = 90

def smooth_move(current, target, pwm, steps=20, delay=0.05):
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

try:
    while True:
        try:
            target_pan = float(input("Pan 0~180: "))
            target_tilt = float(input("Tilt 0~180: "))
        except ValueError:
            print("請輸入數字")
            continue

        # 只有當目標角度和當前角度不一樣才移動
        if target_pan != pan_angle:
            pan_angle = smooth_move(pan_angle, target_pan, pan_pwm)
        if target_tilt != tilt_angle:
            tilt_angle = smooth_move(tilt_angle, target_tilt, tilt_pwm)

except KeyboardInterrupt:
    print("Exiting...")

finally:
    pan_pwm.stop()
    tilt_pwm.stop()
    GPIO.cleanup()