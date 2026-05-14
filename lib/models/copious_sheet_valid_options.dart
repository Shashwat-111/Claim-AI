/// Values allowed by data validation in `Copious Claim Sheet.xlsx` (Sheet1),
/// excluding list-from-range fields (category, currencies) which are loaded
/// from the **Import Range** tab at runtime.
///
/// Column B (STATUS) uses list validation with **allow blank**; uploads leave it empty.
class CopiousSheetValidOptions {
  CopiousSheetValidOptions._();

  /// Column D expense mode — sqref `D7:D8`.
  static const List<String> expenseModes = ['Personal Card', 'Company Card', 'Cash'];

  /// Column H — sqref `H7:H8`.
  static const List<String> invoiceAvailableLabels = ['Yes', 'No'];
}
