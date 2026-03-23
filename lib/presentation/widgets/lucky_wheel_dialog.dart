import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'lucky_wheel.dart';
import 'shimmer_text.dart';
import '../../core/utils/sound_service.dart';
import 'dart:math';

class LuckyWheelDialog extends StatefulWidget {
  const LuckyWheelDialog({super.key});

  @override
  State<LuckyWheelDialog> createState() => _LuckyWheelDialogState();
}

class _LuckyWheelDialogState extends State<LuckyWheelDialog> {
  late ConfettiController _confettiController;
  final List<String> _items = [
    "20k 🧧",
    "50k 🧧",
    "100k 🧧",
    "Chúc Tết 🌸",
    "200k 🧧",
    "Phát Tài 🏮",
    "500k 💎",
    "Hẹn May ☘️"
  ];
  final GlobalKey<LuckyWheelState> _wheelKey = GlobalKey<LuckyWheelState>();
  String _result = "";
  String _spicyMessage = "";
  String _closeButtonLabel = "ĐÓNG";
  bool _isSpinning = false;

  final Map<String, List<String>> _spicyMessages = {
    "fail": [
      "Nhân phẩm hôm nay hơi... lag! Đi rửa tay rồi quay lại sau nhé.",
      "Ông Trời thử thách lòng kiên nhẫn thôi mà. Quay lại lần nữa xem ai sợ ai!",
      "Hụt rồi! Nhưng đừng buồn, ít nhất vòng quay cũng vừa trơn tru hơn.",
      "Gần trúng rồi! Chỉ thiếu đúng... một chút may mắn nữa thôi.",
    ],
    "small": [
      "Có còn hơn không! Đủ ly cà phê sáng nay rồi, chúc mừng bạn nhé!",
      "Lộc lá đã về! Tích tiểu thành đại, biết đâu phát sau lại trúng 500k?",
      "Vận may đang khởi động thôi. Chúc mừng bạn mở bát thành công!",
      "Ting ting! Lì xì đã hạ cánh an toàn vào túi bạn.",
    ],
    "medium": [
      "Quá đã! Một món hời không hề nhỏ, chúc mừng bạn nhé!",
      "Lộc lá xum xuê! 100k-200k là đủ một bữa tiệc trà bánh linh đình rồi.",
      "Vận may đang lên hương! Chỉ cách Jackpot đúng một bước chân thôi.",
      "Tay thơm quá! Giữ vững phong độ này để 'hốt' nốt 500k nhé.",
    ],
    "jackpot": [
      "Hào quang rực rỡ! Bạn chính là 'con cưng' của Thần Tài hôm nay rồiii!",
      "U là trời! 500k đã thuộc về chủ nhân xứng đáng. Bạn có bí kíp gì không?",
      "Nổ hũ! Đề nghị bạn đi khao ngay vì vận may này không phải dạng vừa đâu!",
      "Đỉnh của chóp! Vòng quay hôm nay chính thức 'gục ngã' trước bạn.",
    ]
  };

  final List<String> _closeLabels = ["Thử lại vận may", "Nhận lộc thôi!", "Chơi tiếp cho cháy", "Thoát (trong nuối tiếc)"];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFFFD700), width: 3),
          image: const DecorationImage(
            image: AssetImage('assets/images/tet_pattern.png'),
            opacity: 0.1,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: Text(
                    "🏮 VÒNG QUAY LÌ XÌ 🏮",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: StatefulBuilder(
                    builder: (context, setDialogState) {
                      final sound = SoundService();
                      return IconButton(
                        icon: Icon(
                          sound.soundEnabled ? Icons.volume_up : Icons.volume_off,
                          color: const Color(0xFFFFD700),
                          size: 20,
                        ),
                        onPressed: () {
                          sound.toggleSound();
                          setDialogState(() {});
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Nhấn vào vòng quay để thử vận may!",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive, // Bắn tung tóe hơn
                  colors: const [Colors.red, Colors.yellow, Colors.orange, Colors.white],
                  shouldLoop: false,
                ),
                LuckyWheel(
                  key: _wheelKey,
                  items: _items,
                  onStart: () {
                    setState(() {
                      _isSpinning = true;
                      _result = "";
                    });
                  },
                  onResult: (index) {
                    final item = _items[index];
                    String category = "small";
                    if (item.contains("Hẹn May") || item.contains("Chúc Tết")) {
                      category = "fail";
                      SoundService().playFail();
                    } else if (item.contains("500k") || item.contains("Phát Tài")) {
                      category = "jackpot";
                      SoundService().playJackpot();
                    } else if (item.contains("100k") || item.contains("200k")) {
                      category = "medium";
                      SoundService().playWin(); // Vẫn dùng Win nhưng có thể tùy chỉnh thêm
                    } else {
                      category = "small";
                      SoundService().playWin();
                    }

                    setState(() {
                      _isSpinning = false;
                      _result = item;
                      _spicyMessage = _spicyMessages[category]![Random().nextInt(_spicyMessages[category]!.length)];
                      _closeButtonLabel = _closeLabels[Random().nextInt(_closeLabels.length)];
                    });
                    _confettiController.play();
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            if (_result.isNotEmpty)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _result.contains("500k") 
                                  ? Colors.white.withOpacity(0.8) 
                                  : Colors.black.withOpacity(0.3), 
                                blurRadius: 20,
                                spreadRadius: _result.contains("500k") ? 5 : 0,
                              )
                            ],
                            border: _result.contains("500k") 
                              ? Border.all(color: Colors.white, width: 2) 
                              : null,
                          ),
                          child: Column(
                            children: [
                              ShimmerText(
                                text: "CHÚC MỪNG!",
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                _result,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  _spicyMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _wheelKey.currentState?.spin(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            elevation: 5,
                          ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text("QUAY TIẾP", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              const SizedBox(height: 110), // Increased to match new result block height
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSpinning ? null : () => Navigator.pop(context),
              child: Text(
                _result.isNotEmpty ? _closeButtonLabel : "ĐÓNG",
                style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
