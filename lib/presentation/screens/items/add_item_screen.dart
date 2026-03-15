import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/shopping_provider.dart';
import '../../../core/utils/ocr_service.dart';
import '../../../domain/entities/shopping_item.dart';
import 'scan_preview_screen.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

/// ===== FORMATTER TIỀN =====
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat formatter = NumberFormat('#,###', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String newText = newValue.text.replaceAll('.', '');

    final number = int.tryParse(newText);
    if (number == null) return oldValue;

    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _AddItemScreenState extends State<AddItemScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final _ocrService = OCRService();
  final _picker = ImagePicker();
  bool _isScanning = false;

  final formKey = GlobalKey<FormState>();

  int? selectedCategory;

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm món Tết")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              _buildScanButton(),
              const SizedBox(height: 16),
              _buildTextField("Tên món", nameController),

              /// ===== FIELD GIÁ =====
              _buildTextField(
                "Giá ước tính",
                priceController,
                number: true,
                formatter: CurrencyInputFormatter(),
              ),

              _buildTextField(
                "Số lượng",
                quantityController,
                number: true,
              ),

              const SizedBox(height: 16),

              /// ===== CATEGORY DROPDOWN =====
              DropdownButtonFormField<int>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: "Danh mục",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null) {
                    return "Vui lòng chọn danh mục";
                  }
                  return null;
                },
                items: const [
                  DropdownMenuItem(value: 1, child: Text("Thực phẩm")),
                  DropdownMenuItem(value: 2, child: Text("Đồ cúng")),
                  DropdownMenuItem(value: 3, child: Text("Trang trí")),
                  DropdownMenuItem(value: 4, child: Text("Đồ uống")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              /// ===== BUTTON LƯU =====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    if (selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Vui lòng chọn danh mục")),
                      );
                      return;
                    }

                    /// 👉 Bỏ dấu . trước khi lưu DB
                    final price = double.parse(
                      priceController.text.replaceAll('.', ''),
                    );

                    final item = ShoppingItem(
                      name: nameController.text.trim(),
                      estimatedPrice: price,
                      quantity: int.parse(quantityController.text),
                      categoryId: selectedCategory!,
                    );

                    await context.read<ShoppingProvider>().addItem(item);

                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Lưu món"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isScanning ? null : _scanReceipt,
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.document_scanner, color: Colors.red),
            label: Text(_isScanning ? "Đang quét..." : "Quét hóa đơn bằng AI"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (!_isScanning)
          const Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Tự động trích xuất tên đồ và giá từ ảnh chụp",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Future<void> _scanReceipt() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    setState(() => _isScanning = true);

    try {
      final results = await _ocrService.processReceipt(image.path);

      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Không tìm thấy thông tin trên hóa đơn. Hãy thử lại!")),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScanPreviewScreen(scannedItems: results),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi quét: $e")),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  /// ===== TEXT FIELD BUILDER =====
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool number = false,
    TextInputFormatter? formatter,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: false)
            : TextInputType.text,
        inputFormatters: formatter != null ? [formatter] : [],
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Không được để trống";
          }

          if (number) {
            final raw = value.replaceAll('.', '');
            final numberValue = double.tryParse(raw);

            if (numberValue == null) {
              return "Phải là số hợp lệ";
            }
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
