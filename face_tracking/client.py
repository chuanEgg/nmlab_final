import cv2
import base64
import json
import numpy as np
def Client(frame ,ws):
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
    with open("face_tracking/status.txt", "w") as f:
        f.write(data['status'])
    return processed_frame,  data['status']