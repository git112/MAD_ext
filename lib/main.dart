// ============================================================
// main.dart – App entry point
// Initializes Hive, registers adapters, sets up Provider tree
// ============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/event_model.dart';
import 'models/participant_model.dart';
import 'models/check_in_log_model.dart';
import 'providers/event_provider.dart';
import 'providers/check_in_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/dashboard_screen.dart';
import 'utils/app_theme.dart';
import 'services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Hive initialization ---
  await Hive.initFlutter();

  // Register Hive type adapters (generated via build_runner)
  Hive.registerAdapter(EventModelAdapter());
  Hive.registerAdapter(ParticipantModelAdapter());
  Hive.registerAdapter(CheckInMethodAdapter());
  Hive.registerAdapter(CheckInLogModelAdapter());

  // Open Hive boxes
  await HiveService.init();

  runApp(const SmartEventApp());
}

class SmartEventApp extends StatelessWidget {
  const SmartEventApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()..loadEvents()),
        ChangeNotifierProvider(create: (_) => CheckInProvider()..loadData()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Event Check-in',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const DashboardScreen(),
      ),
    );
  }
}
