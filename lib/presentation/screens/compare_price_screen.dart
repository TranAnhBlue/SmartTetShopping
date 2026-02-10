// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/shopping_provider.dart';
//
// class ComparePriceScreen extends StatelessWidget {
//
//   final int itemId;
//
//   const ComparePriceScreen({super.key, required this.itemId});
//
//   @override
//   Widget build(BuildContext context) {
//
//     final provider = context.watch<ShoppingProvider>();
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("So sánh giá")),
//
//       body: FutureBuilder(
//         future: provider.loadCompare(itemId),
//         builder: (_, __) {
//
//           return Column(
//             children: [
//
//               if (provider.cheapestMarket != null)
//                 ListTile(
//                   title: Text(
//                       "Rẻ nhất: ${provider.cheapestMarket!['market_name']}"),
//                   subtitle: Text(
//                       "${provider.cheapestMarket!['cheapest_price']} đ"),
//                 ),
//
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: provider.priceCompare.length,
//                   itemBuilder: (_, i) {
//
//                     final price = provider.priceCompare[i];
//
//                     return ListTile(
//                       title: Text(price['market_name']),
//                       trailing: Text("${price['price']} đ"),
//                     );
//                   },
//                 ),
//               )
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
