# SmartLocker
### 1. Cài đặt flutter và thêm biến môi trường
### 2. Tải ngrok
Tải theo link: https://dashboard.ngrok.com/

-> Đăng nhập vào web Ngrok -> Tìm "Connect your account"
![image](https://github.com/Haunguyen42193/SmartLocker/assets/76529425/33a1a09a-cf66-4478-9650-afa9b818c9f0)

-> Lấy đoạn "$ ngrok config add-authtoken ...."

-> Mở ngrok.exe -> paste đoạn "$ ngrok config add-authtoken ...." và bấm enter

-> tiếp tục nhập ngrok http https://localhost:7037 -> bấm enter 
-> copy đoạn Forwarding

![image](https://github.com/Haunguyen42193/SmartLocker/assets/76529425/b1ed68c3-1685-41c9-a67a-c50f6f63ad01)

### 3. Cài đặt Microsoft Visual Studio 2022
### 4. Cài đặt Visual Studio Code
-> Cài Extensions Flutter và Dart

![image](https://github.com/Haunguyen42193/SmartLocker/assets/76529425/6390bb2a-d11b-4420-9f2d-7c963b993f03)

-> Thêm môi trường ảo Mobile Emulator

### 5. Mở Microsoft Visual Studio 2022
->Chọn **open a project or solution** 

->Tìm đến **SmartLockerAPI** và mở project

![image](https://github.com/Haunguyen42193/SmartLocker/assets/76529425/bc4a6190-7b14-4a9d-a923-a36fbd53b459)


Run project

![image](https://github.com/Haunguyen42193/SmartLocker/assets/76529425/0fbd3a80-0ee9-4252-9168-00f010ce47e5)


### 6. Sử dụng flutter
-> Mở Visual Studio Code

-> Mở folder **smart_locker**

![image](https://github.com/Haunguyen42193/SmartLocker/assets/76529425/edf73928-5371-442a-8b36-92a4da8376da)

-> Mở file config.dart -> copy đoạn Forwarding ở trên lấy được từ ngrok paste vào endpoint

![image](https://github.com/Haunguyen42193/SmartLocker/assets/76529425/9d6a3b12-1a52-435d-b90f-f7ccbdd41564)

-> Mở môi trường ảo Mobile Emulator

-> Mở terminal -> nhập flutter run -> mở được giao diện 
