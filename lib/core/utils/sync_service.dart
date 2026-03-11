import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/shopping_item.dart';

class SyncService {
  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _itemsCollection =>
      _firestore.collection('users').doc(_userId).collection('items');

  CollectionReference get _luckyMoneyCollection =>
      _firestore.collection('users').doc(_userId).collection('lucky_money');

  /// Uploads a single item to Firestore
  Future<void> uploadItem(ShoppingItem item) async {
    if (_userId == null) return;
    try {
      await _itemsCollection.doc(item.id.toString()).set({
        'name': item.name,
        'estimatedPrice': item.estimatedPrice,
        'quantity': item.quantity,
        'categoryId': item.categoryId,
        'isBought': item.isBought,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Firestore Upload Success: ${item.name}");
    } catch (e) {
      debugPrint("❌ Firestore Upload Error: $e");
    }
  }

  /// TEST: Verifies backend connection with detailed feedback
  Future<String> testConnection() async {
    if (_userId == null) {
       return "CHƯA ĐĂNG NHẬP: Bạn cần Đăng nhập hoặc Tiếp tục vô danh trước.";
    }
    try {
      // Set a small timeout for the test
      await _firestore.collection('users').doc(_userId).set({
        'last_test': FieldValue.serverTimestamp(),
        'status': 'online',
        'device': 'mobile_test',
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
      
      return "SUCCESS";
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return "LỖI QUYỀN TRUY CẬP: Bạn chưa dán Rules vào Firestore (tab Rules).";
      }
      return "LỖI FIREBASE: ${e.message}";
    } catch (e) {
      if (e.toString().contains("timeout")) {
        return "LỖI TIMEOUT: Không thể kết nối server (Kiểm tra mạng).";
      }
      return "LỖI KHÁC: $e";
    }
  }

  /// Lucky Money Sync
  Future<void> uploadLuckyMoney(dynamic luckyMoney) async {
    if (_userId == null) return;
    try {
      await _luckyMoneyCollection.doc(luckyMoney.id.toString()).set({
        'toName': luckyMoney.toName,
        'amount': luckyMoney.amount,
        'isPrepared': luckyMoney.isPrepared,
        'isGave': luckyMoney.isGave,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firestore LuckyMoney Upload Error: $e");
    }
  }

  Future<void> deleteLuckyMoney(int id) async {
    if (_userId == null) return;
    try {
      await _luckyMoneyCollection.doc(id.toString()).delete();
    } catch (e) {
      debugPrint("Firestore LuckyMoney Delete Error: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> listenToLuckyMoney() {
    if (_userId == null) return Stream.value([]);
    return _luckyMoneyCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Deletes an item from Firestore
  Future<void> deleteItem(int itemId) async {
    if (_userId == null) return;
    try {
      await _itemsCollection.doc(itemId.toString()).delete();
    } catch (e) {
      debugPrint("Firestore Delete Error: $e");
    }
  }

  /// Listens for real-time changes from Firestore
  Stream<List<ShoppingItem>> listenToItems() {
    if (_userId == null) return Stream.value([]);
    
    return _itemsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ShoppingItem(
          id: int.tryParse(doc.id),
          name: data['name'] ?? '',
          estimatedPrice: (data['estimatedPrice'] ?? 0.0).toDouble(),
          quantity: data['quantity'] ?? 1,
          categoryId: data['categoryId'] ?? 1,
          isBought: data['isBought'] ?? false,
        );
      }).toList();
    });
  }

  /// Batch upload (sync all local to cloud)
  Future<void> syncAllLocalToCloud(List<ShoppingItem> localItems) async {
    if (_userId == null) return;
    
    final batch = _firestore.batch();
    for (var item in localItems) {
      final docRef = _itemsCollection.doc(item.id.toString());
      batch.set(docRef, {
        'name': item.name,
        'estimatedPrice': item.estimatedPrice,
        'quantity': item.quantity,
        'categoryId': item.categoryId,
        'isBought': item.isBought,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
