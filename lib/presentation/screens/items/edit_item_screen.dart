import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/shopping_provider.dart';
import '../../../domain/entities/shopping_item.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/currency_utils.dart';

class EditItemScreen extends StatefulWidget {

  final ShoppingItem item;

  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(text: widget.item.name);
    _quantityCtrl =
        TextEditingController(text: widget.item.quantity.toString());
    _priceCtrl =
        TextEditingController(text: CurrencyUtils.formatNumber(widget.item.estimatedPrice));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateItem() async {

    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ShoppingProvider>();

    final priceDigits = _priceCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    final updatedItem = ShoppingItem(
      id: widget.item.id,
      name: _nameCtrl.text.trim(),
      categoryId: widget.item.categoryId,
      quantity: int.parse(_quantityCtrl.text),
      estimatedPrice: double.parse(priceDigits),
      isBought: widget.item.isBought,
      imageUrl: widget.item.imageUrl,
    );

    try {
      await provider.updateItem(updatedItem);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating item: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Item")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              /// NAME
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Item name"),
                validator: (value) =>
                value == null || value.isEmpty
                    ? "Required"
                    : null,
              ),

              const SizedBox(height: 16),

              /// QUANTITY
              TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity"),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Required";
                  if (int.tryParse(value) == null) return "Invalid number";
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// PRICE
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyTextInputFormatter(),
                ],
                decoration: const InputDecoration(labelText: "Estimated price (₫)"),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Required";
                  return null;
                },
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _updateItem,
                child: const Text("Update"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
