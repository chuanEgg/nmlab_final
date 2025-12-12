import cv2
import mediapipe as mp
import numpy as np
from ultralytics import YOLO
from collections import deque
import math
from picamera2 import Picamera2
from libcamera import Transform
class FocusAnalyzer:
    def __init__(self):
        print("初始化分析大腦...")
        
        # 1. 載入 MediaPipe Face Mesh
        self.mp_face_mesh = mp.solutions.face_mesh
        self.face_mesh = self.mp_face_mesh.FaceMesh(
            max_num_faces=1,
            refine_landmarks=True,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        
        # 2. 載入 YOLO
        self.yolo = YOLO('yolov8n.pt')

        # 3. 參數設定
        self.FRAME_W = 800 
        self.FRAME_H = 600
        
        self.SLEEP_FRAMES = 15 
        
        # 視線與姿勢容忍度
        self.GAZE_TOLERANCE = 0.18      # 左右看容許範圍
        self.HEAD_DOWN_TOLERANCE = 0.15 # 低頭容許範圍
        self.CALIBRATION_FRAMES = 20    # 校正幀數 (稍微多一點比較準)
        
        # 閉眼判定比例
        # 不再用固定像素，而是：當眼睛小於「正常大小的 60%」時才算睡覺
        self.EYE_CLOSE_RATIO = 0.60 

        # 4. 狀態記憶
        self.focus_score = 100
        self.status = "Init"
        self.closed_eye_counter = 0
        
        # 校正數據
        self.is_calibrated = False
        self.calib_gaze = [] # 視線數據
        self.calib_nose = [] # 鼻子高度數據
        self.calib_eye_h = [] # 眼睛高度數據
        
        self.center_gaze_base = 0.5 
        self.nose_y_base = 0.5      
        self.eye_open_base = 5.0    # 你的「正常眼睛大小」基準
        
        self.gaze_history = deque(maxlen=5) 

        # 關鍵點索引
        self.IDX_L_IRIS = 473
        self.IDX_L_EYE_L = 33
        self.IDX_L_EYE_R = 133
        self.IDX_L_EYE_TOP = 159
        self.IDX_L_EYE_BOT = 145
        self.IDX_NOSE = 1

    def calculate_distance(self, p1, p2, w, h):
        """計算兩點間的歐式距離"""
        x1, y1 = p1.x * w, p1.y * h
        x2, y2 = p2.x * w, p2.y * h
        return math.sqrt((x1 - x2)**2 + (y1 - y2)**2)

    def process_frame(self, frame):
        h, w, _ = frame.shape
        self.FRAME_H, self.FRAME_W = h, w
        CENTER_X, CENTER_Y = w // 2, h // 2

        # 1. 鏡像翻轉
        
        rgb_frame = frame

        # 2. YOLO 手機偵測
        phone_detected = False
        yolo_results = self.yolo(frame, classes=[67], conf=0.5, verbose=False)
        for result in yolo_results:
            for box in result.boxes:
                phone_detected = True
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 3)
                cv2.putText(frame, "PHONE!", (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)

        # 3. MediaPipe 臉部偵測
        results = self.face_mesh.process(rgb_frame)
        face_found = False
        landmarks = None

        if results.multi_face_landmarks:
            for face_landmarks in results.multi_face_landmarks:
                landmarks = face_landmarks.landmark
                face_found = True
                
                # 畫鼻子
                # nose_pt = landmarks[self.IDX_NOSE]
                # cv2.circle(frame, (int(nose_pt.x * w), int(nose_pt.y * h)), 5, (0, 255, 0), -1)

        # --- 邏輯判斷 ---
        if face_found and landmarks:
            # 計算眼睛真實距離 (眼睛開合大小)
            eye_dist = self.calculate_distance(
                landmarks[self.IDX_L_EYE_TOP], 
                landmarks[self.IDX_L_EYE_BOT], w, h
            )

            # 計算視線相對位置
            iris_x = landmarks[self.IDX_L_IRIS].x * w
            eye_l_x = landmarks[self.IDX_L_EYE_L].x * w
            eye_r_x = landmarks[self.IDX_L_EYE_R].x * w
            eye_w = abs(eye_r_x - eye_l_x)
            
            current_rel_pos = 0.5
            if eye_w > 0:
                current_rel_pos = (iris_x - eye_l_x) / eye_w

            # 取得目前鼻子高度
            current_nose_y = landmarks[self.IDX_NOSE].y

            # === 校正模式 ===
            if not self.is_calibrated:
                self.status = f"Calibrating {len(self.calib_gaze)}/{self.CALIBRATION_FRAMES}"
                cv2.putText(frame, "Keep EYES OPEN", (CENTER_X-150, CENTER_Y), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
                
                # 這裡不管眼睛大小，只要有偵測到就蒐集，這樣才能算出「你的」平均值
                self.calib_gaze.append(current_rel_pos)
                self.calib_nose.append(current_nose_y)
                self.calib_eye_h.append(eye_dist) # 蒐集你的眼睛大小
                
                if len(self.calib_gaze) >= self.CALIBRATION_FRAMES:
                    # 計算所有基準值
                    self.center_gaze_base = np.mean(self.calib_gaze)
                    self.nose_y_base = np.mean(self.calib_nose)
                    self.eye_open_base = np.mean(self.calib_eye_h) # 算出你的「標準眼睛大小」
                    
                    self.is_calibrated = True
                    # print(f"校正完成! 眼睛大小基準:{self.eye_open_base:.2f}")

            # === 正常運作模式 ===
            else:
                # 計算動態閉眼門檻：你的標準大小 * 0.6
                dynamic_close_threshold = self.eye_open_base * self.EYE_CLOSE_RATIO

                # 更新視線歷史 (只有張眼時才更新)
                if eye_dist > dynamic_close_threshold:
                    self.gaze_history.append(current_rel_pos)
                avg_rel_pos = np.mean(self.gaze_history) if self.gaze_history else 0.5

                # 判斷優先級
                if phone_detected:
                    self.status = "NO PHONE!"
                    self.focus_score -= 5
                
                # 使用動態門檻
                elif eye_dist < dynamic_close_threshold:
                    self.closed_eye_counter += 1
                    if self.closed_eye_counter > self.SLEEP_FRAMES:
                        self.status = "Sleeping zZz"
                        self.focus_score -= 2
                else:
                    self.closed_eye_counter = 0
                    
                    # 低頭判定
                    if current_nose_y > (self.nose_y_base + self.HEAD_DOWN_TOLERANCE):
                        self.status = "Head Down"
                        self.focus_score -= 1
                    
                    # 視線判定
                    elif avg_rel_pos < (self.center_gaze_base - self.GAZE_TOLERANCE):
                        self.status = "Look RIGHT ->"
                        self.focus_score -= 0.5
                    elif avg_rel_pos > (self.center_gaze_base + self.GAZE_TOLERANCE):
                        self.status = "<- Look LEFT"
                        self.focus_score -= 0.5
                    
                    else:
                        self.status = "Focused!"
                        self.focus_score += 0.5

        else:
            self.status = "Absent"
            self.focus_score -= 1
            self.closed_eye_counter = 0

        # 分數限制
        self.focus_score = max(0, min(100, self.focus_score))

        # 繪製介面
        bar_width = int((self.focus_score / 100) * 300)
        color = (0, 255, 0) if self.focus_score > 60 else (0, 0, 255)
        cv2.rectangle(frame, (20, 40), (20 + bar_width, 70), color, -1)
        cv2.rectangle(frame, (20, 40), (320, 70), (255, 255, 255), 2)
        cv2.putText(frame, f"Score: {int(self.focus_score)}", (340, 65), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2)
        cv2.putText(frame, f"Status: {self.status}", (20, 110), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
        
        # 顯示個人化數據 (Debug)
        # if self.is_calibrated:
        #      cv2.putText(frame, f"Eye Base: {self.eye_open_base:.1f}", (20, 150), cv2.FONT_HERSHEY_PLAIN, 1, (200,200,200), 1)

        return frame, int(self.focus_score), self.status


if __name__ == "__main__":
    try:
        analyzer = FocusAnalyzer()


        picam2 = Picamera2()
        config = picam2.create_preview_configuration(main={"format": "RGB888", "size": (800, 600)})
        picam2.configure(config)
        picam2.start()
        while True:
            frame = picam2.capture_array()
            if frame is None:
                break

            processed_frame, score, status = analyzer.process_frame(frame)

            cv2.imshow("FocusChain Monitor", processed_frame)

            key = cv2.waitKey(1) & 0xFF
            if key == ord('q') or key == 27: # 按 q 或 ESC 離開
                break
        
    finally:
        picam2.stop()
        cv2.destroyAllWindows()