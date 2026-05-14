/// Layout constants derived from `Expense Claims - Shashwat Dubey - 1267.xlsx`.
class ReimbursementSheetLayout {
  ReimbursementSheetLayout._();

  /// Header row for the line-item grid (row 6 in the sample export).
  static const List<String> lineItemHeaderLabels = [
    'EXPENSE DATE',
    'STATUS',
    'CATEGORY',
    'EXPENSE MODE',
    'PARTICULARS',
    'INVOICE CURRENCY',
    'INVOICE AMOUNT',
    'INVOICE AVAILABLE?',
    'REIMBURSEMENT\nREQUIRED?',
    'BILLED CURRENCY',
    'BILLED\nAMOUNT',
    'INVOICE LINK (G-DRIVE)',
    'REIMBURSEMENT\nCURRENCY AMOUNT',
    'AMOUNT IN USD',
  ];

  /// Google Sheets / Excel serial date (epoch 1899-12-30), matching Sheets.
  static int sheetsSerialDate(DateTime localDate) {
    final date = DateTime(localDate.year, localDate.month, localDate.day);
    final epoch = DateTime(1899, 12, 30);
    return date.difference(epoch).inDays;
  }
}
