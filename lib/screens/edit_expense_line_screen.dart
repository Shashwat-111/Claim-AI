import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../config/sheet_static_options.dart';
import '../models/copious_sheet_valid_options.dart';
import '../models/reimbursement_expense_line.dart';

/// Full edit form for one captured expense line before pushing to the sheet.
class EditExpenseLineScreen extends StatefulWidget {
  const EditExpenseLineScreen({super.key, required this.line});

  final ReimbursementExpenseLine line;

  @override
  State<EditExpenseLineScreen> createState() => _EditExpenseLineScreenState();
}

class _EditExpenseLineScreenState extends State<EditExpenseLineScreen> {
  late DateTime _date;
  late String _status;
  late String _category;
  late String _expenseMode;
  late final TextEditingController _particularsCtrl;
  late String _invoiceCurrency;
  late final TextEditingController _invoiceAmountCtrl;
  late bool _invoiceAvailable;
  late bool _reimbursementRequired;
  late String _billedCurrency;
  late final TextEditingController _billedAmountCtrl;
  late final TextEditingController _invoiceLinkCtrl;
  late final TextEditingController _reimbursementAmountCtrl;
  late final TextEditingController _amountUsdCtrl;

  @override
  void initState() {
    super.initState();
    final l = widget.line;
    _date = l.expenseDate;
    _status = l.status.isEmpty ? '' : l.status;
    _category = l.category;
    _expenseMode = l.expenseMode;
    _particularsCtrl = TextEditingController(text: l.particulars);
    _invoiceCurrency = l.invoiceCurrency;
    _invoiceAmountCtrl = TextEditingController(text: _fmtNum(l.invoiceAmount));
    _invoiceAvailable = l.invoiceAvailable;
    _reimbursementRequired = l.reimbursementRequired;
    _billedCurrency = l.billedCurrency;
    _billedAmountCtrl = TextEditingController(text: _fmtNum(l.billedAmount));
    _invoiceLinkCtrl = TextEditingController(text: l.invoiceLink);
    _reimbursementAmountCtrl =
        TextEditingController(text: _fmtNum(l.reimbursementCurrencyAmount));
    _amountUsdCtrl = TextEditingController(text: _fmtNum(l.amountUsd));
    if (!CopiousSheetValidOptions.expenseModes.contains(_expenseMode)) {
      _expenseMode = CopiousSheetValidOptions.expenseModes.first;
    }
    if (!SheetStaticOptions.importCategories.contains(_category)) {
      _category = SheetStaticOptions.importCategories.first;
    }
    if (!SheetStaticOptions.importCurrencies.contains(_invoiceCurrency)) {
      _invoiceCurrency = SheetStaticOptions.importCurrencies.first;
    }
    if (!SheetStaticOptions.importCurrencies.contains(_billedCurrency)) {
      _billedCurrency = SheetStaticOptions.importCurrencies.first;
    }
  }

  String _fmtNum(double v) =>
      (v == v.roundToDouble()) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    _particularsCtrl.dispose();
    _invoiceAmountCtrl.dispose();
    _billedAmountCtrl.dispose();
    _invoiceLinkCtrl.dispose();
    _reimbursementAmountCtrl.dispose();
    _amountUsdCtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) => double.tryParse(s.trim().replaceAll(',', ''));

  void _save() {
    final inv = _parseDouble(_invoiceAmountCtrl.text);
    final billed = _parseDouble(_billedAmountCtrl.text);
    final reimb = _parseDouble(_reimbursementAmountCtrl.text);
    final usd = _parseDouble(_amountUsdCtrl.text);
    if (inv == null || billed == null || reimb == null || usd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid numbers for all amounts.')),
      );
      return;
    }
    final updated = widget.line.copyWith(
      expenseDate: _date,
      status: _status,
      category: _category,
      expenseMode: _expenseMode,
      particulars: _particularsCtrl.text.trim(),
      invoiceCurrency: _invoiceCurrency,
      invoiceAmount: inv,
      invoiceAvailable: _invoiceAvailable,
      reimbursementRequired: _reimbursementRequired,
      billedCurrency: _billedCurrency,
      billedAmount: billed,
      invoiceLink: _invoiceLinkCtrl.text.trim(),
      reimbursementCurrencyAmount: reimb,
      amountUsd: usd,
    );
    Navigator.of(context).pop(updated);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Widget _outlineDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Expense date'),
            subtitle: Text(df.format(_date), style: theme.textTheme.titleMedium),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          _outlineDropdown<String>(
            label: 'Status',
            value: _status.isEmpty ? '' : _status,
            items: [
              const DropdownMenuItem(value: '', child: Text('—')),
              ...CopiousSheetValidOptions.lineStatusOptions.map(
                (e) => DropdownMenuItem(value: e, child: Text(e)),
              ),
            ],
            onChanged: (v) => setState(() => _status = v ?? ''),
          ),
          const SizedBox(height: 16),
          _outlineDropdown<String>(
            label: 'Category',
            value: SheetStaticOptions.importCategories.contains(_category)
                ? _category
                : SheetStaticOptions.importCategories.first,
            items: SheetStaticOptions.importCategories
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 16),
          _outlineDropdown<String>(
            label: 'Expense mode',
            value: CopiousSheetValidOptions.expenseModes.contains(_expenseMode)
                ? _expenseMode
                : CopiousSheetValidOptions.expenseModes.first,
            items: CopiousSheetValidOptions.expenseModes
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _expenseMode = v);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _particularsCtrl,
            decoration: const InputDecoration(
              labelText: 'Particulars',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),
          Text('Invoice', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _outlineDropdown<String>(
                  label: 'Currency',
                  value: SheetStaticOptions.importCurrencies.contains(
                          _invoiceCurrency)
                      ? _invoiceCurrency
                      : SheetStaticOptions.importCurrencies.first,
                  items: SheetStaticOptions.importCurrencies
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _invoiceCurrency = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _invoiceAmountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InvoiceSwitchTile(
            value: _invoiceAvailable,
            onChanged: (v) => setState(() => _invoiceAvailable = v),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _reimbursementRequired,
            onChanged: (v) => setState(() => _reimbursementRequired = v ?? false),
            title: const Text('Reimbursement required'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 24),
          Text('Billed', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _outlineDropdown<String>(
                  label: 'Currency',
                  value: SheetStaticOptions.importCurrencies.contains(
                          _billedCurrency)
                      ? _billedCurrency
                      : SheetStaticOptions.importCurrencies.first,
                  items: SheetStaticOptions.importCurrencies
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _billedCurrency = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _billedAmountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _invoiceLinkCtrl,
            decoration: const InputDecoration(
              labelText: 'Invoice link',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 24),
          Text('Amounts (sheet)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _reimbursementAmountCtrl,
            decoration: const InputDecoration(
              labelText: 'Reimbursement (currency)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountUsdCtrl,
            decoration: const InputDecoration(
              labelText: 'Amount USD',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _save,
            child: const Text('Save changes'),
          ),
        ),
      ),
    );
  }
}

class _InvoiceSwitchTile extends StatelessWidget {
  const _InvoiceSwitchTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                value ? Icons.receipt_long : Icons.receipt_outlined,
                color: scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice on file',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      value ? 'Yes — you have the invoice' : 'No invoice yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
