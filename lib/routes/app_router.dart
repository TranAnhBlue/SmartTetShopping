import 'package:flutter/material.dart';

import '../presentation/args/item_price_args.dart';
import '../presentation/screens/ai/smart_shopping_ai_screen.dart';
import '../presentation/screens/compare/compare_market_premium_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/items/add_item_screen.dart';
import '../presentation/screens/items/edit_item_screen.dart';
import '../presentation/screens/price/item_price_screen.dart';
import '../presentation/screens/lucky_money/lucky_money_screen.dart';
import '../presentation/screens/lucky_money/greeting_screen.dart';
import '../domain/entities/shopping_item.dart';

class AppRouter {
  static Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/add-item':
        return MaterialPageRoute(builder: (_) => const AddItemScreen());
      case '/edit-item':
        if (settings.arguments is! ShoppingItem) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Center(child: Text("Invalid item data"))),
          );
        }
        final item = settings.arguments as ShoppingItem;
        return MaterialPageRoute(builder: (_) => EditItemScreen(item: item));
      case '/item-price':
        if (settings.arguments is! ItemPriceArgs) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Center(child: Text("Invalid item data"))),
          );
        }
        final args = settings.arguments as ItemPriceArgs;
        return MaterialPageRoute(
          builder: (_) => ItemPriceScreen(itemId: args.itemId, itemName: args.itemName),
        );
      case '/compare-market':
        return MaterialPageRoute(builder: (_) => const CompareMarketPremiumScreen());
      case '/smart-ai':
        return MaterialPageRoute(builder: (_) => const SmartShoppingAIScreen());
      case '/lucky-money':
        return MaterialPageRoute(builder: (_) => const LuckyMoneyScreen());
      case '/greetings':
        return MaterialPageRoute(builder: (_) => const GreetingScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text("Route not found"))),
        );
    }
  }
}
