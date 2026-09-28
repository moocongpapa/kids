import 'package:flutter/material.dart';

import 'data/catalog_repository.dart';
import 'models/activity.dart';
import 'screens/home_screen.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MomosupApp());
}

class MomosupApp extends StatefulWidget {
  const MomosupApp({super.key});

  @override
  State<MomosupApp> createState() => _MomosupAppState();
}

class _MomosupAppState extends State<MomosupApp> {
  final AppState appState = AppState();
  late final Future<List<Activity>> boot = _boot();

  Future<List<Activity>> _boot() async {
    await appState.load();
    return const CatalogRepository().load();
  }

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '모모숲',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansKR',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF78966A),
        surface: const Color(0xFFFFFAF0),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFAF0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFAF0),
        foregroundColor: Color(0xFF28372B),
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(52, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE5EBDD)),
        ),
      ),
    ),
    home: FutureBuilder<List<Activity>>(
      future: boot,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('콘텐츠를 불러오지 못했어요.\n${snapshot.error}'),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return HomeScreen(appState: appState, catalog: snapshot.data!);
      },
    ),
  );
}
