import '../../domain/entities/item_price.dart';
import '../../domain/entities/market.dart';
import '../../domain/entities/market_total_cost.dart';
import '../../domain/entities/shopping_item.dart';
import '../../domain/entities/suggested_item.dart';

class SmartShoppingAI {

  /// =====================================================
  /// SAFE FIND ITEM NAME
  /// =====================================================
  static String _getItemName(
      int itemId,
      List<ShoppingItem> items,
      ) {

    final item = items.where((e) => e.id == itemId).toList();

    return item.isEmpty ? "Unknown Item" : item.first.name;
  }

  /// =====================================================
  /// SAFE FIND MARKET NAME
  /// =====================================================
  static String _getMarketName(
      int marketId,
      List<Market> markets,
      ) {

    final market =
    markets.where((e) => e.id == marketId).toList();

    return market.isEmpty ? "Unknown Market" : market.first.name;
  }

  /// =====================================================
  /// 🧠 AI 1 — BEST MARKET PER ITEM
  /// =====================================================
  static List<SuggestedItem> suggestBestMarkets({
    required List<ItemPrice> prices,
    required List<ShoppingItem> items,
    required List<Market> markets,
  }) {

    if (prices.isEmpty) return [];

    final Map<int, ItemPrice> cheapest = {};

    for (final p in prices) {

      final current = cheapest[p.itemId];

      if (current == null || p.price < current.price) {
        cheapest[p.itemId] = p;
      }
    }

    return cheapest.values.map((e) {

      return SuggestedItem(
        name: _getItemName(e.itemId, items),
        price: e.price,
        market: _getMarketName(e.marketId, markets),
      );

    }).toList();
  }

  /// =====================================================
  /// 🧠 AI 2 — TOTAL COST PER MARKET
  /// =====================================================
  static List<MarketTotalCost> calculateMarketTotals({
    required List<ItemPrice> prices,
    required List<Market> markets,
  }) {

    if (prices.isEmpty) return [];

    final Map<int, double> totals = {};

    for (final p in prices) {
      totals[p.marketId] =
          (totals[p.marketId] ?? 0) + p.price;
    }

    return totals.entries.map((entry) {

      return MarketTotalCost(
        marketName:
        _getMarketName(entry.key, markets),
        totalCost: entry.value,
      );

    }).toList();
  }

  /// =====================================================
  /// 🧠 AI 3 — BEST SINGLE MARKET
  /// =====================================================
  static String? findBestMarket(
      List<MarketTotalCost> totals) {

    if (totals.isEmpty) return null;

    final sorted = [...totals]
      ..sort((a, b) =>
          a.totalCost.compareTo(b.totalCost));

    return sorted.first.marketName;
  }

  /// =====================================================
  /// 🤖 MAIN AI ENTRY (UI CALL)
  /// =====================================================
  static List<SuggestedItem> generateSuggestions(
      List<ShoppingItem> items,
      Map<int, List<Map<String, dynamic>>> itemPricesMap,
      ) {

    /// convert Map -> List<ItemPrice>
    final List<ItemPrice> prices = [];

    itemPricesMap.forEach((itemId, priceList) {

      for (final p in priceList) {

        prices.add(
          ItemPrice(
            itemId: itemId,
            marketId: p['marketId'],
            price: (p['price'] as num).toDouble(),
          ),
        );
      }
    });

    /// ⚠️ chưa có dữ liệu
    if (prices.isEmpty) return [];

    /// fake markets list từ data hiện có
    final marketIds =
    prices.map((e) => e.marketId).toSet();

    final markets = marketIds
        .map((id) => Market(id: id, name: "Market $id"))
        .toList();

    /// gọi AI core
    return suggestBestMarkets(
      prices: prices,
      items: items,
      markets: markets,
    );
  }
}