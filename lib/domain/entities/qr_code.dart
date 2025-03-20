import 'package:equatable/equatable.dart';

class QrCode extends Equatable {
  final int? id;
  final String content;
  final DateTime scannedAt;

  const QrCode({
    this.id,
    required this.content,
    required this.scannedAt,
  });

  @override
  List<Object?> get props => [id, content, scannedAt];
}