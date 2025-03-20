import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;
import '../../../domain/entities/qr_code.dart';
import '../../../domain/repositories/qr_repository.dart';

// Events
abstract class QrEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartQrScan extends QrEvent {}

class StopQrScan extends QrEvent {}

class SaveQrCode extends QrEvent {
  final String content;

  SaveQrCode(this.content);

  @override
  List<Object?> get props => [content];
}

class LoadQrCodes extends QrEvent {}

class DeleteQrCode extends QrEvent {
  final int id;

  DeleteQrCode(this.id);

  @override
  List<Object?> get props => [id];
}

// States
abstract class QrState extends Equatable {
  @override
  List<Object?> get props => [];
}

class QrInitial extends QrState {}

class QrLoading extends QrState {}

class QrScanStarted extends QrState {
  final int? textureId;

  QrScanStarted(this.textureId);

  @override
  List<Object?> get props => [textureId];
}

class QrScanStopped extends QrState {}

class QrCodeSaved extends QrState {
  final QrCode qrCode;

  QrCodeSaved(this.qrCode);

  @override
  List<Object?> get props => [qrCode];
}

class QrCodesLoaded extends QrState {
  final List<QrCode> qrCodes;

  QrCodesLoaded(this.qrCodes);

  @override
  List<Object?> get props => [qrCodes];
}

class QrError extends QrState {
  final String message;

  QrError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class QrBloc extends Bloc<QrEvent, QrState> {
  final QrRepository _qrRepository;
  StreamSubscription? _qrCodeSubscription;
  bool _isLoadingQrCodes = false;

  QrBloc(this._qrRepository) : super(QrInitial()) {
    on<StartQrScan>(_onStartQrScan);
    on<StopQrScan>(_onStopQrScan);
    on<SaveQrCode>(_onSaveQrCode);
    on<LoadQrCodes>(_onLoadQrCodes);
    on<DeleteQrCode>(_onDeleteQrCode);

    _setupQrCodeSubscription();

    developer.log('QrBloc inicializado', name: 'QrBloc');
  }

  void _setupQrCodeSubscription() {
    developer.log(
      'Configurando suscripción al stream de códigos QR',
      name: 'QrBloc',
    );

    _qrCodeSubscription?.cancel();
    _qrCodeSubscription = _qrRepository.qrCodeStream.listen(
      (qrCodeContent) {
        developer.log(
          'QR code detectado en stream: $qrCodeContent',
          name: 'QrBloc',
        );
        add(SaveQrCode(qrCodeContent));
      },
      onError: (error) {
        developer.log(
          'Error en stream de QR codes: $error',
          name: 'QrBloc',
          error: error,
        );
      },
    );
  }

  Future<void> _onStartQrScan(StartQrScan event, Emitter<QrState> emit) async {
    developer.log('Iniciando escaneo QR', name: 'QrBloc');
    emit(QrLoading());
    try {
      final textureId = await _qrRepository.startQrScanner();
      developer.log(
        'Escaneo QR iniciado con textureId: $textureId',
        name: 'QrBloc',
      );
      emit(QrScanStarted(textureId));
    } catch (e) {
      developer.log(
        'Error al iniciar escáner QR: $e',
        name: 'QrBloc',
        error: e,
      );
      emit(QrError('Error al iniciar el escáner QR: $e'));
    }
  }

  Future<void> _onStopQrScan(StopQrScan event, Emitter<QrState> emit) async {
    developer.log('Deteniendo escaneo QR', name: 'QrBloc');
    emit(QrLoading()); // Asegúrate de emitir QrLoading primero
    try {
      await _qrRepository.stopQrScanner();
      developer.log('Escaneo QR detenido', name: 'QrBloc');
      emit(QrScanStopped()); // Emitir QrScanStopped al finalizar correctamente
    } catch (e) {
      developer.log(
        'Error al detener escáner QR: $e',
        name: 'QrBloc',
        error: e,
      );
      emit(
        QrError('Error al detener el escáner QR: $e'),
      ); // Emitir QrError si hay error
    }
  }

  Future<void> _onSaveQrCode(SaveQrCode event, Emitter<QrState> emit) async {
    developer.log('Guardando código QR: ${event.content}', name: 'QrBloc');
    emit(QrLoading());
    try {
      final qrCode = QrCode(content: event.content, scannedAt: DateTime.now());
      final savedQrCode = await _qrRepository.saveQrCode(qrCode);
      developer.log(
        'Código QR guardado con ID: ${savedQrCode.id}',
        name: 'QrBloc',
      );
      emit(QrCodeSaved(savedQrCode));
    } catch (e) {
      developer.log('Error al guardar código QR: $e', name: 'QrBloc', error: e);
      emit(QrError('Error al guardar el código QR: $e'));
    }
  }

  Future<void> _onLoadQrCodes(LoadQrCodes event, Emitter<QrState> emit) async {
    // Evitar cargas múltiples simultáneas
    if (_isLoadingQrCodes) {
      developer.log(
        'Ya se está cargando la lista de QR codes, ignorando nueva solicitud',
        name: 'QrBloc',
      );
      return;
    }

    developer.log('Cargando códigos QR', name: 'QrBloc');
    _isLoadingQrCodes = true;
    emit(QrLoading());

    try {
      final qrCodes = await _qrRepository.getAllQrCodes();
      developer.log('Códigos QR cargados: ${qrCodes.length}', name: 'QrBloc');
      _isLoadingQrCodes = false;
      emit(QrCodesLoaded(qrCodes));
    } catch (e) {
      developer.log('Error al cargar códigos QR: $e', name: 'QrBloc', error: e);
      _isLoadingQrCodes = false;
      emit(QrError('Error al cargar los códigos QR: $e'));
    }
  }

  Future<void> _onDeleteQrCode(
    DeleteQrCode event,
    Emitter<QrState> emit,
  ) async {
    developer.log('Eliminando código QR con ID: ${event.id}', name: 'QrBloc');
    emit(QrLoading());
    try {
      await _qrRepository.deleteQrCode(event.id);
      developer.log('Código QR eliminado, cargando la lista', name: 'QrBloc');

      // Esta es la clave: emitir QrLoading nuevamente antes de cargar los códigos
      emit(QrLoading());

      final qrCodes = await _qrRepository.getAllQrCodes();
      emit(QrCodesLoaded(qrCodes));
    } catch (e) {
      developer.log(
        'Error al eliminar código QR: $e',
        name: 'QrBloc',
        error: e,
      );
      emit(QrError('Error al eliminar el código QR: $e'));
    }
  }

  @override
  Future<void> close() {
    developer.log('Cerrando QrBloc', name: 'QrBloc');
    _qrCodeSubscription?.cancel();
    return super.close();
  }
}
