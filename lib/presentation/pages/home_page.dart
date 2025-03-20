import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/qr/qr_bloc.dart';

import 'dart:developer' as developer;
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadQrCodes();
  }

  void _loadQrCodes() {
    context.read<QrBloc>().add(LoadQrCodes());
  }

  void _navigateToScannerPage() {
    context.push('/home/scan');
  }

  void _deleteQrCode(int id) {
    context.read<QrBloc>().add(DeleteQrCode(id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner App'),
        centerTitle: true,
      ),
      body: BlocBuilder<QrBloc, QrState>(
        builder: (context, state) {
          developer.log('ESTADO: $state', name: 'HOME WIDGET');
          if (state is QrLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is QrCodesLoaded) {
            if (state.qrCodes.isEmpty) {
              return const Center(
                child: Text(
                  'No hay códigos QR escaneados.\nEscanea tu primer código!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.qrCodes.length,
              itemBuilder: (context, index) {
                final qrCode = state.qrCodes[index];
                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      qrCode.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Escaneado: ${dateFormat.format(qrCode.scannedAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteQrCode(qrCode.id!),
                    ),
                    onTap: () {
                      context.push('/home/detail', extra: qrCode);
                    },
                  ),
                );
              },
            );
          } else if (state is QrError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          
          return const Center(child: Text('Comienza a escanear códigos QR'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToScannerPage,
        child: const Icon(Icons.qr_code_scanner),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}