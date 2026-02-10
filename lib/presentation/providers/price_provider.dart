import 'package:flutter/material.dart';

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

  List<MarketPrice> prices = [];
  CheapestMarket? cheapestMarket;
  List<MarketTotalCost> totals = [];

  bool isLoading = false;
  String? error;

  int? _currentItemId;

  // ================= LOAD ITEM PRICES =================
  Future<void> loadPrices(int itemId) async {

    try {

      _currentItemId = itemId;

      isLoading = true;
      error = null;
      notifyListeners();

      prices = await getPricesUsecase(itemId);
      cheapestMarket = await cheapestUsecase(itemId);

    } catch (e) {

      error = e.toString();

    } finally {

      isLoading = false;
      notifyListeners();
    }
  }

  // ================= LOAD DASHBOARD =================
  Future<void> loadMarketTotals() async {

    try {

      isLoading = true;
      notifyListeners();

      totals = await totalUsecase();

    } catch (e) {

      error = e.toString();

    } finally {

      isLoading = false;
      notifyListeners();
    }
  }

  // ================= ADD PRICE =================
  Future<void> addPrice(ItemPrice price) async {

    await addPriceUsecase(price);

    /// ⭐ reload lại data sau khi thêm
    if (_currentItemId != null) {
      await loadPrices(_currentItemId!);
    }
  }
}
