class ChatAdvisor {
  const ChatAdvisor({
    required this.personId,
    required this.proposedUserId,
    required this.displayName,
    this.profileImageUrl,
  });

  final String personId;
  final String proposedUserId;
  final String displayName;
  final String? profileImageUrl;
}

class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.fileName,
    this.fileUri,
    this.isUploading = false,
  });

  final String id;
  final String fileName;
  final String? fileUri;
  final bool isUploading;

  ChatAttachment copyWith({bool? isUploading, String? fileUri}) {
    return ChatAttachment(
      id: id,
      fileName: fileName,
      fileUri: fileUri ?? this.fileUri,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

enum ChatMessageType { text, attachment, dateLabel }

class ChatMessageItem {
  const ChatMessageItem({
    required this.type,
    required this.sentOn,
    this.messageBody,
    this.attachment,
    this.senderPersonId,
    this.isIncoming = false,
    this.isOutgoing = false,
  });

  final ChatMessageType type;
  final DateTime sentOn;
  final String? messageBody;
  final ChatAttachment? attachment;
  final String? senderPersonId;
  final bool isIncoming;
  final bool isOutgoing;

  bool get isDateLabel => type == ChatMessageType.dateLabel;
}

enum ChatLoadState { loading, loaded, noAdvisor, noThread, error }
