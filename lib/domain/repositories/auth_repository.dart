abstract class AuthRepository {
  Future<bool> isBiometricAvailable();
  Future<bool> authenticateWithBiometrics();
  Future<bool> authenticateWithPin(String pin);
  Future<void> savePin(String pin);
  Future<bool> isPinSet();
}