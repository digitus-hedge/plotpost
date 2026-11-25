import 'package:flutter/material.dart';

import '../models/property_post.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/property_icon_helper.dart';
import '../widgets/property_image.dart';
import 'create_post_screen.dart';
import 'edit_post_screen.dart';
import 'property_details_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({
    super.key,
    required this.userPosts,
    required this.onPublishPost,
    required this.onDeletePost,
  });

  final List<PropertyPost> userPosts;
  final PostPublisher onPublishPost;
  final ValueChanged<PropertyPost> onDeletePost;

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  String _activeFilter = 'All';

  void _openCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(onPublish: widget.onPublishPost),
      ),
    );
  }

  void _openDetails(PropertyPost post) {
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

  void _confirmDelete(PropertyPost post) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to remove "${post.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFED4956),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onDeletePost(post);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Property listing removed.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filters = ['All', 'Active', 'For sale', 'For rent'];

    final filtered = widget.userPosts.where((post) {
      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'Active') return true;
      return post.deal == _activeFilter;
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
          'My Listed Properties',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Property',
            icon: Icon(
              Icons.add_circle_outline_rounded,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            onPressed: _openCreatePost,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subheader Banner & Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.userPosts.length} ${widget.userPosts.length == 1 ? 'property' : 'properties'} currently listed',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: filters.map((filter) {
                      final isSelected = _activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary.withValues(
                            alpha: 0.18,
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.4,
                                  )
                                : (isDark
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFE2E8F0)),
                            width: 0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (_) =>
                              setState(() => _activeFilter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Property Listings Feed
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_work_outlined,
                            size: 52,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No property listings found',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap the button below to post and publish your first property listing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _openCreatePost,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Post a Property'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: theme.colorScheme.primary,
                    onRefresh: () async {
                      await Future<void>.delayed(const Duration(milliseconds: 700));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final post = filtered[index];
                        return KeyedSubtree(
                          key: ValueKey(post.storageKey),
                          child: _buildListingCard(post, theme),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(PropertyPost post, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image / Video Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 88,
                    height: 88,
                    color: post.color,
                    child: post.imagePaths.isNotEmpty
                        ? PropertyImage(
                            path: post.imagePaths.first,
                            fit: BoxFit.cover,
                            cacheWidth: 300,
                            errorBuilder: (_, _, _) => Container(
                              color: post.color,
                              child: Icon(
                                PropertyIconHelper.getPropertyTypeIcon(post.type),
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              post.video
                                  ? Icons.play_circle_fill_rounded
                                  : PropertyIconHelper.getPropertyTypeIcon(post.type),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Active Listing',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: plotPostTextAccent(
                                  context,
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            post.age,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.price.isNotEmpty ? post.price : 'Price on request',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: plotPostTextAccent(
                            context,
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),

          // Actions Row (View, Edit, Delete)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openDetails(post),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditPostScreen(
                          post: post,
                          onUpdated: (updatedPost) async {
                            try {
                              await widget.onPublishPost(updatedPost, const []);
                            } catch (error) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Could not save post: $error',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFED4956),
                  ),
                  onPressed: () => _confirmDelete(post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
