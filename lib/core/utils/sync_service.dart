import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/shopping_item.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _itemsCollection =>
      _firestore.collection('users').doc(_userId).collection('items');

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
    } catch (e) {
      debugPrint("Firestore Upload Error: $e");
    }
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
