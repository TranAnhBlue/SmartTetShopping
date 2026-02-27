import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'presentation/widgets/festival/tet_overlay.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Smart Tet Shopping",
      debugShowCheckedModeBanner: false,

      /// ⭐ Localization (Hỗ trợ tiếng Việt)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', ''),
        Locale('en', ''),
      ],
      locale: const Locale('vi', ''),

      /// ⭐ Theme Tết
      theme: AppTheme.lightTheme,

      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,

      /// ⭐ Overlay Tết toàn app
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const TetOverlay(),
          ],
        );
      },
    );
  }
}

