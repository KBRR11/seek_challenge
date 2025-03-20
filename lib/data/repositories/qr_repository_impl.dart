import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../../domain/entities/qr_code.dart';
import '../../domain/repositories/qr_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/qr_code_model.dart';

class QrRepositoryImpl implements QrRepository {
  final DatabaseHelper _databaseHelper;
  static const MethodChannel _channel = MethodChannel('com.example.seek_challenge/qr_scanner');
  final StreamController<String> _qrCodeController = StreamController<String>.broadcast();
  
  // Para manejar la textura de la cámara
  int? _cameraTextureId;

  QrRepositoryImpl(this._databaseHelper) {
    _setupMethodCallHandler();
    developer.log('QrRepositoryImpl inicializado y MethodCallHandler configurado', name: 'QrRepository');
  }

  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      developer.log('Llamada de método recibida: ${call.method} con args: ${call.arguments}', name: 'QrRepository');
      
      if (call.method == 'onQRCodeDetected') {
        final String qrCode = call.arguments;
        developer.log('QR Code detectado en channel: $qrCode', name: 'QrRepository');
        
        // Emitir el código QR en el stream
        _qrCodeController.add(qrCode);
        
        // Devolver un valor para completar el Future
        return 'recibido';
      }
      
      return null;
    });
  }

  @override
  Stream<String> get qrCodeStream => _qrCodeController.stream;

  @override
  Future<List<QrCode>> getAllQrCodes() async {
    developer.log('Obteniendo todos los códigos QR', name: 'QrRepository');
    return await _databaseHelper.getAllQrCodes();
  }

  @override
  Future<QrCode> saveQrCode(QrCode qrCode) async {
    developer.log('Guardando código QR: ${qrCode.content}', name: 'QrRepository');
    final qrCodeModel = QrCodeModel.fromEntity(qrCode);
    final id = await _databaseHelper.insertQrCode(qrCodeModel);
    return QrCodeModel(
      id: id,
      content: qrCode.content,
      scannedAt: qrCode.scannedAt,
    );
  }

  @override
  Future<void> deleteQrCode(int id) async {
    developer.log('Eliminando código QR con ID: $id', name: 'QrRepository');
    await _databaseHelper.deleteQrCode(id);
  }

  @override
  Future<int?> startQrScanner() async {
    developer.log('Iniciando escáner de QR', name: 'QrRepository');
    try {
      // Usar dynamic para evitar problemas de tipo
      final dynamic result = await _channel.invokeMethod('startScan');
      developer.log('Resultado bruto del escáner: $result', name: 'QrRepository');
      
      if (result is Map) {
        // Extrae el ID de textura de manera segura
        final textureId = result['textureId'];
        if (textureId is int) {
          _cameraTextureId = textureId;
          developer.log('Escáner de QR iniciado correctamente con textureId: $_cameraTextureId', name: 'QrRepository');
          return _cameraTextureId;
        } else {
          developer.log('Error: textureId no es un entero: $textureId (${textureId.runtimeType})', name: 'QrRepository');
          throw Exception('Error: ID de textura inválido');
        }
      } else {
        developer.log('Error: resultado no es un Map: $result (${result.runtimeType})', name: 'QrRepository');
        throw Exception('Error: formato de respuesta inválido');
      }
    } on PlatformException catch (e) {
      developer.log('Error al iniciar escáner de QR: ${e.message}', name: 'QrRepository', error: e);
      throw Exception('Error al iniciar el escáner de QR: ${e.message}');
    } catch (e) {
      developer.log('Error inesperado al iniciar escáner de QR: $e', name: 'QrRepository', error: e);
      throw Exception('Error inesperado al iniciar el escáner de QR: $e');
    }
  }

  @override
  Future<void> stopQrScanner() async {
    developer.log('Deteniendo escáner de QR', name: 'QrRepository');
    try {
      await _channel.invokeMethod('stopScan');
      _cameraTextureId = null;
      developer.log('Escáner de QR detenido correctamente', name: 'QrRepository');
    } on PlatformException catch (e) {
      developer.log('Error al detener escáner de QR: ${e.message}', name: 'QrRepository', error: e);
      // No lanzamos excepción aquí para no afectar al flujo de la aplicación
    }
  }

  int? get cameraTextureId => _cameraTextureId;

  void dispose() {
    _qrCodeController.close();
  }
}