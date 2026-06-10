import 'package:flutter/material.dart';

import '../config/auth_roles.dart';
import '../screens/login_screen.dart';
import '../screens/map_screen.dart';
import 'auth_session.dart';

Future<void> completeLoginOrShowRoleError(BuildContext context, dynamic user) async {
  if (!userHasAllowedRole(user)) {
    await clearStoredAuth();
    if (!context.mounted) return;
    await showDialog<void>(
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
    MaterialPageRoute<void>(builder: (_) => const MapScreen()),
    (_) => false,
  );
}

Future<void> showUnauthorizedAccessDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Geen toegang'),
      content: const Text(unauthorizedSessionMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> forceReLoginAfterUnauthorized(BuildContext context) async {
  await clearStoredAuth();
  if (!context.mounted) return;
  await showUnauthorizedAccessDialog(context);
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (context) => LoginScreen(
        onLoginSuccess: completeLoginOrShowRoleError,
      ),
    ),
    (_) => false,
  );
}
