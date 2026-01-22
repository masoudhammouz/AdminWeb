import 'dart:async';
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

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  List<dynamic> _conversations = [];
  String? _selectedConversationId;
  List<dynamic> _messages = [];
  final _messageController = TextEditingController();
  bool _isLoading = true;
  Timer? _conversationsPollingTimer;
  Timer? _messagesPollingTimer;
  bool _isScreenVisible = true;

  String _initialFor(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConversations();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _conversationsPollingTimer?.cancel();
    _messagesPollingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isScreenVisible = state == AppLifecycleState.resumed;
    if (_isScreenVisible) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    _stopPolling();
    if (!mounted) return;
    
    // Poll conversations every 5 seconds
    _conversationsPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_isScreenVisible) {
        timer.cancel();
        return;
      }
      _loadConversations(silent: true);
    });
    
    // Poll messages every 3 seconds if conversation is selected
    _messagesPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_isScreenVisible || _selectedConversationId == null) {
        return;
      }
      _loadMessages(_selectedConversationId!, silent: true);
    });
  }

  void _stopPolling() {
    _conversationsPollingTimer?.cancel();
    _messagesPollingTimer?.cancel();
    _conversationsPollingTimer = null;
    _messagesPollingTimer = null;
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    final result = await ChatService.getAllConversations();
    if (result['success'] == true) {
      final data = result['data'];
      final newConversations = data is Map
          ? (data['data'] as List<dynamic>? ?? [])
          : (data is List ? data : []);
      
      // Check if conversations changed
      final conversationsChanged = _conversations.length != newConversations.length ||
          (newConversations.isNotEmpty && _conversations.isNotEmpty &&
           newConversations.first['_id'] != _conversations.first['_id']);
      
      if (conversationsChanged || !silent) {
        setState(() {
          _conversations = newConversations;
          _isLoading = false;
        });
      } else if (!silent) {
        setState(() => _isLoading = false);
      }
    } else {
      if (!silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMessages(String conversationId, {bool silent = false}) async {
    if (!silent) {
      setState(() {
        _selectedConversationId = conversationId;
        _isLoading = true;
      });
    }
    final result = await ChatService.getMessages(conversationId);
    if (result['success'] == true) {
      final data = result['data'];
      final newMessages = data is Map
          ? (data['data'] as List<dynamic>? ?? [])
          : (data is List ? data : []);
      
      // Check if messages changed
      final messagesChanged = _messages.length != newMessages.length ||
          (newMessages.isNotEmpty && _messages.isNotEmpty &&
           newMessages.last['_id'] != _messages.last['_id']);
      
      if (messagesChanged || !silent) {
        setState(() {
          _messages = newMessages;
          _isLoading = false;
        });
        if (messagesChanged && !silent) {
          // Mark as read only on manual load
          await ChatService.markAsRead(conversationId);
          _loadConversations(); // Refresh to update unread count
        }
      } else if (!silent) {
        setState(() => _isLoading = false);
      }
    } else {
      if (!silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedConversationId == null) return;
    
    final content = _messageController.text.trim();
    _messageController.clear();
    
    final result = await ChatService.sendMessage(_selectedConversationId!, content);
    if (result['success'] == true) {
      _loadMessages(_selectedConversationId!, silent: false);
      _loadConversations(silent: false);
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.beige,
        body: Row(
          children: [
            Sidebar(currentRoute: '/chat'),
            Expanded(
              child: Column(
                children: [
                  const app_bar.AppBar(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
                          tooltip: 'Back to Dashboard',
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Support Chat',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ],
                    ),
                  ),
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
                                                  backgroundImage: (user?['profilePicture'] as String?)?.isNotEmpty == true
                                                      ? NetworkImage(user?['profilePicture'] as String)
                                                      : null,
                                                  child: (user?['profilePicture'] as String?)?.isNotEmpty == true
                                                      ? null
                                                      : Text(
                                                          _initialFor(user?['name'] as String?),
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
                                              Map<String, dynamic>? sender;
                                              final rawSender = msg['senderId'];
                                              if (rawSender is Map<String, dynamic>) {
                                                sender = rawSender;
                                              } else if (rawSender is Map) {
                                                sender = Map<String, dynamic>.from(rawSender);
                                              }
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
    ),
    );
  }
}
