import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/bill_provider.dart';
import 'providers/settings_provider.dart';
import 'pages/chat_page.dart';
import 'pages/splash_page.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  await settings.init();
  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final SettingsProvider settings;
  const MyApp({Key? key, required this.settings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
      ],
      child: MaterialApp(
        title: '小熊记账',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primaryColor: AppTheme.primaryBrown,
          scaffoldBackgroundColor: AppTheme.backgroundCream,
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryBrown,
            secondary: AppTheme.accentCherry,
            surface: AppTheme.cardCream,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textHint),
          ),
        ),
        home: SplashPage(),
      ),
    );
  }
}
