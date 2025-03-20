import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  final bool isBiometricAvailable;

  const AuthPage({
    Key? key,
    required this.isBiometricAvailable,
  }) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _pinController = TextEditingController();
  bool _isPinSetup = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    // Verificar si ya hay un PIN configurado
    context.read<AuthBloc>().add(CheckPinStatus());
    
    // Si hay biometría disponible, intentar autenticar automáticamente
    if (widget.isBiometricAvailable) {
      Future.delayed(Duration.zero, () {
        context.read<AuthBloc>().add(AuthenticateWithBiometrics());
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _authenticateWithBiometrics() {
    context.read<AuthBloc>().add(AuthenticateWithBiometrics());
  }

  void _authenticateWithPin() {
    if (_pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu PIN')),
      );
      return;
    }
    
    context.read<AuthBloc>().add(AuthenticateWithPin(_pinController.text));
  }

  void _setPin() {
    if (_pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El PIN debe tener al menos 4 dígitos')),
      );
      return;
    }
    
    context.read<AuthBloc>().add(SetPin(_pinController.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticación'),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is PinSetStatus) {
            setState(() {
              _isPinSetup = state.isSet;
            });
          } else if (state is PinSetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN configurado correctamente')),
            );
            setState(() {
              _isPinSetup = true;
            });
            _pinController.clear();
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Ícono de autenticación
                Icon(
                  widget.isBiometricAvailable ? Icons.fingerprint : Icons.pin,
                  size: 100,
                  color: Theme.of(context).primaryColor,
                ),
                
                const SizedBox(height: 40),
                
                // Título según el estado
                Text(
                  _isPinSetup 
                      ? 'Inicie sesión para continuar' 
                      : 'Configure su PIN de seguridad',
                  style: const TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Campo de PIN
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: _isObscured,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: _isPinSetup ? 'Ingrese su PIN' : 'Crear PIN',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Botón de acción según estado
                ElevatedButton(
                  onPressed: state is AuthLoading 
                      ? null 
                      : _isPinSetup 
                          ? _authenticateWithPin 
                          : _setPin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: state is AuthLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          _isPinSetup ? 'Iniciar Sesión' : 'Configurar PIN',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Botón de biometría si está disponible
                if (widget.isBiometricAvailable && _isPinSetup)
                  OutlinedButton.icon(
                    onPressed: 
                        state is AuthLoading ? null : _authenticateWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Usar Biometría'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}