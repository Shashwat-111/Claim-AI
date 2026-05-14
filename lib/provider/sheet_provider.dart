import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/sheet_config.dart';
import '../models/reimbursement_expense_line.dart';
import '../services/google_sheets_service.dart';

class SheetProvider extends ChangeNotifier {
  SheetProvider();

  static const _assetPath = 'assets/secrets/google_service_account.json';

  GoogleSheetsService? _service;
  String? _initError;

  List<String> importCategories = [];
  List<String> importCurrencies = [];
  String? dropdownListsMessage;
  String? dropdownListsError;

  bool _busy = false;
  String? _lastMessage;
  String? _lastError;

  bool get busy => _busy;
  String? get lastMessage => _lastMessage;
  String? get lastError => _lastError;
  String? get initError => _initError;

  Future<void> ensureInitialized() async {
    if (_service != null) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      _service = await GoogleSheetsService.fromServiceAccountJson(raw);
      _initError = null;
    } catch (e, st) {
      _initError =
          'Missing or invalid $_assetPath. Copy assets/secrets/google_service_account.example.json '
          'to google_service_account.json, paste your real service account JSON from Google Cloud, '
          'then run flutter pub get and rebuild so the asset is bundled. Error: $e';
      if (kDebugMode) {
        debugPrintStack(stackTrace: st, label: 'SheetProvider.ensureInitialized');
      }
    }
    notifyListeners();
  }

  /// Loads category (column A) and currency (column B) lists from the Import Range tab.
  Future<void> loadImportListOptions() async {
    dropdownListsMessage = null;
    dropdownListsError = null;
    await ensureInitialized();
    if (_service == null) {
      dropdownListsError = _initError ?? 'Sheets client not initialized.';
      notifyListeners();
      return;
    }
    _busy = true;
    notifyListeners();
    try {
      final id = SheetConfig.spreadsheetId;
      final imp = SheetConfig.importRangeTab;
      importCategories = await _service!.readDistinctColumn(
        id,
        '${SheetConfig.quoteTab(imp)}!A2:A200',
      );
      importCurrencies = await _service!.readDistinctColumn(
        id,
        '${SheetConfig.quoteTab(imp)}!B2:B200',
      );
      dropdownListsMessage =
          'Loaded ${importCategories.length} categories, ${importCurrencies.length} currencies from "$imp".';
    } catch (e) {
      dropdownListsError = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Inserts a row immediately **above** the TOTAL row (auto-detect in column D from row 7).
  Future<void> insertLineAboveTotal(ReimbursementExpenseLine line) async {
    _lastError = null;
    _lastMessage = null;
    await ensureInitialized();
    if (_service == null) {
      _lastError = _initError ?? 'Sheets client not initialized.';
      notifyListeners();
      return;
    }
    _busy = true;
    notifyListeners();
    try {
      await _service!.insertExpenseLineAboveTotal(
        spreadsheetId: SheetConfig.spreadsheetId,
        tabName: SheetConfig.claimTabName,
        line: line,
        manualInsertBeforeOneBasedRow: null,
      );
      _lastMessage = 'Row inserted above TOTAL on ${SheetConfig.claimTabName} '
          '(row copied for format & formulas; only A–L filled from the app).';
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}

