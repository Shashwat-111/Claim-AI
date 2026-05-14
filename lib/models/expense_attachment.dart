import 'dart:typed_data';

/// One user-selected file (image or PDF) to send to Gemini.
class ExpenseAttachment {
  ExpenseAttachment({
    required this.displayName,
    required this.mimeType,
    required this.bytes,
  });

  final String displayName;
  final String mimeType;
  final Uint8List bytes;
}
