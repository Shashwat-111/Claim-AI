/// Category and currency lists from **Import Range** in Copious Claim Sheet-5.xlsx.
/// Sheet1 validates category against `A2:A16` and invoice/billed currency against `B2:B8` only.
class SheetStaticOptions {
  SheetStaticOptions._();

  static const List<String> importCategories = [
    'Accommodation',
    'Bank Charges',
    'Client Entertainment',
    'Client Gifts',
    'Data/Voice',
    'Food',
    'Learning Material',
    'Miscellaneous',
    'Office Assets',
    'Office Stationary',
    'Software Subscription',
    'Talent Entertainment',
    'Talent Gifts',
    'Team Building',
    'Travel',
  ];

  /// Validated list for columns F and J (Import Range `B2:B8` only).
  static const List<String> importCurrencies = [
    'USD',
    'SGD',
    'ZAR',
    'INR',
    'HKD',
    'AED',
    'EUR',
  ];
}
