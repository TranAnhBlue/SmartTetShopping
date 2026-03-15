import 'package:flutter/material.dart';
import '../../data/local_db/dao/lucky_money_dao.dart';
import '../../data/local_db/database_helper.dart';
import '../../domain/entities/lucky_money.dart';

import '../../core/utils/sync_service.dart';

class LuckyMoneyProvider with ChangeNotifier {
  final SyncService _syncService = SyncService();
  List<LuckyMoney> _luckyMoneyList = [];
  bool _isLoading = false;

  List<LuckyMoney> get luckyMoneyList => _luckyMoneyList;
  bool get isLoading => _isLoading;

  double get totalBudget => _luckyMoneyList.fold(0, (sum, item) => sum + item.amount);
  double get preparedAmount => _luckyMoneyList.where((e) => e.isPrepared == 1).fold(0, (sum, e) => sum + e.amount);
  double get gaveAmount => _luckyMoneyList.where((e) => e.isGave == 1).fold(0, (sum, e) => sum + e.amount);

  Map<String, double> getGroupPercentages() {
    if (_luckyMoneyList.isEmpty) return {};
    final totals = <String, double>{};
    for (var item in _luckyMoneyList) {
      totals[item.group] = (totals[item.group] ?? 0) + item.amount;
    }
    return totals;
  }

  LuckyMoney? getRandomRecipient() {
    final candidates = _luckyMoneyList.where((e) => e.isGave == 0).toList();
    if (candidates.isEmpty) return null;
    candidates.shuffle();
    return candidates.first;
  }

  Future<void> seedLuckyMoney() async {
    final samples = [
      LuckyMoney(recipient: "Ông Bà", amount: 500000, group: "Gia đình", isPrepared: 1),
      LuckyMoney(recipient: "Bố Mẹ", amount: 200000, group: "Gia đình", isPrepared: 1),
      LuckyMoney(recipient: "Em trai", amount: 50000, group: "Gia đình"),
      LuckyMoney(recipient: "Bạn thân", amount: 100000, group: "Bạn bè"),
      LuckyMoney(recipient: "Sếp Tổng", amount: 500000, group: "Đồng nghiệp"),
    ];

    for (final item in samples) {
      await addLuckyMoney(item);
    }
  }

  Future<void> loadLuckyMoney() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final dao = LuckyMoneyDao(db);
      _luckyMoneyList = await dao.getAll();
    } catch (e) {
      debugPrint("Error loading lucky money: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLuckyMoney(LuckyMoney luckyMoney) async {
    final db = await DatabaseHelper.instance.database;
    final dao = LuckyMoneyDao(db);
    final id = await dao.insert(luckyMoney);
    final newItem = luckyMoney.copyWith(id: id);
    _luckyMoneyList.insert(0, newItem);
    
    // Sync to cloud
    await _syncService.uploadLuckyMoney(newItem);
    
    notifyListeners();
  }

  Future<void> updateLuckyMoney(LuckyMoney luckyMoney) async {
    final db = await DatabaseHelper.instance.database;
    final dao = LuckyMoneyDao(db);
    await dao.update(luckyMoney);
    
    final index = _luckyMoneyList.indexWhere((e) => e.id == luckyMoney.id);
    if (index != -1) {
      _luckyMoneyList[index] = luckyMoney;
      
      // Sync to cloud
      await _syncService.uploadLuckyMoney(luckyMoney);
      
      notifyListeners();
    }
  }

  Future<void> deleteLuckyMoney(int id) async {
    final db = await DatabaseHelper.instance.database;
    final dao = LuckyMoneyDao(db);
    await dao.delete(id);
    _luckyMoneyList.removeWhere((e) => e.id == id);
    
    // Sync to cloud
    await _syncService.deleteLuckyMoney(id);
    
    notifyListeners();
  }

  /// Cloud Sync
  Future<void> syncCloudToLocal() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cloudItems = await _syncService.listenToLuckyMoney().first.timeout(const Duration(seconds: 5));
      final db = await DatabaseHelper.instance.database;
      final dao = LuckyMoneyDao(db);

      for (var cloudData in cloudItems) {
        final id = int.tryParse(cloudData['id'] ?? '');
        if (id == null) continue;

        final exists = _luckyMoneyList.any((local) => local.id == id);
        if (!exists) {
          await dao.insert(LuckyMoney(
            id: id,
            recipient: cloudData['toName'] ?? '',
            amount: (cloudData['amount'] ?? 0).toDouble(),
            group: 'Gia đình', // Group mapping if needed
            isPrepared: cloudData['isPrepared'] ?? 0,
            isGave: cloudData['isGave'] ?? 0,
          ));
        }
      }
      await loadLuckyMoney();
    } catch (e) {
      debugPrint("LuckyMoney Sync Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncLocalToCloud() async {
    for (var item in _luckyMoneyList) {
      await _syncService.uploadLuckyMoney(item);
    }
  }
}
