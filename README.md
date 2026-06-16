# Chat App Flutter

Một ứng dụng trò chuyện và gọi video thời gian thực cao cấp được xây dựng bằng **Flutter**, **Firebase** và **WebRTC**.

Ứng dụng cung cấp các tính năng nhắn tin tức thì, cuộc gọi video P2P hiệu năng cao thông qua cơ chế truyền phát dữ liệu (signaling) dựa trên Cloud Firestore, cùng với các biện pháp bảo mật người dùng đầy đủ (Chặn, Báo cáo) đáp ứng các tiêu chuẩn xuất bản ứng dụng.

---

## 🚀 Tính năng nổi bật

*   **Xác thực người dùng (Authentication):** Đăng nhập và đăng ký tài khoản bảo mật bằng **Firebase Authentication**.
*   **Chat thời gian thực (Real-time Messaging):** Gửi và nhận tin nhắn tức thì qua **Cloud Firestore**. Tự động cuộn thông minh khi có tin nhắn mới hoặc khi bàn phím xuất hiện.
*   **Gọi Video thời gian thực (P2P Video Call):** Gọi video chất lượng cao sử dụng giao thức **WebRTC** (`flutter_webrtc`), tối ưu hóa kết nối ngang hàng trực tiếp.
*   **Signaling qua Firestore:** Không cần máy chủ WebSockets riêng, ứng dụng sử dụng Firestore làm trung gian trao đổi thông tin phòng gọi (Offer/Answer) và các địa chỉ mạng (ICE Candidates).
*   **Tương thích & Bảo mật người dùng (User Safety):**
    *   **Báo cáo (Report):** Nhấn giữ tin nhắn của người khác để gửi báo cáo vi phạm nội dung lên hệ thống quản trị Firestore.
    *   **Chặn người dùng (Block/Unblock):** Chặn các tài khoản không mong muốn. Hệ thống tự động lọc danh sách và không hiển thị người dùng đã chặn. Trang quản lý danh sách chặn trong Cài đặt cho phép dễ dàng bỏ chặn.
*   **Chủ đề Sáng & Tối (Light & Dark Theme):** Hỗ trợ chuyển đổi giao diện mượt mà thông qua `ThemeProvider` sử dụng gói `provider`.
*   **Biểu tượng ứng dụng tùy chỉnh (Launcher Icon):** Cấu hình tự động tạo icon ứng dụng chuyên nghiệp qua gói `flutter_launcher_icons`.

---

## 🛠️ Công nghệ sử dụng

*   **Framework:** [Flutter](https://flutter.dev) (hỗ trợ SDK Dart `^3.6.1`)
*   **Cơ sở dữ liệu & Xác thực:**
    *   `firebase_core` - Khởi tạo cấu hình Firebase.
    *   `firebase_auth` - Xác thực người dùng qua Email/Mật khẩu.
    *   `cloud_firestore` - Đồng bộ tin nhắn, trạng thái phòng gọi và thông tin người dùng.
*   **Kết nối P2P:**
    *   `flutter_webrtc` - Truyền phát hình ảnh và âm thanh trực tiếp.
    *   **STUN Servers:** Sử dụng các máy chủ STUN công cộng của Google (`stun1.l.google.com:19302`, `stun2.l.google.com:19302`) giúp thiết lập kết nối NAT xuyên suốt qua Internet.
*   **Quản lý trạng thái:** `provider` (quản lý theme và dữ liệu cập nhật trạng thái block/unblock).
*   **Cấp quyền:** `permission_handler` (quản lý quyền truy cập Camera và Microphone động).

---

## 📂 Cấu trúc Project

```text
lib/
├── components/          # Các widget UI dùng chung
│   ├── chat_bubble.dart   # Bong bóng chat hỗ trợ nhấn giữ để Block/Report
│   ├── my_button.dart     # Nút bấm tùy chỉnh đồng bộ với Theme
│   ├── my_drawer.dart     # Menu bên điều hướng ứng dụng
│   ├── my_textfield.dart  # Ô nhập liệu văn bản tùy chỉnh
│   └── user_tile.dart     # Thẻ hiển thị thông tin người dùng trong danh sách
├── models/              # Mô hình dữ liệu
│   └── message.dart       # Lớp Message cấu trúc hóa tin nhắn (text, call log)
├── pages/               # Các trang giao diện (Screens)
│   ├── blocked_users_page.dart # Quản lý & mở khóa tài khoản đã chặn
│   ├── call_page.dart          # Màn hình gọi video (điều khiển Mic/Camera/Cúp máy)
│   ├── chat_page.dart          # Giao diện hội thoại & nút khởi tạo cuộc gọi
│   ├── home_page.dart          # Màn hình chính chứa danh sách liên lạc & trình nghe cuộc gọi đến
│   ├── incoming_call_page.dart # Màn hình chấp nhận hoặc từ chối cuộc gọi đến
│   ├── login_page.dart         # Trang đăng nhập tài khoản
│   ├── register_page.dart      # Trang đăng ký tài khoản
│   └── setting_page.dart       # Trang cài đặt (Chế độ tối, Danh sách chặn)
├── services/            # Tầng xử lý logic nghiệp vụ
│   ├── auth/              # Logic xác thực và điều hướng
│   │   ├── auth_gate.dart          # Cổng kiểm tra đăng nhập (đăng nhập -> Home, chưa -> Login)
│   │   ├── auth_service.dart       # Giao tiếp trực tiếp với Firebase Authentication
│   │   └── login_or_register.dart  # Trình chuyển đổi qua lại giữa Login & Register
│   ├── chat/              # Xử lý tin nhắn, báo cáo, và chặn/mở chặn
│   │   └── chat_service.dart       # Quản lý luồng tin nhắn và tương tác người dùng qua Firestore
│   └── webrtc/            # Xử lý kết nối video ngang hàng
│       └── signaling_service.dart  # Tạo phòng, tham gia phòng, thu thập ICE Candidates & dọn dẹp kết nối
├── themes/              # Cấu hình giao diện sáng/tối
│   ├── dark_mode.dart     # Định nghĩa bộ màu chế độ tối
│   ├── light_mode.dart    # Định nghĩa bộ màu chế độ sáng
│   └── theme_provider.dart # Trình cung cấp và chuyển đổi Theme thông qua Provider
├── firebase_options.dart # Tự động tạo bởi FlutterFire CLI chứa cấu hình SDK Firebase
└── main.dart            # Điểm khởi chạy ứng dụng (main entry point)
```

---

## 🗄️ Thiết kế Cơ sở dữ liệu (Firestore Schema)

Hệ thống Firestore được tổ chức thành các Collections chính như sau:

### 1. `Users`
Lưu trữ thông tin người dùng đã đăng ký và danh sách người dùng bị họ chặn.
*   **Document ID:** `uid` của người dùng.
*   **Các trường dữ liệu:**
    *   `uid`: `String` (ID định danh)
    *   `email`: `String` (Địa chỉ email)
    *   `last_login`: `Timestamp` (Thời gian đăng nhập gần nhất)
*   **Sub-collection: `blocked_users`**
    *   **Document ID:** `uid` của người bị chặn.
    *   **Dữ liệu:** `{}` (Bản ghi rỗng đại diện cho mối quan hệ chặn).

### 2. `chat_rooms`
Lưu trữ lịch sử hội thoại giữa các cặp người dùng.
*   **Document ID:** Ghép từ hai UID của người gửi và người nhận theo thứ tự bảng chữ cái để đảm bảo phòng chat là duy nhất (Ví dụ: `uidA_uidB`).
*   **Sub-collection: `messages`**
    *   **Document ID:** Auto-generated từ Firestore.
    *   **Các trường dữ liệu:**
        *   `sender_id`: `String` (UID người gửi)
        *   `sender_email`: `String` (Email người gửi)
        *   `receiver_id`: `String` (UID người nhận)
        *   `message`: `String` (Nội dung tin nhắn hoặc thông báo cuộc gọi)
        *   `timestamp`: `Timestamp` (Thời gian gửi)
        *   `type`: `String` (Phân loại: `'text'` hoặc `'call'`)

### 3. `calls`
Kênh trao đổi tín hiệu WebRTC thời gian thực phục vụ cuộc gọi video.
*   **Document ID:** ID phòng được tự động tạo (`roomId`).
*   **Các trường dữ liệu:**
    *   `offer`: `Map` (Mô tả cấu hình kết nối SDP của người gọi)
    *   `answer`: `Map` (Mô tả cấu hình kết nối SDP phản hồi của người nghe, xuất hiện sau khi đồng ý nhận cuộc gọi)
    *   `senderId`: `String` (UID người gọi)
    *   `senderName`: `String` (Email người gọi)
    *   `receiverId`: `String` (UID người nhận)
    *   `timestamp`: `Timestamp` (Thời gian bắt đầu cuộc gọi)
*   **Sub-collections:**
    *   `callerCandidates`: Chứa danh sách các địa chỉ mạng ICE Candidate do người gọi phát hiện gửi lên.
    *   `calleeCandidates`: Chứa danh sách các địa chỉ mạng ICE Candidate do người nghe phát hiện gửi lên.

### 4. `reports`
Thu thập báo cáo nội dung không phù hợp từ người dùng.
*   **Document ID:** Auto-generated từ Firestore.
*   **Các trường dữ liệu:**
    *   `reported_by`: `String` (UID của người gửi báo cáo)
    *   `message_id`: `String` (ID tin nhắn bị báo cáo)
    *   `message_owner_id`: `String` (UID của người bị báo cáo)
    *   `timestamp`: `Timestamp` (Thời điểm báo cáo, lưu trữ theo server timestamp)

---

## 🛠️ Hướng dẫn cài đặt & Cấu hình

### 1. Yêu cầu hệ thống (Prerequisites)
*   Đã cài đặt **Flutter SDK** (Khuyến nghị phiên bản tương thích với SDK Dart `^3.6.1`).
*   Một tài khoản **Firebase Console** đang hoạt động.
*   Đã cài đặt [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup?platform=ios) trên máy tính để tạo file cấu hình tự động.

### 2. Cấu hình Firebase
1.  Truy cập Firebase Console và tạo một dự án mới (ví dụ: `chat-app-flutter`).
2.  Bật dịch vụ **Firebase Authentication** và kích hoạt phương thức đăng nhập bằng **Email/Password**.
3.  Bật dịch vụ **Cloud Firestore** ở chế độ thử nghiệm hoặc cấu hình Rule phù hợp.
4.  Cài đặt cấu hình Firebase vào ứng dụng Flutter bằng lệnh sau trong thư mục gốc của dự án:
    ```bash
    flutterfire configure
    ```
    *(Lệnh này sẽ tự động cập nhật cấu hình vào file `lib/firebase_options.dart` và tạo các tệp cấu hình cho Android/iOS).*

### 3. Cấu hình quyền truy cập phần cứng (Platform-specific configurations)

Do tính năng cuộc gọi video cần sử dụng camera và microphone, bạn cần thêm các cấu hình cấp quyền sau:

#### Android
Quyền đã được thiết lập sẵn trong tệp `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.INTERNET"/>
```

#### iOS
Thêm các khoá sau vào tệp `ios/Runner/Info.plist` để giải thích mục đích sử dụng Camera và Micro với Apple:
```xml
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần quyền truy cập Camera để bạn thực hiện cuộc gọi video.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Ứng dụng cần quyền truy cập Microphone để bạn truyền giọng nói trong cuộc gọi.</string>
```

---

## 🏃 Khởi chạy ứng dụng

1.  Cài đặt các gói thư viện phụ thuộc:
    ```bash
    flutter pub get
    ```
2.  Chạy ứng dụng trên thiết bị giả lập hoặc thiết bị thật đã kết nối:
    ```bash
    flutter run
    ```

### Hướng dẫn build Icon ứng dụng (Tùy chọn)
Nếu bạn thay đổi tệp tin ảnh logo tại `assets/app_icon.png`, bạn có thể cập nhật icon hiển thị cho các nền tảng bằng lệnh:
```bash
flutter pub run flutter_launcher_icons
```

