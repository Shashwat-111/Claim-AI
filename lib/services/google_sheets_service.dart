import 'dart:convert';

import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';

import '../config/sheet_config.dart';
import '../models/reimbursement_expense_line.dart';

/// Minimal Sheets writer using a service account JSON (Phase 1, no auth UI).
class GoogleSheetsService {
  GoogleSheetsService._(this._client, this._api);

  final AutoRefreshingAuthClient _client;
  final sheets.SheetsApi _api;

  static Future<GoogleSheetsService> fromServiceAccountJson(String jsonRaw) async {
    final credentials = ServiceAccountCredentials.fromJson(
      json.decode(jsonRaw) as Map<String, dynamic>,
    );
    final client = await clientViaServiceAccount(
      credentials,
      const [sheets.SheetsApi.spreadsheetsScope],
    );
    return GoogleSheetsService._(client, sheets.SheetsApi(client));
  }

  Future<void> close() async {
    _client.close();
  }

  Future<int?> _sheetIdForTitle(String spreadsheetId, String title) async {
    final ss = await _api.spreadsheets.get(spreadsheetId);
    for (final sheet in ss.sheets ?? const <sheets.Sheet>[]) {
      if (sheet.properties?.title == title) {
        return sheet.properties?.sheetId;
      }
    }
    return null;
  }

  /// Reads a single-column range (e.g. `A2:A99`) and returns trimmed non-empty
  /// unique strings in order of first appearance.
  Future<List<String>> readDistinctColumn(String spreadsheetId, String rangeA1) async {
    final result = await _api.spreadsheets.values.get(spreadsheetId, rangeA1);
    final rows = result.values;
    if (rows == null) return [];
    final out = <String>[];
    final seen = <String>{};
    for (final row in rows) {
      if (row.isEmpty) continue;
      final raw = row.first?.toString().trim() ?? '';
      if (raw.isEmpty) continue;
      if (seen.add(raw)) out.add(raw);
    }
    return out;
  }

  /// Finds the first row at or below [fromRowOneBased] in column D whose cell
  /// contains `TOTAL` (case-insensitive), e.g. `TOTAL →`.
  Future<int?> findTotalRowOneBased({
    required String spreadsheetId,
    required String tabName,
    int fromRowOneBased = 7,
  }) async {
    final range = '${SheetConfig.quoteTab(tabName)}!D$fromRowOneBased:D500';
    final result = await _api.spreadsheets.values.get(spreadsheetId, range);
    final rows = result.values ?? [];
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].isEmpty) continue;
      final cell = rows[i].first?.toString() ?? '';
      if (cell.toUpperCase().contains('TOTAL')) {
        return fromRowOneBased + i;
      }
    }
    return null;
  }

  /// Inserts a blank row before [insertBeforeOneBasedRow], copies the row above
  /// (or the first line-item row if the row above is the header) with
  /// **PASTE_NORMAL** so formulas, formatting, checkboxes, and validation match,
  /// then writes only **A:L** from [line] so columns M+ keep sheet formulas.
  Future<void> insertExpenseLineBeforeRow({
    required String spreadsheetId,
    required String tabName,
    required int insertBeforeOneBasedRow,
    required ReimbursementExpenseLine line,
  }) async {
    final sheetId = await _sheetIdForTitle(spreadsheetId, tabName);
    if (sheetId == null) {
      throw StateError('No sheet tab named "$tabName" in this spreadsheet.');
    }
    final insertAt0 = insertBeforeOneBasedRow - 1;
    if (insertAt0 < 0) {
      throw StateError('insertBeforeOneBasedRow must be >= 1 (got $insertBeforeOneBasedRow).');
    }

    final above0 = insertAt0 - 1;
    final minTemplate0 = SheetConfig.firstLineItemDataRowOneBased - 1;
    final sourceStart0 = above0 < minTemplate0 ? minTemplate0 : above0;
    final gridEnd = SheetConfig.fullLineGridEndColumnExclusive;

    await _api.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          sheets.Request(
            insertDimension: sheets.InsertDimensionRequest(
              inheritFromBefore: false,
              range: sheets.DimensionRange(
                sheetId: sheetId,
                dimension: 'ROWS',
                startIndex: insertAt0,
                endIndex: insertAt0 + 1,
              ),
            ),
          ),
          sheets.Request(
            copyPaste: sheets.CopyPasteRequest(
              pasteType: 'PASTE_NORMAL',
              source: sheets.GridRange(
                sheetId: sheetId,
                startRowIndex: sourceStart0,
                endRowIndex: sourceStart0 + 1,
                startColumnIndex: 0,
                endColumnIndex: gridEnd,
              ),
              destination: sheets.GridRange(
                sheetId: sheetId,
                startRowIndex: insertAt0,
                endRowIndex: insertAt0 + 1,
                startColumnIndex: 0,
                endColumnIndex: gridEnd,
              ),
            ),
          ),
        ],
      ),
      spreadsheetId,
    );

    final row = insertBeforeOneBasedRow;
    final a1 =
        '${SheetConfig.quoteTab(tabName)}!A$row:${_columnLetter(SheetConfig.userInputLastColumnOneBased)}$row';
    await _api.spreadsheets.values.update(
      sheets.ValueRange(values: [line.toUserInputRowAtoL()]),
      spreadsheetId,
      a1,
      valueInputOption: 'USER_ENTERED',
    );
  }

  /// 1-based column index → Excel/Sheets column letters (1=A, 27=AA).
  static String _columnLetter(int columnOneBased) {
    var n = columnOneBased;
    final buf = StringBuffer();
    while (n > 0) {
      n -= 1;
      buf.writeCharCode(65 + (n % 26));
      n ~/= 26;
    }
    return buf.toString().split('').reversed.join();
  }

  /// Resolves insert position: [manualInsertBeforeOneBasedRow] if set, else
  /// first TOTAL row in column D from row 7.
  Future<void> insertExpenseLineAboveTotal({
    required String spreadsheetId,
    required String tabName,
    required ReimbursementExpenseLine line,
    int? manualInsertBeforeOneBasedRow,
    int scanTotalFromRowOneBased = 7,
  }) async {
    final insertBefore = manualInsertBeforeOneBasedRow ??
        await findTotalRowOneBased(
          spreadsheetId: spreadsheetId,
          tabName: tabName,
          fromRowOneBased: scanTotalFromRowOneBased,
        );
    if (insertBefore == null) {
      throw StateError(
        'Could not find a TOTAL row in column D (from row $scanTotalFromRowOneBased). '
        'Add a label like "TOTAL →" in column D, or set a manual "insert before" row.',
      );
    }
    await insertExpenseLineBeforeRow(
      spreadsheetId: spreadsheetId,
      tabName: tabName,
      insertBeforeOneBasedRow: insertBefore,
      line: line,
    );
  }
}
