import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../bloc/qr/qr_bloc.dart';
import 'qr_result_page.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({Key? key}) : super(key: key);

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  late final QrBloc _qrBloc;
  
  @override
  void initState() {
    super.initState();
    developer.log('QrScannerPage - initState', name: 'QrScannerPage');
    // Obtenemos la referencia al bloc aquí para usarla en dispose
    _qrBloc = context.read<QrBloc>();
    _startQrScanner();
  }

  void _startQrScanner() {
    developer.log('Iniciando escáner QR', name: 'QrScannerPage');
    _qrBloc.add(StartQrScan());
  }

  @override
  void dispose() {
    developer.log('QrScannerPage - dispose', name: 'QrScannerPage');
    // Usamos la referencia guardada en initState
    // _qrBloc.add(StopQrScan());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Interceptar el botón de regreso para garantizar que los recursos se liberen
      onWillPop: () async {
        developer.log('Botón de retroceso presionado', name: 'QrScannerPage');
        _qrBloc.add(StopQrScan());
        // Esperar un momento para asegurarse de que los recursos se liberan
        await Future.delayed(const Duration(milliseconds: 100));
        // Devolver true para permitir la navegación de retorno
        Navigator.of(context).pop(true); // Indicar que se escaneó un QR
        return false; // No permitir que WillPopScope maneje la navegación
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Escanear Código QR'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              developer.log('Botón de retroceso en AppBar presionado', name: 'QrScannerPage');
              _qrBloc.add(StopQrScan());
              // Esperar un momento para asegurarse de que los recursos se liberan
              Future.delayed(const Duration(milliseconds: 100), () {
                Navigator.of(context).pop(true); // Indicar que se escaneó un QR
              });
            },
          ),
        ),
        body: BlocConsumer<QrBloc, QrState>(
          listener: (context, state) {
            developer.log('Estado del bloc: ${state.runtimeType}', name: 'QrScannerPage');
            
            if (state is QrCodeSaved) {
              // Cuando se detecta y guarda un código QR, ir a la página de resultado
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => QrResultPage(qrCode: state.qrCode),
                ),
              );
            } else if (state is QrError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}')),
              );
            }
          },
          builder: (context, state) {
            if (state is QrLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is QrScanStarted) {
              // Si tenemos un ID de textura, mostrar la vista previa de la cámara
              if (state.textureId != null) {
                return Stack(
                  children: [
                    // Vista previa de la cámara usando Texture
                    Positioned.fill(
                      child: Texture(textureId: state.textureId!),
                    ),
                    // Recuadro de guía para escaneo
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // Texto informativo
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Container(
                        alignment: Alignment.center,
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text(
                          'Apunte la cámara al código QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Si el ID de textura es nulo, mostrar mensaje de error
                return const Center(
                  child: Text('Error al iniciar la cámara'),
                );
              }
            }
            
            // Estado por defecto
            return const Center(
              child: Text('Preparando cámara...'),
            );
          },
        ),
      ),
    );
  }
}