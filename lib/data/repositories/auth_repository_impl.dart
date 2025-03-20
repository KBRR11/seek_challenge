import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const MethodChannel _channel = MethodChannel('com.example.seek_challenge/biometrics');

  @override
  Future<bool> isBiometricAvailable() async {
    developer.log('Verificando disponibilidad de biometría', name: 'AuthRepository');
    try {
      // Añadir un fallback si hay problemas con el channel
      try {
        final bool result = await _channel.invokeMethod('isBiometricAvailable');
        developer.log('Resultado nativo de disponibilidad: $result', name: 'AuthRepository');
        return result;
      } on PlatformException catch (e) {
        developer.log('Error en channel nativo: ${e.message}', name: 'AuthRepository', error: e);
        // Si falla la comunicación con el canal nativo, devolvemos false
        return false;
      }
    } catch (e) {
      developer.log('Error general al verificar biometría: $e', name: 'AuthRepository', error: e);
      return false;
    }
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    developer.log('Iniciando autenticación biométrica', name: 'AuthRepository');
    try {
      final bool result = await _channel.invokeMethod('authenticateWithBiometrics');
      developer.log('Resultado de autenticación biométrica: $result', name: 'AuthRepository');
      return result;
    } on PlatformException catch (e) {
      developer.log('Error durante autenticación biométrica: ${e.message}', name: 'AuthRepository', error: e);
      return false;
    } catch (e) {
      developer.log('Error general en autenticación biométrica: $e', name: 'AuthRepository', error: e);
      return false;
    }
  }

  @override
  Future<bool> authenticateWithPin(String pin) async {
    developer.log('Iniciando autenticación con PIN', name: 'AuthRepository');
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('pin');
      developer.log('PIN guardado encontrado: ${savedPin != null}', name: 'AuthRepository');
      
      if (savedPin == null) return false;
      
      final hashedPin = _hashPin(pin);
      final isMatch = savedPin == hashedPin;
      developer.log('Resultado de verificación de PIN: $isMatch', name: 'AuthRepository');
      return isMatch;
    } catch (e) {
      developer.log('Error en autenticación con PIN: $e', name: 'AuthRepository', error: e);
      return false;
    }
  }

  @override
  Future<void> savePin(String pin) async {
    developer.log('Guardando nuevo PIN', name: 'AuthRepository');
    try {
      final prefs = await SharedPreferences.getInstance();
      final hashedPin = _hashPin(pin);
      await prefs.setString('pin', hashedPin);
      developer.log('PIN guardado exitosamente', name: 'AuthRepository');
    } catch (e) {
      developer.log('Error al guardar PIN: $e', name: 'AuthRepository', error: e);
      throw Exception('No se pudo guardar el PIN: $e');
    }
  }

  @override
  Future<bool> isPinSet() async {
    developer.log('Verificando si el PIN está configurado', name: 'AuthRepository');
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPin = prefs.containsKey('pin');
      developer.log('PIN configurado: $hasPin', name: 'AuthRepository');
      return hasPin;
    } catch (e) {
      developer.log('Error al verificar estado del PIN: $e', name: 'AuthRepository', error: e);
      return false;
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}