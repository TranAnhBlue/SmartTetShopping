import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'presentation/widgets/festival/tet_overlay.dart';
import 'presentation/widgets/confetti_overlay.dart';
import 'core/utils/auth_service.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/auth/login_screen.dart';

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

      home: StreamBuilder<User?>(
        stream: AuthService().user,
        initialData: AuthService().currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          
          if (user != null) {
            debugPrint("Auth State: Login SUCCESS - User: ${user.uid}");
            return const HomeScreen(key: ValueKey('home'));
          }
          
          debugPrint("Auth State: GOING TO LOGIN (Current data: $user, State: ${snapshot.connectionState})");
          return const LoginScreen(key: ValueKey('login'));
        },
      ),
      onGenerateRoute: AppRouter.generateRoute,

      /// ⭐ Overlay Tết toàn app
      builder: (context, child) {
        return ConfettiOverlay(
          child: Stack(
            children: [
              child!,
              const TetOverlay(),
            ],
          ),
        );
      },
    );
  }
}

