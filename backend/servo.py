import time
import lgpio

SERVO_PIN = 17  # BCM 腳位


# ---- PWM 設定 ----
chip = lgpio.gpiochip_open(0)
lgpio.gpio_claim_output(chip, SERVO_PIN)

# SG90 參考
# 0 度  = 0.5 ms
# 90 度 = 1.5 ms
# 180 度= 2.5 ms
# PWM 週期 = 20 ms → 頻率 = 50Hz


def angle_to_pulse(angle):
    # 限制角度
    angle = max(0, min(180, angle))
    # 轉換成 us
    return 500 + (angle / 180) * 2000


def set_angle(angle):
    pulse = angle_to_pulse(angle)
    period = 20000  # 20,000 us = 20 ms

    # 設定成 PWM
    lgpio.tx_pwm(chip, SERVO_PIN, 50, pulse / period * 100)  # duty = (pulse/period)*100


try:
    while True:
        print("轉到 0°")
        set_angle(0)
        time.sleep(1)

        print("轉到 90°")
        set_angle(90)
        time.sleep(1)

        print("轉到 180°")
        set_angle(180)
        time.sleep(1)

except KeyboardInterrupt:
    pass

finally:
    lgpio.gpiochip_close(chip)