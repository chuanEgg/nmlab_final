from flask import Flask, Response, jsonify, request
from pymongo import MongoClient
from bson.objectid import ObjectId
import os
from datetime import datetime, timezone, timedelta
import math
import threading
import time
#import tracker
from  face_tracking.tracker import tracker_task
from picamera2 import Picamera2
import cv2

def calculate_level(score):
    return math.floor((-1 + math.sqrt(1 + 0.16 * score)) / 2)
app = Flask(__name__)
stop_event = threading.Event()
task_thread = None  # 全域保存 thread 物件
button_status = 0
# --- 設定區 ---
PHOTO_PATH = "face_tracking/latest.jpg"
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




STATUS_FILE = "face_tracking/status.txt"
def write_status(parameter, value):
    """
    更新 cam collection 指定欄位的值
    button 存布林，tracker 存字串
    """
    global button_status
    if parameter == "button":
        button_status = value
    elif parameter == "tracker":
        with open(STATUS_FILE, "w") as f:
            f.write(value)
        
    

@app.route("/tracker/status", methods=["GET"])
def get_tracker_status():
    with open(STATUS_FILE, "r") as f:
        tracker_string = f.read().strip()
    return jsonify({"tracker_status": tracker_string})

@app.route("/button/status", methods=["GET"])
def get_button_status():
    global button_status
    return jsonify({"button_status": button_status})

def long_task():
    while not stop_event.is_set():
        print("Task running...")
        time.sleep(1)
    print("Task stopped.")

@app.route("/button/toggle", methods=["POST"])
def toggle_button():
    global task_thread, stop_event,picamera2, button_status
    current = button_status
    print(f"Current button status: {current}")
    new_status = 0 if current == 1 else 1
    write_status("button", new_status)

    if new_status == 1:
        # 等上一次 thread 完全結束
        if task_thread is not None and task_thread.is_alive():
            stop_event.set()
            task_thread.join()

        stop_event.clear()
        task_thread = threading.Thread(target=tracker_task, args=(stop_event,picamera2))
        #task_thread = threading.Thread(target=long_task)
        task_thread.start()
        #start_session_internal("Allen")
        return jsonify({"msg": "Tracker started"}), 202

    else:
        stop_event.set()
        if task_thread is not None:
            task_thread.join()   # 等 thread 結束
        #stop_session_internal("Allen")
        #append_score_internal("Allen", 50)
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
    picamera2 = Picamera2()
    config = picamera2.create_preview_configuration(main={"format": "RGB888", "size": (800, 600)})
    picamera2.configure(config)
    picamera2.start()

    app.run(host='0.0.0.0', port=8000)