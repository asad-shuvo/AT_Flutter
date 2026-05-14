import 'dart:typed_data';

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/drive/application/drive_controller.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DriveCapturePreviewPage extends StatefulWidget {
  const DriveCapturePreviewPage({
    super.key,
    required this.imageBytes,
    required this.controller,
  });

  final Uint8List imageBytes;
  final DriveController controller;

  @override
  State<DriveCapturePreviewPage> createState() =>
      _DriveCapturePreviewPageState();
}

class _DriveCapturePreviewPageState extends State<DriveCapturePreviewPage> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _markAsFavorite = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final ok = await widget.controller.captureAndUploadPhoto(
      title: _titleController.text.trim(),
      bytes: widget.imageBytes.toList(),
      markAsFavorite: _markAsFavorite,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tr('tns.UPLOAD_FAILED')),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _AppBar(l10n: l10n),
          AnimatedOpacity(
            opacity: _isSaving ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: const _SavingIndicator(),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ImagePreview(imageBytes: widget.imageBytes),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TitleField(controller: _titleController, l10n: l10n),
                          const SizedBox(height: 12),
                          _FavoriteCheckbox(
                            value: _markAsFavorite,
                            l10n: l10n,
                            onChanged: (v) =>
                                setState(() => _markAsFavorite = v ?? false),
                          ),
                          const SizedBox(height: 24),
                          _SaveButton(
                            isSaving: _isSaving,
                            l10n: l10n,
                            onPressed: _save,
                          ),
                        ],
                      ),
                    ),
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

class _AppBar extends StatelessWidget {
  const _AppBar({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Text(
              l10n.tr('tns.capturePhoto'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageBytes});
  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Image.memory(
        imageBytes,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _SavingIndicator extends StatelessWidget {
  const _SavingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        color: AppColors.primaryRed,
        backgroundColor: Color(0xFFF6D7DD),
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller, required this.l10n});
  final TextEditingController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: 20,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontFamily: 'Calibri', fontSize: 15),
      decoration: InputDecoration(
        labelText: l10n.tr('tns.title'),
        labelStyle: const TextStyle(fontFamily: 'Calibri', fontSize: 14),
        counterText: '',
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryRed),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (v) {
        final trimmed = v?.trim() ?? '';
        if (trimmed.isEmpty) {
          return l10n.tr('tns.fieldRequired');
        }
        if (trimmed.length > 20) {
          return l10n.tr(
            'tns.maximumCharacters',
            {'count': '20'},
          );
        }
        return null;
      },
    );
  }
}

class _FavoriteCheckbox extends StatelessWidget {
  const _FavoriteCheckbox({
    required this.value,
    required this.l10n,
    required this.onChanged,
  });
  final bool value;
  final AppLocalizations l10n;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryRed,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.tr('tns.Favorite'),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.l10n,
    required this.onPressed,
  });
  final bool isSaving;
  final AppLocalizations l10n;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Text(
          l10n.tr('tns.save'),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}


