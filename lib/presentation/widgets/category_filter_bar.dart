import 'package:flutter/material.dart';
import '../providers/shopping_provider.dart';

class CategoryFilterBar extends StatelessWidget {
  final ShoppingProvider provider;
  final Function(int?) onCategorySelected;

  const CategoryFilterBar({
    super.key,
    required this.provider,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            "Tất cả",
            provider.selectedCategoryId == null,
            () => onCategorySelected(null),
          ),
          ...provider.categories.map((cat) => _chip(
                cat.name,
                provider.selectedCategoryId == cat.id,
                () => onCategorySelected(cat.id),
              )),
        ],
      ),
    );
  }

  Widget _chip(String text, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        selectedColor: Colors.orange,
        backgroundColor: Colors.white,
        showCheckmark: true,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
