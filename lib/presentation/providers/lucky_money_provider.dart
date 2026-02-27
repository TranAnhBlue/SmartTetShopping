import 'package:flutter/material.dart';
import '../../data/local_db/dao/lucky_money_dao.dart';
import '../../data/local_db/database_helper.dart';
import '../../domain/entities/lucky_money.dart';

class LuckyMoneyProvider with ChangeNotifier {
  List<LuckyMoney> _luckyMoneyList = [];
  bool _isLoading = false;

  List<LuckyMoney> get luckyMoneyList => _luckyMoneyList;
  bool get isLoading => _isLoading;

  double get totalBudget => _luckyMoneyList.fold(0, (sum, item) => sum + item.amount);
  double get preparedAmount => _luckyMoneyList.where((e) => e.isPrepared == 1).fold(0, (sum, e) => sum + e.amount);
  double get gaveAmount => _luckyMoneyList.where((e) => e.isGave == 1).fold(0, (sum, e) => sum + e.amount);

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
    _luckyMoneyList.insert(0, luckyMoney.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateLuckyMoney(LuckyMoney luckyMoney) async {
    final db = await DatabaseHelper.instance.database;
    final dao = LuckyMoneyDao(db);
    await dao.update(luckyMoney);
    
    final index = _luckyMoneyList.indexWhere((e) => e.id == luckyMoney.id);
    if (index != -1) {
      _luckyMoneyList[index] = luckyMoney;
      notifyListeners();
    }
  }

  Future<void> deleteLuckyMoney(int id) async {
    final db = await DatabaseHelper.instance.database;
    final dao = LuckyMoneyDao(db);
    await dao.delete(id);
    _luckyMoneyList.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
