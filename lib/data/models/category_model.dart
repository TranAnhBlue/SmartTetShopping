class CategoryModel {

  final int? id;
  final String name;
  final String? icon;
  final String? color;

  CategoryModel({
    this.id,
    required this.name,
    this.icon,
    this.color,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
    };
  }
}
