import 'package:flutter/material.dart';

import 'app_localization.dart';
import 'screens/activity_list_screen.dart';
import 'screens/activity_management_screen.dart';
import 'screens/create_activity_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'session_controller.dart';

void main() {
  runApp(const QutongxingApp());
}

class QutongxingApp extends StatefulWidget {
  const QutongxingApp({super.key});

  @override
  State<QutongxingApp> createState() => _QutongxingAppState();
}

class _QutongxingAppState extends State<QutongxingApp> {
  final SessionController _sessionController = SessionController();
  final AppLocalization _localization = AppLocalization();

  @override
  void initState() {
    super.initState();
    _sessionController.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _sessionController,
        _localization,
      ]),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: _localization.tr('appName'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6D5EF9),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F7FF),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Color(0xFF1E1B4B),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              iconTheme: IconThemeData(color: Color(0xFF1E1B4B)),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE8EBFF)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                // 注意：不能在全局给按钮设置无限宽（Size.fromHeight 会得到 width=Infinity），
                // 否则在 Row/Wrap 等横向布局中会触发 "BoxConstraints forces an infinite width"。
                minimumSize: const Size(0, 50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDDE2FF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDDE2FF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF6D5EF9),
                  width: 1.4,
                ),
              ),
            ),
          ),
          home: _buildInitialPage(),
          routes: <String, WidgetBuilder>{
            '/login': (_) => LoginScreen(
              sessionController: _sessionController,
              localization: _localization,
            ),
            '/register': (_) => RegisterScreen(
              localization: _localization,
              onLanguageSelected: _localization.setLanguage,
            ),
            '/activities': (_) =>
                ActivityListScreen(
                  sessionController: _sessionController,
                  localization: _localization,
                ),
            '/create': (_) =>
                CreateActivityScreen(
                  sessionController: _sessionController,
                ),
            '/manage': (_) =>
                ActivityManagementScreen(
                  sessionController: _sessionController,
                ),
            '/profile': (_) =>
                ProfileScreen(
                  sessionController: _sessionController,
                  localization: _localization,
                ),
          },
        );
      },
    );
  }

  Widget _buildInitialPage() {
    if (_sessionController.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_sessionController.isLoggedIn) {
      return ActivityListScreen(
        sessionController: _sessionController,
        localization: _localization,
      );
    }
    return LoginScreen(
      sessionController: _sessionController,
      localization: _localization,
    );
  }
}
