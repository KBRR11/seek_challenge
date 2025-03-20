import '../entities/qr_code.dart';

abstract class QrRepository {
  Future<List<QrCode>> getAllQrCodes();
  Future<QrCode> saveQrCode(QrCode qrCode);
  Future<void> deleteQrCode(int id);
  Future<int?> startQrScanner(); 
  Future<void> stopQrScanner();
  Stream<String> get qrCodeStream;
}