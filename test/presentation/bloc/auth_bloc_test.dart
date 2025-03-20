import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:seek_challenge/domain/repositories/auth_repository.dart';
import 'package:seek_challenge/presentation/bloc/auth/auth_bloc.dart';

@GenerateMocks([AuthRepository])
import 'auth_bloc_test.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state should be AuthInitial', () {
    expect(authBloc.state, isA<AuthInitial>());
  });

  group('CheckBiometricAvailability', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, BiometricAvailabilityState] when biometric is available',
      build: () {
        when(
          mockAuthRepository.isBiometricAvailable(),
        ).thenAnswer((_) async => true);
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckBiometricAvailability()),
      expect:
          () => [
            isA<AuthLoading>(),
            isA<BiometricAvailabilityState>().having(
              (state) => state.isAvailable,
              'isAvailable',
              true,
            ),
          ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, BiometricAvailabilityState] when biometric is not available',
      build: () {
        when(
          mockAuthRepository.isBiometricAvailable(),
        ).thenAnswer((_) async => false);
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckBiometricAvailability()),
      expect:
          () => [
            isA<AuthLoading>(),
            isA<BiometricAvailabilityState>().having(
              (state) => state.isAvailable,
              'isAvailable',
              false,
            ),
          ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, BiometricAvailabilityState(false)] when error occurs',
      build: () {
        when(
          mockAuthRepository.isBiometricAvailable(),
        ).thenThrow(Exception('Error'));
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckBiometricAvailability()),
      expect:
          () => [
            isA<AuthLoading>(),
            isA<BiometricAvailabilityState>().having(
              (state) => state.isAvailable,
              'isAvailable',
              false,
            ),
          ],
    );
  });

  group('AuthenticateWithBiometrics', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when biometric authentication succeeds',
      build: () {
        when(
          mockAuthRepository.authenticateWithBiometrics(),
        ).thenAnswer((_) async => true);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthenticateWithBiometrics()),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when biometric authentication fails',
      build: () {
        when(
          mockAuthRepository.authenticateWithBiometrics(),
        ).thenAnswer((_) async => false);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthenticateWithBiometrics()),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  group('AuthenticateWithPin', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when PIN authentication succeeds',
      build: () {
        when(
          mockAuthRepository.authenticateWithPin(any),
        ).thenAnswer((_) async => true);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthenticateWithPin('1234')),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when PIN authentication fails',
      build: () {
        when(
          mockAuthRepository.authenticateWithPin(any),
        ).thenAnswer((_) async => false);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthenticateWithPin('1234')),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  group('SetPin', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, PinSetSuccess] when PIN is set',
      build: () {
        when(mockAuthRepository.savePin(any)).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(SetPin('1234')),
      expect: () => [isA<AuthLoading>(), isA<PinSetSuccess>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when setting PIN fails',
      build: () {
        when(mockAuthRepository.savePin(any)).thenThrow(Exception('Error'));
        return authBloc;
      },
      act: (bloc) => bloc.add(SetPin('1234')),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  group('CheckPinStatus', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, PinSetStatus] when PIN is set',
      build: () {
        when(mockAuthRepository.isPinSet()).thenAnswer((_) async => true);
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckPinStatus()),
      expect:
          () => [
            isA<AuthLoading>(),
            isA<PinSetStatus>().having((state) => state.isSet, 'isSet', true),
          ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, PinSetStatus] when PIN is not set',
      build: () {
        when(mockAuthRepository.isPinSet()).thenAnswer((_) async => false);
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckPinStatus()),
      expect:
          () => [
            isA<AuthLoading>(),
            isA<PinSetStatus>().having((state) => state.isSet, 'isSet', false),
          ],
    );
  });
}
