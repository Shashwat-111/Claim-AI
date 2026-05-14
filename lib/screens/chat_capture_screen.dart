import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/expense_attachment.dart';
import '../services/gemini_expense_service.dart';
import 'home_screen.dart';
import 'review_captured_screen.dart';

class _PickedFile {
  _PickedFile({
    required this.path,
    required this.displayLabel,
    required this.isImage,
  });

  final String path;
  final String displayLabel;
  final bool isImage;
}

class ChatCaptureScreen extends StatefulWidget {
  const ChatCaptureScreen({super.key});

  @override
  State<ChatCaptureScreen> createState() => _ChatCaptureScreenState();
}

class _ChatCaptureScreenState extends State<ChatCaptureScreen> {
  final _messageCtrl = TextEditingController();
  final _gemini = GeminiExpenseService();
  final List<_PickedFile> _files = [];
  int _pdfSeq = 0;
  int _imgSeq = 0;

  bool get _showWelcome =>
      _messageCtrl.text.trim().isEmpty && _files.isEmpty;

  @override
  void initState() {
    super.initState();
    _messageCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  String _nextLabelForPath(String path) {
    final ext = p.extension(path).toLowerCase();
    final isPdf = ext == '.pdf';
    if (isPdf) {
      _pdfSeq += 1;
      return 'PDF $_pdfSeq';
    }
    _imgSeq += 1;
    return 'Image $_imgSeq';
  }

  bool _pathIsImage(String path) {
    const img = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.heic'};
    return img.contains(p.extension(path).toLowerCase());
  }

  Future<void> _openAttachSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photos'),
              onTap: () async {
                Navigator.pop(ctx);
                final r = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  allowMultiple: true,
                  withData: false,
                );
                if (!mounted || r == null) return;
                _addPicks(r);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Files'),
              subtitle: const Text('PDF, images'),
              onTap: () async {
                Navigator.pop(ctx);
                final r = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: [
                    'pdf',
                    'png',
                    'jpg',
                    'jpeg',
                    'webp',
                    'gif',
                    'heic',
                  ],
                  allowMultiple: true,
                  withData: false,
                );
                if (!mounted || r == null) return;
                _addPicks(r);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addPicks(FilePickerResult r) {
    for (final f in r.files) {
      final path = f.path;
      if (path == null || path.isEmpty) continue;
      final isImage = _pathIsImage(path);
      setState(() {
        _files.add(
          _PickedFile(
            path: path,
            displayLabel: _nextLabelForPath(path),
            isImage: isImage,
          ),
        );
      });
    }
  }

  void _removeAt(int i) {
    setState(() => _files.removeAt(i));
    _relabelFiles();
  }

  void _relabelFiles() {
    var pCount = 0;
    var iCount = 0;
    final next = <_PickedFile>[];
    for (final f in _files) {
      final isPdf = p.extension(f.path).toLowerCase() == '.pdf';
      if (isPdf) {
        pCount += 1;
        next.add(
          _PickedFile(
            path: f.path,
            displayLabel: 'pdf$pCount',
            isImage: false,
          ),
        );
      } else {
        iCount += 1;
        next.add(
          _PickedFile(
            path: f.path,
            displayLabel: 'img$iCount',
            isImage: f.isImage,
          ),
        );
      }
    }
    setState(() {
      _files
        ..clear()
        ..addAll(next);
      _pdfSeq = pCount;
      _imgSeq = iCount;
    });
  }

  Future<void> _send() async {
    if (_files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one receipt (attach).')),
      );
      return;
    }

    if (!mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: _ExtractionLoadingDialog(),
        ),
      ),
    );

    try {
      final attachments = <ExpenseAttachment>[];
      for (final f in _files) {
        final bytes = await readAttachmentBytes(f.path);
        attachments.add(
          ExpenseAttachment(
            displayName: f.displayLabel,
            mimeType: mimeTypeForExpenseFile(f.path),
            bytes: bytes,
          ),
        );
      }
      final lines = await _gemini.extractLines(
        userText: _messageCtrl.text,
        attachments: attachments,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      final added = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ReviewCapturedScreen(lines: lines),
        ),
      );
      if (mounted && added == true) {
        setState(() {
          _files.clear();
          _pdfSeq = 0;
          _imgSeq = 0;
          _messageCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Copious ReimburseAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Manual entry',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (_showWelcome)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Just send me your files — I will fill the claim sheet for you.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                                color: scheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  )
                else if (_files.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Attached',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverToBoxAdapter(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (var i = 0; i < _files.length; i++)
                            _AttachmentCard(
                              file: _files[i],
                              onRemove: () => _removeAt(i),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ] else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Attach receipts to continue.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            elevation: 6,
            shadowColor: Colors.black26,
            color: scheme.surface,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + bottomInset),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded),
                    tooltip: 'Attach',
                    onPressed: _openAttachSheet,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (_files.isNotEmpty) _send();
                      },
                      decoration: InputDecoration(
                        hintText: 'Optional note…',
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.65,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: scheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      shape: const CircleBorder(),
                    ),
                    onPressed: _files.isEmpty ? null : _send,
                    child: const Icon(Icons.send_rounded, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.file, required this.onRemove});

  final _PickedFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const thumbSize = 72.0;

    return Material(
      elevation: 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      color: scheme.surfaceContainerLow,
      child: SizedBox(
        width: thumbSize + 88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      height: thumbSize,
                      width: double.infinity,
                      child: file.isImage
                          ? Image.file(
                              File(file.path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _FilePlaceholder(isImage: true),
                            )
                          : const _FilePlaceholder(isImage: false),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: scheme.surface.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(Icons.close_rounded),
                        onPressed: onRemove,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Text(
                  file.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _FilePlaceholder extends StatelessWidget {
  const _FilePlaceholder({required this.isImage});

  final bool isImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          isImage ? Icons.image_outlined : Icons.picture_as_pdf_rounded,
          size: 36,
          color: isImage ? scheme.primary : Colors.red.shade400,
        ),
      ),
    );
  }
}

class _ExtractionLoadingDialog extends StatefulWidget {
  @override
  State<_ExtractionLoadingDialog> createState() =>
      _ExtractionLoadingDialogState();
}

class _ExtractionLoadingDialogState extends State<_ExtractionLoadingDialog> {
  static const _messages = [
    'Uploading your receipts…',
    'Reading amounts and dates…',
    'Matching categories to your claim…',
    'Almost there — polishing the rows…',
  ];
  var _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      content: SizedBox(
        width: 300,
        height: 164,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Working on your expenses',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 72,
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Text(
                  _messages[_index],
                  key: ValueKey<int>(_index),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
