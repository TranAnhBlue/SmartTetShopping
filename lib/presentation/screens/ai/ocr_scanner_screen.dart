import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/ai_service.dart';
import '../../../core/utils/currency_utils.dart';
import '../../providers/shopping_provider.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../../core/utils/sync_service.dart';
import './live_camera_scanner_screen.dart';
import 'package:camera/camera.dart';

class OCRScannerScreen extends StatefulWidget {
  const OCRScannerScreen({super.key});

  @override
  State<OCRScannerScreen> createState() => _OCRScannerScreenState();
}

class _OCRScannerScreenState extends State<OCRScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final SyncService _syncService = SyncService();
  File? _imageFile;
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _extractedItems = [];
  String? _error;
  String? _webImageUrl;
  Uint8List? _webImageBytes;

  Future<void> _pickImage(ImageSource source) async {
    try {
      XFile? pickedFile;
      
      if (source == ImageSource.camera) {
        // Use custom live camera screen
        pickedFile = await Navigator.push<XFile>(
          context,
          MaterialPageRoute(builder: (context) => const LiveCameraScannerScreen()),
        );
      } else {
        // Use gallery picker
        pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
      }

      if (pickedFile != null) {
        debugPrint('Đã nhận được ảnh: ${pickedFile.path}');
        setState(() {
          _imageFile = File(pickedFile!.path);
          _extractedItems = [];
          _error = null;
        });
        _analyzeImage(pickedFile);
      } else {
        debugPrint('Không nhận được ảnh từ camera/gallery');
      }
    } catch (e) {
      setState(() => _error = "Lỗi khi chọn ảnh: $e");
    }
  }

  Future<void> _analyzeImage(XFile? file, {Uint8List? directBytes}) async {
    setState(() => _isAnalyzing = true);
    try {
      final Uint8List bytes = directBytes ?? await file!.readAsBytes();
      final items = await AIService().analyzeReceipt(bytes);
      
      setState(() {
        _extractedItems = items;
        _isAnalyzing = false;
        if (items.isEmpty) {
          _error = "Không nhận diện được mặt hàng nào. Hãy thử chụp rõ hơn nhé!";
        } else {
          // Sync to Cloud Backend
          _syncService.uploadOCRHistory(items);
        }
      });
    } catch (e) {
      setState(() {
        _error = "Lỗi phân tích: $e";
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _showUrlDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập URL ảnh'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://example.com/image.jpg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Phân tích')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      _analyzeFromUrl(result);
    }
  }

  Future<void> _analyzeFromUrl(String url) async {
    setState(() {
      _isAnalyzing = true;
      _imageFile = null;
      _webImageUrl = url;
      _webImageBytes = null;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        setState(() => _webImageBytes = bytes);
        _analyzeImage(null, directBytes: bytes);
      } else {
        setState(() {
          _error = "Không thể tải ảnh từ URL (Mã lỗi: ${response.statusCode})";
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Lỗi khi tải ảnh: $e";
        _isAnalyzing = false;
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _extractedItems.removeAt(index);
    });
  }

  Future<void> _addAllToCart() async {
    final provider = Provider.of<ShoppingProvider>(context, listen: false);
    
    final List<ShoppingItem> newItems = _extractedItems.map((item) {
      final String name = item['name'] ?? 'Không rõ';
      final double price = (item['estimated_price'] ?? 0).toDouble();
      final int quantity = (item['quantity'] ?? 1).toInt();
      final String categoryStr = item['category'] ?? 'Thực phẩm';
      
      return ShoppingItem(
        name: name,
        estimatedPrice: price,
        quantity: quantity,
        categoryId: provider.getCategoryIdByName(categoryStr),
      );
    }).toList();

    await provider.addItemsBatch(newItems);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${newItems.length} món vào danh sách!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhận Diện Đồ & Hóa Đơn AI'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _extractedItems.isEmpty && !_isAnalyzing
                ? _buildInitialView()
                : _buildResultsView(),
          ),
          if (_extractedItems.isNotEmpty && !_isAnalyzing)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _addAllToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('THÊM TẤT CẢ VÀO GIỎ HÀNG', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Chụp ảnh hóa đơn HOẶC các món đồ thực tế để AI tự động thêm vào danh sách',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 20),
              _buildActionButton(
                icon: Icons.photo_library,
                label: 'Thư viện',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(width: 20),
              _buildActionButton(
                icon: Icons.link,
                label: 'Link ảnh',
                onTap: _showUrlDialog,
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_imageFile != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
          )
        else if (_webImageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_webImageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
        const SizedBox(height: 20),
        if (_isAnalyzing)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('AI đang phân tích hình ảnh...'),
              ],
            ),
          )
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red))
        else ...[
          const Text('Danh sách trích xuất được:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._extractedItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text('${item['quantity'] ?? 1}')),
                title: Text(item['name'] ?? 'Không rõ'),
                subtitle: Text('${CurrencyUtils.format(item['estimated_price'] ?? 0)} - ${item['category'] ?? 'Thực phẩm'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại với ảnh khác'),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.red.shade800),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
