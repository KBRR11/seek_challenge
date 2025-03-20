import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../bloc/auth/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import 'auth_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    developer.log('SplashPage - initState', name: 'SplashPage');
    _initApp();
  }

  void _initApp() async {
    developer.log('SplashPage - Iniciando proceso de carga', name: 'SplashPage');
    
    // Simular un poco de tiempo de carga
    developer.log('SplashPage - Esperando delay inicial', name: 'SplashPage');
    await Future.delayed(const Duration(seconds: 2));
    developer.log('SplashPage - Delay completado', name: 'SplashPage');
    
    if (mounted) {
      developer.log('SplashPage - Widget sigue montado, verificando biometría', name: 'SplashPage');
      // Verificar si el dispositivo soporta biometría
      try {
        developer.log('SplashPage - Enviando evento CheckBiometricAvailability', name: 'SplashPage');
        context.read<AuthBloc>().add(CheckBiometricAvailability());
        developer.log('SplashPage - Evento enviado correctamente', name: 'SplashPage');
      } catch (e) {
        developer.log('SplashPage - Error al enviar evento: $e', name: 'SplashPage', error: e);
      }
    } else {
      developer.log('SplashPage - Widget ya no está montado', name: 'SplashPage');
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('SplashPage - Construyendo UI', name: 'SplashPage');
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        developer.log('SplashPage - BlocListener recibió estado: ${state.runtimeType}', name: 'SplashPage');
        
        if (state is BiometricAvailabilityState) {
          developer.log('SplashPage - Biometría disponible: ${state.isAvailable}', name: 'SplashPage');
          context.pushReplacement('/auth?biometric=${state.isAvailable}');
        } else if (state is AuthLoading) {
          developer.log('SplashPage - Estado de carga detectado', name: 'SplashPage');
        } else if (state is AuthFailure) {
          developer.log('SplashPage - Error de autenticación: ${state.message}', name: 'SplashPage');
          // Mostrar error y redirigir a AuthPage de todos modos después de un tiempo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const AuthPage(isBiometricAvailable: false),
                ),
              );
            }
          });
        } else {
          developer.log('SplashPage - Estado no manejado: ${state.runtimeType}', name: 'SplashPage');
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'QR Scanner App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              // Añadir indicador de estado de carga
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return Text(
                    'Estado: ${state.runtimeType}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}