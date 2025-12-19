import asyncio
import websockets
import json
import base64
import cv2
import numpy as np
from focus_analyzer import FocusAnalyzer  # 你的 FocusAnalyzer



async def handler(ws):   # 必須有兩個參數！
    analyzer = FocusAnalyzer()
    async for msg in ws:
        try:
            
            data = json.loads(msg)

            frame_b64 = data["frame"]
            frame_bytes = base64.b64decode(frame_b64)
            frame = cv2.imdecode(np.frombuffer(frame_bytes, np.uint8), cv2.IMREAD_COLOR)
            frame_flip = cv2.flip(frame, 0)
            processed_frame, score, status = analyzer.process_frame(frame_flip)

            _, jpeg = cv2.imencode(".jpg", processed_frame)
            jpeg_b64 = base64.b64encode(jpeg.tobytes()).decode()

            resp = json.dumps({
                "frame": jpeg_b64,
                "score": score,
                "status": status
            })

            await ws.send(resp)

        except Exception as e:
            print("Server error:", e)

async def main():
    print("Server started on port 8765")
    async with websockets.serve(handler, "0.0.0.0", 8765):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())