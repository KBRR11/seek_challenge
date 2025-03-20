import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/qr_code.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/auth_page.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/qr_scanner_page.dart';
import '../../presentation/pages/qr_detail_page.dart';
import '../../presentation/pages/qr_result_page.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) {
          // Obtener parámetros de query si existen
          final isBiometricAvailable = state.uri.queryParameters['biometric'] == 'true';
          return AuthPage(isBiometricAvailable: isBiometricAvailable);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'scan',
            name: 'scan',
            builder: (context, state) => const QrScannerPage(),
          ),
          GoRoute(
            path: 'detail',
            name: 'detail',
            builder: (context, state) {
              // Obtener el QR code de los parámetros extras
              final qrCode = state.extra as QrCode?;
              if (qrCode == null) {
                // Si no hay QR code, redirigir a home
                return const HomePage();
              }
              return QrDetailPage(qrCode: qrCode);
            },
          ),
          GoRoute(
            path: 'result',
            name: 'result',
            builder: (context, state) {
              // Obtener el QR code de los parámetros extras
              final qrCode = state.extra as QrCode?;
              if (qrCode == null) {
                // Si no hay QR code, redirigir a home
                return const HomePage();
              }
              return QrResultPage(qrCode: qrCode);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error?.message ?? "Página no encontrada"}'),
      ),
    ),
  );
}