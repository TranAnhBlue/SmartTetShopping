import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import 'dart:ui';

class AISmartReminder extends StatelessWidget {
  const AISmartReminder({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final suggestion = provider.aiSuggestion;
    final isThinking = provider.isAIThinking;

    if (!isThinking && suggestion == null) return const SizedBox.shrink();

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
                  Colors.blue.withOpacity(0.15),
                  Colors.purple.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: isThinking 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
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
  }
}
