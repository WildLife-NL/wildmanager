import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildlifenl_login_components/wildlifenl_login_components.dart';

import 'config/app_config.dart';
import 'config/auth_roles.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';

const _bearerTokenKey = 'bearer_token';
const _scopesKey = 'scopes';

Future<void> _clearStoredAuth() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_bearerTokenKey);
  await prefs.remove(_scopesKey);
}

void main() {
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

/// Toont eerst laadstatus, daarna hoofdscherm of navigeert naar apart loginscherm.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_bearerTokenKey);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _hasToken = token != null && token.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasToken) {
      return const HomeScreen();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => LoginScreen(
            onLoginSuccess: (BuildContext context, dynamic user) async {
              if (!userHasAllowedRole(user)) {
                await _clearStoredAuth();
                if (!context.mounted) return;
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Geen toegang'),
                    content: const Text(noAllowedRoleMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
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

/// Beperkt breedte op desktop en centreert de inhoud voor betere schaling.
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
