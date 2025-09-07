import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:godarna/services/admin_service.dart';
import 'package:godarna/widgets/admin/admin_search_bar.dart';
import 'package:godarna/widgets/common/app_app_bar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  String _searchQuery = '';

  bool _loading = true;
  bool _updating = false;
  final int _pageSize = 20;
  int _offset = 0;
  int _total = 0;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _offset = 0;
        _items = [];
      });
    }
    try {
      final res = await _adminService.listUsers(
        search: _searchQuery.trim(),
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      final items = List<Map<String, dynamic>>.from(res['items'] ?? []);
      final total = (res['total'] ?? 0) as int;
      setState(() {
        _total = total;
        _items = reset ? items : [..._items, ...items];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      dev.log('Load users failed: $e', name: 'UserManagement');
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل تحميل المستخدمين: $e'),
            backgroundColor: cs.error),
      );
    }
  }

  Future<void> _loadMore() async {
    if (_items.length >= _total) return;
    setState(() => _offset += _pageSize);
    await _load();
  }

  Future<void> _onToggleActive(Map<String, dynamic> user, bool value) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await _adminService.setUserActive(userId: user['id'], isActive: value);
      if (!mounted) return;
      setState(() {
        user['is_active'] = value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(value ? 'تم تفعيل المستخدم' : 'تم تعطيل المستخدم')),
      );
    } catch (e) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر التحديث: $e'), backgroundColor: cs.error),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _onChangeRole(Map<String, dynamic> user, String role) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await _adminService.updateUserRole(userId: user['id'], role: role);
      if (!mounted) return;
      setState(() {
        user['role'] = role;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث دور المستخدم')),
      );
    } catch (e) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تعذّر تحديث الدور: $e'), backgroundColor: cs.error),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'إدارة المستخدمين'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () => _load(reset: true),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AdminSearchBar(
                hint: 'بحث بالبريد/الاسم/الهاتف...',
                onSearch: (q) {
                  _searchQuery = q;
                  _load(reset: true);
                },
              ),
            ),
          ),
          if (_loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: cs.primary),
              ),
            )
          else if (_items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('لا توجد نتائج')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _items.length) {
                    return _buildLoadMore();
                  }
                  final user = _items[index];
                  return _buildUserTile(user);
                },
                childCount: _items.length + (_items.length < _total ? 1 : 0),
              ),
            ),
        ],
      ),
    );
  }

  // Getter for color scheme
  ColorScheme get cs => Theme.of(context).colorScheme;

  Widget _buildUserTile(Map<String, dynamic> user) {
    final name = _formatName(user);
    final email = user['email'] ?? '';
    final role = (user['role'] ?? 'tenant') as String;
    final isActive = (user['is_active'] ?? true) as bool;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha((0.08 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primary.withAlpha((0.08 * 255).toInt()),
            child: Text(
              _avatarInitials(user),
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? email : name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'tenant', child: Text('مستأجر')),
                DropdownMenuItem(value: 'host', child: Text('مضيف')),
                DropdownMenuItem(value: 'admin', child: Text('مدير')),
              ],
              onChanged: (val) {
                if (val == null || val == role) return;
                _onChangeRole(user, val);
              },
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isActive,
            activeColor: cs.primary,
            onChanged: (v) => _onToggleActive(user, v),
          ),
        ],
      ),
    );
  }

  String _formatName(Map<String, dynamic> user) {
    final fn = (user['first_name'] ?? '').toString().trim();
    final ln = (user['last_name'] ?? '').toString().trim();
    return [fn, ln].where((e) => e.isNotEmpty).join(' ');
  }

  String _avatarInitials(Map<String, dynamic> user) {
    final fn = (user['first_name'] ?? '').toString().trim();
    final ln = (user['last_name'] ?? '').toString().trim();
    final email = (user['email'] ?? '').toString();
    final base = (fn + (ln.isNotEmpty ? ln[0] : '')).isNotEmpty
        ? (fn + (ln.isNotEmpty ? ln[0] : ''))
        : email;
    return base.isEmpty ? '?' : base.substring(0, 1).toUpperCase();
  }

  Widget _buildLoadMore() {
    final canLoad = _items.length < _total;
    if (!canLoad) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ElevatedButton.icon(
        onPressed: _loadMore,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.expand_more),
        label: const Text('تحميل المزيد'),
      ),
    );
  }
}
