import cv2
import base64
import json
import numpy as np
tracking_status = "Not Running!"
processed_frame = None
def Client(frame ,ws):
    global tracking_status, processed_frame
    _, jpeg = cv2.imencode('.jpg', frame)
    frame_b64 = base64.b64encode(jpeg.tobytes()).decode()

    ws.send(json.dumps({'frame': frame_b64}))

    # 收 server 回傳
    resp = ws.recv()
    try:
        data = json.loads(resp)
    except json.JSONDecodeError:
        print("Failed to decode JSON response")
        return None
    processed_bytes = base64.b64decode(data['frame'])
    processed_frame = cv2.imdecode(np.frombuffer(processed_bytes, np.uint8), cv2.IMREAD_COLOR)

    
    print(f"Score: {data['score']}, Status: {data['status']}")
    tracking_status = data['status']
    #cv2.imshow("Processed Frame", processed_frame)

    cv2.imwrite("face_tracking/latest.jpg", processed_frame )
