import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'data/catalog_repository.dart';
import 'models/activity.dart';
import 'screens/home_screen.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(
    nativeAppKey: const String.fromEnvironment(
      'KAKAO_NATIVE_APP_KEY',
      defaultValue: 'a661beaef8c57f975952f84ebe609804',
    ),
  );
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
    await appState.loadJourneys();
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
        seedColor: const Color(0xFF477A53),
        primary: const Color(0xFF477A53),
        surface: const Color(0xFFF9F1D9),
      ),
      scaffoldBackgroundColor: const Color(0xFFF3EED7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFD9E4BF),
        foregroundColor: Color(0xFF284E3D),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 64),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFF9E7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFF9E8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFC6D2AD)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          foregroundColor: const Color(0xFF345C43),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFD7DDBE), space: 28),
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
