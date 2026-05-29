import 'package:filip_at_flutter/features/chat/data/chat_models.dart';
import 'package:filip_at_flutter/features/chat/presentation/widgets/chat_date_separator.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMessageBubble extends StatefulWidget {
  const ChatMessageBubble({super.key, required this.item});

  final ChatMessageItem item;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _showTime = false;

  static const _incomingBg = Color(0xFFFFEBEF);
  static const _outgoingBg = Color(0xFFE5E5E5);
  static const _timeColor = Color(0xFFB4B4B4);

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item.isDateLabel) return ChatDateSeparator(date: item.sentOn);
    if (item.isIncoming) return _buildIncoming(item);
    if (item.isOutgoing) return _buildOutgoing(item);
    return const SizedBox.shrink();
  }

  // ─── Incoming ─────────────────────────────────────────────────────────────

  Widget _buildIncoming(ChatMessageItem item) {
    return GestureDetector(
      onTap: () => setState(() => _showTime = !_showTime),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 8, 60, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // tail triangle
                ClipPath(
                  clipper: _IncomingTriangleClipper(),
                  child: Container(width: 10, height: 10, color: _incomingBg),
                ),
                // bubble
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    decoration: const BoxDecoration(
                      color: _incomingBg,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    child: item.attachment != null
                        ? _buildAttachment(item.attachment!, incoming: true)
                        : Text(
                            item.messageBody ?? '',
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            if (_showTime)
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 3),
                child: _timeLabel(item.sentOn),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Outgoing ─────────────────────────────────────────────────────────────

  Widget _buildOutgoing(ChatMessageItem item) {
    return GestureDetector(
      onTap: () => setState(() => _showTime = !_showTime),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(60, 8, 15, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    decoration: const BoxDecoration(
                      color: _outgoingBg,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                    ),
                    child: item.attachment != null
                        ? _buildAttachment(item.attachment!, incoming: false)
                        : Text(
                            item.messageBody ?? '',
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                  ),
                ),
                // tail triangle
                ClipPath(
                  clipper: _OutgoingTriangleClipper(),
                  child: Container(width: 10, height: 10, color: _outgoingBg),
                ),
              ],
            ),
            if (_showTime)
              Padding(
                padding: const EdgeInsets.only(right: 14, top: 3),
                child: _timeLabel(item.sentOn),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Attachment ───────────────────────────────────────────────────────────

  Widget _buildAttachment(ChatAttachment att, {required bool incoming}) {
    if (att.isUploading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                incoming ? const Color(0xFFA11C36) : const Color(0xFF888888),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              att.fileName,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                fontWeight: FontWeight.w300,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _openFile(att),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // circle icon — matches NS download-icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: incoming
                  ? const Color(0xFFF7D4D8)
                  : const Color(0xFFD2D2D2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.attach_file,
              size: 18,
              color: incoming
                  ? const Color(0xFFA11C36)
                  : const Color(0xFF555555),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              att.fileName,
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                fontWeight: FontWeight.w300,
                decoration: TextDecoration.underline,
                color: incoming
                    ? const Color(0xFF333333)
                    : const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(ChatAttachment att) async {
    final uri = att.fileUri;
    if (uri == null || uri.isEmpty) return;
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return;
    if (await canLaunchUrl(parsed)) {
      await launchUrl(parsed, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Time label ───────────────────────────────────────────────────────────

  Widget _timeLabel(DateTime dt) {
    // Format: D.M.YYYY at HH:mm — no leading zeros on day/month (NS parity)
    final d = dt.day;
    final m = dt.month;
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return Text(
      '$d.$m.$y  at  $hh:$mm',
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 14,
        color: _timeColor,
      ),
    );
  }
}

// ─── Triangle clippers ────────────────────────────────────────────────────

class _IncomingTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(0, size.height)
    ..lineTo(size.width, size.height)
    ..close();

  @override
  bool shouldReclip(_IncomingTriangleClipper old) => false;
}

class _OutgoingTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(0, size.height)
    ..lineTo(size.width, size.height)
    ..close();

  @override
  bool shouldReclip(_OutgoingTriangleClipper old) => false;
}
