import 'dart:async';

import 'package:flutter/material.dart';

Future<void> showDossierProgressSheet({required BuildContext context}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: scheme.surface,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => const _DossierProgressSheet(),
  );
}

class _DossierProgressSheet extends StatefulWidget {
  const _DossierProgressSheet();

  @override
  State<_DossierProgressSheet> createState() => _DossierProgressSheetState();
}

class _DossierProgressSheetState extends State<_DossierProgressSheet> {
  double _progress = 0.09;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() {
        _progress += 0.10;
        if (_progress >= 1.0) _progress = 0.09;
      });
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Your dossier is being prepared. You will receive a notification when it is ready to download.',
                  style: TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 13,
                    color: scheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.close, color: scheme.primary, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: scheme.errorContainer,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
