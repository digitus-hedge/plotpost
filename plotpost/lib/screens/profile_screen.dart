import 'package:flutter/material.dart';

import '../data/sample_posts.dart';
import '../models/property_post.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/property_post_card.dart';
import 'account_settings_screen.dart';
import 'create_post_screen.dart';
import 'edit_profile_screen.dart';
import 'inquiries_screen.dart';
import 'my_listings_screen.dart';
import 'property_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userPosts,
    required this.onPublishPost,
  });

  final List<PropertyPost> userPosts;
  final PostPublisher onPublishPost;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filled from the logged-in account; empty until loaded.
  String _name = 'PlotPost User';
  String _email = '';
  String _phone = '';
  String _bio = '';
  String _location = '';
  String _agency = '';
  String _role = '';
  String _profileImage = '';
  bool _isVerified = false;

  void _applyUser(Map<String, dynamic> user) {
    String text(String key) => user[key]?.toString() ?? '';
    if (text('name').isNotEmpty) _name = text('name');
    _email = text('email');
    _phone = text('phone');
    _bio = text('bio');
    _agency = text('agency');
    _role = text('designation');
    _location = text('location');
    _profileImage = text('profileImage');
    _isVerified = user['isEmailVerified'] == true;
  }

  static String _orNotAdded(String value) =>
      value.trim().isEmpty ? 'Not added yet' : value;

  List<PropertyPost> _fetchedUserPosts = [];
  int _inquiriesCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCachedUserFirst();
    _loadProfileData(showLoading: false);
  }

  Future<void> _loadCachedUserFirst() async {
    final cachedUser = await ApiService.getUser();
    if (mounted && cachedUser != null) {
      setState(() => _applyUser(cachedUser));
    }
  }

  Future<void> _loadProfileData({bool showLoading = false}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getMyPosts(),
        ApiService.getMyEnquiriesCount(),
      ]);

      final profileRes = results[0] as Map<String, dynamic>;
      final userPosts = results[1] as List<PropertyPost>;
      final enquiriesCount = results[2] as int;

      if (mounted) {
        if (profileRes['success'] == true && profileRes['user'] != null) {
          _applyUser(profileRes['user'] as Map<String, dynamic>);
        }

        _fetchedUserPosts = userPosts;
        _inquiriesCount = enquiriesCount;
        _isLoading = false;
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          onPublish: (post, images) async {
            final result = await widget.onPublishPost(post, images);
            _loadProfileData();
            return result;
          },
        ),
      ),
    );
  }

  void _openPostDetails(PropertyPost post) {
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

  void _openEditProfile() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: _name,
          initialEmail: _email,
          initialPhone: _phone,
          initialBio: _bio,
          initialAgency: _agency,
          initialRole: _role,
          initialLocation: _location,
          initialProfileImage: _profileImage,
          onSaved: (updated) {
            setState(() {
              if (updated['name']?.isNotEmpty ?? false) {
                _name = updated['name']!;
              }
              _phone = updated['phone'] ?? _phone;
              _bio = updated['bio'] ?? _bio;
              _agency = updated['agency'] ?? _agency;
              _role = updated['role'] ?? _role;
              _location = updated['location'] ?? _location;
              _profileImage = updated['profileImage'] ?? _profileImage;
            });
          },
        ),
      ),
    );

    if (result != null) {
      _loadProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final allUserPosts = <PropertyPost>[
      ...widget.userPosts,
      ..._fetchedUserPosts,
      if (widget.userPosts.isEmpty && _fetchedUserPosts.isEmpty) ...[
        posts[0],
        posts[4],
      ],
    ];

    final nameParts = _name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final initials = nameParts.isNotEmpty
        ? (nameParts.length > 1
                  ? '${nameParts[0][0]}${nameParts[1][0]}'
                  : nameParts[0].substring(0, 1))
              .toUpperCase()
        : 'PU';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: Icon(
              Icons.settings_outlined,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Header Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      backgroundImage:
                                          _profileImage.startsWith('http')
                                          ? NetworkImage(_profileImage)
                                          : null,
                                      child: _profileImage.startsWith('http')
                                          ? null
                                          : Text(
                                              initials,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: theme
                                                    .colorScheme
                                                    .onPrimary,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                ),
                                              ),
                                              if (_isVerified) ...[
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.verified_rounded,
                                                  size: 16,
                                                  color: theme
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (_role.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              _role,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: plotPostTextAccent(
                                                  context,
                                                  theme.colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (_location.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 14,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                _location,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Metric Highlights
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard(
                                        '${allUserPosts.length}',
                                        'Listed',
                                        Icons.home_work_outlined,
                                        theme,
                                        onTap: () =>
                                            _openListingsScreen(allUserPosts),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildMetricCard(
                                        '$_inquiriesCount',
                                        'Inquiries',
                                        Icons.chat_outlined,
                                        theme,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const InquiriesScreen(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildMetricCard(
                                        '4.9',
                                        'Rating',
                                        Icons.star_outline_rounded,
                                        theme,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Primary Action: Add New Listing
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _openCreatePost,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 20,
                              ),
                              label: const Text(
                                'Post a New Property',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Tab Bar: My Listings vs Activity
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: theme.colorScheme.primary,
                        indicatorWeight: 2,
                        labelColor: theme.colorScheme.onSurface,
                        unselectedLabelColor:
                            theme.colorScheme.onSurfaceVariant,
                        labelStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                        tabs: const [
                          Tab(text: 'My Listings'),
                          Tab(text: 'Account Details'),
                        ],
                      ),
                      theme,
                    ),
                  ),
                ];
              },

              // Tab Content
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: My Property Listings
                  RefreshIndicator(
                    color: theme.colorScheme.primary,
                    onRefresh: _loadProfileData,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                      itemCount: allUserPosts.length,
                      itemBuilder: (context, index) {
                        final post = allUserPosts[index];
                        return PropertyPostCard(
                          key: ValueKey(post.storageKey),
                          post: post,
                          onTap: () => _openPostDetails(post),
                        );
                      },
                    ),
                  ),

                  // Tab 2: Account Details & Contact Card
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoTile(
                        'Phone Number',
                        _orNotAdded(_phone),
                        Icons.phone_outlined,
                        theme,
                      ),
                      _buildInfoTile(
                        'Email Address',
                        _orNotAdded(_email),
                        Icons.email_outlined,
                        theme,
                      ),
                      _buildInfoTile(
                        'Office / Agency',
                        _orNotAdded(
                          [_agency, _location]
                              .where((s) => s.trim().isNotEmpty)
                              .join(', '),
                        ),
                        Icons.business_outlined,
                        theme,
                      ),
                      _buildInfoTile(
                        'Bio',
                        _orNotAdded(_bio),
                        Icons.info_outline_rounded,
                        theme,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _openEditProfile,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Account Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  void _openListingsScreen(List<PropertyPost> allUserPosts) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyListingsScreen(
          userPosts: allUserPosts,
          onPublishPost: widget.onPublishPost,
          onDeletePost: (post) {
            setState(() {
              widget.userPosts.remove(post);
              _fetchedUserPosts.remove(post);
            });
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String value,
    String label,
    IconData icon,
    ThemeData theme, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar, this._theme);

  final TabBar _tabBar;
  final ThemeData _theme;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _theme.scaffoldBackgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
