import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildlifenl_login_components/wildlifenl_login_components.dart';

import 'auth/auth_flow.dart';
import 'auth/auth_session.dart';
import 'config/app_config.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'services/living_labs_service.dart';
import 'state/map_filter_notifier.dart';

Future<void> main() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Release web builds use --dart-define=DEV_BASE_URL=... (no .env asset in git).
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loginApiClient = HttpLoginApiClient(
      baseUrl: AppConfig.loginBaseUrl,
      displayNameApp: AppConfig.appName,
    );
    final loginService = DefaultLoginService(
      loginApiClient,
      displayNameApp: AppConfig.appName,
    );

    return MultiProvider(
      providers: [
        Provider<LoginInterface>.value(value: loginService),
        ChangeNotifierProvider(create: (_) => MapFilterNotifier()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _hasToken = false;
  bool _sessionWasUnauthorized = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(bearerTokenKey);
    if (token == null || token.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasToken = false;
      });
      return;
    }

    try {
      await fetchLivingLabs();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasToken = true;
      });
    } catch (e) {
      if (isUnauthorizedError(e)) {
        await clearStoredAuth();
        if (!mounted) return;
        setState(() {
          _loading = false;
          _hasToken = false;
          _sessionWasUnauthorized = true;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasToken = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasToken) {
      return const MapScreen();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_sessionWasUnauthorized) {
        await showUnauthorizedAccessDialog(context);
        if (!mounted) return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => LoginScreen(
            onLoginSuccess: completeLoginOrShowRoleError,
          ),
        ),
      );
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WildManager')),
      body: _DesktopFriendlyLayout(
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const MapScreen(),
                ),
              );
            },
            child: const Text('Naar kaart'),
          ),
        ),
      ),
    );
  }
}

class _DesktopFriendlyLayout extends StatelessWidget {
  const _DesktopFriendlyLayout({required this.child});

  final Widget child;

  static const double _maxContentWidth = 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _maxContentWidth) {
          return child;
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: child,
          ),
        );
      },
    );
  }
}