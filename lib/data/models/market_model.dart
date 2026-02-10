class MarketModel {

  final int? id;
  final String name;
  final String? location;
  final String? zone;

  MarketModel({
    this.id,
    required this.name,
    this.location,
    this.zone,
  });

  factory MarketModel.fromMap(Map<String, dynamic> map) {
    return MarketModel(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      zone: map['zone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'zone': zone,
    };
  }
}
