import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'markdown_content.dart';

class AiChatPanel extends StatefulWidget {
  final Question question;

  const AiChatPanel({
    super.key,
    required this.question,
  });

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _configureAiService();
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _configureAiService() {
    final settings = context.read<SettingsProvider>();
    final quiz = context.read<QuizProvider>();

    quiz.setAiConfigurator((service) {
      service.configure(
        apiKey: settings.aiApiKey,
        baseUrl: settings.aiBaseUrl,
        provider: settings.aiProvider == 'claude'
            ? AiProvider.claude
            : AiProvider.gemini,
        model: settings.aiModel,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = Provider.of<QuizProvider>(context);
    final messages = quiz.currentAiChatHistory;
    final aiStream = quiz.currentAiStream;

    // Determine total count: history + (optional) streaming bubble
    final hasStreaming = aiStream != null && aiStream.isLoading && aiStream.streamingResponse.isNotEmpty;
    final hasLoadingIndicator = aiStream != null && aiStream.isLoading && aiStream.streamingResponse.isEmpty;
    final extraItemCount = (hasStreaming || hasLoadingIndicator) ? 1 : 0;
    final itemCount = messages.length + extraItemCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      key: const Key('ai_chat_panel_gesture'),
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: const Key('ai_chat_panel_container'),
        height: MediaQuery.of(context).size.height * 0.75,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          key: const Key('ai_chat_panel_column'),
          children: [
            // Handle
            Container(
              key: const Key('ai_chat_panel_handle'),
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // Header with Session Management
          Padding(
            key: const Key('ai_chat_header_padding'),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              key: const Key('ai_chat_header_row'),
              children: [
                Text(
                  'AI 解析',
                  key: const Key('ai_chat_header_title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(key: Key('ai_chat_header_spacer')),
                // Cancel button when streaming
                if (aiStream != null && aiStream.isLoading)
                  IconButton(
                    key: const Key('ai_chat_cancel_button'),
                    icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                    tooltip: 'Cancel',
                    onPressed: () => quiz.cancelAiChat(widget.question.id),
                  ),
                IconButton(
                  key: const Key('ai_chat_history_button'),
                  icon: const Icon(Icons.history),
                  tooltip: 'Chat History',
                  onPressed: () => _showHistorySheet(context),
                ),
                IconButton(
                  key: const Key('ai_chat_new_button'),
                  icon: const Icon(Icons.add),
                  tooltip: 'New Chat',
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    quiz.createChatSession();
                  },
                ),
              ],
            ),
          ),
          const Divider(key: Key('ai_chat_header_divider'), height: 1),

          // Chat Messages or Quick Replies
          Expanded(
            key: const Key('ai_chat_content_expanded'),
            child: (messages.isEmpty && !hasStreaming && !hasLoadingIndicator)
                ? _buildQuickReplies(context)
                : ListView.builder(
                    key: const Key('ai_chat_listview'),
                    controller: _scrollController,
                    reverse: true, // Key to smooth keyboard animation
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      // Logic for reversed list with optional streaming bubble at the bottom (index 0)

                      // 1. Check if we are at the "bottom" (visual bottom, index 0) and have streaming/loading content
                      if (extraItemCount > 0 && index == 0) {
                        if (hasStreaming) {
                          return _buildMessageBubble(ChatMessage(text: aiStream!.streamingResponse, isUser: false), index);
                        } else {
                          return _buildMessageBubble(ChatMessage(text: '...', isUser: false), index);
                        }
                      }

                      // 2. Otherwise, map to history messages
                      // Since we might have used index 0 for streaming, adjust the index lookup
                      final historyIndex = index - extraItemCount;

                      // Reverse access: 0 is the last item in the list
                      final messageIndex = messages.length - 1 - historyIndex;
                      return _buildMessageBubble(messages[messageIndex], index);
                    },
                  ),
          ),

          // Input Area
          Container(
            key: const Key('ai_chat_input_outer_container'),
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SafeArea(
              key: const Key('ai_chat_input_safe_area'),
              top: false,
              child: Container(
                key: const Key('ai_chat_input_inner_container'),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.only(left: 16, right: 4),
                child: Row(
                  key: const Key('ai_chat_input_row'),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      key: const Key('ai_chat_input_expanded'),
                      child: TextField(
                        key: const Key('ai_chat_input_textfield'),
                        controller: _messageController,
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        style: const TextStyle(fontSize: 15),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(
                          hintText: 'Ask a question...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 4, key: Key('ai_chat_input_spacer')),
                    Container(
                      key: const Key('ai_chat_send_button_container'),
                      decoration: BoxDecoration(
                        color: _messageController.text.trim().isNotEmpty
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        key: const Key('ai_chat_send_button'),
                        icon: Icon(
                          Icons.arrow_upward,
                          key: const Key('ai_chat_send_icon'),
                          size: 18,
                          color: _messageController.text.trim().isNotEmpty
                              ? Colors.white
                              : Colors.grey,
                        ),
                        onPressed: _messageController.text.trim().isNotEmpty
                            ? () => _sendMessage(_messageController.text)
                            : null,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  static const _suggestions = [
    '详细解析本题',
    '为什么其他选项是错误的？',
    '这道题考察的知识点是什么？',
    '用更简单的话解释',
    '帮我翻译成中文',
  ];

  Widget _buildQuickReplies(BuildContext context) {

    return LayoutBuilder(
      key: const Key('ai_chat_quick_replies_layout'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          key: const Key('ai_chat_quick_replies_scroll'),
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            key: const Key('ai_chat_quick_replies_box'),
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              key: const Key('ai_chat_quick_replies_center'),
              child: Column(
                key: const Key('ai_chat_quick_replies_column'),
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, key: const Key('ai_chat_quick_replies_icon'), size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16, key: Key('ai_chat_quick_replies_spacer_1')),
                  Text(
                    'Start a conversation with AI',
                    key: const Key('ai_chat_quick_replies_text'),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 24, key: Key('ai_chat_quick_replies_spacer_2')),
                  Wrap(
                    key: const Key('ai_chat_quick_replies_wrap'),
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _suggestions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final text = entry.value;
                      return ActionChip(
                        key: Key('ai_chat_suggestion_$index'),
                        label: Text(text),
                        onPressed: () => _sendMessage(text),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer<QuizProvider>(
          key: const Key('ai_chat_history_consumer'),
          builder: (context, quiz, child) {
            final sessions = quiz.chatSessions;
            return Column(
              key: const Key('ai_chat_history_column'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  key: const Key('ai_chat_history_header_padding'),
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Chat History',
                    key: const Key('ai_chat_history_title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (sessions.isEmpty)
                  const Padding(
                    key: Key('ai_chat_history_empty_padding'),
                    padding: EdgeInsets.all(32.0),
                    child: Text('No history yet.', key: Key('ai_chat_history_empty_text')),
                  )
                else
                  Flexible(
                    key: const Key('ai_chat_history_flexible'),
                    child: ListView.separated(
                      key: const Key('ai_chat_history_listview'),
                      shrinkWrap: true,
                      itemCount: sessions.length,
                      separatorBuilder: (context, index) => const Divider(key: Key('ai_chat_history_divider'), height: 1),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isSelected = session.id == quiz.currentChatSessionId;
                        return ListTile(
                          key: Key('ai_chat_history_item_$index'),
                          leading: Icon(
                            isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline,
                            key: Key('ai_chat_history_item_icon_$index'),
                            color: isSelected ? Theme.of(context).colorScheme.primary : null,
                          ),
                          title: Text(
                            session.title,
                            key: Key('ai_chat_history_item_title_$index'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('MM/dd HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(session.createdAt),
                            ),
                            key: Key('ai_chat_history_item_subtitle_$index'),
                          ),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            quiz.switchChatSession(session.id);
                            Navigator.pop(context);
                          },
                          trailing: Row(
                            key: Key('ai_chat_history_item_trailing_$index'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) Icon(Icons.check, key: Key('ai_chat_history_item_check_$index'), size: 16, color: Colors.green),
                              IconButton(
                                key: Key('ai_chat_history_item_delete_$index'),
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                onPressed: () => _confirmDeleteSession(context, quiz, session),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSession(BuildContext context, QuizProvider quiz, ChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('ai_chat_delete_dialog'),
        title: const Text('Delete Chat?', key: Key('ai_chat_delete_dialog_title')),
        content: Text('Are you sure you want to delete "${session.title}"?', key: const Key('ai_chat_delete_dialog_content')),
        actions: [
          TextButton(
            key: const Key('ai_chat_delete_dialog_cancel'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('ai_chat_delete_dialog_confirm'),
            onPressed: () {
              quiz.deleteChatSession(session.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bubbleColor = isUser
        ? colorScheme.primary
        : (theme.brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200);

    final textColor = isUser
        ? colorScheme.onPrimary
        : theme.textTheme.bodyLarge?.color;

    return Padding(
      key: Key('ai_chat_message_padding_$index'),
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        key: Key('ai_chat_message_align_$index'),
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          key: Key('ai_chat_message_container_$index'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
            ),
          ),
          child: Theme(
            key: Key('ai_chat_message_theme_$index'),
            data: theme.copyWith(
              textSelectionTheme: TextSelectionThemeData(
                selectionColor: isUser 
                    ? colorScheme.onPrimary.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: 0.3),
                selectionHandleColor: isUser ? colorScheme.onPrimary : colorScheme.primary,
              ),
            ),
            child: MarkdownContent(
              key: Key('ai_chat_message_markdown_$index'),
              content: message.text,
              fontSize: 15,
              textColor: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final quiz = context.read<QuizProvider>();

    // Check if already streaming
    if (quiz.isAiStreaming) return;

    _messageController.clear();

    try {
      await quiz.startAiChat(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
    }
  }
}
