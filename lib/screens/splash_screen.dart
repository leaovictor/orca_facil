import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../viewmodels/auth_viewmodel.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;

    final authState = ref.read(authStateProvider);

    authState.when(
      data: (user) {
        if (mounted) {
          if (user != null) {
            context.go('/dashboard');
          } else {
            context.go('/login');
          }
        }
      },
      loading: () {
        if (mounted) context.go('/login');
      },
      error: (error, stack) {
        if (mounted) context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/logo/splash_screen.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward().then((value) => _checkAuthAndNavigate());
          },
        ),
      ),
    );
  }
}
