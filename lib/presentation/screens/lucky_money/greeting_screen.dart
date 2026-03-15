import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/greeting_service.dart';
import '../../../core/utils/ai_service.dart';

class GreetingScreen extends StatefulWidget {
  const GreetingScreen({super.key});

  @override
  State<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends State<GreetingScreen> {
  final _greetingService = GreetingService();
  final _aiService = AIService();
  String _selectedGroup = 'Gia đình';
  List<String> _greetings = [];
  bool _isLoading = false;
  final _customQueryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _greetings = _greetingService.getGreetings(_selectedGroup);
  }

  void _updateGreetings(String group) async {
    setState(() {
      _selectedGroup = group;
      _isLoading = true;
    });

    try {
      final aiGreetings = await _aiService.generateGreeting(group);
      if (mounted) {
        setState(() {
          _greetings = aiGreetings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _greetings = _greetingService.getGreetings(group);
          _isLoading = false;
        });
      }
    }
  }

  void _generateCustomGreeting() async {
    if (_customQueryController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final aiGreetings = await _aiService.generateGreeting(_selectedGroup, customQuery: _customQueryController.text.trim());
      if (mounted) {
        setState(() {
          _greetings = aiGreetings;
          _isLoading = false;
        });
      }
    } catch (e) {
       // Fallback or error snackbar
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lời chúc Tết AI 💌"),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildGroupSelector(),
          _buildCustomInput(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _greetings.length,
                  itemBuilder: (context, index) {
                    return _buildGreetingCard(_greetings[index]);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector() {
    final groups = ['Gia đình', 'Họ hàng', 'Bạn bè', 'Đồng nghiệp'];
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final isSelected = groups[index] == _selectedGroup;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(groups[index]),
              selected: isSelected,
              onSelected: (_) => _updateGreetings(groups[index]),
              selectedColor: Colors.red,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.red),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreetingCard(String text) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 20, color: Colors.blue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã sao chép lời chúc!")),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 20, color: Colors.green),
                  onPressed: () {
                    // Logic share
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCustomInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customQueryController,
              decoration: InputDecoration(
                hintText: "Nhập yêu cầu thêm (vd: hài hước, thơ...)",
                hintStyle: const TextStyle(fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _generateCustomGreeting,
            icon: const Icon(Icons.auto_awesome),
            style: IconButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

