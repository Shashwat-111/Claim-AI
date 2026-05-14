import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/sheet_static_options.dart';
import '../models/copious_sheet_valid_options.dart';
import '../models/reimbursement_expense_line.dart';
import '../models/reimbursement_sheet_layout.dart';
import '../provider/sheet_provider.dart';

/// Manual expense entry (opened from chat screen settings).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _particularsCtrl = TextEditingController(text: 'Example expense');
  final _invoiceLinkCtrl = TextEditingController();

  final _invoiceAmountCtrl = TextEditingController(text: '10');
  final _billedAmountCtrl = TextEditingController(text: '800');

  DateTime _expenseDate = DateTime.now();

  String _expenseMode = CopiousSheetValidOptions.expenseModes.first;
  String _invoiceAvailableLabel = CopiousSheetValidOptions.invoiceAvailableLabels.first;

  String _category = SheetStaticOptions.importCategories.first;
  String _invoiceCurrency = SheetStaticOptions.importCurrencies.first;
  String _billedCurrency = SheetStaticOptions.importCurrencies.first;
  String _statusSelection = '';

  bool _reimbursementRequired = true;

  @override
  void dispose() {
    _particularsCtrl.dispose();
    _invoiceLinkCtrl.dispose();
    _invoiceAmountCtrl.dispose();
    _billedAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  ReimbursementExpenseLine _lineFromForm() {
    double parseMoney(String s) => double.tryParse(s.trim()) ?? 0;
    return ReimbursementExpenseLine(
      expenseDate: _expenseDate,
      status: _statusSelection,
      category: _category,
      expenseMode: _expenseMode,
      particulars: _particularsCtrl.text.trim(),
      invoiceCurrency: _invoiceCurrency,
      invoiceAmount: parseMoney(_invoiceAmountCtrl.text),
      invoiceAvailable: _invoiceAvailableLabel == 'Yes',
      reimbursementRequired: _reimbursementRequired,
      billedCurrency: _billedCurrency,
      billedAmount: parseMoney(_billedAmountCtrl.text),
      invoiceLink: _invoiceLinkCtrl.text.trim(),
      reimbursementCurrencyAmount: 0,
      amountUsd: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SheetProvider>();
    final df = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (provider.initError != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(provider.initError!),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Line-item columns (from your template):',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            ReimbursementSheetLayout.lineItemHeaderLabels.join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Expense date: ${df.format(_expenseDate)}'),
                  trailing: TextButton(onPressed: _pickDate, child: const Text('Change')),
                ),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Category (Import Range)',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _category,
                      items: [
                        for (final c in SheetStaticOptions.importCategories)
                          DropdownMenuItem(value: c, child: Text(c)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expense mode (validated)',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _expenseMode,
                      items: [
                        for (final m in CopiousSheetValidOptions.expenseModes)
                          DropdownMenuItem(value: m, child: Text(m)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _expenseMode = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'STATUS (optional, validated)',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _statusSelection,
                      items: [
                        const DropdownMenuItem(value: '', child: Text('(blank)')),
                        for (final s in CopiousSheetValidOptions.lineStatusOptions)
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (v) => setState(() => _statusSelection = v ?? ''),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _particularsCtrl,
                  decoration: const InputDecoration(labelText: 'Particulars', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Invoice currency',
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _invoiceCurrency,
                            items: [
                              for (final c in SheetStaticOptions.importCurrencies)
                                DropdownMenuItem(value: c, child: Text(c)),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _invoiceCurrency = v);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _invoiceAmountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Invoice amount',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Invoice available? (validated)',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _invoiceAvailableLabel,
                      items: [
                        for (final y in CopiousSheetValidOptions.invoiceAvailableLabels)
                          DropdownMenuItem(value: y, child: Text(y)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _invoiceAvailableLabel = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Reimbursement required? (writes TRUE / FALSE in column I)'),
                  value: _reimbursementRequired,
                  onChanged: (v) => setState(() => _reimbursementRequired = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Billed currency',
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _billedCurrency,
                            items: [
                              for (final c in SheetStaticOptions.importCurrencies)
                                DropdownMenuItem(value: c, child: Text(c)),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _billedCurrency = v);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _billedAmountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Billed amount',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _invoiceLinkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Invoice link (G-Drive)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Columns M onward use your sheet formulas after the row is copied.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: provider.busy
                      ? null
                      : () async {
                          await provider.insertLineAboveTotal(_lineFromForm());
                        },
                  child: Text(provider.busy ? 'Writing…' : 'Add expense (above TOTAL)'),
                ),
                if (provider.lastMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(provider.lastMessage!, style: const TextStyle(color: Colors.green)),
                ],
                if (provider.lastError != null) ...[
                  const SizedBox(height: 12),
                  Text(provider.lastError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
