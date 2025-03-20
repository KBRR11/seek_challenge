import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/qr_code.dart';

class QrDetailPage extends StatelessWidget {
  final QrCode qrCode;
  
  const QrDetailPage({super.key, required this.qrCode});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Código QR'),
        centerTitle: true,
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
              label: const Text('Copiar Contenido'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            
            // Si el contenido parece ser una URL, mostrar opción para abrirla
            if (qrCode.content.startsWith('http://') || 
                qrCode.content.startsWith('https://'))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Aquí se añadiría la funcionalidad para abrir URL
                    // Por ejemplo, usando url_launcher
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función para abrir URL'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Abrir Enlace'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}