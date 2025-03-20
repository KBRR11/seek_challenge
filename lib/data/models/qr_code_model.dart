import '../../domain/entities/qr_code.dart';

class QrCodeModel extends QrCode {
  const QrCodeModel({
    int? id,
    required String content,
    required DateTime scannedAt,
  }) : super(
          id: id,
          content: content,
          scannedAt: scannedAt,
        );

  factory QrCodeModel.fromMap(Map<String, dynamic> map) {
    return QrCodeModel(
      id: map['id'],
      content: map['content'],
      scannedAt: DateTime.parse(map['scanned_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  factory QrCodeModel.fromEntity(QrCode entity) {
    return QrCodeModel(
      id: entity.id,
      content: entity.content,
      scannedAt: entity.scannedAt,
    );
  }
}