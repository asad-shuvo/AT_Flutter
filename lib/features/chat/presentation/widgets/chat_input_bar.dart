import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendFile,
    this.enabled = true,
  });

  final Future<void> Function(String text) onSendText;
  final Future<void> Function({
    required String fileId,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) onSendFile;
  final bool enabled;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  String? _pendingFileName;
  List<int>? _pendingBytes;
  String? _pendingContentType;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (!widget.enabled || _isSending || _pendingFileName != null) return;
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    const maxBytes = 10 * 1024 * 1024;
    if (file.bytes!.length > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum file size is 10 MB')),
        );
      }
      return;
    }
    setState(() {
      _pendingFileName = file.name;
      _pendingBytes = file.bytes!;
      _pendingContentType = _mimeFromExtension(file.extension ?? '');
    });
  }

  void _clearPending() {
    setState(() {
      _pendingFileName = null;
      _pendingBytes = null;
      _pendingContentType = null;
    });
  }

  Future<void> _send() async {
    if (!widget.enabled || _isSending) return;
    final text = _controller.text.trim();
    final hasPending = _pendingBytes != null && _pendingFileName != null;
    if (text.isEmpty && !hasPending) return;

    setState(() => _isSending = true);
    try {
      if (hasPending) {
        await widget.onSendFile(
          fileId: _uuid(),
          fileName: _pendingFileName!,
          bytes: _pendingBytes!,
          contentType: _pendingContentType ?? 'application/octet-stream',
        );
        _clearPending();
      } else {
        await widget.onSendText(text);
        _controller.clear();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || _isSending;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // divider line
        Container(height: 1, color: Colors.grey.shade300),
        // file preview bar
        if (_pendingFileName != null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 18, color: Color(0xFFD82034)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _pendingFileName!,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      color: Color(0xFFD82034),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _clearPending,
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
        // input row — matches NS: bg #E4E4E4, padding 10 15
        Container(
          color: const Color(0xFFE4E4E4),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button — white, radius 8, 50×54
              GestureDetector(
                onTap: (disabled || _pendingFileName != null) ? null : _pickFile,
                child: Opacity(
                  opacity: (disabled || _pendingFileName != null) ? 0.4 : 1.0,
                  child: Container(
                    width: 50,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.attach_file,
                      size: 22,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Text field — white, radius 8
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 54, maxHeight: 108),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: _controller,
                    enabled: !disabled,
                    maxLines: null,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF333333),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Write a message',
                      hintStyle: TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFFB0B0B0),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Send button — red #D82034, radius 8, 50×54, white icon
              GestureDetector(
                onTap: disabled ? null : _send,
                child: Opacity(
                  opacity: disabled ? 0.4 : 1.0,
                  child: Container(
                    width: 50,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD82034),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, size: 22, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _mimeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  static String _uuid() {
    final rng = Random.secure();
    final b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
