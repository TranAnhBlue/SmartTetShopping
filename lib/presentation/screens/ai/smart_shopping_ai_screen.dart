import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/ai_service.dart';
import '../../providers/shopping_provider.dart';
import '../../../domain/entities/shopping_item.dart';

class SmartShoppingAIScreen extends StatefulWidget {
  const SmartShoppingAIScreen({super.key});

  @override
  State<SmartShoppingAIScreen> createState() => _SmartShoppingAIScreenState();
}

class _SmartShoppingAIScreenState extends State<SmartShoppingAIScreen> {
  final TextEditingController _controller = TextEditingController();
  final AIService _aiService = AIService();
  
  bool _isLoading = false;
  String _aiAdvice = "";
  List<Map<String, dynamic>> _suggestedItemsOutput = [];

  Future<void> _handlePrompt() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _aiAdvice = "";
      _suggestedItemsOutput = [];
    });

    try {
      // 1. Get List Suggestion
      final listResult = await _aiService.generateShoppingList(prompt);
      
      // 2. Get AI Advice
      final adviceResult = await _aiService.getTetAdvice(prompt);

      setState(() {
        _suggestedItemsOutput = listResult;
        _aiAdvice = adviceResult;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi AI: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addAllItems() {
    if (_suggestedItemsOutput.isEmpty) return;

    final provider = context.read<ShoppingProvider>();
    final List<ShoppingItem> newItems = _suggestedItemsOutput.map((data) {
      return ShoppingItem(
        name: data['name'] ?? "Sản phẩm mới",
        estimatedPrice: (data['estimated_price'] as num).toDouble(),
        categoryId: provider.getCategoryIdByName(data['category'] ?? ""),
        quantity: (data['quantity'] as num).toInt(),
      );
    }).toList();

    provider.addItemsBatch(newItems);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🛍️ Đã thêm tất cả vào danh sách!")),
    );
    
    // Giữ nguyên trang để xem danh sách hoặc pop cũng được, pop thì comment lại.
    // Navigator.pop(context); 
  }

  void _addSingleItem(Map<String, dynamic> itemData) {
    if (itemData.isEmpty) return;

    final provider = context.read<ShoppingProvider>();
    final newItem = ShoppingItem(
      name: itemData['name'] ?? "Sản phẩm mới",
      estimatedPrice: (itemData['estimated_price'] as num).toDouble(),
      categoryId: provider.getCategoryIdByName(itemData['category'] ?? ""),
      quantity: (itemData['quantity'] as num).toInt(),
    );

    provider.addItemsBatch([newItem]);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🛍️ Đã thêm ${newItem.name} vào danh sách!")),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount);
  }

  double _calculateTotalPrice() {
    double total = 0;
    for (var item in _suggestedItemsOutput) {
      final price = (item['estimated_price'] as num).toDouble();
      final quantity = (item['quantity'] as num).toInt();
      total += price * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🤖 Smart Shopping AI"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade50.withOpacity(0.5),
        ),
        child: Column(
          children: [
            _buildPromptInput(),
            Expanded(
              child: _isLoading 
                ? _buildLoadingState() 
                : _buildAIResult(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Bạn muốn sắm gì cho Tết này?",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onSubmitted: (_) => _handlePrompt(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.red,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _handlePrompt,
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip("Đồ cúng Tết"),
                _buildQuickChip("Trang trí nhà"),
                _buildQuickChip("Quà biếu Tết"),
                _buildQuickChip("Tiệc tất niên"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: false,
        onSelected: (_) {
          _controller.text = label;
          _handlePrompt();
        },
        backgroundColor: Colors.red.shade50,
        labelStyle: TextStyle(color: Colors.red.shade900, fontSize: 13),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.red),
          const SizedBox(height: 16),
          Text(
            "AI đang suy nghĩ cho Tết này...",
            style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAIResult() {
    if (_aiAdvice.isEmpty && _suggestedItemsOutput.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 60, color: Colors.red.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text("Hỏi AI bất cứ điều gì về sắm Tết nhé!"),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. AI Advice Section
        if (_aiAdvice.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(
              _aiAdvice,
              style: const TextStyle(fontSize: 16, height: 1.5, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 24),
        ],

      // 2. Suggested Items Section
        if (_suggestedItemsOutput.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "📋 Danh sách gợi ý",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: _addAllItems,
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                      label: const Text("Thêm tất cả"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    )
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng dự kiến:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      _formatCurrency(_calculateTotalPrice()),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._suggestedItemsOutput.map((item) => _buildSuggestionCard(item)),
        ],
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
          child: const Icon(Icons.shopping_bag, color: Colors.orange),
        ),
        title: Text(item['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${item['category']} • SL: ${item['quantity']}"),
              const SizedBox(height: 4),
              Text(
                _formatCurrency((item['estimated_price'] as num).toDouble()),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
          onPressed: () => _addSingleItem(item),
          tooltip: 'Thêm vào giỏ',
        ),
      ),
    );
  }
}
