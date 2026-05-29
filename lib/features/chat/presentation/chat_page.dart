import 'dart:async';
import 'dart:typed_data';

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/app/services/app_services.dart';
import 'package:filip_at_flutter/features/chat/application/chat_controller.dart';
import 'package:filip_at_flutter/features/chat/data/chat_models.dart';
import 'package:filip_at_flutter/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:filip_at_flutter/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/widgets/contracts_household_member_filter.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;
  late final HouseholdMemberFilterController _householdController;
  final _scrollController = ScrollController();
  String? _lastInitialisedPersonId;


  @override
  void initState() {
    super.initState();
    final services = AppServices.instance;
    _householdController = services.householdController;

    _controller = ChatController(
      chatRepository: services.chatRepository,
      userSessionCache: services.userSessionCache,
    );

    // Ensure household data is loaded, then init chat for the selected member.
    unawaited(
      _householdController.ensureLoaded().then((_) {
        if (mounted) _initForSelectedMember();
      }),
    );

    // React to household selection changes.
    _householdController.addListener(_onHouseholdChanged);
    _controller.addListener(_onControllerUpdate);
    _scrollController.addListener(_onScroll);
  }

  void _initForSelectedMember() {
    final members = _householdController.visibleMembers;
    if (members.isEmpty) return;

    // NS parity: uses res[0] — first element of selectedPersonIds array.
    final selectedIds = _householdController.selectedPersonIds;
    final firstSelectedId = selectedIds.isNotEmpty ? selectedIds.first : null;

    final member = firstSelectedId != null
        ? members.firstWhere(
            (m) => m.personId == firstSelectedId,
            orElse: () => members.first,
          )
        : members.first;

    // Skip reinit when same member already loaded (household reload with no selection change).
    if (member.personId == _lastInitialisedPersonId) return;
    _lastInitialisedPersonId = member.personId;

    _controller.initialize(
      targetPersonId: member.personId,
      targetManagerNr: member.managerNr,
      isCurrentUser: member.isCurrentUser,
    );
  }

  void _onHouseholdChanged() {
    _initForSelectedMember();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMoreMessages();
    }
  }

  @override
  void dispose() {
    _householdController.removeListener(_onHouseholdChanged);
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openHouseholdSheet() async {
    if (_householdController.isLoading || !_householdController.shouldShowFilter) {
      return;
    }
    final result = await showContractsHouseholdFilterSheet(
      context,
      initialMode: _householdController.mode,
      initialHouseholdMembers: _householdController.copyHouseholdMembers(),
      initialBusinessMembers: _householdController.copyBusinessMembers(),
    );
    if (result == null) return;
    _householdController.applySelection(
      mode: result.mode,
      householdMembers: result.householdMembers,
      businessMembers: result.businessMembers,
    );
  }

  void _handleMemberTap(String personId) {
    final didUpdate = _householdController.toggleVisibleMemberSelection(personId);
    if (!didUpdate && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(context.l10n.tr('tns.householdCannotDeselectAll')),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            // Household member filter — same widget as Contracts/Drive
            ListenableBuilder(
              listenable: _householdController,
              builder: (_, _) => ContractsHouseholdMemberFilterBar(
                controller: _householdController,
                onMemberTap: _handleMemberTap,
                onArrowTap: _openHouseholdSheet,
              ),
            ),
            Expanded(child: _buildBody(l10n)),
            // NS: input hidden entirely for non-logged-in household members.
            if (_controller.isCurrentUser &&
                (_controller.state == ChatLoadState.loaded ||
                    _controller.state == ChatLoadState.noThread))
              ChatInputBar(
                enabled: _controller.canSend,
                onSendText: (text) => _controller.sendTextMessage(text),
                onSendFile: ({
                  required fileId,
                  required fileName,
                  required bytes,
                  required contentType,
                }) =>
                    _controller.sendFileMessage(
                  fileId: fileId,
                  fileName: fileName,
                  bytes: Uint8List.fromList(bytes),
                  contentType: contentType,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final advisor = _controller.advisor;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: Color(0xFF808080),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (advisor != null) ...[
            _buildAdvisorAvatar(advisor),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              advisor?.displayName.isNotEmpty == true
                  ? advisor!.displayName
                  : l10n.tr('tns.messageWithAdvisor'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisorAvatar(ChatAdvisor advisor) {
    final imageUrl = advisor.profileImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(imageUrl),
        backgroundColor: Colors.grey.shade200,
      );
    }
    final initial =
        advisor.displayName.isNotEmpty ? advisor.displayName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: 'Calibri',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_controller.state) {
      case ChatLoadState.loading:
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
          ),
        );

      case ChatLoadState.noAdvisor:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.tr('tns.noAdvisorAssignedMessage'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                color: Color(0xFF888888),
              ),
            ),
          ),
        );

      case ChatLoadState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFD82034)),
              const SizedBox(height: 12),
              Text(
                l10n.tr('SOMETHING_WENT_WRONG'),
                style: const TextStyle(fontFamily: 'Calibri', fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _initForSelectedMember,
                child: Text(l10n.tr('tns.retry')),
              ),
            ],
          ),
        );

      case ChatLoadState.noThread:
      case ChatLoadState.loaded:
        return _buildMessageList(l10n);
    }
  }

  Widget _buildMessageList(AppLocalizations l10n) {
    final messages = _controller.messages;
    final isEmpty = messages.isEmpty &&
        (_controller.state == ChatLoadState.loaded ||
            _controller.state == ChatLoadState.noThread);

    // Background hex pattern — from NS: backgroundImage="res://message_background"
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/chat/message_background.png'),
          repeat: ImageRepeat.repeat,
          opacity: 0.5,
        ),
        color: Colors.white,
      ),
      child: isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.tr('tns.noMessageFound'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 18,
                      color: Color(0xFFB4B4B4),
                    ),
                  ),
                  Text(
                    l10n.tr('tns.startConversation'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 18,
                      color: Color(0xFFB4B4B4),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: messages.length + (_controller.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryRed),
                        ),
                      ),
                    ),
                  );
                }
                return ChatMessageBubble(item: messages[index]);
              },
            ),
    );
  }
}
