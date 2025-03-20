import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;
import '../../../domain/repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckBiometricAvailability extends AuthEvent {}

class AuthenticateWithBiometrics extends AuthEvent {}

class AuthenticateWithPin extends AuthEvent {
  final String pin;
  
  AuthenticateWithPin(this.pin);
  
  @override
  List<Object?> get props => [pin];
}

class SetPin extends AuthEvent {
  final String pin;
  
  SetPin(this.pin);
  
  @override
  List<Object?> get props => [pin];
}

class CheckPinStatus extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class BiometricAvailabilityState extends AuthState {
  final bool isAvailable;
  
  BiometricAvailabilityState(this.isAvailable);
  
  @override
  List<Object?> get props => [isAvailable];
}

class AuthSuccess extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  
  AuthFailure(this.message);
  
  @override
  List<Object?> get props => [message];
}

class PinSetStatus extends AuthState {
  final bool isSet;
  
  PinSetStatus(this.isSet);
  
  @override
  List<Object?> get props => [isSet];
}

class PinSetSuccess extends AuthState {}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  
  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<CheckBiometricAvailability>(_onCheckBiometricAvailability);
    on<AuthenticateWithBiometrics>(_onAuthenticateWithBiometrics);
    on<AuthenticateWithPin>(_onAuthenticateWithPin);
    on<SetPin>(_onSetPin);
    on<CheckPinStatus>(_onCheckPinStatus);
    
    developer.log('AuthBloc inicializado', name: 'AuthBloc');
  }
  
  Future<void> _onCheckBiometricAvailability(
    CheckBiometricAvailability event, 
    Emitter<AuthState> emit
  ) async {
    developer.log('Verificando disponibilidad de biometría', name: 'AuthBloc');
    emit(AuthLoading());
    try {
      developer.log('Llamando a isBiometricAvailable()', name: 'AuthBloc');
      final isAvailable = await _authRepository.isBiometricAvailable();
      developer.log('Biometría disponible: $isAvailable', name: 'AuthBloc');
      emit(BiometricAvailabilityState(isAvailable));
    } catch (e) {
      developer.log('Error al verificar biometría: $e', name: 'AuthBloc', error: e);
      // En caso de error, asumimos que la biometría no está disponible
      emit(BiometricAvailabilityState(false));
    }
  }
  
  Future<void> _onAuthenticateWithBiometrics(
    AuthenticateWithBiometrics event, 
    Emitter<AuthState> emit
  ) async {
    developer.log('Autenticando con biometría', name: 'AuthBloc');
    emit(AuthLoading());
    try {
      final isAuthenticated = await _authRepository.authenticateWithBiometrics();
      developer.log('Resultado de autenticación biométrica: $isAuthenticated', name: 'AuthBloc');
      if (isAuthenticated) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailure('Autenticación biométrica fallida'));
      }
    } catch (e) {
      developer.log('Error durante autenticación biométrica: $e', name: 'AuthBloc', error: e);
      emit(AuthFailure('Error durante autenticación biométrica: $e'));
    }
  }
  
  Future<void> _onAuthenticateWithPin(
    AuthenticateWithPin event, 
    Emitter<AuthState> emit
  ) async {
    developer.log('Autenticando con PIN', name: 'AuthBloc');
    emit(AuthLoading());
    try {
      final isAuthenticated = await _authRepository.authenticateWithPin(event.pin);
      developer.log('Resultado de autenticación PIN: $isAuthenticated', name: 'AuthBloc');
      if (isAuthenticated) {
        emit(AuthSuccess());
      } else {
        emit(AuthFailure('PIN inválido'));
      }
    } catch (e) {
      developer.log('Error durante autenticación PIN: $e', name: 'AuthBloc', error: e);
      emit(AuthFailure('Error durante autenticación con PIN: $e'));
    }
  }
  
  Future<void> _onSetPin(
    SetPin event, 
    Emitter<AuthState> emit
  ) async {
    developer.log('Configurando PIN', name: 'AuthBloc');
    emit(AuthLoading());
    try {
      await _authRepository.savePin(event.pin);
      developer.log('PIN configurado correctamente', name: 'AuthBloc');
      emit(PinSetSuccess());
    } catch (e) {
      developer.log('Error al configurar PIN: $e', name: 'AuthBloc', error: e);
      emit(AuthFailure('Error al configurar PIN: $e'));
    }
  }
  
  Future<void> _onCheckPinStatus(
    CheckPinStatus event, 
    Emitter<AuthState> emit
  ) async {
    developer.log('Verificando estado del PIN', name: 'AuthBloc');
    emit(AuthLoading());
    try {
      final isPinSet = await _authRepository.isPinSet();
      developer.log('PIN configurado: $isPinSet', name: 'AuthBloc');
      emit(PinSetStatus(isPinSet));
    } catch (e) {
      developer.log('Error al verificar estado del PIN: $e', name: 'AuthBloc', error: e);
      emit(AuthFailure('Error al verificar estado del PIN: $e'));
    }
  }
}