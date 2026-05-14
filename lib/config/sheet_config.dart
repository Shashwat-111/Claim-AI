/// Hardcoded Copious Google Sheet targets. Change these constants to use another file/tab.
class SheetConfig {
  SheetConfig._();

  static const String spreadsheetId = '155cVni4r4TNu-H8aI4B_hc7SYXP7mrPZc253PqBNxYo';

  /// Tab with claim header, line items, and TOTAL row.
  static const String claimTabName = 'Sheet1';

  /// Tab with category (col A) and currency (col B) lists for dropdowns.
  static const String importRangeTab = 'Import Range';

  /// First 1-based row of line-item **data** (below the header row). Used as the
  /// lowest row allowed when copying a template row above an insertion point.
  static const int firstLineItemDataRowOneBased = 7;

  /// Last **inclusive** column for user-entered cells (1=A … 12=L). Columns M
  /// onward keep formulas/format from the copied template row.
  static const int userInputLastColumnOneBased = 12;

  /// Exclusive end column index (0-based) when copying A..O (15 columns).
  static const int fullLineGridEndColumnExclusive = 15;

  /// A1 notation tab name with special characters escaped.
  static String quoteTab(String tabName) {
    final t = tabName.trim();
    final escaped = t.replaceAll("'", "''");
    return "'$escaped'";
  }
}
