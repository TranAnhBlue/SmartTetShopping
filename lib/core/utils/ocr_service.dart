import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Processes an image and returns a list of suggested items and prices
  Future<List<Map<String, dynamic>>> processReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    List<Map<String, dynamic>> items = [];
    
    // Simple parsing logic: 
    // Usually receipts have Name on one side and Price on the other.
    // We'll look for lines that contain numbers (likely prices).
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        final text = line.text.trim();
        
        // Try to find a price in the line (looking for numbers with 3 digits after a dot/comma, e.g. 15.000)
        final priceMatch = RegExp(r'(\d{1,3}([.,]\d{3})+)').firstMatch(text);
        
        if (priceMatch != null) {
          final priceStr = priceMatch.group(0)!.replaceAll('.', '').replaceAll(',', '');
          final price = double.tryParse(priceStr) ?? 0.0;
          
          // Cleaner name extraction
          String name = text.replaceAll(priceMatch.group(0)!, '').replaceAll(RegExp(r'[^\w\s]'), '').trim();
          
          if (name.isEmpty || name.length < 2) {
             name = "Sản phẩm mới";
          }

          if (price >= 1000) { // Most Tet items are >= 1000 VND
            items.add({
              'name': name,
              'price': price,
              'quantity': 1,
            });
          }
        }
      }
    }

    return items;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
