import 'reimbursement_sheet_layout.dart';

/// One line item row aligned to columns A–N of the sample expense table.
class ReimbursementExpenseLine {
  const ReimbursementExpenseLine({
    required this.expenseDate,
    this.status = '',
    required this.category,
    required this.expenseMode,
    required this.particulars,
    required this.invoiceCurrency,
    required this.invoiceAmount,
    required this.invoiceAvailable,
    required this.reimbursementRequired,
    required this.billedCurrency,
    required this.billedAmount,
    required this.invoiceLink,
    required this.reimbursementCurrencyAmount,
    required this.amountUsd,
  });

  final DateTime expenseDate;

  /// Column B (STATUS). May be empty on upload; sheet list validation allows blank.
  final String status;
  final String category;
  final String expenseMode;
  final String particulars;
  final String invoiceCurrency;
  final double invoiceAmount;
  final bool invoiceAvailable;
  final bool reimbursementRequired;
  final String billedCurrency;
  final double billedAmount;
  final String invoiceLink;
  final double reimbursementCurrencyAmount;
  final double amountUsd;

  factory ReimbursementExpenseLine.fromJson(Map<String, dynamic> json) {
    return ReimbursementExpenseLine(
      expenseDate: DateTime.parse(json['expenseDate'] as String),
      status: (json['status'] as String?)?.trim() ?? '',
      category: json['category'] as String,
      expenseMode: json['expenseMode'] as String,
      particulars: json['particulars'] as String,
      invoiceCurrency: json['invoiceCurrency'] as String,
      invoiceAmount: (json['invoiceAmount'] as num).toDouble(),
      invoiceAvailable: json['invoiceAvailable'] as bool,
      reimbursementRequired: json['reimbursementRequired'] as bool,
      billedCurrency: json['billedCurrency'] as String,
      billedAmount: (json['billedAmount'] as num).toDouble(),
      invoiceLink: json['invoiceLink'] as String,
      reimbursementCurrencyAmount: (json['reimbursementCurrencyAmount'] as num).toDouble(),
      amountUsd: (json['amountUsd'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'expenseDate': expenseDate.toIso8601String().split('T').first,
        'status': status,
        'category': category,
        'expenseMode': expenseMode,
        'particulars': particulars,
        'invoiceCurrency': invoiceCurrency,
        'invoiceAmount': invoiceAmount,
        'invoiceAvailable': invoiceAvailable,
        'reimbursementRequired': reimbursementRequired,
        'billedCurrency': billedCurrency,
        'billedAmount': billedAmount,
        'invoiceLink': invoiceLink,
        'reimbursementCurrencyAmount': reimbursementCurrencyAmount,
        'amountUsd': amountUsd,
      };

  ReimbursementExpenseLine copyWith({
    DateTime? expenseDate,
    String? status,
    String? category,
    String? expenseMode,
    String? particulars,
    String? invoiceCurrency,
    double? invoiceAmount,
    bool? invoiceAvailable,
    bool? reimbursementRequired,
    String? billedCurrency,
    double? billedAmount,
    String? invoiceLink,
    double? reimbursementCurrencyAmount,
    double? amountUsd,
  }) {
    return ReimbursementExpenseLine(
      expenseDate: expenseDate ?? this.expenseDate,
      status: status ?? this.status,
      category: category ?? this.category,
      expenseMode: expenseMode ?? this.expenseMode,
      particulars: particulars ?? this.particulars,
      invoiceCurrency: invoiceCurrency ?? this.invoiceCurrency,
      invoiceAmount: invoiceAmount ?? this.invoiceAmount,
      invoiceAvailable: invoiceAvailable ?? this.invoiceAvailable,
      reimbursementRequired: reimbursementRequired ?? this.reimbursementRequired,
      billedCurrency: billedCurrency ?? this.billedCurrency,
      billedAmount: billedAmount ?? this.billedAmount,
      invoiceLink: invoiceLink ?? this.invoiceLink,
      reimbursementCurrencyAmount:
          reimbursementCurrencyAmount ?? this.reimbursementCurrencyAmount,
      amountUsd: amountUsd ?? this.amountUsd,
    );
  }

  /// Values for columns **A through L** only (user-entered cells). Columns M
  /// onward are left to sheet formulas after a template row copy.
  List<Object?> toUserInputRowAtoL() {
    return [
      ReimbursementSheetLayout.sheetsSerialDate(expenseDate),
      status,
      category,
      expenseMode,
      particulars,
      invoiceCurrency,
      invoiceAmount,
      invoiceAvailable ? 'Yes' : 'No',
      reimbursementRequired,
      billedCurrency,
      billedAmount,
      invoiceLink,
    ];
  }
}
