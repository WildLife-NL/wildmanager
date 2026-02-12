import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wildlifenl_login_components/wildlifenl_login_components.dart';

import '../config/app_config.dart';

class _LoginSubmitIntent extends Intent {
  const _LoginSubmitIntent();
}

const double kDesktopLoginMaxWidth = 1200;

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.showErrorDialog,
  });

  final void Function(BuildContext context, dynamic user) onLoginSuccess;
  final void Function(BuildContext context, List<dynamic> messages)? showErrorDialog;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final shortcuts = const <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.enter): _LoginSubmitIntent(),
      SingleActivator(LogicalKeyboardKey.numpadEnter): _LoginSubmitIntent(),
    };
    final actions = <Type, Action<Intent>>{
      _LoginSubmitIntent: CallbackAction<_LoginSubmitIntent>(
        onInvoke: (_) {
          _findAndPressLoginButton(context);
          return null;
        },
      ),
    };

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportW = constraints.hasBoundedWidth ? constraints.maxWidth : media.width;
            final viewportH = constraints.hasBoundedHeight ? constraints.maxHeight : media.height;
            final maxW = viewportW > kDesktopLoginMaxWidth ? kDesktopLoginMaxWidth : viewportW;

            return SizedBox(
              width: viewportW,
              height: viewportH,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: maxW,
                    height: viewportH,
                    child: Shortcuts(
                      shortcuts: shortcuts,
                      child: Actions(
                        actions: actions,
                        child: WildLifeNLLoginScreen(
                          key: const ValueKey<String>('wildlife_login'),
                          config: WildLifeNLLoginConfig(
                            logoAssetPath: 'assets/app_logo.png',
                            appName: AppConfig.appName,
                            theme: const LoginTheme(),
                            onLoginSuccess: onLoginSuccess,
                            showErrorDialog: showErrorDialog ?? _defaultShowErrorDialog,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static void _findAndPressLoginButton(BuildContext context) {
    void visit(Element element) {
      final widget = element.widget;
      if (widget is ElevatedButton && widget.onPressed != null) {
        widget.onPressed!();
        return;
      }
      if (widget is FilledButton && widget.onPressed != null) {
        widget.onPressed!();
        return;
      }
      element.visitChildElements(visit);
    }
    context.visitChildElements(visit);
  }

  static void _defaultShowErrorDialog(BuildContext context, List<dynamic> messages) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fout'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: messages
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(m.toString()),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
