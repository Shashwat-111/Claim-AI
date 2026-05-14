/// Values allowed by data validation in Copious Claim Sheet-5.xlsx (Sheet1).
/// Categories and currencies are defined in `lib/config/sheet_static_options.dart`.
///
/// Column B (STATUS) uses list validation with **allow blank**; uploads may leave it empty.
class CopiousSheetValidOptions {
  CopiousSheetValidOptions._();

  /// Column D expense mode — validated range `D7:D9`.
  static const List<String> expenseModes = ['Personal Card', 'Company Card', 'Cash'];

  /// Column H — validated range `H7:H9`.
  static const List<String> invoiceAvailableLabels = ['Yes', 'No'];

  /// Column B line status — validated range `B7:B9` (blank allowed).
  static const List<String> lineStatusOptions = ['Approved', 'Query', 'Declined'];
}
