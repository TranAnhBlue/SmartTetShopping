import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/local_db/database_helper.dart';

import '../../domain/entities/market_price.dart';
import '../../domain/entities/cheapest_market.dart';
import '../../domain/entities/market_total_cost.dart';
import '../../domain/entities/item_price.dart';

import '../../domain/usecases/price/add_price_usecase.dart';
import '../../domain/usecases/price/get_prices_with_market_usecase.dart';
import '../../domain/usecases/price/get_cheapest_market_usecase.dart';
import '../../domain/usecases/price/get_total_cost_by_market_usecase.dart';

class PriceProvider extends ChangeNotifier {

  final AddPriceUsecase addPriceUsecase;
  final GetPricesWithMarketUsecase getPricesUsecase;
  final GetCheapestMarketUsecase cheapestUsecase;
  final GetTotalCostByMarketUsecase totalUsecase;

  PriceProvider(
      this.addPriceUsecase,
      this.getPricesUsecase,
      this.cheapestUsecase,
      this.totalUsecase,
      );

  // ================= STATE =================

  List<MarketPrice> prices = [];
  CheapestMarket? cheapestMarket;
  List<MarketTotalCost> totals = [];

  bool isLoading = false;
  String? error;

  int? _currentItemId;

  // ===================================================
  // LOAD ITEM PRICES
  // ===================================================
  Future<void> loadPrices(int itemId) async {
    try {
      _currentItemId = itemId;

      isLoading = true;
      error = null;
      notifyListeners();

      /// ⭐ AUTO GENERATE PRICE IF EMPTY
      await DatabaseHelper.instance.generatePricesIfNeeded(
        itemId,
        30000, // fallback price
      );

      final resultPrices = await getPricesUsecase(itemId);
      final cheapest = await cheapestUsecase(itemId);

      prices = resultPrices;
      cheapestMarket = cheapest;

    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===================================================
  // ⭐ RANDOM MARKET TOTALS (NO DB REQUIRED)
  // ===================================================
  Future<void> loadMarketTotals() async {

    try {

      isLoading = true;
      notifyListeners();

      /// ⭐ FETCH REAL TOTALS FROM DB
      final result = await totalUsecase();
      totals = result;

    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===================================================
  // SORT TOTALS
  // ===================================================
  List<MarketTotalCost> getTotalsSorted({bool asc = true}) {

    final list = [...totals];

    list.sort((a, b) =>
    asc
        ? a.totalCost.compareTo(b.totalCost)
        : b.totalCost.compareTo(a.totalCost));

    return list;
  }

  // ===================================================
  // GET CHEAPEST MARKET TOTAL
  // ===================================================
  MarketTotalCost? get cheapestMarketTotal {

    if (totals.isEmpty) return null;

    final sorted = getTotalsSorted(asc: true);
    return sorted.first;
  }

  // ===================================================
  // ADD PRICE
  // ===================================================
  Future<void> addPrice(ItemPrice price) async {

    try {

      await addPriceUsecase(price);

      if (_currentItemId != null) {
        await loadPrices(_currentItemId!);
      }

      await loadMarketTotals();

    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  // ===================================================
  void clearError() {
    error = null;
    notifyListeners();
  }

  // ===================================================
// BUYING SUGGESTION
// ===================================================
  String get buyingSuggestion {

    if (prices.isEmpty || cheapestMarket == null) {
      return "";
    }

    /// tìm giá cao nhất
    final highest = prices.reduce(
          (a, b) => a.price > b.price ? a : b,
    );

    final diff =
        highest.price - cheapestMarket!.price;

    return "Nên mua tại ${cheapestMarket!.marketName}"
        " (rẻ hơn ${diff.toStringAsFixed(0)}đ)";
  }

  // ===================================================
// CHECK CHEAPEST MARKET
// ===================================================
  bool isCheapest(String marketName) {
    return cheapestMarket?.marketName == marketName;
  }

}