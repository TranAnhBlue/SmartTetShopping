# 🧧 Smart Tet Shopping Manager ✨

**Smart Tet Shopping Manager** là ứng dụng di động (Flutter) mang đến trải nghiệm mua sắm và quản lý Tết hiện đại, thông minh và tràn đầy không khí lễ hội. Ứng dụng kết hợp giữa trí tuệ nhân tạo (AI) và các hiệu ứng hình ảnh/âm thanh cao cấp để biến việc chuẩn bị Tết thành một hành trình thú vị.

---

## 🌟 Tính năng "Premium" nổi bật

### 1. 🤖 Trợ lý AI Thông minh & Có giọng nói (Audio AI)
- **Gợi ý mua sắm AI**: Tự động phân tích giỏ hàng và đưa ra lời khuyên mua sắm Tết (Dùng Gemini Flash API).
- **Text-to-Speech (TTS)**: Trợ lý AI có thể **đọc vang** các gợi ý bằng giọng tiếng Việt chuẩn, giúp bạn rảnh tay khi đang bận rộn sắm Tết.
- **AI Sound Cues**: Hiệu ứng âm thanh "Ping" công nghệ mỗi khi AI đưa ra gợi ý mới.

### 2. 🎡 Vòng quay Lì xì "Muối mặn" (Lucky Wheel)
- **Gacha cảm xúc**: Hệ thống trúng thưởng ngẫu nhiên với các tệp âm thanh riêng biệt cho **Jackpot**, **Thắng lớn**, **Thắng nhỏ** và **Hụt quà**.
- **Spicy Feedback**: Những câu thoại phản hồi hài hước và "thả thính" tùy theo nhân phẩm của người quay (VD: "Nhân phẩm hơi lag", "Hào quang rực rỡ").
- **Hiệu ứng rực rỡ**: Pháo hoa giấy (Confetti), hiệu ứng chớp sáng (Flash) và rung cảm biến khi dừng vòng quay.

### 3. 📊 Quản lý Chi tiêu "Lấp lánh" (Spending Dashboard)
- **Biểu đồ chuyên nghiệp**: Theo dõi ngân sách Tết qua biểu đồ tròn sinh động.
- **Hiệu ứng Shimmer**: Số tiền ngân sách được phủ lớp vàng lấp lánh (Golden Shimmer) sang trọng.
- **Cảnh báo thông minh**: Hiệu ứng nhịp thở (Pulse) màu đỏ cảnh báo ngay lập tức khi bạn chi tiêu vượt định mức.

### 4. 🏮 Không khí Tết Đinh Mùi (Atmosphere)
- **Visual cực đỉnh**: Lồng đèn đung đưa, đom đóm bay lượn trên nền tảng Canvas tối ưu hiệu năng.
- **Countdown Breathing**: Đồng hồ đếm ngược giao thừa với hiệu ứng ánh sáng mờ ảo "thở" theo nhịp.
- **Âm nhạc đa dạng**: Trình phát nhạc Tết chạy nền với khả năng ẩn/hiện linh hoạt.

---

## 🛠️ Công nghệ sử dụng

- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **AI Engine**: Google Generative AI (Gemini API)
- **Audio Engine**: AudioPlayers (Sound SFX & Background Music)
- **Speech**: Flutter TTS (Vietnamese Voice)
- **UI/UX**: Custom Painters, AnimationControllers, Shimmer, Lottie, Confetti.

---

## 📂 Cấu trúc âm thanh chuyên biệt (Sound Schema)

Để ứng dụng đạt trải nghiệm tốt nhất, bạn cần chuẩn bị các tệp âm thanh sau trong `assets/audio/`:
- `sfx_spin.mp3`: Tiếng quay vòng tạch tạch.
- `sfx_jackpot.mp3`: Nhạc mừng thắng lớn.
- `sfx_win.mp3`: Nhạc mừng trúng quà nhỏ.
- `sfx_fail.mp3`: Tiếng cười/tiếc nuối khi hụt quà.
- `sfx_ai_ping.mp3`: m thanh thông báo của Trợ lý AI.

---

## ✨ Cài đặt & Trải nghiệm

1. Clone dự án.
2. Cấp quyền Camera & Vị trí (cho tính năng Quét hóa đơn & Thời tiết).
3. Thêm API Key của Gemini vào `lib/core/constants/app_constants.dart`.
4. Chạy lệnh: `flutter pub get` và `flutter run`.

---

**Chúc bạn một năm mới Đinh Mùi 2027 vạn sự như ý, tỷ sự như mơ!** 🧧🎆🏮
