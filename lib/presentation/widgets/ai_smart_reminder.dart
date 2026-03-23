import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import 'dart:ui';

class AISmartReminder extends StatefulWidget {
  const AISmartReminder({super.key});

  @override
  State<AISmartReminder> createState() => _AISmartReminderState();
}

class _AISmartReminderState extends State<AISmartReminder> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final suggestion = provider.aiSuggestion;
    final isThinking = provider.isAIThinking;

    if (!isThinking && suggestion == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.15 + (0.05 * _pulseController.value)),
                      Colors.purple.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.3 + (0.4 * _pulseController.value)),
                    width: 1 + (0.5 * _pulseController.value),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.1 * _pulseController.value),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3 * _pulseController.value),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: isThinking 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)
                          )
                        : Icon(Icons.auto_awesome, color: Colors.blue.withOpacity(0.7 + 0.3 * _pulseController.value), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isThinking ? "Trợ lý AI đang phân tích..." : "Gợi ý từ Trợ lý Tết",
                            style: const TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.blueAccent
                            ),
                          ),
                          if (suggestion != null && !isThinking)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                suggestion,
                                style: const TextStyle(
                                  fontSize: 14, 
                                  color: Colors.white, 
                                  height: 1.3,
                                  fontStyle: FontStyle.italic
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isThinking)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: Colors.white54),
                        onPressed: () => provider.updateAISuggestion(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
