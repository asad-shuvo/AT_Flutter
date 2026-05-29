import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/chat/data/chat_models.dart';
import 'package:filip_at_flutter/features/chat/data/chat_repository.dart';
import 'package:flutter/foundation.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required ChatRepository chatRepository,
    required UserSessionCache userSessionCache,
  })  : _repo = chatRepository,
        _sessionCache = userSessionCache;

  final ChatRepository _repo;
  final UserSessionCache _sessionCache;

  ChatLoadState _state = ChatLoadState.loading;
  ChatAdvisor? _advisor;
  String? _threadId;

  // index 0 = newest (bottom), last = oldest (top) — matches reverse ListView
  final List<ChatMessageItem> _messages = [];

  bool _hasMoreMessages = true;
  int _skip = 0;
  static const int _take = 20;

  bool _isSending = false;
  bool _isLoadingMore = false;

  ChatLoadState get state => _state;
  ChatAdvisor? get advisor => _advisor;
  List<ChatMessageItem> get messages => List.unmodifiable(_messages);
  bool get hasMoreMessages => _hasMoreMessages;
  bool get isSending => _isSending;
  bool get isLoadingMore => _isLoadingMore;
  bool get canSend => _threadId != null && !_isSending && _isCurrentUser;

  // Whether the selected member is the logged-in user (input enabled only then).
  bool _isCurrentUser = true;
  bool get isCurrentUser => _isCurrentUser;

  // ─── Init ─────────────────────────────────────────────────────────────────

  /// [targetPersonId] and [targetManagerNr]: override to chat on behalf of a
  /// household member other than the logged-in user.
  /// [isCurrentUser]: false → read-only (NS: input hidden for other members).
  Future<void> initialize({
    String? targetPersonId,
    String? targetManagerNr,
    bool isCurrentUser = true,
  }) async {
    _isCurrentUser = isCurrentUser;
    _setState(ChatLoadState.loading);

    final session = await _sessionCache.resolve();
    if (session == null) {
      _setState(ChatLoadState.error);
      return;
    }

    final managerNr = targetManagerNr ?? session.managerNr;
    if (managerNr == null || managerNr.isEmpty) {
      _setState(ChatLoadState.noAdvisor);
      return;
    }

    final advisor = await _repo.fetchAdvisor(managerNr);
    if (advisor == null) {
      _setState(ChatLoadState.noAdvisor);
      return;
    }
    _advisor = advisor;

    final personId = targetPersonId ?? session.personId;
    String? threadId = await _repo.findThreadId(
      personId: personId,
      advisorPersonId: advisor.personId,
    );

    if (threadId == null) {
      if (!isCurrentUser) {
        // NS: non-current-user + no thread → NoDataFound, no thread creation.
        _setState(ChatLoadState.noThread);
        return;
      }
      threadId = await _repo.createThread(
        personId: personId,
        advisorPersonId: advisor.personId,
        advisorProposedUserId: advisor.proposedUserId,
      );
    }

    if (threadId == null) {
      _setState(ChatLoadState.noThread);
      return;
    }

    _threadId = threadId;
    _skip = 0;
    _messages.clear();

    final items = await _repo.fetchMessages(
      threadId: threadId,
      advisorPersonId: advisor.personId,
      skip: 0,
      take: _take,
    );

    if (items == null) {
      _setState(ChatLoadState.error);
      return;
    }

    _messages.addAll(items);
    _hasMoreMessages = items.length >= _take;
    _skip = items.length;

    // NS: only mark read when selected member is the logged-in user.
    if (isCurrentUser) {
      _repo.markThreadRead(threadId);
    }

    _setState(ChatLoadState.loaded);
  }

  // ─── Pagination ───────────────────────────────────────────────────────────

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _threadId == null || _advisor == null) {
      return;
    }
    _isLoadingMore = true;
    notifyListeners();

    final items = await _repo.fetchMessages(
      threadId: _threadId!,
      advisorPersonId: _advisor!.personId,
      skip: _skip,
      take: _take,
    );

    _isLoadingMore = false;

    if (items == null || items.isEmpty) {
      _hasMoreMessages = false;
      notifyListeners();
      return;
    }

    _messages.addAll(items);
    _hasMoreMessages = items.length >= _take;
    _skip += items.length;
    notifyListeners();
  }

  // ─── Send text ────────────────────────────────────────────────────────────

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty || !canSend) return;
    final session = await _sessionCache.resolve();
    if (session == null) return;

    _isSending = true;
    notifyListeners();

    final ok = await _repo.sendMessage(
      threadId: _threadId!,
      fromPersonId: session.personId,
      senderDisplayName: session.displayName,
      text: text.trim(),
    );

    if (ok) {
      _messages.insert(
        0,
        ChatMessageItem(
          type: ChatMessageType.text,
          sentOn: DateTime.now(),
          messageBody: text.trim(),
          senderPersonId: session.personId,
          isIncoming: false,
          isOutgoing: true,
        ),
      );

      // notify advisor in background
      if (_advisor != null && _advisor!.proposedUserId.isNotEmpty) {
        _repo.notifyAdvisor(
          advisorUserId: _advisor!.proposedUserId,
          threadId: _threadId!,
          message: text.trim(),
          senderPersonId: session.personId,
          senderDisplayName: session.displayName,
          senderEmail: session.email,
        );
      }
    }

    _isSending = false;
    notifyListeners();
  }

  // ─── Send file ────────────────────────────────────────────────────────────

  Future<void> sendFileMessage({
    required String fileId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (!canSend) return;
    final session = await _sessionCache.resolve();
    if (session == null) return;

    _isSending = true;

    // optimistic: show uploading attachment bubble
    final uploadingItem = ChatMessageItem(
      type: ChatMessageType.attachment,
      sentOn: DateTime.now(),
      senderPersonId: session.personId,
      isIncoming: false,
      isOutgoing: true,
      attachment: ChatAttachment(
        id: fileId,
        fileName: fileName,
        isUploading: true,
      ),
    );
    _messages.insert(0, uploadingItem);
    notifyListeners();

    // 1. Get presigned URL
    final uploadUrl = await _repo.getPresignedUploadUrl(
      fileId: fileId,
      fileName: fileName,
    );

    if (uploadUrl == null) {
      _messages.remove(uploadingItem);
      _isSending = false;
      notifyListeners();
      return;
    }

    // 2. Upload bytes
    final uploaded = await _repo.uploadFileToPresignedUrl(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
    );

    if (!uploaded) {
      _messages.remove(uploadingItem);
      _isSending = false;
      notifyListeners();
      return;
    }

    // 3. Send message with file attachment
    await Future<void>.delayed(const Duration(seconds: 2));
    final ok = await _repo.sendMessage(
      threadId: _threadId!,
      fromPersonId: session.personId,
      senderDisplayName: session.displayName,
      text: '',
      attachmentFileIds: [fileId],
    );

    // replace optimistic bubble with final state
    final idx = _messages.indexOf(uploadingItem);
    if (idx >= 0) {
      _messages[idx] = ChatMessageItem(
        type: ChatMessageType.attachment,
        sentOn: DateTime.now(),
        senderPersonId: session.personId,
        isIncoming: false,
        isOutgoing: true,
        attachment: ChatAttachment(
          id: fileId,
          fileName: fileName,
          isUploading: false,
        ),
      );
    }

    if (ok && _advisor != null && _advisor!.proposedUserId.isNotEmpty) {
      _repo.notifyAdvisor(
        advisorUserId: _advisor!.proposedUserId,
        threadId: _threadId!,
        message: '',
        senderPersonId: session.personId,
        senderDisplayName: session.displayName,
        senderEmail: session.email,
        attachments: [
          {'AttachmentId': fileId, 'FileName': fileName},
        ],
      );
    }

    _isSending = false;
    notifyListeners();
  }

  void _setState(ChatLoadState s) {
    _state = s;
    notifyListeners();
  }
}
