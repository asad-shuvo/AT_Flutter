import 'package:file_picker/file_picker.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';

enum DocumentAddMode { externalLink, upload }

final _urlRegex = RegExp(
  r'^(http://www\.|https://www\.|http://|https://)?[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*\.[a-zA-Z]{2,5}(:[0-9]{1,5})?(\/.*)?$',
);

class _PickedFile {
  const _PickedFile({required this.path, required this.name});
  final String path;
  final String name;
}

class ContractDocumentAddSheet extends StatefulWidget {
  const ContractDocumentAddSheet({
    super.key,
    required this.onSubmit,
  });

  final Future<void> Function({
    required String resourceTitle,
    required String? urlAddress,
    required String? uploadedFilePath,
  }) onSubmit;

  @override
  State<ContractDocumentAddSheet> createState() =>
      _ContractDocumentAddSheetState();
}

class _ContractDocumentAddSheetState extends State<ContractDocumentAddSheet> {
  DocumentAddMode _mode = DocumentAddMode.externalLink;
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  _PickedFile? _pickedFile;
  bool _isPickingFile = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _urlController = TextEditingController();
    _titleController.addListener(_onFormChanged);
    _urlController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_onFormChanged)
      ..dispose();
    _urlController
      ..removeListener(_onFormChanged)
      ..dispose();
    super.dispose();
  }

  bool get _hasFile => _pickedFile != null;

  bool get _isFormValid {
    final title = _titleController.text.trim();
    if (title.length < 4) return false;
    if (_mode == DocumentAddMode.externalLink) {
      final url = _urlController.text.trim();
      return url.isNotEmpty && _urlRegex.hasMatch(url);
    }
    return _hasFile;
  }

  Future<void> _pickFile() async {
    if (_isPickingFile || _isSubmitting) return;
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (!mounted) return;
      if (result != null && result.files.isNotEmpty) {
        final f = result.files.first;
        if (f.path != null) {
          setState(() {
            _pickedFile = _PickedFile(path: f.path!, name: f.name);
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tr('tns.UPLOAD_FAILED'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _removeFile() => setState(() => _pickedFile = null);

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Resource Title is required');
      return;
    }
    if (title.length < 4) {
      _showError('Resource Title must be at least 4 characters');
      return;
    }

    if (_mode == DocumentAddMode.externalLink) {
      final url = _urlController.text.trim();
      if (url.isEmpty) {
        _showError('URL Address is required');
        return;
      }
      if (!_urlRegex.hasMatch(url)) {
        _showError('Please enter a valid URL');
        return;
      }
      await _submit(resourceTitle: title, urlAddress: url, filePath: null);
    } else {
      if (!_hasFile) {
        _showError('Please select a document to upload');
        return;
      }
      await _submit(
        resourceTitle: title,
        urlAddress: null,
        filePath: _pickedFile!.path,
      );
    }
  }

  Future<void> _submit({
    required String resourceTitle,
    required String? urlAddress,
    required String? filePath,
  }) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        resourceTitle: resourceTitle,
        urlAddress: urlAddress,
        uploadedFilePath: filePath,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showError('Failed to save document: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildToggleButtons(),
                      const SizedBox(height: 24),
                      _buildResourceTitleField(),
                      const SizedBox(height: 20),
                      if (_mode == DocumentAddMode.externalLink)
                        _buildUrlField()
                      else
                        _buildUploadArea(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          const Icon(
            IconData(0xE9DF, fontFamily: 'filip_at_iconpack_29022024'),
            size: 22,
            color: Color(0xFF333333),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.tr('tns.relatedDocument'),
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ),
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Color(0xFF666666), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _buildModeButton(
            DocumentAddMode.externalLink,
            l10n.tr('EXTERNAL_LINK'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModeButton(
            DocumentAddMode.upload,
            l10n.tr('DOCUMENT_UPLOAD'),
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(DocumentAddMode mode, String label) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: _isSubmitting ? null : () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.primaryRed : const Color(0xFFCCCCCC),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
          color: selected
              ? AppColors.primaryRed.withValues(alpha: 0.03)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primaryRed : const Color(0xFFCCCCCC),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primaryRed : const Color(0xFF555555),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.tr('SOURCE_TITLE'),
          style: TextStyle(
            fontFamily: 'Calibri',
            fontSize: 14,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          enabled: !_isSubmitting,
          maxLength: 200,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: context.l10n.tr('SOURCE_TITLE'),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
              borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
              borderSide: const BorderSide(
                color: AppColors.primaryRed,
                width: 1.2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            hintStyle: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 15,
              color: Color(0xFFBBBBBB),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 15,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.tr('URL_ADDRESS'),
          style: TextStyle(
            fontFamily: 'Calibri',
            fontSize: 14,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _urlController,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.url,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: context.l10n.tr('URL_ADDRESS'),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
              borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
              borderSide: const BorderSide(
                color: AppColors.primaryRed,
                width: 1.2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            hintStyle: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 15,
              color: Color(0xFFBBBBBB),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 15,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clickable upload box
        GestureDetector(
          onTap: (_isSubmitting || _isPickingFile || _hasFile) ? null : _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCCCCCC)),
              borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
              color: const Color(0xFFF7F7F7),
            ),
            child: Center(
              child: _isPickingFile
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                      ),
                    )
                  : Text(
                      _hasFile ? 'Max Number of Files Reached' : 'Tap here to upload document',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 15,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
            ),
          ),
        ),
        // Selected file row
        if (_hasFile) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFEEEEEE)),
              borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(
                  IconData(0xEA31, fontFamily: 'filip_at_iconpack_29022024'),
                  size: 18,
                  color: Color(0xFF888888),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _pickedFile!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _isSubmitting ? null : _removeFile,
                  child: const Icon(
                    IconData(0xE9F9, fontFamily: 'filip_at_iconpack_29022024'),
                    size: 20,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_isSubmitting || !_isFormValid) ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.55),
            elevation: 0,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  context.l10n.tr('tns.confirm'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontFamily: 'Calibri',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
        ),
      ),
    );
  }
}

Future<bool?> showContractDocumentAddSheet(
  BuildContext context, {
  required Future<void> Function({
    required String resourceTitle,
    required String? urlAddress,
    required String? uploadedFilePath,
  }) onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
    ),
    builder: (_) => ContractDocumentAddSheet(onSubmit: onSubmit),
  );
}

