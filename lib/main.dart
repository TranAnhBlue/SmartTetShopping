import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';

/// DB
import 'data/local_db/database_helper.dart';
import 'data/local_db/dao/item_dao.dart';
import 'data/local_db/dao/price_dao.dart';

/// Repository
import 'data/repositories/shopping_repository_impl.dart';

/// Item Usecase
import 'domain/usecases/item/add_item_usecase.dart';
import 'domain/usecases/item/get_items_usecase.dart';
import 'domain/usecases/item/delete_item_usecase.dart';
import 'domain/usecases/item/update_item_usecase.dart';

/// Price Usecase
import 'domain/usecases/price/add_price_usecase.dart';
import 'domain/usecases/price/get_prices_with_market_usecase.dart';
import 'domain/usecases/price/get_cheapest_market_usecase.dart';
import 'domain/usecases/price/get_total_cost_by_market_usecase.dart';

/// Providers
import 'presentation/providers/shopping_provider.dart';
import 'presentation/providers/price_provider.dart';

/// ⭐ Web SQLite
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// ⭐ fix SQLite Web
  // if (kIsWeb) {
  //   databaseFactory = databaseFactoryFfiWeb;
  // }

  await DatabaseHelper.instance.debugDatabase();
  // await DatabaseHelper.instance.deleteDB();

  /// =========================
  /// DAO
  /// =========================
  final itemDao = ItemDao();
  final priceDao = PriceDao();

  /// =========================
  /// Repository (DÙNG CHUNG)
  /// =========================
  final repository = ShoppingRepositoryImpl(itemDao, priceDao);

  /// =========================
  /// ITEM USECASES
  /// =========================
  final addItemUsecase = AddItemUsecase(repository);
  final getItemsUsecase = GetItemsUsecase(repository);
  final deleteItemUsecase = DeleteItemUsecase(repository);
  final updateItemUsecase = UpdateItemUsecase(repository);

  /// =========================
  /// PRICE USECASES
  /// =========================
  final addPriceUsecase = AddPriceUsecase(repository);
  final getPricesUsecase = GetPricesWithMarketUsecase(repository);
  final cheapestUsecase = GetCheapestMarketUsecase(repository);
  final totalUsecase = GetTotalCostByMarketUsecase(repository);

  runApp(
    MultiProvider(
      providers: [

        /// ✅ SHOPPING PROVIDER
        ChangeNotifierProvider(
          create: (_) => ShoppingProvider(
            addItemUsecase,
            getItemsUsecase,
            updateItemUsecase,
            deleteItemUsecase,

            /// ⭐⭐⭐ THÊM 3 USECASE NÀY (FIX CHÍNH)
            getPricesUsecase,
            cheapestUsecase,
            totalUsecase,
          )
            ..loadCategories()
            ..loadItems(),
        ),

        /// PRICE PROVIDER (dùng cho màn compare riêng)
        ChangeNotifierProvider(
          create: (_) => PriceProvider(
            addPriceUsecase,
            getPricesUsecase,
            cheapestUsecase,
            totalUsecase,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}