import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/app_constants.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late final GenerativeModel _model;

  void init() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: AppConstants.geminiApiKey,
    );
  }

  /// Generates a suggested shopping list for Tet based on Gemini AI
  Future<List<Map<String, dynamic>>> generateShoppingList(String query) async {
    // Chỉ trả về fallback nếu key vẫn là placeholder mặc định
    if (AppConstants.geminiApiKey == "AIzaSyBCQ0ItbqpZGHpCr_OVVVRZOQS6bP9PaZg" || AppConstants.geminiApiKey.isEmpty) {
      return _generateFallbackList(query);
    }

    try {
      final prompt = '''
      Bạn là chuyên gia về sắm Tết Việt Nam. 
      Người dùng muốn: "$query"
      Hãy gợi ý danh sách tối đa 5 món đồ cần mua. 
      Trả về kết quả dưới dạng JSON array, mỗi object có:
      - "name": tên sản phẩm (Tiếng Việt)
      - "estimated_price": giá ước tính (VND, số nguyên)
      - "category": tên nhóm (Thực phẩm, Đồ cúng, Trang trí, Đồ uống, Bánh kẹo)
      - "quantity": số lượng cần mua (số nguyên)
      
      Chỉ trả về chuỗi JSON ròng, không kèm markdown hay giải thích.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final text = response.text;
      if (text == null) return _generateFallbackList(query);

      // Clean the response if Gemini wraps it in markdown code blocks
      final cleanedText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(cleanedText);
      
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print("Gemini AI Error: $e");
      return _generateFallbackList(query);
    }
  }

  /// Provides expert advice on choosing ingredients or traditional Tet recipes
  Future<String> getTetAdvice(String query) async {
    if (AppConstants.geminiApiKey == "AIzaSyBCQ0ItbqpZGHpCr_OVVVRZOQS6bP9PaZg" || AppConstants.geminiApiKey.isEmpty) {
      return "💡 Chào bạn! Hãy cài đặt Gemini API Key để nhận lời khuyên chuyên sâu từ AI nhé!";
    }

    try {
      final prompt = "Bạn là chuyên gia về văn hóa và mua sắm Tết Việt Nam. Hãy đưa ra lời khuyên ngắn gọn (khoảng 2-3 câu) cho yêu cầu này của người dùng: $query";
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? "Chúc bạn sắm Tết thật ưng ý!";
    } catch (e) {
      return "💡 Hãy ưu tiên chọn thực phẩm tươi ngon và trang trí nhà cửa rực rỡ để đón Tết may mắn nhé!";
    }
  }

  /// Keep the old logic as fallback
  List<Map<String, dynamic>> _generateFallbackList(String query) {
     final normalized = query.toLowerCase();
     if (normalized.contains('cúng')) {
       return [
        {'name': 'Gạo nếp ngon', 'estimated_price': 35000, 'category': 'Thực phẩm', 'quantity': 2},
        {'name': 'Đậu xanh cà vỏ', 'estimated_price': 45000, 'category': 'Thực phẩm', 'quantity': 1},
        {'name': 'Hoa cúc vàng', 'estimated_price': 50000, 'category': 'Trang trí', 'quantity': 2},
      ];
     }
     return [
      {'name': 'Bánh chưng', 'estimated_price': 60000, 'category': 'Thực phẩm', 'quantity': 2},
      {'name': 'Kẹo mứt Tết', 'estimated_price': 45000, 'category': 'Bánh kẹo', 'quantity': 1},
    ];
  }
}
