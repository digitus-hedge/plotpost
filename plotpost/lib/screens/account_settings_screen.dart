import 'package:flutter/material.dart';

import '../data/sample_posts.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_field.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';
import 'inquiries_screen.dart';
import 'my_listings_screen.dart';
import 'terms_privacy_screen.dart';
import 'verify_code_screen.dart';
import 'welcome_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailInquiries = true;
  bool _showPhoneOnListings = true;

  Map<String, dynamic> _user = const {};

  String _text(String key) => _user[key]?.toString() ?? '';

  String get _initials {
    final parts = _text('name')
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'PU';
    return (parts.length > 1 ? '${parts[0][0]}${parts[1][0]}' : parts[0][0])
        .toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final cached = await ApiService.getUser();
    if (cached != null && mounted) _applyUser(cached);
    final res = await ApiService.getProfile();
    if (mounted && res['success'] == true && res['user'] is Map<String, dynamic>) {
      _applyUser(res['user'] as Map<String, dynamic>);
    }
  }

  void _applyUser(Map<String, dynamic> user) {
    final settings = user['settings'] is Map ? user['settings'] as Map : const {};
    setState(() {
      _user = user;
      _pushNotifications = settings['pushNotifications'] != false;
      _emailInquiries = settings['emailInquiries'] != false;
      _showPhoneOnListings = settings['showPhoneNumber'] != false;
    });
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  /// Flips the switch right away and undoes it if the server says no.
  Future<void> _saveSetting(
    String key,
    bool value,
    void Function(bool) apply,
  ) async {
    setState(() => apply(value));
    final res = await ApiService.updateSettings({key: value});
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() => apply(!value));
      _snack(res['message']?.toString() ?? 'Could not save the setting.', error: true);
    }
  }

  Future<void> _openEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: _text('name'),
          initialEmail: _text('email'),
          initialPhone: _text('phone'),
          initialBio: _text('bio'),
          initialAgency: _text('agency'),
          initialRole: _text('designation'),
          initialLocation: _text('location'),
          initialProfileImage: _text('profileImage'),
        ),
      ),
    );
    final cached = await ApiService.getUser();
    if (cached != null && mounted) _applyUser(cached);
  }

  Future<void> _verifyEmail() async {
    final res = await ApiService.resendVerification();
    if (!mounted) return;
    if (res['success'] != true) {
      _snack(res['message']?.toString() ?? 'Could not send a code.', error: true);
      return;
    }
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VerifyCodeScreen(
          purpose: CodePurpose.verifyEmail,
          email: _text('email'),
          continueToApp: false,
        ),
      ),
    );
    if (verified == true) await _loadUser();
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    var saving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Change password'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthField(
                    controller: current,
                    hint: 'Current password',
                    icon: Icons.lock_outline_rounded,
                    obscure: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leave empty if you signed up with Google and never set a password.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthField(
                    controller: next,
                    hint: 'New password',
                    icon: Icons.lock_reset_rounded,
                    obscure: true,
                    validator: validateNewPassword,
                  ),
                  const SizedBox(height: 12),
                  AuthField(
                    controller: confirm,
                    hint: 'Confirm new password',
                    icon: Icons.lock_reset_rounded,
                    obscure: true,
                    validator: (val) =>
                        val != next.text ? 'Passwords do not match' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      final res = await ApiService.changePassword(
                        currentPassword: current.text,
                        newPassword: next.text,
                      );
                      if (!dialogContext.mounted) return;
                      setDialogState(() => saving = false);
                      if (res['success'] == true) {
                        Navigator.pop(dialogContext);
                        if (mounted) {
                          _snack('Password changed. Other devices have been logged out.');
                        }
                      } else if (mounted) {
                        _snack(
                          res['message']?.toString() ?? 'Could not change the password.',
                          error: true,
                        );
                      }
                    },
              child: Text(saving ? 'Saving…' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final confirmation = TextEditingController();
    var deleting = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Delete account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your account, your property posts and '
                'their photos, and your enquiries. It cannot be undone.',
              ),
              const SizedBox(height: 14),
              AuthField(
                controller: confirmation,
                hint: 'Your password (or type DELETE)',
                icon: Icons.lock_outline_rounded,
                obscure: true,
              ),
              const SizedBox(height: 4),
              Text(
                'If you sign in with Google and have no password, type DELETE.',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: deleting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFED4956),
              ),
              onPressed: deleting
                  ? null
                  : () async {
                      if (confirmation.text.isEmpty) return;
                      setDialogState(() => deleting = true);
                      final res = await ApiService.deleteAccount(confirmation.text);
                      if (!dialogContext.mounted) return;
                      setDialogState(() => deleting = false);
                      if (res['success'] == true) {
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        _snack('Your account has been deleted.');
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                          (route) => false,
                        );
                      } else if (mounted) {
                        _snack(
                          res['message']?.toString() ?? 'Could not delete the account.',
                          error: true,
                        );
                      }
                    },
              child: Text(deleting ? 'Deleting…' : 'Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of PlotPost?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFED4956),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ApiService.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          'Settings',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Account Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: _text('profileImage').startsWith('http')
                      ? NetworkImage(_text('profileImage'))
                      : null,
                  child: _text('profileImage').startsWith('http')
                      ? null
                      : Text(
                          _initials,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _text('name').isEmpty ? 'PlotPost User' : _text('name'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (_user['isEmailVerified'] == true) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _text('email'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_text('designation').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _text('designation'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: plotPostTextAccent(
                              context,
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 1: Appearance & Preferences
          _buildSectionHeader('Appearance & Preferences', theme),
          _themeSelectorTile(theme, isDark),
          _buildSwitchTile(
            'Push Notifications',
            'Receive alerts for buyer inquiries and price drops',
            Icons.notifications_none_rounded,
            _pushNotifications,
            (val) => _saveSetting('pushNotifications', val, (v) => _pushNotifications = v),
            theme,
            isDark,
          ),
          _buildSwitchTile(
            'Email Inquiries',
            'Receive copies of messages in your email inbox',
            Icons.email_outlined,
            _emailInquiries,
            (val) => _saveSetting('emailInquiries', val, (v) => _emailInquiries = v),
            theme,
            isDark,
          ),

          const SizedBox(height: 20),

          // Section 2: Account & Security
          _buildSectionHeader('Account & Security', theme),
          _buildNavigationTile(
            'Edit Profile Details',
            'Name, agency, phone number and location',
            Icons.person_outline_rounded,
            _openEditProfile,
            theme,
            isDark,
          ),
          _buildSwitchTile(
            'Show Phone Number',
            'Display contact number publicly on property listings',
            Icons.phone_outlined,
            _showPhoneOnListings,
            (val) => _saveSetting('showPhoneNumber', val, (v) => _showPhoneOnListings = v),
            theme,
            isDark,
          ),
          if (_user.isNotEmpty && _user['isEmailVerified'] != true)
            _buildNavigationTile(
              'Verify Email Address',
              'Get a 6-digit code at ${_text('email')}',
              Icons.mark_email_unread_outlined,
              _verifyEmail,
              theme,
              isDark,
            ),
          _buildNavigationTile(
            'Change Password',
            'Update account login password',
            Icons.lock_outline_rounded,
            _showChangePasswordDialog,
            theme,
            isDark,
          ),
          _buildNavigationTile(
            'Delete Account',
            'Permanently remove your account and listings',
            Icons.delete_outline_rounded,
            _showDeleteAccountDialog,
            theme,
            isDark,
          ),

          const SizedBox(height: 20),

          // Section 3: Property & Listings
          _buildSectionHeader('Listings & Leads', theme),
          _buildNavigationTile(
            'Manage My Postings',
            'View, edit or archive your published properties',
            Icons.home_work_outlined,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MyListingsScreen(
                  userPosts: posts,
                  onPublishPost: (post, _) async => post,
                  onDeletePost: (_) {},
                ),
              ),
            ),
            theme,
            isDark,
          ),
          _buildNavigationTile(
            'Auto-Reply Settings',
            'Configure automatic responses for buyer inquiries',
            Icons.reply_rounded,
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const InquiriesScreen())),
            theme,
            isDark,
          ),

          const SizedBox(height: 20),

          // Section 4: Support & Legal
          _buildSectionHeader('Support & Legal', theme),
          _buildNavigationTile(
            'Help Center & FAQs',
            'Get support or read guide articles',
            Icons.help_outline_rounded,
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
            theme,
            isDark,
          ),
          _buildNavigationTile(
            'Privacy Policy & Terms',
            'Read PlotPost terms of service',
            Icons.privacy_tip_outlined,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()),
            ),
            theme,
            isDark,
          ),

          const SizedBox(height: 24),

          // Log Out Button
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(
                Icons.logout_rounded,
                size: 20,
                color: Color(0xFFED4956),
              ),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFED4956),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: const Color(0xFFED4956).withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Version Footer
          Center(
            child: Text(
              'PlotPost v1.0.0 (Build 1) • Created by Digit-us',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _themeSelectorTile(ThemeData theme, bool isDark) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: plotPostThemeMode,
      builder: (context, currentMode, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'App Theme Mode',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildThemeOption(
                    'Dark',
                    ThemeMode.dark,
                    currentMode,
                    theme,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    'Light',
                    ThemeMode.light,
                    currentMode,
                    theme,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    'System',
                    ThemeMode.system,
                    currentMode,
                    theme,
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    String label,
    ThemeMode mode,
    ThemeMode currentMode,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setPlotPostThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.18)
                : (isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
