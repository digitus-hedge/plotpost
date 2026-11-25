import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/property_post.dart';
import '../theme/property_icon_helper.dart';
import 'property_image.dart';
import 'comments_modal_sheet.dart';
import 'report_post_modal.dart';
import 'share_post_modal_sheet.dart';

class PropertyPostCard extends StatefulWidget {
  const PropertyPostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.isSaved = false,
    this.onToggleSaved,
  });

  final PropertyPost post;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback? onToggleSaved;

  @override
  State<PropertyPostCard> createState() => _PropertyPostCardState();
}

class _PropertyPostCardState extends State<PropertyPostCard> {
  bool _isLiked = false;
  int _likeCount = 42;
  bool _showHeartOverlay = false;

  @override
  void initState() {
    super.initState();
    _likeCount = 40 + (widget.post.title.length * 3) % 150;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
    });
  }

  void _onDoubleTapPhoto() {
    if (!_isLiked) {
      setState(() {
        _isLiked = true;
        _likeCount++;
      });
    }

    setState(() => _showHeartOverlay = true);

    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) {
        setState(() => _showHeartOverlay = false);
      }
    });
  }

  String? get _displayImage {
    if (widget.post.imagePaths.isNotEmpty) {
      return widget.post.imagePaths.first;
    }
    if (widget.post.socialUrl.isNotEmpty) {
      final url = widget.post.socialUrl.trim();
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final pathLower = uri.path.toLowerCase();
        if (pathLower.endsWith('.jpg') ||
            pathLower.endsWith('.jpeg') ||
            pathLower.endsWith('.png') ||
            pathLower.endsWith('.webp') ||
            pathLower.endsWith('.gif') ||
            url.startsWith('data:image/')) {
          return url;
        }
        if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
          String? videoId;
          if (uri.host.contains('youtu.be')) {
            if (uri.pathSegments.isNotEmpty) videoId = uri.pathSegments.first;
          } else if (uri.pathSegments.contains('shorts') &&
              uri.pathSegments.length >= 2) {
            videoId = uri.pathSegments[uri.pathSegments.indexOf('shorts') + 1];
          } else {
            videoId = uri.queryParameters['v'];
          }
          if (videoId != null && videoId.isNotEmpty) {
            return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
          }
        }
      }
    }
    return null;
  }

  bool get _isVideo {
    if (widget.post.video) return true;
    final url = widget.post.socialUrl.toLowerCase();
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('/reel/') ||
        url.contains('/reels/') ||
        url.contains('/shorts/') ||
        url.contains('/watch');
  }

  void _showPostOptionsMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181B22) : theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.copy_rounded, size: 20),
                title: const Text(
                  'Copy property details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  final lines = [
                    widget.post.title,
                    'Price: ${widget.post.price.isEmpty ? 'Price on request' : widget.post.price}',
                    'Type: ${widget.post.type} · ${widget.post.deal}',
                    if (widget.post.location.isNotEmpty)
                      'Location: ${widget.post.location}',
                  ];
                  Clipboard.setData(ClipboardData(text: lines.join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listing details copied to clipboard.'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.flag_outlined,
                  color: Color(0xFFED4956),
                  size: 20,
                ),
                title: const Text(
                  'Report this post',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFFED4956),
                  ),
                ),
                subtitle: const Text(
                  'Flag fake, spam, or inappropriate content',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  showReportPostModal(context, widget.post);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;

    final shortLoc = post.shortLocation;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.scaffoldBackgroundColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.surface,
                          child: Text(
                            post.initials,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.seller,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (shortLoc.isNotEmpty)
                        Text(
                          shortLoc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface,
                            height: 1.2,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: () => _showPostOptionsMenu(context),
                  tooltip: 'Post options',
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: widget.onTap,
            onDoubleTap: _onDoubleTapPhoto,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: _displayImage != null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: PropertyImage(
                                  path: _displayImage!,
                                  fit: BoxFit.cover,
                                  cacheWidth: 800,
                                  errorBuilder: (_, _, _) => Container(
                                    color: post.color,
                                    child: Icon(
                                      PropertyIconHelper.getPropertyTypeIcon(
                                        post.type,
                                      ),
                                      size: 48,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              if (_isVideo)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                                ),
                            ],
                          )
                        : Container(
                            color: post.color,
                            child: Center(
                              child: Icon(
                                _isVideo
                                    ? Icons.play_circle_fill_rounded
                                    : PropertyIconHelper.getPropertyTypeIcon(
                                        post.type,
                                      ),
                                size: 52,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                  ),

                  if (_showHeartOverlay)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showHeartOverlay ? 1.0 : 0.0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFED4956),
                          size: 72,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleLike,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 3, 4),
                    child: Icon(
                      _isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 24,
                      color: _isLiked
                          ? const Color(0xFFED4956)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showCommentsModalSheet(context, widget.post),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 4,
                    ),
                    child: PropertyIconHelper.commentImageAsset(
                      size: 21,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showSharePostModalSheet(context, widget.post),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 4,
                    ),
                    child: PropertyIconHelper.shareImageAsset(
                      size: 19,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),

                const Spacer(),

                if (widget.onToggleSaved != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onToggleSaved,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 4, 0, 4),
                      child: Icon(
                        widget.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 24,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_likeCount likes',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${post.seller} ',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: post.title,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (post.price.isNotEmpty ||
                    post.type.isNotEmpty ||
                    post.deal.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (post.price.isNotEmpty) post.price,
                      if (post.type.isNotEmpty) post.type,
                      if (post.deal.isNotEmpty) post.deal,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () => showCommentsModalSheet(context, widget.post),
                  child: Text(
                    'View all 3 comments',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  post.age.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.3,
                    color: theme.colorScheme.onSurfaceVariant,
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
