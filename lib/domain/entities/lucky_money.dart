class LuckyMoney {
  final int? id;
  final String recipient;
  final double amount;
  final String group; // e.g., Family, Friend, Colleague
  final int isPrepared; // 0 or 1
  final int isGave; // 0 or 1
  final String? note;

  LuckyMoney({
    this.id,
    required this.recipient,
    required this.amount,
    required this.group,
    this.isPrepared = 0,
    this.isGave = 0,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipient': recipient,
      'amount': amount,
      'group_name': group,
      'is_prepared': isPrepared,
      'is_gave': isGave,
      'note': note,
    };
  }

  factory LuckyMoney.fromMap(Map<String, dynamic> map) {
    return LuckyMoney(
      id: map['id'],
      recipient: map['recipient'],
      amount: map['amount'],
      group: map['group_name'],
      isPrepared: map['is_prepared'] ?? 0,
      isGave: map['is_gave'] ?? 0,
      note: map['note'],
    );
  }

  LuckyMoney copyWith({
    int? id,
    String? recipient,
    double? amount,
    String? group,
    int? isPrepared,
    int? isGave,
    String? note,
  }) {
    return LuckyMoney(
      id: id ?? this.id,
      recipient: recipient ?? this.recipient,
      amount: amount ?? this.amount,
      group: group ?? this.group,
      isPrepared: isPrepared ?? this.isPrepared,
      isGave: isGave ?? this.isGave,
      note: note ?? this.note,
    );
  }
}
