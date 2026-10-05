import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'theme.dart';
import 'state/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'services/reminder_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ReminderService.init(); // hatırlatma varsa yeniden planla (hatalıysa sessiz geçer)
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: const QuantoraApp(),
    ),
  );
}

class QuantoraApp extends StatelessWidget {
  const QuantoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const _Root(),
    );
  }
}

/// Routes between splash / auth / onboarding / home based on app state.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    switch (state.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return state.onboardingComplete ? const HomeScreen() : const OnboardingScreen();
    }
  }
}
