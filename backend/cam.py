from picamera2 import Picamera2
import time

picam2 = Picamera2()

# 設定拍照模式
config = picam2.create_still_configuration()
picam2.configure(config)

# 開啟預覽畫面（在桌面模式會出現視窗）
picam2.start_preview()

# 啟動相機
picam2.start()
time.sleep(2)  # 給鏡頭2秒自動曝光

# 拍照
picam2.capture_file("test.jpg")
print("Saved test.jpg")

# 停止相機
picam2.stop()
