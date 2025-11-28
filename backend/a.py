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

while True:
    # 拍最大解析度影像
    frame = picam2.capture_array()
    h, w = frame.shape[:2]

    # DNN 輸入 600x600
    dnn_input = cv2.resize(frame, (600, 600))
    blob = cv2.dnn.blobFromImage(dnn_input, 1.0, (600, 600), (104.0, 177.0, 123.0))
    net.setInput(blob)
    detections = net.forward()

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

    # 顯示輸出縮小到 1920x1080
    display_frame = cv2.resize(frame, (1770,1000 ))
    cv2.imshow("DNN Face Detection", display_frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cv2.destroyAllWindows()
picam2.close()