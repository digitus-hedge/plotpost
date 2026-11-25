import 'package:flutter/material.dart';

import '../data/sample_posts.dart';
import '../models/property_post.dart';
import 'property_details_screen.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userName,
    required this.userAvatarInitials,
    required this.actionText,
    required this.timeAgo,
    required this.section,
    this.post,
    this.hasActionButton = false,
    this.actionButtonLabel = 'View',
    this.isUnread = false,
  });

  final String id;
  final String userName;
  final String userAvatarInitials;
  final String actionText;
  final String timeAgo;
  final String section; // 'Today', 'Yesterday', 'This Week', 'Earlier'
  final PropertyPost? post;
  final bool hasActionButton;
  final String actionButtonLabel;
  final bool isUnread;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      NotificationItem(
        id: '1',
        userName: 'Ravi Kumar',
        userAvatarInitials: 'RK',
        actionText: 'liked your 3 BHK villa listing in Mananchira.',
        timeAgo: '2h',
        section: 'Today',
        post: posts[0],
        isUnread: true,
      ),
      NotificationItem(
        id: '2',
        userName: 'Green Acre Realty',
        userAvatarInitials: 'GA',
        actionText: 'sent an enquiry regarding your 2 BHK apartment post.',
        timeAgo: '5h',
        section: 'Today',
        post: posts[2],
        hasActionButton: true,
        actionButtonLabel: 'Reply',
        isUnread: true,
      ),
      NotificationItem(
        id: '3',
        userName: 'Prime Plots Kerala',
        userAvatarInitials: 'PP',
        actionText: 'posted a new 10 cent plot in Chevayur.',
        timeAgo: 'Yesterday',
        section: 'Yesterday',
        post: posts[1],
        hasActionButton: true,
        actionButtonLabel: 'View',
      ),
      NotificationItem(
        id: '4',
        userName: 'Home Tours Calicut',
        userAvatarInitials: 'HT',
        actionText: 'updated the price on 3 BHK flat with sea view.',
        timeAgo: '2d',
        section: 'This Week',
        post: posts[3],
      ),
      NotificationItem(
        id: '5',
        userName: 'Calicut Homes',
        userAvatarInitials: 'CH',
        actionText: 'bookmarked your gated villa listing on Mavoor Road.',
        timeAgo: '3d',
        section: 'This Week',
        post: posts[4],
        hasActionButton: true,
        actionButtonLabel: 'Contact',
      ),
      NotificationItem(
        id: '6',
        userName: 'Anil Kumar',
        userAvatarInitials: 'AK',
        actionText: 'started following your property updates.',
        timeAgo: '5d',
        section: 'This Week',
        hasActionButton: true,
        actionButtonLabel: 'Follow',
      ),
      NotificationItem(
        id: '7',
        userName: 'PlotPost System',
        userAvatarInitials: 'PP',
        actionText: 'Welcome to PlotPost! Discover and post properties easily.',
        timeAgo: '1w',
        section: 'Earlier',
      ),
    ];
  }

  void _openPost(PropertyPost? post) {
    if (post == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(
          post: post,
          isSaved: false,
          fallbackLocation: 'Kozhikode',
          onToggleSaved: () {},
          onShowInterest: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sections = ['Today', 'Yesterday', 'This Week', 'Earlier'];

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
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 700));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: sections.map((sectionName) {
            final items = _notifications
                .where((item) => item.section == sectionName)
                .toList();

            if (items.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    sectionName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...items.map(
                  (item) => _buildNotificationTile(item, theme, isDark),
                ),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    NotificationItem item,
    ThemeData theme,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        if (item.isUnread) {
          setState(() {
            _notifications = _notifications.map((n) {
              return n.id == item.id
                  ? NotificationItem(
                      id: n.id,
                      userName: n.userName,
                      userAvatarInitials: n.userAvatarInitials,
                      actionText: n.actionText,
                      timeAgo: n.timeAgo,
                      section: n.section,
                      post: n.post,
                      hasActionButton: n.hasActionButton,
                      actionButtonLabel: n.actionButtonLabel,
                      isUnread: false,
                    )
                  : n;
            }).toList();
          });
        }
        _openPost(item.post);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // User Avatar with Story Ring / Initial
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: item.isUnread
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF60A5FA),
                          Color(0xFF1E40AF),
                          Color(0xFF000000),
                        ],
                      )
                    : null,
                color: item.isUnread
                    ? null
                    : (isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFDBDBDB)),
              ),
              child: CircleAvatar(
                radius: 21,
                backgroundColor: isDark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFEFEFEF),
                child: Text(
                  item.userAvatarInitials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text Content
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.userName} ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: item.actionText,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: '  ${item.timeAgo}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            // Right Side Action Button or Thumbnail
            if (item.hasActionButton)
              SizedBox(
                height: 32,
                child: FilledButton(
                  onPressed: () {
                    if (item.actionButtonLabel == 'Reply' ||
                        item.actionButtonLabel == 'Contact') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Contact ${item.userName} connected.'),
                        ),
                      );
                    } else if (item.post != null) {
                      _openPost(item.post);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(item.actionButtonLabel),
                ),
              )
            else if (item.post != null)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: item.post!.color,
                ),
                child: const Icon(
                  Icons.home_work_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
