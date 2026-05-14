import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/gemini_config.dart';
import '../config/sheet_static_options.dart';
import '../models/copious_sheet_valid_options.dart';
import '../models/expense_attachment.dart';
import '../models/reimbursement_expense_line.dart';

/// Calls Gemini with receipt images/PDFs and parses a JSON array of [ReimbursementExpenseLine].
class GeminiExpenseService {
  GeminiExpenseService();

  String _systemPrompt() {
    final cats = SheetStaticOptions.importCategories.map((e) => '"$e"').join(', ');
    final curs = SheetStaticOptions.importCurrencies.map((e) => '"$e"').join(', ');
    final modes = CopiousSheetValidOptions.expenseModes.map((e) => '"$e"').join(', ');
    final inv = CopiousSheetValidOptions.invoiceAvailableLabels.join(' or ');
    final status = CopiousSheetValidOptions.lineStatusOptions.map((e) => '"$e"').join(', ');
    return '''
You extract structured reimbursement line items from receipts (images and/or PDFs).

Return ONLY a JSON array (no markdown fences, no commentary). Each array element must be one object with EXACTLY these keys and types:
- expenseDate: string "YYYY-MM-DD"
- status: string, either "" or one of: $status
- category: string, MUST be one of: $cats
- expenseMode: string, MUST be one of: $modes
- particulars: string (short description of the expense)
- invoiceCurrency: string, MUST be one of: $curs
- invoiceAmount: number
- invoiceAvailable: boolean (true if an invoice/receipt document is present)
- reimbursementRequired: boolean (default true unless clearly not required)
- billedCurrency: string, MUST be one of: $curs
- billedAmount: number (use invoice amount in billed currency if only one amount is visible; otherwise best estimate)
- invoiceLink: string (empty "" if no URL; plain text link if visible on receipt)
- reimbursementCurrencyAmount: number (use 0 if unknown)
- amountUsd: number (use 0 if unknown)

Rules:
- Produce one object per distinct expense/receipt when possible.
- Use only the allowed literals for category, invoiceCurrency, billedCurrency, and expenseMode (exact spelling).
- For invoice available, map receipt/invoice presence to true/false; labels on the sheet use "$inv" but you output booleans.
- Dates must be reasonable invoice or expense dates from the documents; if unclear, use the most recent date mentioned.
''';
  }

  String _userPreamble(String userText) {
    final buf = StringBuffer(
      'Attached are receipt file(s). Extract line items as specified in your instructions.\n',
    );
    if (userText.trim().isNotEmpty) {
      buf.writeln('\nUser note: ${userText.trim()}');
    }
    return buf.toString();
  }

  Future<List<ReimbursementExpenseLine>> extractLines({
    required String userText,
    required List<ExpenseAttachment> attachments,
  }) async {
    final apiKey = kGeminiApiKey;
    if (apiKey.isEmpty) {
      throw StateError(
        'Missing Gemini API key. Set kGeminiApiKey in lib/config/gemini_secrets.example.dart '
        'or run with --dart-define=GEMINI_API_KEY=...',
      );
    }
    if (attachments.isEmpty) {
      throw ArgumentError('At least one attachment is required.');
    }
    if (attachments.length > kGeminiMaxAttachments) {
      throw ArgumentError('Too many attachments (max $kGeminiMaxAttachments).');
    }
    var total = 0;
    for (final a in attachments) {
      total += a.bytes.length;
    }
    if (total > kGeminiMaxTotalBytes) {
      throw ArgumentError(
        'Attachments exceed ${kGeminiMaxTotalBytes ~/ (1024 * 1024)} MB total.',
      );
    }

    final model = GenerativeModel(
      model: kGeminiModelId,
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt()),
      generationConfig: GenerationConfig(
        temperature: 0.2,
        responseMimeType: 'application/json',
      ),
    );

    final parts = <Part>[TextPart(_userPreamble(userText))];
    for (final a in attachments) {
      parts.add(DataPart(a.mimeType, a.bytes));
    }

    final response = await model.generateContent([Content.multi(parts)]);
    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw StateError('Empty response from Gemini.');
    }

    final decoded = jsonDecode(_stripJsonFences(text.trim()));
    if (decoded is! List) {
      throw FormatException('Expected JSON array, got ${decoded.runtimeType}.');
    }
    final out = <ReimbursementExpenseLine>[];
    for (var i = 0; i < decoded.length; i++) {
      final el = decoded[i];
      if (el is! Map) {
        throw FormatException('Element $i is not an object.');
      }
      out.add(_parseLine(Map<String, dynamic>.from(el), index: i));
    }
    return out;
  }

  String _stripJsonFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      final firstNl = t.indexOf('\n');
      if (firstNl != -1) {
        t = t.substring(firstNl + 1);
      }
      final end = t.lastIndexOf('```');
      if (end != -1) {
        t = t.substring(0, end).trim();
      }
    }
    return t;
  }

  ReimbursementExpenseLine _parseLine(Map<String, dynamic> json, {required int index}) {
    final expenseDate = _parseDate(json['expenseDate'], index);
    final status = _parseStatus(json['status'], index);
    final category = _matchAllowed(
      value: json['category'],
      allowed: SheetStaticOptions.importCategories,
      field: 'category',
      index: index,
    );
    final expenseMode = _matchAllowed(
      value: json['expenseMode'],
      allowed: CopiousSheetValidOptions.expenseModes,
      field: 'expenseMode',
      index: index,
    );
    final particulars = (json['particulars']?.toString() ?? '').trim();
    if (particulars.isEmpty) {
      throw FormatException('Line $index: particulars is required.');
    }
    final invoiceCurrency = _matchAllowed(
      value: json['invoiceCurrency'],
      allowed: SheetStaticOptions.importCurrencies,
      field: 'invoiceCurrency',
      index: index,
    );
    final invoiceAmount = _parseDouble(json['invoiceAmount'], 'invoiceAmount', index);
    final invoiceAvailable = _parseBool(json['invoiceAvailable'], 'invoiceAvailable', index);
    final reimbursementRequired = _parseBool(
      json['reimbursementRequired'],
      'reimbursementRequired',
      index,
      defaultValue: true,
    );
    final billedCurrency = _matchAllowed(
      value: json['billedCurrency'],
      allowed: SheetStaticOptions.importCurrencies,
      field: 'billedCurrency',
      index: index,
    );
    final billedAmount = _parseDouble(json['billedAmount'], 'billedAmount', index);
    final invoiceLink = (json['invoiceLink']?.toString() ?? '').trim();
    final reimbursementCurrencyAmount = _parseDoubleOrZero(
      json['reimbursementCurrencyAmount'],
      'reimbursementCurrencyAmount',
    );
    final amountUsd = _parseDoubleOrZero(json['amountUsd'], 'amountUsd');

    return ReimbursementExpenseLine(
      expenseDate: expenseDate,
      status: status,
      category: category,
      expenseMode: expenseMode,
      particulars: particulars,
      invoiceCurrency: invoiceCurrency,
      invoiceAmount: invoiceAmount,
      invoiceAvailable: invoiceAvailable,
      reimbursementRequired: reimbursementRequired,
      billedCurrency: billedCurrency,
      billedAmount: billedAmount,
      invoiceLink: invoiceLink,
      reimbursementCurrencyAmount: reimbursementCurrencyAmount,
      amountUsd: amountUsd,
    );
  }

  DateTime _parseDate(Object? raw, int index) {
    if (raw == null) throw FormatException('Line $index: expenseDate is required.');
    final s = raw.toString().trim();
    final d = DateTime.tryParse(s);
    if (d == null) throw FormatException('Line $index: invalid expenseDate "$s".');
    return DateTime(d.year, d.month, d.day);
  }

  String _parseStatus(Object? raw, int index) {
    if (raw == null) return '';
    final s = raw.toString().trim();
    if (s.isEmpty) return '';
    return _matchAllowed(
      value: raw,
      allowed: CopiousSheetValidOptions.lineStatusOptions,
      field: 'status',
      index: index,
    );
  }

  double _parseDouble(Object? raw, String field, int index) {
    if (raw == null) throw FormatException('Line $index: $field is required.');
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().trim()) ??
        (throw FormatException('Line $index: invalid $field "${raw.toString()}".'));
  }

  double _parseDoubleOrZero(Object? raw, String field) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().trim()) ?? 0;
  }

  bool _parseBool(Object? raw, String field, int index, {bool defaultValue = false}) {
    if (raw == null) return defaultValue;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final s = raw.toString().trim().toLowerCase();
    if (s == 'true' || s == 'yes' || s == '1') return true;
    if (s == 'false' || s == 'no' || s == '0') return false;
    throw FormatException('Line $index: invalid $field "$raw".');
  }

  String _matchAllowed({
    required Object? value,
    required List<String> allowed,
    required String field,
    required int index,
  }) {
    if (value == null) {
      throw FormatException('${_linePrefix(index)}$field is required.');
    }
    final s = value.toString().trim();
    if (s.isEmpty) {
      throw FormatException('${_linePrefix(index)}$field is required.');
    }
    for (final a in allowed) {
      if (a == s) return a;
    }
    final lower = s.toLowerCase();
    for (final a in allowed) {
      if (a.toLowerCase() == lower) return a;
    }
    throw FormatException(
      '${_linePrefix(index)}$field "$s" is not allowed. Allowed: ${allowed.join(", ")}.',
    );
  }

  String _linePrefix(int index) => 'Line $index: ';
}

/// Guess MIME type from file name for Gemini [DataPart].
String mimeTypeForExpenseFile(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.heic')) return 'image/heic';
  return 'application/octet-stream';
}

Future<Uint8List> readAttachmentBytes(String path) => File(path).readAsBytes();
