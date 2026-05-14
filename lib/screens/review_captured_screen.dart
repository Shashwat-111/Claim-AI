import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/reimbursement_expense_line.dart';
import '../provider/sheet_provider.dart';
import 'edit_expense_line_screen.dart';

class ReviewCapturedScreen extends StatefulWidget {
  const ReviewCapturedScreen({super.key, required this.lines});

  final List<ReimbursementExpenseLine> lines;

  @override
  State<ReviewCapturedScreen> createState() => _ReviewCapturedScreenState();
}

class _ReviewCapturedScreenState extends State<ReviewCapturedScreen> {
  late List<ReimbursementExpenseLine> _lines;

  @override
  void initState() {
    super.initState();
    _lines = List<ReimbursementExpenseLine>.from(widget.lines);
  }

  Future<void> _openEdit(int index) async {
    final updated = await Navigator.of(context).push<ReimbursementExpenseLine>(
      MaterialPageRoute<ReimbursementExpenseLine>(
        builder: (_) => EditExpenseLineScreen(line: _lines[index]),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _lines[index] = updated);
    }
  }

  Future<void> _onAddExpense() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _PushToSheetDialog(
        lines: _lines,
        scaffoldMessenger: messenger,
      ),
    );
    if (!mounted) return;
    if (ok == true) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Review your expense'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _lines.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                return _ExpenseReviewCard(
                  line: _lines[i],
                  onEdit: () => _openEdit(i),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Consumer<SheetProvider>(
                builder: (context, provider, _) {
                  return FilledButton.icon(
                    icon: const Icon(Icons.upload_file_rounded, size: 22),
                    label: const Text('Add expense'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: provider.busy ? null : _onAddExpense,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseReviewCard extends StatelessWidget {
  const _ExpenseReviewCard({required this.line, required this.onEdit});

  final ReimbursementExpenseLine line;
  final VoidCallback onEdit;

  static String _fmtMoney(double v) =>
      (v == v.roundToDouble()) ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final df = DateFormat.MMMd();
    final subtle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Material(
      elevation: 0,
      color: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    line.particulars,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TagChip(icon: Icons.event_rounded, label: df.format(line.expenseDate)),
                _TagChip(icon: Icons.category_outlined, label: line.category),
                _TagChip(icon: Icons.payment_rounded, label: line.expenseMode),
                if (line.status.isNotEmpty)
                  _TagChip(icon: Icons.flag_outlined, label: line.status),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _AmountBlock(
                    title: 'Invoice',
                    currency: line.invoiceCurrency,
                    amount: _fmtMoney(line.invoiceAmount),
                    alignEnd: false,
                  ),
                ),
                Container(
                  width: 1,
                  height: 56,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: _AmountBlock(
                    title: 'Billed',
                    currency: line.billedCurrency,
                    amount: _fmtMoney(line.billedAmount),
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatusPill(
                  label: line.invoiceAvailable ? 'Invoice' : 'No invoice',
                  active: line.invoiceAvailable,
                  icon: Icons.receipt_long_rounded,
                ),
                const SizedBox(width: 10),
                _StatusPill(
                  label: line.reimbursementRequired ? 'Reimburse' : 'No reimb.',
                  active: line.reimbursementRequired,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
            if (line.invoiceLink.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Link', style: subtle?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                line.invoiceLink,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: scheme.primary.withValues(alpha: 0.4),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({
    required this.title,
    required this.currency,
    required this.amount,
    required this.alignEnd,
  });

  final String title;
  final String currency;
  final String amount;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: alignEnd ? 12 : 0, right: alignEnd ? 0 : 12),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currency,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.active,
    required this.icon,
  });

  final String label;
  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = active
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final fg = active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: active ? 0.35 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
          ),
        ],
      ),
    );
  }
}

class _PushToSheetDialog extends StatefulWidget {
  const _PushToSheetDialog({
    required this.lines,
    required this.scaffoldMessenger,
  });

  final List<ReimbursementExpenseLine> lines;
  final ScaffoldMessengerState scaffoldMessenger;

  @override
  State<_PushToSheetDialog> createState() => _PushToSheetDialogState();
}

class _PushToSheetDialogState extends State<_PushToSheetDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _doneCtrl;
  late final Animation<double> _doneScale;
  int _done = 0;
  int _total = 0;
  bool _finished = false;
  bool _success = false;
  String _message = 'Adding your expenses to the claim sheet…';

  @override
  void initState() {
    super.initState();
    _total = widget.lines.length;
    _doneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _doneScale = CurvedAnimation(
      parent: _doneCtrl,
      curve: Curves.elasticOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _doneCtrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final provider = context.read<SheetProvider>();
    await provider.ensureInitialized();
    if (!mounted) return;
    if (provider.initError != null) {
      widget.scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(provider.initError!)),
      );
      Navigator.of(context).pop(false);
      return;
    }

    await provider.insertAllLinesAboveTotal(
      widget.lines,
      onProgress: (completed, tot) {
        if (!mounted) return;
        setState(() {
          _done = completed;
          _total = tot;
          _message = 'Writing row $completed of $tot to your sheet…';
        });
      },
    );
    if (!mounted) return;

    final err = provider.lastError;
    if (err != null) {
      widget.scaffoldMessenger.showSnackBar(SnackBar(content: Text(err)));
      Navigator.of(context).pop(false);
      return;
    }

    if (provider.lastMessage != null) {
      setState(() {
        _finished = true;
        _success = true;
        _message = 'All set — your claim sheet is updated.';
      });
      await _doneCtrl.forward();
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = _total > 0 ? _done / _total : 0.0;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        content: SizedBox(
          width: 300,
          height: 228,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _success && _finished
                ? SizedBox(
                    key: const ValueKey('done'),
                    width: 300,
                    height: 228,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: ScaleTransition(
                            scale: _doneScale,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 44,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Done',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: Text(
                            _message,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('progress'),
                    width: 300,
                    height: 228,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Syncing to Google Sheets',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 72,
                          width: double.infinity,
                          child: Text(
                            _message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _total > 0 ? '$_done of $_total uploaded' : ' ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.primary,
                                  ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _total > 0 ? progress.clamp(0.0, 1.0) : null,
                            minHeight: 6,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
