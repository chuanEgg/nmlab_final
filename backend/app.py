import json
import os
import threading
from flask import Flask, Response, jsonify, request

app = Flask(__name__)

# --- 設定區 ---
PHOTO_PATH = "latest.jpg" 
DATA_FILE = "game_data.json"
file_lock = threading.Lock()

# --- 初始化資料庫 ---
def init_db():
    if not os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'w') as f:
            json.dump({}, f)

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

# 功能 1: 讀取最新照片
@app.route('/latest_photo', methods=['GET'])
def get_latest_photo():
    try:
        with open(PHOTO_PATH, 'rb') as f:
            image_data = f.read()
            return Response(image_data, mimetype='image/jpeg')
    except FileNotFoundError:
        return jsonify({"error": "Photo not found yet"}), 404

# 功能 2: 查玩家資料或所有玩家
@app.route('/status', defaults={'username': None}, methods=['GET'])
@app.route('/status/<username>', methods=['GET'])
def get_status(username):
    data = read_json()
    if username:  # 查單一玩家
        if username in data:
            user_data = data[username].copy()
            user_data['name'] = username
            return jsonify(user_data)
        else:
            return jsonify({"error": "User not found"}), 404
    else:  # 查全部玩家
        all_data = []
        for uname, udata in data.items():
            d = udata.copy()
            d['name'] = uname
            all_data.append(d)
        return jsonify(all_data)


# 功能 3: 更新玩家資料
@app.route('/update/<username>', methods=['POST'])
def update_user(username):
    incoming_data = request.json
    if not incoming_data:
        return jsonify({"error": "No JSON data"}), 400

    all_data = read_json()

    # 如果是新玩家，建立預設值
    if username not in all_data:
        all_data[username] = {"score": 0, "level": 1, "play_time": 0}  # 新增 play_time 預設值

    # 更新欄位
    if 'score' in incoming_data:
        all_data[username]['score'] = incoming_data['score']
    if 'level' in incoming_data:
        all_data[username]['level'] = incoming_data['level']
    if 'play_time' in incoming_data:
        all_data[username]['play_time'] = incoming_data['play_time']

    write_json(all_data)
    
    return jsonify({"message": "Updated", "data": all_data[username]})
# 功能 4: 刪除玩家資料
@app.route('/delete/<username>', methods=['DELETE'])
def delete_user(username):
    all_data = read_json()

    if username in all_data:
        deleted_data = all_data.pop(username)
        write_json(all_data)
        return jsonify({"message": "User deleted", "data": deleted_data})
    else:
        return jsonify({"error": "User not found"}), 404
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)