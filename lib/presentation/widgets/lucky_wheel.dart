import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/utils/sound_service.dart';

class LuckyWheel extends StatefulWidget {
  final List<String> items;
  final Function(int) onResult;
  final VoidCallback onStart;

  const LuckyWheel({
    super.key,
    required this.items,
    required this.onResult,
    required this.onStart,
  });

  @override
  State<LuckyWheel> createState() => LuckyWheelState();
}

class LuckyWheelState extends State<LuckyWheel> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _pulseController;
  double _currentRotation = 0;
  bool _isSpinning = false;
  bool _showFlash = false; // Trạng thái hiệu ứng chớp sáng

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        SoundService().playWin(); // Âm thanh chiến thắng
        setState(() {
          _isSpinning = false;
          _showFlash = true;
        });
        
        // Tắt chớp sáng sau 100ms
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() => _showFlash = false);
        });

        _currentRotation = _animation.value;
        
        final double normalizedRotation = _currentRotation % (2 * pi);
        final double sectionAngle = (2 * pi) / widget.items.length;
        
        // Adjust for pointer at top (12 o'clock = 3*pi/2 radians)
        int index = (((3 * pi / 2) - normalizedRotation) % (2 * pi) / sectionAngle).floor();
        index = index % widget.items.length;
        
        widget.onResult(index);
      }
    });
  }

  void spin() {
    if (_isSpinning) return;

    SoundService().playSpin(); // Phát tiếng xoay
    widget.onStart();
    setState(() => _isSpinning = true);

    final random = Random();
    final double extraRotation = random.nextDouble() * 2 * pi;
    final double totalRotation = 10 * pi + extraRotation;

    final double startRotation = _currentRotation;
    final double endRotation = _currentRotation + totalRotation;

    _animation = Tween<double>(
      begin: startRotation,
      end: endRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _controller.reset();
    _controller.forward().then((_) {
      _currentRotation = endRotation;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: spin,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Pulsing Glow
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 290 + (10 * _pulseController.value),
                    height: 290 + (10 * _pulseController.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3 + (0.4 * _pulseController.value)),
                          blurRadius: 15 + (15 * _pulseController.value),
                          spreadRadius: 2 + (8 * _pulseController.value),
                        )
                      ],
                    ),
                  );
                },
              ),
              // The Wheel
              Transform.rotate(
                angle: _animation.value,
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: _WheelPainter(items: widget.items),
                ),
              ),
              // Lighting Flash Overlay
              if (_showFlash)
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              // Center Cap
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade900, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.star, color: Colors.red, size: 20),
                ),
              ),
              // Pointer (Top)
              Positioned(
                top: -10,
                child: CustomPaint(
                  size: const Size(30, 40),
                  painter: _PointerPainter(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> items;

  _WheelPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final sweepAngle = (2 * pi) / items.length;

    final List<Color> colors = [
      Colors.red.shade700,
      const Color(0xFFD32F2F),
      Colors.red.shade900,
      const Color(0xFFB71C1C),
    ];

    for (int i = 0; i < items.length; i++) {
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        paint,
      );

      // Gold Border for segments
      final borderPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Text
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * sweepAngle + sweepAngle / 2);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i],
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(radius * 0.45, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Outer gold ring
    final ringPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, ringPaint);
    
    // Decorative dots
    final dotPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 12; i++) {
        final angle = (i * 2 * pi) / 12;
        canvas.drawCircle(
            Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
            3,
            dotPaint
        );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    
    final borderPaint = Paint()
      ..color = Colors.red.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
