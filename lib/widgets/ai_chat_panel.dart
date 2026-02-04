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
  final AiService _aiService = AiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _streamingResponse = '';

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _aiService.configure(
      apiKey: settings.aiApiKey,
      baseUrl: settings.aiBaseUrl,
      provider: settings.aiProvider == 'claude'
          ? AiProvider.claude
          : AiProvider.gemini,
      model: settings.aiModel,
    );
    _messageController.addListener(() {
      if (mounted) setState(() {});
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
    
    // Determine total count: history + (optional) streaming bubble
    final hasStreaming = _isLoading && _streamingResponse.isNotEmpty;
    final hasLoadingIndicator = _isLoading && _streamingResponse.isEmpty;
    final extraItemCount = (hasStreaming || hasLoadingIndicator) ? 1 : 0;
    final itemCount = messages.length + extraItemCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'AI 解析',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Chat History',
                  onPressed: () => _showHistorySheet(context),
                ),
                IconButton(
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
          const Divider(height: 1),

          // Chat Messages or Quick Replies
          Expanded(
            child: (messages.isEmpty && !hasStreaming && !hasLoadingIndicator)
                ? _buildQuickReplies(context)
                : ListView.builder(
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
                          return _buildMessageBubble(ChatMessage(text: _streamingResponse, isUser: false));
                        } else {
                          return _buildMessageBubble(ChatMessage(text: '...', isUser: false));
                        }
                      }
                      
                      // 2. Otherwise, map to history messages
                      // Since we might have used index 0 for streaming, adjust the index lookup
                      final historyIndex = index - extraItemCount;
                      
                      // Reverse access: 0 is the last item in the list
                      final messageIndex = messages.length - 1 - historyIndex;
                      return _buildMessageBubble(messages[messageIndex]);
                    },
                  ),
          ),

          // Input Area
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.only(left: 16, right: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
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
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: _messageController.text.trim().isNotEmpty
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_upward, 
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
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Start a conversation with AI',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _suggestions.map((text) {
                      return ActionChip(
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
          builder: (context, quiz, child) {
            final sessions = quiz.chatSessions;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Chat History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No history yet.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: sessions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isSelected = session.id == quiz.currentChatSessionId;
                        return ListTile(
                          leading: Icon(
                            isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline,
                            color: isSelected ? Theme.of(context).colorScheme.primary : null,
                          ),
                          title: Text(
                            session.title,
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
                          ),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            quiz.switchChatSession(session.id);
                            Navigator.pop(context);
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) const Icon(Icons.check, size: 16, color: Colors.green),
                              IconButton(
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
        title: const Text('Delete Chat?'),
        content: Text('Are you sure you want to delete "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
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

  Widget _buildMessageBubble(ChatMessage message) {
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
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
          child: MarkdownContent(
            content: message.text, 
            fontSize: 15,
            textColor: textColor,
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    final quiz = context.read<QuizProvider>();
    _messageController.clear();
    await quiz.addAiChatMessage(ChatMessage(text: text, isUser: true));

    setState(() {
      _isLoading = true;
      _streamingResponse = '';
    });

    try {
      final stream = _aiService.explain(
        questionStem: widget.question.content,
        options: {for (var c in widget.question.choices) c.key: c.content},
        correctAnswer: widget.question.answer,
        userQuestion: text,
      );

      await for (final chunk in stream) {
        if (!mounted) return;
        setState(() {
          _streamingResponse += chunk;
        });
      }

      if (mounted && _streamingResponse.isNotEmpty) {
        await quiz.addAiChatMessage(ChatMessage(text: _streamingResponse, isUser: false));
      }
    } catch (e) {
      if (mounted) {
        await quiz.addAiChatMessage(ChatMessage(
          text: 'Error: ${e.toString().replaceAll("Exception: ", "")}', 
          isUser: false
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _streamingResponse = '';
        });
      }
    }
  }
}
