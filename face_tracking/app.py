from flask import Flask, Response, jsonify, request
from pymongo import MongoClient
from bson.objectid import ObjectId
import os
from datetime import datetime, timezone, timedelta
import math
import threading
import time
from tracker import tracker_task

def calculate_level(score):
    return math.floor((-1 + math.sqrt(1 + 0.16 * score)) / 2)
app = Flask(__name__)
stop_event = threading.Event()
task_thread = None  # 全域保存 thread 物件

# --- 設定區 ---
PHOTO_PATH = "latest.jpg"
# MongoDB 連線
MONGO_URI = "mongodb+srv://hsiehjason00:hsiehjason00@cluster0.wiei66x.mongodb.net/?appName=Cluster0"
client = MongoClient(MONGO_URI)
db = client['focusmate_db']
users_collection = db['users']

try:
    client.admin.command('ping')
    print("Pinged your deployment. You successfully connected to MongoDB!")
except Exception as e:
    print(e)

# --- API 路由 ---
@app.route('/')
def index():
    return "Server Running (MongoDB Version with Sessions)"

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
    if username:
        user = users_collection.find_one({"username": username})
        if user:
            # 計算 score & level
            scores = user.get("scores", [])
            score = sum(scores)
            level = calculate_level(score)

            # 更新資料庫
            users_collection.update_one(
                {"username": username},
                {"$set": {"score": score, "level": level}}
            )

            # 將 _id 轉成字串
            user['_id'] = str(user['_id'])
            user["score"] = score
            user["level"] = level

            return jsonify(user)
        else:
            return jsonify({"error": "User not found"}), 404
    else:
        all_users = list(users_collection.find())
        for user in all_users:
            # 計算 score & level
            scores = user.get("scores", [])
            score = sum(scores)
            level = calculate_level(score)

            # 更新資料庫
            users_collection.update_one(
                {"_id": user["_id"]},
                {"$set": {"score": score, "level": level}}
            )

            # 將 _id 轉成字串
            user['_id'] = str(user['_id'])
            user["score"] = score
            user["level"] = level

        return jsonify(all_users)
# 功能 3: 更新玩家資料
@app.route('/update/<username>', methods=['POST'])
def update_user(username):
    incoming_data = request.json if request.is_json else {}

    # 如果玩家不存在，建立預設值
    default_data = {
        "username": username,
        "score": 0,
        "level": 1,
        "scores": [],
        "sessions": []
    }

    users_collection.update_one(
        {"username": username},
        {"$setOnInsert": default_data},
        upsert=True
    )


    # 更新簡單欄位（score, level）
    for field in ["score", "level"]:
        if field in incoming_data:
            update_fields[field] = incoming_data[field]

    # play_time 要是 array
    if "scores" in incoming_data:
        if isinstance(incoming_data["scores"], list):
            update_fields["scores"] = incoming_data["scores"]
        else:
            return jsonify({"error": "scores must be an array"}), 400

    # 更新 sessions（整個覆蓋）
    if "sessions" in incoming_data:
        if isinstance(incoming_data["sessions"], list):
            update_fields["sessions"] = incoming_data["sessions"]
        else:
            return jsonify({"error": "sessions must be an array"}), 400

    # 做更新
    if update_fields:
        users_collection.update_one(
            {"username": username},
            {"$set": update_fields}
        )

    user = users_collection.find_one({"username": username})
    user["_id"] = str(user["_id"])
    return jsonify({"message": "Updated", "data": user})


@app.route('/session/<username>', methods=['POST'])
def add_single_session(username):
    incoming = request.json or {}

    # 檢查格式
    if "start_time" not in incoming or "end_time" not in incoming:
        return jsonify({"error": "JSON must include start_time and end_time"}), 400

    # 確保 user 存在（不存在就建立）
    users_collection.update_one(
        {"username": username},
        {
            "$setOnInsert": {
                "username": username,
                "score": 0,
                "level": 1,
                "scores": 0,
                "sessions": []
            }
        },
        upsert=True
    )

    # 新 session 物件
    new_session = {
        "start_time": incoming["start_time"],
        "end_time": incoming["end_time"]
    }

    # append 到 sessions 陣列
    users_collection.update_one(
        {"username": username},
        {"$push": {"sessions": new_session}}
    )

    return jsonify({"message": "Session added", "session": new_session})

@app.route('/users', methods=['GET'])
def get_all_users():
    # 只抓 username 欄位
    users = users_collection.find({}, {"_id": 0, "username": 1})
    usernames = [user["username"] for user in users]
    return jsonify({"usernames": usernames})
@app.route('/rank', methods=['GET'])
def rank_by_score():
    # 找所有玩家，按 score 降序排序，只取 username 和 score
    users = list(users_collection.find(
        {},                    # 篩選條件，空表示所有玩家
        {"_id": 0, "username": 1, "score": 1}  # projection，只取 username & score
    ).sort("score", -1))       # -1 表示降序
    return jsonify(users)

@app.route('/session/start/<username>', methods=['POST'])
def start_session(username):
    session_info = start_session_internal(username)
    return jsonify({
        "message": "Session started",
        "session": session_info
    })


STATUS_FILE = "status.txt"


def read_status():
    if not os.path.exists(STATUS_FILE):
        return 0  # default = OFF
    with open(STATUS_FILE, "r") as f:
        return int(f.read().strip())


def write_status(value):
    with open(STATUS_FILE, "w") as f:
        f.write(str(value))


@app.route("/button/status", methods=["GET"])
def get_button_status():
    s = read_status()
    global task_thread, stop_event
    
    return jsonify({"button_status": s, "task_thread": str(task_thread)})

def long_task():
    while not stop_event.is_set():
        print("Task running...")
        time.sleep(1)
    print("Task stopped.")

@app.route("/button/toggle", methods=["POST"])
def toggle_button():
    global task_thread, stop_event

    current = read_status()
    new_status = 0 if current == 1 else 1
    write_status(new_status)

    if new_status == 1:
        # 等上一次 thread 完全結束
        if task_thread is not None and task_thread.is_alive():
            stop_event.set()
            task_thread.join()

        stop_event.clear()
        task_thread = threading.Thread(target=tracker_task, args=(stop_event,))
        task_thread.start()
        #start_session_internal("Allen")
        return jsonify({"msg": "Tracker started"}), 202

    else:
        stop_event.set()
        if task_thread is not None:
            task_thread.join()   # 等 thread 結束
        #stop_session_internal("Allen")
        #append_score_internal("Allen", 10)
        return jsonify({"msg": "Tracker stopped"}), 200


tz_utc8 = timezone(timedelta(hours=8))

def start_session_internal(username):
    """真正處理 session start 的邏輯，可供內部呼叫。"""
    
    # 若沒有這個 user，建立新資料
    users_collection.update_one(
        {"username": username},
        {
            "$setOnInsert": {
                "username": username,
                "score": 0,
                "level": 1,
                "scores": [],
                "sessions": []
            }
        },
        upsert=True
    )

    now_str = datetime.now(tz_utc8).strftime("%Y-%m-%dT%H:%M:%S")

    new_session = {"start_time": now_str, "end_time": None}

    users_collection.update_one(
        {"username": username},
        {"$push": {"sessions": new_session}}
    )

    return new_session


def stop_session_internal(username):
    """結束最後一個尚未結束的 session，可供內部呼叫。"""

    now_str = datetime.now(tz_utc8).strftime("%Y-%m-%dT%H:%M:%S")

    # 找尚未結束的 session
    result = users_collection.update_one(
        {
            "username": username,
            "sessions.end_time": None
        },
        {
            "$set": {
                "sessions.$.end_time": now_str
            }
        }
    )

    return result.modified_count > 0

def append_score_internal(username, score_value):
    """將分數 append 進使用者的 scores，並更新 total score。"""

    users_collection.update_one(
        {"username": username},
        {
            "$push": {"scores": score_value},
            "$inc": {"score": score_value}
        }
    )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)