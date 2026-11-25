import 'package:flutter/material.dart';

import '../data/sample_posts.dart';
import '../models/property_post.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.userName,
    required this.userAvatarInitials,
    required this.lastMessage,
    required this.timeAgo,
    this.isOnline = false,
    this.isUnread = false,
    this.post,
  });

  final String id;
  final String userName;
  final String userAvatarInitials;
  final String lastMessage;
  final String timeAgo;
  final bool isOnline;
  final bool isUnread;
  final PropertyPost? post;
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Conversation> _conversations = [
    Conversation(
      id: '1',
      userName: 'Ravi Kumar',
      userAvatarInitials: 'RK',
      lastMessage: 'Is the 3 BHK villa near Mananchira still available?',
      timeAgo: '10m',
      isOnline: true,
      isUnread: true,
      post: posts[0],
    ),
    Conversation(
      id: '2',
      userName: 'Prime Plots Kerala',
      userAvatarInitials: 'PP',
      lastMessage:
          'Yes, 10 cent plot has 20 ft road access. When can you visit?',
      timeAgo: '1h',
      isOnline: true,
      isUnread: true,
      post: posts[1],
    ),
    Conversation(
      id: '3',
      userName: 'Green Acre Realty',
      userAvatarInitials: 'GA',
      lastMessage: 'Monthly rent for 2 BHK is ₹18,000 including maintenance.',
      timeAgo: '3h',
      isOnline: false,
      post: posts[2],
    ),
    Conversation(
      id: '4',
      userName: 'Home Tours Calicut',
      userAvatarInitials: 'HT',
      lastMessage: 'Sent a video tour of 9th floor flat • 1d',
      timeAgo: '1d',
      isOnline: false,
      post: posts[3],
    ),
    Conversation(
      id: '5',
      userName: 'Calicut Homes',
      userAvatarInitials: 'CH',
      lastMessage: 'Thanks for inquiring! 6 units remain in Mavoor Road.',
      timeAgo: '2d',
      isOnline: false,
      post: posts[4],
    ),
    Conversation(
      id: '6',
      userName: 'Anil Kumar',
      userAvatarInitials: 'AK',
      lastMessage: 'House has parking space for two large cars.',
      timeAgo: '4d',
      isOnline: false,
      post: posts[5],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChat(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          userName: conversation.userName,
          userInitials: conversation.userAvatarInitials,
          isOnline: conversation.isOnline,
          post: conversation.post,
          initialMessage: conversation.lastMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _conversations.where((conv) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return conv.userName.toLowerCase().contains(query) ||
          conv.lastMessage.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Direct Messages',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New message',
            icon: Icon(
              Icons.edit_note_rounded,
              size: 26,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NewMessageScreen(recipients: _conversations),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Instagram Search Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13.5,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF262626)
                    : const Color(0xFFEFEFEF),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // Active Notes / Story Tray
          SizedBox(
            height: 82,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNoteAvatar('Your note', '＋', theme, isDark, isSelf: true),
                _buildNoteAvatar(
                  'Ravi K.',
                  'RK',
                  theme,
                  isDark,
                  isOnline: true,
                ),
                _buildNoteAvatar(
                  'Prime P.',
                  'PP',
                  theme,
                  isDark,
                  isOnline: true,
                ),
                _buildNoteAvatar('Green A.', 'GA', theme, isDark),
                _buildNoteAvatar('Home T.', 'HT', theme, isDark),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Messages List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  'Requests',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: plotPostTextAccent(
                      context,
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Conversations List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No messages found',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: theme.colorScheme.primary,
                    onRefresh: () async {
                      await Future<void>.delayed(const Duration(milliseconds: 700));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final conv = filtered[index];
                        return _buildConversationTile(conv, theme, isDark);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteAvatar(
    String label,
    String initials,
    ThemeData theme,
    bool isDark, {
    bool isSelf = false,
    bool isOnline = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 14),
      width: 62,
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: isDark
                    ? const Color(0xFF262626)
                    : const Color(0xFFEFEFEF),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
    Conversation conv,
    ThemeData theme,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => _openChat(conv),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Row(
          children: [
            // User Avatar with Online Dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: isDark
                      ? const Color(0xFF262626)
                      : const Color(0xFFEFEFEF),
                  child: Text(
                    conv.userAvatarInitials,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (conv.isOnline)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Message Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.userName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: conv.isUnread
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${conv.lastMessage} • ${conv.timeAgo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: conv.isUnread
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: conv.isUnread
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
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

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key, required this.recipients});

  final List<Conversation> recipients;

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startConversation(Conversation recipient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          userName: recipient.userName,
          userInitials: recipient.userAvatarInitials,
          isOnline: recipient.isOnline,
          post: recipient.post,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final recipients = widget.recipients
        .where((recipient) => recipient.userName.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'New message',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search people',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Suggested',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: recipients.isEmpty
                ? Center(
                    child: Text(
                      'No people found',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: recipients.length,
                    itemBuilder: (context, index) {
                      final recipient = recipients[index];
                      return ListTile(
                        onTap: () => _startConversation(recipient),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            recipient.userAvatarInitials,
                            style: TextStyle(
                              color: plotPostTextAccent(
                                context,
                                theme.colorScheme.primary,
                              ),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          recipient.userName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          recipient.post?.shortLocation ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: recipient.isOnline
                            ? const Icon(
                                Icons.circle,
                                size: 9,
                                color: Color(0xFF10B981),
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
