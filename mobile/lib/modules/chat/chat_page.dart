import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:itc_events/app/formatters/event_date.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/chat/chat_controller.dart';
import 'package:itc_events/modules/events/event.dart';
import 'package:itc_events/modules/events/event_detail_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  ChatController get controller => Get.find<ChatController>();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _submit([String? preset]) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await controller.send(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final scaffold = AppTheme.scaffoldOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: scaffold,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                    : const Color(0xFFDBEAFE),
                scaffold,
                scaffold,
              ],
              stops: const [0, 0.28, 1],
            ),
          ),
          child: Column(
            children: [
              _ChatHeader(
                remainingToday: controller.remainingToday,
                onClear: controller.clearChat,
              ),
              Expanded(
                child: Obx(() {
                  _scrollToEnd();
                  final items = controller.messages;
                  final busy = controller.isSending.value;

                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      ...items.map(
                        (message) => _MessageRow(
                          message: message,
                          onSelectAction: busy ? null : _submit,
                        ),
                      ),
                      if (busy) const _TypingIndicator(),
                    ],
                  );
                }),
              ),
              _ComposerBar(
                controller: _inputController,
                focusNode: _focusNode,
                onSubmit: () => _submit(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.remainingToday,
    required this.onClear,
  });

  final RxnInt remainingToday;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final foreground = AppTheme.textPrimaryOf(context);
    final chat = Get.find<ChatController>();

    return Padding(
      padding: EdgeInsets.fromLTRB(8, top + 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.arrow_back_rounded, color: foreground),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.heroBlue],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'chat_title'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'chat_online'.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Obx(() {
            final left = remainingToday.value;
            if (left == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceOf(context).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.borderOf(context).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'chat_remaining'.trParams({'count': '$left'}),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondaryOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
          Obx(() {
            if (!chat.hasConversation) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'chat_clear'.tr,
              onPressed: onClear,
              icon: Icon(
                Icons.refresh_rounded,
                color: AppTheme.textSecondaryOf(context),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChatAction {
  const _ChatAction({
    required this.icon,
    required this.labelKey,
    required this.promptKey,
  });

  final IconData icon;
  final String labelKey;
  final String promptKey;
}

const _chatActions = [
  _ChatAction(
    icon: Icons.event_available_outlined,
    labelKey: 'chat_action_events',
    promptKey: 'chat_suggestion_events',
  ),
  _ChatAction(
    icon: Icons.confirmation_number_outlined,
    labelKey: 'chat_action_reserve',
    promptKey: 'chat_suggestion_reserve',
  ),
  _ChatAction(
    icon: Icons.qr_code_2_rounded,
    labelKey: 'chat_action_qr',
    promptKey: 'chat_suggestion_qr',
  ),
  _ChatAction(
    icon: Icons.bookmark_outline_rounded,
    labelKey: 'chat_action_save',
    promptKey: 'chat_suggestion_save',
  ),
  _ChatAction(
    icon: Icons.login_rounded,
    labelKey: 'chat_action_signin',
    promptKey: 'chat_suggestion_signin',
  ),
  _ChatAction(
    icon: Icons.how_to_reg_outlined,
    labelKey: 'chat_action_checkin',
    promptKey: 'chat_suggestion_checkin',
  ),
  _ChatAction(
    icon: Icons.person_outline_rounded,
    labelKey: 'chat_action_profile',
    promptKey: 'chat_suggestion_profile',
  ),
  _ChatAction(
    icon: Icons.event_seat_outlined,
    labelKey: 'chat_action_spots',
    promptKey: 'chat_suggestion_spots',
  ),
  _ChatAction(
    icon: Icons.help_outline_rounded,
    labelKey: 'chat_action_help',
    promptKey: 'chat_suggestion_help',
  ),
];

class _ActionMenuGrid extends StatelessWidget {
  const _ActionMenuGrid({required this.onSelect});

  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldOf(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.borderOf(context).withValues(alpha: 0.4),
        ),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.92,
        children: [
          for (final action in _chatActions)
            Material(
              color: AppTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onSelect == null
                    ? null
                    : () => onSelect!(action.promptKey.tr),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action.icon, color: AppTheme.primary, size: 26),
                      const SizedBox(height: 8),
                      Text(
                        action.labelKey.tr,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: AppTheme.textPrimaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    this.onSelectAction,
  });

  final ChatMessage message;
  final ValueChanged<String>? onSelectAction;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.86;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 16,
                color: AppTheme.primary,
              ),
            ),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppTheme.primary, AppTheme.heroBlue],
                            )
                          : null,
                      color: isUser ? null : AppTheme.surfaceOf(context),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 6),
                        bottomRight: Radius.circular(isUser ? 6 : 18),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: AppTheme.borderOf(
                                context,
                              ).withValues(alpha: 0.45),
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isUser ? 0.12 : 0.04,
                          ),
                          blurRadius: isUser ? 10 : 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      message.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isUser
                            ? Colors.white
                            : AppTheme.textPrimaryOf(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (message.hasEventCards) ...[
                    const SizedBox(height: 8),
                    ...message.events.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ChatEventCard(event: event),
                      ),
                    ),
                  ],
                  if (message.showActionMenu) ...[
                    const SizedBox(height: 8),
                    _ActionMenuGrid(onSelect: onSelectAction),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEventCard extends StatelessWidget {
  const _ChatEventCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final full = event.isSoldOut;
    final spotsColor = full ? AppTheme.error : AppTheme.success;

    return Material(
      color: AppTheme.surfaceOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => EventDetailPage(event: event)),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderOf(context).withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _coverFallback(),
                          )
                        : _coverFallback(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppTheme.textSecondaryOf(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              EventDate.format(event.startsAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondaryOf(context),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppTheme.textSecondaryOf(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.locationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondaryOf(context),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: spotsColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          full
                              ? 'chat_event_full'.tr
                              : 'chat_spots_left'.trParams({
                                  'count': '${event.spotsRemaining}',
                                }),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: spotsColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondaryOf(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.12),
      child: const Icon(Icons.event_rounded, color: AppTheme.primary),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 16,
              color: AppTheme.primary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.borderOf(context).withValues(alpha: 0.45),
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final t = (_controller.value + index * 0.2) % 1.0;
                    final lift = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                    return Padding(
                      padding: EdgeInsets.only(right: index < 2 ? 5 : 0),
                      child: Transform.translate(
                        offset: Offset(0, -3 * lift),
                        child: Opacity(
                          opacity: 0.35 + 0.65 * lift,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final chat = Get.find<ChatController>();

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      color: AppTheme.surfaceOf(context),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmit(),
                  decoration: InputDecoration(
                    hintText: 'chat_input_hint'.tr,
                    filled: true,
                    fillColor: AppTheme.scaffoldOf(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() {
                final busy = chat.isSending.value;
                return AnimatedScale(
                  scale: busy ? 0.94 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: Material(
                    color: busy
                        ? AppTheme.primary.withValues(alpha: 0.45)
                        : AppTheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: busy ? null : onSubmit,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
