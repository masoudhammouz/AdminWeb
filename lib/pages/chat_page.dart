import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_bar.dart' as app_bar;
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<dynamic> _conversations = [];
  String? _selectedConversationId;
  List<dynamic> _messages = [];
  final _messageController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final result = await ChatService.getAllConversations();
    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        if (data is Map) {
          _conversations = data['data'] as List<dynamic>? ?? [];
        } else if (data is List) {
          _conversations = data;
        } else {
          _conversations = [];
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages(String conversationId) async {
    setState(() {
      _selectedConversationId = conversationId;
      _isLoading = true;
    });
    final result = await ChatService.getMessages(conversationId);
    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        if (data is Map) {
          _messages = data['data'] as List<dynamic>? ?? [];
        } else if (data is List) {
          _messages = data;
        } else {
          _messages = [];
        }
        _isLoading = false;
      });
      // Mark as read
      await ChatService.markAsRead(conversationId);
      _loadConversations(); // Refresh to update unread count
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedConversationId == null) return;
    
    final content = _messageController.text.trim();
    _messageController.clear();
    
    final result = await ChatService.sendMessage(_selectedConversationId!, content);
    if (result['success'] == true) {
      _loadMessages(_selectedConversationId!);
      _loadConversations();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Failed to send message')),
        );
      }
      _messageController.text = content; // Restore message on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Row(
        children: [
          Sidebar(currentRoute: '/chat'),
          Expanded(
            child: Column(
              children: [
                const app_bar.AppBar(),
                Expanded(
                  child: Row(
                    children: [
                      // Conversations list
                      Container(
                        width: 320,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(-2, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.06),
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.primaryGreen.withOpacity(0.2),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Conversations',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkGreen,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : _conversations.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.forum_outlined, size: 48, color: AppColors.grey600),
                                              const SizedBox(height: 12),
                                              Text(
                                                'No conversations yet',
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                      color: AppColors.grey600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          itemCount: _conversations.length,
                                          itemBuilder: (context, index) {
                                            final conv = _conversations[index];
                                            final user = conv['userId'] as Map<String, dynamic>?;
                                            final unread = conv['unreadCount'] as int? ?? 0;
                                            final convId = conv['_id'] as String? ?? conv['id'] as String? ?? '';
                                            final isSelected = convId == _selectedConversationId;
                                            final lastMsg = conv['lastMessage'] as String? ?? '';
                                            return Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.primaryGreen.withOpacity(0.1)
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(12),
                                                border: isSelected
                                                    ? Border.all(color: AppColors.primaryGreen.withOpacity(0.4))
                                                    : null,
                                              ),
                                              child: ListTile(
                                                selected: isSelected,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                leading: CircleAvatar(
                                                  radius: 24,
                                                  backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
                                                  child: Text(
                                                    (user?['name'] as String? ?? '?')[0].toUpperCase(),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primaryGreen,
                                                    ),
                                                  ),
                                                ),
                                                title: Text(
                                                  user?['name'] as String? ?? 'Unknown',
                                                  style: TextStyle(
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                    color: isSelected ? AppColors.darkGreen : null,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  lastMsg.isEmpty ? 'No messages' : lastMsg,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.grey600,
                                                  ),
                                                ),
                                                trailing: unread > 0
                                                    ? Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primaryGreen,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          unread.toString(),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      )
                                                    : null,
                                                onTap: () => _loadMessages(convId),
                                              ),
                                            );
                                          },
                                        ),
                            ),
                          ],
                        ),
                      ),
                      // Chat window
                      Expanded(
                        child: _selectedConversationId == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 80,
                                      color: AppColors.grey600.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Select a conversation',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: AppColors.grey600,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Choose from the list on the left to start chatting',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.grey600,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: _isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : ListView.builder(
                                            padding: const EdgeInsets.all(20),
                                            itemCount: _messages.length,
                                            itemBuilder: (context, index) {
                                              final msg = _messages[index];
                                              final isAdmin = msg['senderType'] == 'admin';
                                              final sender = msg['senderId'] as Map<String, dynamic>?;
                                              final content = msg['content'] as String? ?? '';
                                              return Align(
                                                alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                                child: Container(
                                                  margin: const EdgeInsets.only(bottom: 12),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  constraints: const BoxConstraints(maxWidth: 340),
                                                  decoration: BoxDecoration(
                                                    color: isAdmin
                                                        ? AppColors.primaryGreen
                                                        : AppColors.white,
                                                    borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(16),
                                                      topRight: Radius.circular(16),
                                                      bottomLeft: Radius.circular(isAdmin ? 16 : 4),
                                                      bottomRight: Radius.circular(isAdmin ? 4 : 16),
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.06),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      if (sender != null && !isAdmin)
                                                        Padding(
                                                          padding: const EdgeInsets.only(bottom: 6),
                                                          child: Text(
                                                            sender['name'] as String? ?? 'User',
                                                            style: TextStyle(
                                                              color: AppColors.primaryGreen,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      Text(
                                                        content,
                                                        style: TextStyle(
                                                          color: isAdmin ? Colors.white : AppColors.darkGreen,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, -2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _messageController,
                                            decoration: InputDecoration(
                                              hintText: 'Type a message...',
                                              filled: true,
                                              fillColor: AppColors.grey100,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 14,
                                              ),
                                            ),
                                            onSubmitted: (_) => _sendMessage(),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Material(
                                          color: AppColors.primaryGreen,
                                          borderRadius: BorderRadius.circular(14),
                                          child: InkWell(
                                            onTap: _sendMessage,
                                            borderRadius: BorderRadius.circular(14),
                                            child: Container(
                                              padding: const EdgeInsets.all(14),
                                              child: const Icon(
                                                Icons.send_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
