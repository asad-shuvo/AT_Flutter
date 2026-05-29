import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/chat/data/chat_models.dart';

class ChatRepository {
  ChatRepository({
    required ApiClient apiClient,
    required UserSessionCache userSessionCache,
  })  : _apiClient = apiClient,
        _sessionCache = userSessionCache;

  final ApiClient _apiClient;
  final UserSessionCache _sessionCache;

  static const String _chatTag = 'Chat-Of-EntityBasedChat';
  static const String _threadTag = 'MessageThread-For-Chat';
  static const String _topicName = 'TOPIC';
  static const String _subject = 'Optimizer';

  Map<String, String> _headers(String token) => {
        'Authorization': 'bearer $token',
        'Origin': _apiClient.originUrl,
      };

  // ─── Advisor ──────────────────────────────────────────────────────────────

  Future<ChatAdvisor?> fetchAdvisor(String managerNr) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    final response = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: {
        'EntityName': 'AdvisorDenormalized',
        'Text':
            'Select <PersonId,DisplayName,ProposedUserId,ProfileImageId>from<AdvisorDenormalized>where<ManagerNr=__eql($managerNr)>pageNumber=<0>pageSize= <1>',
        'ExcludeCount': true,
      },
      headers: _headers(session.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body = response['body'] as Map<String, dynamic>? ?? {};
    final results = body['Results'];
    if (results is! List || results.isEmpty) return null;

    final data = Map<String, dynamic>.from(results.first as Map);
    final personId = _str(data['PersonId']) ?? '';
    if (personId.isEmpty) return null;

    final profileImageId = _str(data['ProfileImageId']);
    return ChatAdvisor(
      personId: personId,
      proposedUserId: _str(data['ProposedUserId']) ?? '',
      displayName: _str(data['DisplayName']) ?? '',
      profileImageUrl: _apiClient.resolveProfileImageUrl(profileImageId),
    );
  }

  // ─── Thread ───────────────────────────────────────────────────────────────

  Future<String?> findThreadId({
    required String personId,
    required String advisorPersonId,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    // Query EntityBasedChat with only the IsMailThreadArchived=false filter.
    // Tags and Recipients are array fields — the SQL filter engine does not
    // reliably support __eql / __all on arrays, so we filter client-side.
    final response = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: {
        'EntityName': 'EntityBasedChat',
        'Text':
            'Select <MailThreadId,Recipients,Tags>from<EntityBasedChat>where<IsMailThreadArchived=__eql(false)>pageNumber=<0>pageSize= <20>',
        'ExcludeCount': true,
      },
      headers: _headers(session.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body = response['body'] as Map<String, dynamic>? ?? {};
    final results = body['Results'];
    if (results is! List || results.isEmpty) return null;

    for (final raw in results) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);

      // Only chat threads (Tags contains our chat tag).
      final tags = item['Tags'];
      final tagList = _toStringList(tags);
      if (!tagList.contains(_chatTag)) continue;

      // Recipients must contain both personId and advisorPersonId.
      final recipients = item['Recipients'];
      final recipientList = _toStringList(recipients);
      if (recipientList.contains(personId) &&
          recipientList.contains(advisorPersonId)) {
        return _str(item['MailThreadId']);
      }
    }
    return null;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      // Could be JSON array string or comma-separated.
      final trimmed = value.trim();
      if (trimmed.startsWith('[')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return trimmed.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  Future<String?> createThread({
    required String personId,
    required String advisorPersonId,
    required String advisorProposedUserId,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    final recipients = [advisorPersonId, personId];
    final threadId = _uuid();
    final headers = _headers(session.accessToken);

    // 1. RegisterMailThread
    final registerRes = await _apiClient.postJson(
      url: '${_apiClient.messagingServiceUrl}/MailThreadingCommand/RegisterMailThread',
      body: {
        'MailThreadId': threadId,
        'Subject': _subject,
        'DispatchTemplateName': 'slsn-mail-discuss',
        'Tags': [_threadTag],
        'Recipients': recipients,
        'TopicName': _topicName,
      },
      headers: headers,
    );

    final regStatus = registerRes['statusCode'] as int? ?? 0;
    if (regStatus < 200 || regStatus >= 300) return null;

    final regBody = registerRes['body'] as Map<String, dynamic>? ?? {};
    final regErrors = regBody['ErrorMessages'];
    if (regErrors is List && regErrors.isNotEmpty) return null;

    // 2. RegisterRecipients
    final recipientsRes = await _apiClient.postJson(
      url: '${_apiClient.messagingServiceUrl}/MailThreadingCommand/RegisterRecipients',
      body: {
        'ThreadId': threadId,
        'RecipientIds': recipients,
      },
      headers: headers,
    );

    final recStatus = recipientsRes['statusCode'] as int? ?? 0;
    if (recStatus < 200 || recStatus >= 300) return null;

    // 3. Insert EntityBasedChat record
    final itemId = _uuid();
    final defaultMsg = jsonEncode({'message': 'YOU_CAN_START_CHATTING_ON_THIS_THREAD_NOW'});
    await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationCommand/Insert',
      body: {
        'EntityName': 'EntityBasedChat',
        'JsonString': jsonEncode({
          'ItemId': itemId,
          'Language': 'en-US',
          'Tags': [_chatTag],
          'TopicName': _topicName,
          'TopicEntityName': 'EntityBasedChat',
          'TopicId': itemId,
          'Recipients': recipients,
          'MailThreadId': threadId,
          'MailThreadLastMessage': {
            'MessageBody': defaultMsg,
            'SentOn': DateTime.now().toUtc().toIso8601String(),
          },
        }),
        'EventData': {'EventType': 'EntityBasedChat.Created'},
      },
      headers: headers,
    );

    return threadId;
  }

  // ─── Messages ─────────────────────────────────────────────────────────────

  Future<List<ChatMessageItem>?> fetchMessages({
    required String threadId,
    required String advisorPersonId,
    int skip = 0,
    int take = 20,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    final response = await _apiClient.postJson(
      url: '${_apiClient.messagingServiceUrl}/MailThreadingQuery/GetSpecificMailsForThread',
      body: {
        'Skip': skip,
        'Take': take,
        'ThreadId': threadId,
        'OrderBy': [
          {'Property': 'SentOn', 'Order': -1},
        ],
      },
      headers: _headers(session.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body = response['body'] as Map<String, dynamic>? ?? {};
    final results = body['Results'];
    if (results is! List) return [];

    final items = <ChatMessageItem>[];
    DateTime? prevDate;

    for (final raw in results) {
      if (raw is! Map) continue;
      final mail = Map<String, dynamic>.from(raw);

      final sentOnRaw = mail['SentOn'];
      final sentOn = _parseDate(sentOnRaw) ?? DateTime.now();

      Map<String, dynamic> mailBody;
      final isReply = mail['IsReply'] == true;
      if (!isReply) {
        final rawBody = mail['MailBody'];
        if (rawBody is String) {
          try {
            mailBody = Map<String, dynamic>.from(jsonDecode(rawBody) as Map);
          } catch (_) {
            mailBody = {'message': rawBody, 'sender': ''};
          }
        } else if (rawBody is Map) {
          mailBody = Map<String, dynamic>.from(rawBody);
        } else {
          mailBody = {};
        }
      } else {
        mailBody = {
          'message': mail['MailBody']?.toString() ?? '',
          'sender': _str(mail['ReceivedFrom']) ?? '',
        };
      }

      final sender = _str(mailBody['sender']) ?? '';
      final isIncoming = sender == advisorPersonId;
      final isOutgoing = !isIncoming;
      final messageText = _str(mailBody['message']) ?? '';

      // date label when day changes
      if (prevDate == null || !_sameDay(prevDate, sentOn)) {
        if (items.isNotEmpty) {
          items.add(ChatMessageItem(
            type: ChatMessageType.dateLabel,
            sentOn: sentOn,
          ));
        }
        prevDate = sentOn;
      }

      // skip default "start chatting" message
      if (messageText == 'YOU_CAN_START_CHATTING_ON_THIS_THREAD_NOW') continue;

      if (messageText.trim().isNotEmpty) {
        items.add(ChatMessageItem(
          type: ChatMessageType.text,
          sentOn: sentOn,
          messageBody: messageText,
          senderPersonId: sender,
          isIncoming: isIncoming,
          isOutgoing: isOutgoing,
        ));
      }

      final attachments = mail['Attachments'];
      if (attachments is List) {
        for (final att in attachments) {
          if (att is! Map) continue;
          final a = Map<String, dynamic>.from(att);
          items.add(ChatMessageItem(
            type: ChatMessageType.attachment,
            sentOn: sentOn,
            senderPersonId: sender,
            isIncoming: isIncoming,
            isOutgoing: isOutgoing,
            attachment: ChatAttachment(
              id: _str(a['AttachmentId']) ?? '',
              fileName: _str(a['FileName']) ?? '',
              fileUri: _str(a['FileUri']),
            ),
          ));
        }
      }
    }

    return items;
  }

  // UpdateMailThreadReadStatuses expects a JSON array body.
  // ApiClient.postJson only supports Map bodies, so we call the raw HTTP client via a
  // thin helper that serialises the list directly.
  Future<bool> markThreadRead(String threadId) async {
    final session = await _sessionCache.resolve();
    if (session == null) return false;

    final payload = jsonEncode([
      {'MailThreadId': threadId, 'Read': true},
    ]);

    try {
      final response = await _apiClient.postJsonRaw(
        url: '${_apiClient.messagingServiceUrl}/mailthreadingcommand/UpdateMailThreadReadStatuses',
        rawBody: payload,
        headers: _headers(session.accessToken),
      );
      final statusCode = response['statusCode'] as int? ?? 0;
      return statusCode >= 200 && statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ─── Send Message ─────────────────────────────────────────────────────────

  Future<bool> sendMessage({
    required String threadId,
    required String fromPersonId,
    required String senderDisplayName,
    required String text,
    List<String> attachmentFileIds = const [],
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return false;

    final mailBody = jsonEncode({
      'message': text,
      'sender': fromPersonId,
      'SenderDisplayName': senderDisplayName,
    });

    final response = await _apiClient.postJson(
      url: '${_apiClient.messagingServiceUrl}/SendMailToThread/PostWithFile',
      body: {
        'Subject': 'FiLiP Messages',
        'MailId': _uuid(),
        'ThreadId': threadId,
        'From': fromPersonId,
        'MailBody': mailBody,
        'MailTemplateName': 'slsn-mail-discuss',
        'Attachments': attachmentFileIds,
      },
      headers: _headers(session.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return false;

    final body = response['body'] as Map<String, dynamic>? ?? {};
    final errors = body['Errors'] as Map<String, dynamic>?;
    return errors?['IsValid'] == true;
  }

  // ─── File Upload ──────────────────────────────────────────────────────────

  Future<String?> getPresignedUploadUrl({
    required String fileId,
    required String fileName,
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;

    final response = await _apiClient.postJson(
      url: '${_apiClient.storageServiceUrl}StorageQuery/GetPreSignedUrlForUpload',
      body: {
        'ItemId': fileId,
        'Name': fileName,
        'ParentDirectoryId': null,
        'Tags': jsonEncode(['attachment']),
      },
      headers: _headers(session.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body = response['body'] as Map<String, dynamic>? ?? {};
    return body['UploadUrl'] as String?;
  }

  Future<bool> uploadFileToPresignedUrl({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final statusCode = await _apiClient.putBytes(
        url: uploadUrl,
        bytes: bytes,
        contentType: contentType,
        extraHeaders: {'x-ms-blob-type': 'BlockBlob'},
      );
      return statusCode >= 200 && statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ─── Notify ───────────────────────────────────────────────────────────────

  Future<void> notifyAdvisor({
    required String advisorUserId,
    required String threadId,
    required String message,
    required String senderPersonId,
    required String senderDisplayName,
    required String senderEmail,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final session = await _sessionCache.resolve();
    if (session == null) return;

    final denomData = jsonEncode({
      'title': 'You have a new message!',
      'message': message,
      'attachements': attachments,
      'time': DateTime.now().toUtc().toIso8601String(),
      'who': senderPersonId,
      'senderName': senderDisplayName,
      'Email': senderEmail,
      'ThreadId': threadId,
      'Success': true,
    });

    await _apiClient.postJson(
      url: '${_apiClient.notificationUrl}/api/Notifier/Notify',
      body: {
        'UserIds': [advisorUserId],
        'NotificationType': 'UserSpecificReceiverType',
        'ResponseKey': 'MessagingThreadNotification',
        'SubscriptionFilters': [
          {'Context': 'MessagingThreadNotification'},
        ],
        'ResponseValue': jsonEncode({'ThreadId': threadId}),
        'DenormalizedPayload': denomData,
      },
      headers: _headers(session.accessToken),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _uuid() {
    final rng = Random.secure();
    final b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    return v.toString();
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      if (v is String) return DateTime.parse(v).toLocal();
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt()).toLocal();
    } catch (_) {}
    return null;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
