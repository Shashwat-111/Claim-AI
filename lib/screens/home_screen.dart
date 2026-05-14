import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/copious_sheet_valid_options.dart';
import '../models/reimbursement_expense_line.dart';
import '../models/reimbursement_sheet_layout.dart';
import '../provider/sheet_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _particularsCtrl = TextEditingController(text: 'Example expense');
  final _invoiceLinkCtrl = TextEditingController();

  final _categoryManualCtrl = TextEditingController(text: 'Software Subscription');
  final _invoiceCurrencyManualCtrl = TextEditingController(text: 'USD');
  final _billedCurrencyManualCtrl = TextEditingController(text: 'INR');

  final _invoiceAmountCtrl = TextEditingController(text: '10');
  final _billedAmountCtrl = TextEditingController(text: '800');

  DateTime _expenseDate = DateTime.now();

  String _expenseMode = CopiousSheetValidOptions.expenseModes.first;
  String _invoiceAvailableLabel = CopiousSheetValidOptions.invoiceAvailableLabels.first;

  String _category = 'Software Subscription';
  String _invoiceCurrency = 'USD';
  String _billedCurrency = 'INR';

  bool _reimbursementRequired = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<SheetProvider>();
      await provider.loadImportListOptions();
      if (!mounted) return;
      setState(_syncSelectionsAfterImportLoad);
    });
  }

  void _syncSelectionsAfterImportLoad() {
    final p = context.read<SheetProvider>();
    if (p.importCategories.isNotEmpty) {
      if (!p.importCategories.contains(_category)) {
        _category = p.importCategories.first;
      }
    }
    if (p.importCurrencies.isNotEmpty) {
      if (!p.importCurrencies.contains(_invoiceCurrency)) {
        _invoiceCurrency = p.importCurrencies.first;
      }
      if (!p.importCurrencies.contains(_billedCurrency)) {
        _billedCurrency = p.importCurrencies.first;
      }
    }
    _categoryManualCtrl.text = _category;
    _invoiceCurrencyManualCtrl.text = _invoiceCurrency;
    _billedCurrencyManualCtrl.text = _billedCurrency;
  }

  @override
  void dispose() {
    _particularsCtrl.dispose();
    _invoiceLinkCtrl.dispose();
    _categoryManualCtrl.dispose();
    _invoiceCurrencyManualCtrl.dispose();
    _billedCurrencyManualCtrl.dispose();
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
    final p = context.read<SheetProvider>();
    final category = p.importCategories.isEmpty ? _categoryManualCtrl.text.trim() : _category;
    final invCur = p.importCurrencies.isEmpty
        ? _invoiceCurrencyManualCtrl.text.trim().toUpperCase()
        : _invoiceCurrency.trim().toUpperCase();
    final billedCur = p.importCurrencies.isEmpty
        ? _billedCurrencyManualCtrl.text.trim().toUpperCase()
        : _billedCurrency.trim().toUpperCase();
    return ReimbursementExpenseLine(
      expenseDate: _expenseDate,
      category: category,
      expenseMode: _expenseMode,
      particulars: _particularsCtrl.text.trim(),
      invoiceCurrency: invCur,
      invoiceAmount: parseMoney(_invoiceAmountCtrl.text),
      invoiceAvailable: _invoiceAvailableLabel == 'Yes',
      reimbursementRequired: _reimbursementRequired,
      billedCurrency: billedCur,
      billedAmount: parseMoney(_billedAmountCtrl.text),
      invoiceLink: _invoiceLinkCtrl.text.trim(),
      // Sheet formulas in columns M+ compute these after insert+copy.
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
        title: const Text('Copious ReimburseAI'),
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
                OutlinedButton.icon(
                  onPressed: provider.busy
                      ? null
                      : () async {
                          await provider.loadImportListOptions();
                          if (mounted) setState(_syncSelectionsAfterImportLoad);
                        },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reload category / currency lists'),
                ),
                if (provider.dropdownListsMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(provider.dropdownListsMessage!, style: const TextStyle(color: Colors.green)),
                  ),
                if (provider.dropdownListsError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      provider.dropdownListsError!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Expense date: ${df.format(_expenseDate)}'),
                  trailing: TextButton(onPressed: _pickDate, child: const Text('Change')),
                ),
                if (provider.importCategories.isEmpty)
                  TextFormField(
                    controller: _categoryManualCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category (type manually if lists not loaded)',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Category (from Import tab col A)',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: provider.importCategories.contains(_category)
                            ? _category
                            : provider.importCategories.first,
                        items: [
                          for (final c in provider.importCategories)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _category = v);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _expenseMode,
                  decoration: const InputDecoration(
                    labelText: 'Expense mode (validated)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final m in CopiousSheetValidOptions.expenseModes)
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  onChanged: (v) => setState(() => _expenseMode = v ?? _expenseMode),
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
                      child: provider.importCurrencies.isEmpty
                          ? TextFormField(
                              controller: _invoiceCurrencyManualCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Invoice currency',
                                border: OutlineInputBorder(),
                              ),
                            )
                          : InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Invoice currency',
                                border: OutlineInputBorder(),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: provider.importCurrencies.contains(_invoiceCurrency)
                                      ? _invoiceCurrency
                                      : provider.importCurrencies.first,
                                  items: [
                                    for (final c in provider.importCurrencies)
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
                DropdownButtonFormField<String>(
                  initialValue: _invoiceAvailableLabel,
                  decoration: const InputDecoration(
                    labelText: 'Invoice available? (validated)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final y in CopiousSheetValidOptions.invoiceAvailableLabels)
                      DropdownMenuItem(value: y, child: Text(y)),
                  ],
                  onChanged: (v) => setState(() => _invoiceAvailableLabel = v ?? _invoiceAvailableLabel),
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
                      child: provider.importCurrencies.isEmpty
                          ? TextFormField(
                              controller: _billedCurrencyManualCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Billed currency',
                                border: OutlineInputBorder(),
                              ),
                            )
                          : InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Billed currency',
                                border: OutlineInputBorder(),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: provider.importCurrencies.contains(_billedCurrency)
                                      ? _billedCurrency
                                      : provider.importCurrencies.first,
                                  items: [
                                    for (final c in provider.importCurrencies)
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
