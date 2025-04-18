import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/qr/qr_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../../domain/entities/qr_code.dart';
import 'package:go_router/go_router.dart';

class QrResultPage extends StatelessWidget {
  final QrCode qrCode;

  const QrResultPage({Key? key, required this.qrCode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log('QrResultPage - build', name: 'QrResultPage');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    returnHome() {
      context.read<QrBloc>().add(LoadQrCodes());
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }

    return WillPopScope(
      onWillPop: () async {
        developer.log(
          'QrResultPage - Botón de retroceso presionado',
          name: 'QrResultPage',
        );

        // Indicar que se debe recargar la lista
        returnHome();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resultado del Escaneo'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              returnHome(); 
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contenido del Código QR:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          qrCode.content,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Escaneado: ${dateFormat.format(qrCode.scannedAt)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: qrCode.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contenido copiado al portapapeles'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.pushReplacement('/home/scan');
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear Otro'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
