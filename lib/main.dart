import 'package:flutter/material.dart';
import 'services/app_settings_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = AppSettingsService.instance;
  await settingsService.load();
  runApp(MyApp(settingsService: settingsService));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.settingsService});

  final AppSettingsService settingsService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    widget.settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settingsService.currentSettings;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        fontFamily: settings.appFontFamily,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        fontFamily: settings.appFontFamily,
      ),
      home: const SplashScreen(),
    );
  }
}