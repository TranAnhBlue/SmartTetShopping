class Category {

  final int? id;
  final String name;
  final String? icon;
  final String? color;

  Category({
    this.id,
    required this.name,
    this.icon,
    this.color,
  });

  // ===== FROM MAP (DB → Entity)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      icon: map['icon'],
      color: map['color'],
    );
  }

  // ===== TO MAP (Entity → DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
    };
  }
}
