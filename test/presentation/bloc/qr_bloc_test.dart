import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:seek_challenge/domain/entities/qr_code.dart';
import 'package:seek_challenge/domain/repositories/qr_repository.dart';
import 'package:seek_challenge/presentation/bloc/qr/qr_bloc.dart';
import 'dart:async';

@GenerateMocks([QrRepository])
import 'qr_bloc_test.mocks.dart';

void main() {
  late MockQrRepository mockQrRepository;
  late QrBloc qrBloc;
  late StreamController<String> qrCodeStreamController;

  setUp(() {
    mockQrRepository = MockQrRepository();
    qrCodeStreamController = StreamController<String>.broadcast();

    when(
      mockQrRepository.qrCodeStream,
    ).thenAnswer((_) => qrCodeStreamController.stream);

    qrBloc = QrBloc(mockQrRepository);
  });

  tearDown(() {
    qrBloc.close();
    qrCodeStreamController.close();
  });

  test('initial state should be QrInitial', () {
    expect(qrBloc.state, isA<QrInitial>());
  });

  group('StartQrScan', () {
    blocTest<QrBloc, QrState>(
      'emits [QrLoading, QrScanStarted] when scan starts successfully',
      build: () {
        when(mockQrRepository.startQrScanner()).thenAnswer((_) async {
          return null;
        });
        return qrBloc;
      },
      act: (bloc) => bloc.add(StartQrScan()),
      expect: () => [isA<QrLoading>(), isA<QrScanStarted>()],
    );

    blocTest<QrBloc, QrState>(
      'emits [QrLoading, QrError] when starting scan fails',
      build: () {
        when(mockQrRepository.startQrScanner()).thenThrow(Exception('Error'));
        return qrBloc;
      },
      act: (bloc) => bloc.add(StartQrScan()),
      expect: () => [isA<QrLoading>(), isA<QrError>()],
    );
  });

  group('StopQrScan', () {
    blocTest<QrBloc, QrState>(
      'emite [QrLoading, QrScanStopped] cuando se detiene el escaneo correctamente',
      build: () {
        when(mockQrRepository.stopQrScanner()).thenAnswer((_) async {});
        return qrBloc;
      },
      act: (bloc) => bloc.add(StopQrScan()),
      expect: () => [isA<QrLoading>(), isA<QrScanStopped>()],
    );

    blocTest<QrBloc, QrState>(
      'emite [QrLoading, QrError] cuando falla la detención del escaneo',
      build: () {
        when(mockQrRepository.stopQrScanner()).thenThrow(Exception('Error'));
        return qrBloc;
      },
      act: (bloc) => bloc.add(StopQrScan()),
      expect: () => [isA<QrLoading>(), isA<QrError>()],
    );
  });

  group('SaveQrCode', () {

    final savedQrCode = QrCode(
      id: 1,
      content: 'Test QR Code',
      scannedAt: DateTime.now(),
    );

    blocTest<QrBloc, QrState>(
      'emits [QrLoading, QrCodeSaved] when QR code is saved successfully',
      build: () {
        when(
          mockQrRepository.saveQrCode(any),
        ).thenAnswer((_) async => savedQrCode);
        return qrBloc;
      },
      act: (bloc) => bloc.add(SaveQrCode('Test QR Code')),
      expect:
          () => [
            isA<QrLoading>(),
            isA<QrCodeSaved>().having(
              (state) => state.qrCode.content,
              'content',
              'Test QR Code',
            ),
          ],
    );

    blocTest<QrBloc, QrState>(
      'emits [QrLoading, QrError] when saving QR code fails',
      build: () {
        when(mockQrRepository.saveQrCode(any)).thenThrow(Exception('Error'));
        return qrBloc;
      },
      act: (bloc) => bloc.add(SaveQrCode('Test QR Code')),
      expect: () => [isA<QrLoading>(), isA<QrError>()],
    );
  });

  group('LoadQrCodes', () {
    final qrCodes = [
      QrCode(id: 1, content: 'QR Code 1', scannedAt: DateTime.now()),
      QrCode(id: 2, content: 'QR Code 2', scannedAt: DateTime.now()),
    ];

    blocTest<QrBloc, QrState>(
      'emits [QrLoading, QrCodesLoaded] when QR codes are loaded successfully',
      build: () {
        when(mockQrRepository.getAllQrCodes()).thenAnswer((_) async => qrCodes);
        return qrBloc;
      },
      act: (bloc) => bloc.add(LoadQrCodes()),
      expect:
          () => [
            isA<QrLoading>(),
            isA<QrCodesLoaded>().having(
              (state) => state.qrCodes.length,
              'length',
              2,
            ),
          ],
    );

    blocTest<QrBloc, QrState>(
      'emits [QrLoading, QrError] when loading QR codes fails',
      build: () {
        when(mockQrRepository.getAllQrCodes()).thenThrow(Exception('Error'));
        return qrBloc;
      },
      act: (bloc) => bloc.add(LoadQrCodes()),
      expect: () => [isA<QrLoading>(), isA<QrError>()],
    );
  });

  group('DeleteQrCode', () {
    final emptyQrCodes = <QrCode>[];

    blocTest<QrBloc, QrState>(
      'emits [QrLoading, QrCodesLoaded] when QR code is deleted successfully',
      build: () {
        when(mockQrRepository.deleteQrCode(any)).thenAnswer((_) async {});
        when(
          mockQrRepository.getAllQrCodes(),
        ).thenAnswer((_) async => emptyQrCodes);
        return qrBloc;
      },
      act: (bloc) => bloc.add(DeleteQrCode(1)),
      expect:
          () => [
            isA<QrLoading>(),
            isA<QrCodesLoaded>().having(
              (state) => state.qrCodes,
              'qrCodes',
              emptyQrCodes,
            ),
          ],
    );

    blocTest<QrBloc, QrState>(
      'emite [QrLoading, QrCodesLoaded] cuando se elimina el código QR correctamente',
      build: () {
        when(mockQrRepository.deleteQrCode(any)).thenAnswer((_) async {});
        when(mockQrRepository.getAllQrCodes()).thenAnswer((_) async => []);
        return qrBloc;
      },
      act: (bloc) => bloc.add(DeleteQrCode(1)),
      expect:
          () => [
            isA<QrLoading>(),
            isA<QrCodesLoaded>().having(
              (state) => state.qrCodes,
              'qrCodes',
              [],
            ),
          ],
    );
  });
}
