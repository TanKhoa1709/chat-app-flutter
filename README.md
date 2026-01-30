# Chat App Flutter

Một ứng dụng chat thời gian thực được xây dựng bằng Flutter và Firebase.

## Tính năng

* **Xác thực người dùng:** Đăng nhập và đăng ký an toàn bằng Firebase Authentication.
* **Chat thời gian thực:** Nhắn tin tức thì giữa các người dùng với Firebase Firestore.
* **Gọi Video/Thoại:** Tích hợp WebRTC để giao tiếp thời gian thực.
* **Chủ đề Sáng & Tối:** Một trình cung cấp chủ đề để chuyển đổi giữa chế độ sáng và tối.
* **Quản lý Người dùng:** Xem danh sách người dùng, chặn người dùng và quản lý cài đặt.
* **Thành phần giao diện người dùng tùy chỉnh:** Một bộ các widget có thể tái sử dụng để có giao
  diện nhất quán.

## Cấu trúc Project

```
lib/
├── components/       # Các widget giao diện người dùng có thể tái sử dụng
├── models/           # Các lớp mô hình dữ liệu
├── pages/            # Các màn hình hoặc trang của ứng dụng
├── services/         # Logic nghiệp vụ (xác thực, chat, WebRTC)
├── themes/           # Logic chủ đề cho chế độ sáng và tối
├── firebase_options.dart # Cấu hình Firebase
└── main.dart         # Điểm vào chính của ứng dụng
```
