import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../state/auth_controller.dart';
import '../state/history_controller.dart';
import '../widgets/agro_header.dart';
import 'auth/auth_layout.dart';

/// Pantalla de arranque: recupera la sesión guardada y decide a dónde ir.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final auth = context.read<AuthController>();
    final history = context.read<HistoryController>();
    await Future.wait([auth.restore(), Future<void>.delayed(const Duration(milliseconds: 900))]);
    if (!mounted) return;

    final user = auth.user;
    if (auth.isAuthenticated && user != null) {
      await history.load(user.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AgroBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AgroLogo(large: true),
              SizedBox(height: 36),
              SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
            ],
          ),
        ),
      ),
    );
  }
}
