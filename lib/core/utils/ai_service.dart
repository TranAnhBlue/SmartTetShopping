import 'dart:async';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// 🧠 LOCAL EXPERT DATABASE
  final Map<String, Map<String, dynamic>> _expertKnowledge = {
    'cúng': {
      'advice': "🧧 Cho việc cúng kiếng, bạn nên ưu tiên chọn hoa quả tươi (Ngũ quả), hoa cúc hoặc hoa ly. Đừng quên mua đủ nếp, đậu xanh và thịt heo để gói bánh chưng/bánh tét nhé!",
      'items': [
        {'name': 'Gạo nếp ngon', 'estimated_price': 35000, 'category': 'Thực phẩm', 'quantity': 2},
        {'name': 'Đậu xanh cà vỏ', 'estimated_price': 45000, 'category': 'Thực phẩm', 'quantity': 1},
        {'name': 'Thịt ba rọi', 'estimated_price': 150000, 'category': 'Thực phẩm', 'quantity': 1},
        {'name': 'Hoa cúc vàng', 'estimated_price': 50000, 'category': 'Trang trí', 'quantity': 2},
        {'name': 'Trái cây Ngũ quả', 'estimated_price': 200000, 'category': 'Thực phẩm', 'quantity': 1},
      ]
    },
    'trang trí': {
      'advice': "✨ Để nhà cửa thêm rộn ràng, bạn có thể mua thêm bao lì xì, dây treo may mắn và vài chậu hoa vạn thọ hoặc hoa mai/đào. Một chút ánh sáng từ dây đèn LED cũng rất tuyệt!",
      'items': [
        {'name': 'Bao lì xì đỏ', 'estimated_price': 20000, 'category': 'Trang trí', 'quantity': 5},
        {'name': 'Dây treo trang trí', 'estimated_price': 15000, 'category': 'Trang trí', 'quantity': 10},
        {'name': 'Dây đèn LED', 'estimated_price': 80000, 'category': 'Trang trí', 'quantity': 2},
        {'name': 'Hoa vạn thọ', 'estimated_price': 40000, 'category': 'Trang trí', 'quantity': 4},
      ]
    },
    'quà': {
      'advice': "🎁 Quà biếu Tết thường là các giỏ bánh kẹo sang trọng, trà ngon hoặc rượu vang. Bạn nên chọn những sản phẩm có bao bì màu đỏ hoặc vàng để mang lại may mắn.",
      'items': [
        {'name': 'Giỏ quà bánh kẹo', 'estimated_price': 500000, 'category': 'Bánh kẹo', 'quantity': 1},
        {'name': 'Hộp trà đặc sản', 'estimated_price': 120000, 'category': 'Đồ uống', 'quantity': 2},
        {'name': 'Rượu vang đỏ', 'estimated_price': 350000, 'category': 'Đồ uống', 'quantity': 1},
      ]
    },
    'ăn': {
      'advice': "🥘 Tiệc tất niên không thể thiếu gà luộc, canh măng và nem rán. Hãy kiểm tra lại gia vị trong bếp như nước mắm, dầu ăn và hạt nêm xem đã đủ chưa nhé!",
      'items': [
        {'name': 'Gà ta thả vườn', 'estimated_price': 180000, 'category': 'Thực phẩm', 'quantity': 1},
        {'name': 'Măng khô', 'estimated_price': 100000, 'category': 'Thực phẩm', 'quantity': 1},
        {'name': 'Bánh tráng cuốn nem', 'estimated_price': 15000, 'category': 'Thực phẩm', 'quantity': 3},
        {'name': 'Nước mắm ngon', 'estimated_price': 85000, 'category': 'Thực phẩm', 'quantity': 1},
      ]
    }
  };

  /// Generates a suggested shopping list for Tet based on local templates
  Future<List<Map<String, dynamic>>> generateShoppingList(String query) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate "thinking"
    
    final normalized = query.toLowerCase();
    
    for (var key in _expertKnowledge.keys) {
      if (normalized.contains(key)) {
        return List<Map<String, dynamic>>.from(_expertKnowledge[key]!['items']);
      }
    }
    
    // Default fallback list if no match
    return [
      {'name': 'Bánh chưng', 'estimated_price': 60000, 'category': 'Thực phẩm', 'quantity': 2},
      {'name': 'Kẹo mứt Tết', 'estimated_price': 45000, 'category': 'Bánh kẹo', 'quantity': 1},
      {'name': 'Nước ngọt/Bia', 'estimated_price': 180000, 'category': 'Đồ uống', 'quantity': 1},
    ];
  }

  /// Provides expert advice on choosing ingredients or traditional Tet recipes
  Future<String> getTetAdvice(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final normalized = query.toLowerCase();
    
    for (var key in _expertKnowledge.keys) {
      if (normalized.contains(key)) {
        return _expertKnowledge[key]!['advice'];
      }
    }
    
    return "💡 Chào bạn! Bạn có thể hỏi tôi về 'đồ cúng', 'trang trí', 'quà biếu' hoặc 'đồ ăn Tết' để nhận được những gợi ý mua sắm thông minh nhất!";
  }
}
