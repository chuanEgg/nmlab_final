import json
import os
import threading
from flask import Flask, Response, jsonify, request

app = Flask(__name__)

# --- 設定區 ---
# 1. 照片路徑：請確保你的照片是存在這裡
# 如果是用系統指令拍照存到 RAM，路徑通常是 '/dev/shm/latest.jpg'
# 如果是放在同資料夾下，就寫 'latest.jpg'
PHOTO_PATH = "latest.jpg" 

# 2. 資料庫檔案名稱
DATA_FILE = "game_data.json"

# 3. 檔案鎖：避免多個請求同時寫入造成資料損壞
file_lock = threading.Lock()

# --- 初始化資料庫 ---
def init_db():
    if not os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'w') as f:
            json.dump({}, f) # 建立空字典

init_db()

# --- 輔助函式 ---
def read_json():
    with file_lock:
        try:
            with open(DATA_FILE, 'r') as f:
                return json.load(f)
        except:
            return {}

def write_json(data):
    with file_lock:
        with open(DATA_FILE, 'w') as f:
            json.dump(data, f, indent=4)

# --- API 路由 ---

@app.route('/')
def index():
    return "Server Running (Reader Mode)"

# === 功能 1: 讀取照片 ===
@app.route('/latest_photo', methods=['GET'])
def get_latest_photo():
    """
    讀取硬碟中的圖片檔案並回傳給 App
    """
    try:
        with open(PHOTO_PATH, 'rb') as f:
            image_data = f.read()
            # 回傳圖片 (MIME type 設定為 image/jpeg)
            return Response(image_data, mimetype='image/jpeg')
    except FileNotFoundError:
        return jsonify({"error": "Photo not found yet"}), 404

# === 功能 2: 讀取特定玩家資料 ===
@app.route('/status/<username>', methods=['GET'])
def get_user_status(username):
    data = read_json()
    if username in data:
        user_data = data[username]
        user_data['name'] = username
        return jsonify(user_data)
    else:
        return jsonify({"error": "User not found"}), 404

# === 功能 3: 更新特定玩家資料 ===
@app.route('/update/<username>', methods=['POST'])
def update_user(username):
    incoming_data = request.json
    if not incoming_data:
        return jsonify({"error": "No JSON data"}), 400

    all_data = read_json()

    # 如果是新玩家，建立預設值
    if username not in all_data:
        all_data[username] = {"score": 0, "level": 1}

    # 更新欄位
    if 'score' in incoming_data:
        all_data[username]['score'] = incoming_data['score']
    if 'level' in incoming_data:
        all_data[username]['level'] = incoming_data['level']

    write_json(all_data)
    
    return jsonify({"message": "Updated", "data": all_data[username]})

if __name__ == '__main__':
    # 啟動 Server
    app.run(host='0.0.0.0', port=8000)