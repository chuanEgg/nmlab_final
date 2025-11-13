# Network and Multimedia Lab Final Project

# 網多期末專題

組名: 第九組

## original
> 📚 FocusChain：AI 專注力挑戰與學習激勵平台
Study Focus Challenge System with AI + Blockchain + IoT + App Integration
🌟 核心概念
這是一個能「監測讀書專注力、紀錄成果上鏈、並給獎勵」的系統。
讓使用者在讀書時，不只是看計時器，而是真正透過 AI 分析專注程度，
再透過 區塊鏈保存成果與獎勵代幣。
👉 一句話版本：
「讓 AI 當你的專注裁判，區塊鏈當你的成就見證人。」
🧩 系統四大部分
① 感測與資料蒐集層（硬體端）
設備選項：
🎥 攝影機（辨識臉部專注度）
🧠 腦波 / 心率感測器（如 Muse、NeuroSky、Pulse Sensor）
💡 光線感測器（確認是否在書桌前）
功能：
透過攝影機或感測器偵測「是否專心」
可以偵測動作（是否看手機、低頭、離開）
若長時間專注 → 傳送資料到 AI 模型
② AI 專注力分析層（Machine Learning 模型）
模型可以判斷的東西：
臉部朝向、眼神移動（是否看書本或螢幕）
表情分析（是否疲倦或分心）
生理訊號（心率穩定度 = 專注）
技術方向：
OpenCV + MediaPipe 偵測臉部與眼睛
TensorFlow 模型訓練專注 / 分心分類器
若資源有限，可用 Edge ML（TinyML / ESP32-CAM）
輸出結果：
專注分數 F(t)（0~100）
專注時間段（連續專注超過 10 分鐘算一段）
③ 區塊鏈層（Blockchain 紀錄與獎勵）
用途：
每完成一段「專注任務」，AI 傳送結果上鏈
區塊鏈儲存不可篡改的「專注紀錄」
同時發放「FocusToken」作為獎勵

> 額外玩法：
每完成一小時專注可獲得 1 FocusToken
Token 可在 App 中換取「勳章」或「解鎖功能」
④ 手機 App 層（User Interface）
功能特色：
📊 專注力即時圖表（分數 vs. 時間）
🏆 挑戰任務：
「連續專注 25 分鐘」→ 成功後上鏈
「今天累積專注 2 小時」→ 解鎖 NFT 勳章
💰 FocusToken 錢包：
顯示你累積的代幣數
可用來兌換「專注主題 / 音樂 / 虛擬徽章」
🌐 排行榜（可選）：
區塊鏈保證公平
比誰今天最專心
App 技術：
Flutter / React Native
Bluetooth / WiFi 接硬體
Web3.js / Web3dart 連區塊鏈
🧠 延伸創意玩法
創意元素    說明
🎮 專注遊戲化    專注時畫面中的樹會長大，分心就枯萎（像「Forest」App + AI 強化版）
🪙 專注 NFT    連續專注 7 天 → 生成一張 NFT 勳章（「7 Days of Focus」）
👥 朋友挑戰    兩人開房間，同時開鏡頭比誰分心少，AI 自動判斷輸贏
💬 社群支持    區塊鏈上的專注紀錄可分享至好友榜，打造信任式學習圈
🤖 AI 教練    模型長期學你專注的模式 → 自動給出建議（如建議什麼時間最有效）
🧱 展示時可以 Demo：
攝影機開啟 → AI 實時顯示「專注分數」
App 顯示計時器 + 專注曲線
專注 5 分鐘 → 上鏈記錄（可到 Etherscan 查）
App 彈出「你獲得 1 FocusToken 🪙！」
使用者用 Token 換徽章或背景
💡 給你們的發展建議
如果硬體資源少，可先用筆電鏡頭 + ML 模型模擬感測器。
若有時間可再加 ESP32 + 心率 Sensor，做生理輔助分析。
App 先做簡版：顯示專注時間 + Token 錢包。
區塊鏈建議用 Polygon Testnet，便宜且快。
想要我幫你們擴充這題變成「比賽報告架構」版本嗎？
例如：
題目背景
動機
系統架構圖
功能展示
預期成果
那個可以直接拿去交 proposal。

## 硬體
可以轉的鏡頭
做得可愛一點

## 後端 
VLM (finetune or not? data collection?)
ViT (using facial expression & posture to determine state)
web3 (iota? this might be optional)

## 前端
App (楊)
