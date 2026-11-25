import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/api_client.dart';
import 'theme/app_colors.dart';

final GlobalKey<NavigatorState> plotPostNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> plotPostMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadPlotPostThemePreference();
  ApiClient.sessionExpired.addListener(_onSessionExpired);
  runApp(const PlotPostApp());
}

/// The login session ended (logged out elsewhere, password changed, or
/// expired after 30 days without use): go back to the welcome screen.
void _onSessionExpired() {
  plotPostNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    (_) => false,
  );
  plotPostMessengerKey.currentState?.showSnackBar(
    const SnackBar(content: Text('Your session has ended. Please log in again.')),
  );
}

class PlotPostApp extends StatelessWidget {
  const PlotPostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: plotPostThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'PlotPost',
          debugShowCheckedModeBanner: false,
          navigatorKey: plotPostNavigatorKey,
          scaffoldMessengerKey: plotPostMessengerKey,
          theme: buildPlotPostTheme(Brightness.light),
          darkTheme: buildPlotPostTheme(Brightness.dark),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
