import 'dart:io';
import 'ai_service.dart';

class OCRService {
  /// Processes an image and returns a list of suggested items and prices using Gemini AI
  Future<List<Map<String, dynamic>>> processReceipt(String imagePath) async {
    final File imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    
    // Use the smarter AI service
    return await AIService().analyzeReceipt(bytes);
  }

  void dispose() {
    // No longer needs to close the recognizer
  }
}
