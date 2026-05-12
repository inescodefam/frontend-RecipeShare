import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';
import '../widgets/admin_moderation_detail_dialogs.dart';
import 'admin_recipes_tab.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _search = TextEditingController();
  List<AdminUserListItem> _users = const [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  final int _pageSize = 10;
  int _totalCount = 0;
  bool _hasNextPage = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    final nextPage = page ?? _page;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<RecipeShareServices>().admin.getAdminUsers(
            pageNumber: nextPage,
            pageSize: _pageSize,
            search: _search.text.trim().isEmpty ? null : _search.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _users = result.items;
        _page = result.pageNumber;
        _totalCount = result.totalCount;
        _hasNextPage = result.hasNextPage;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _isCurrentUser(AdminUserListItem user) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (currentUserId == null) return false;
    return currentUserId == '${user.id}';
  }

  Future<void> _openUserDetail(AdminUserListItem user) async {
    final updated = await showAdminUserDetailDialog(context, userId: user.id);
    if (updated && mounted) {
      await _load(page: _page);
    }
  }

  Future<void> _toggleBlocked(AdminUserListItem user) async {
    if (_isCurrentUser(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot block your own account.')),
      );
      return;
    }
    try {
      await context.read<RecipeShareServices>().admin.toggleUserBlocked('${user.id}');
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isBlocked ? 'User unblocked.' : 'User blocked.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _setDeleted(AdminUserListItem user, bool delete) async {
    if (_isCurrentUser(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your own account from here.')),
      );
      return;
    }
    try {
      final admin = context.read<RecipeShareServices>().admin;
      if (delete) {
        await admin.deleteUser('${user.id}');
      } else {
        await admin.restoreUser('${user.id}');
      }
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(delete ? 'User deleted.' : 'User restored.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(page: _page),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _search,
            onSubmitted: (_) => _load(page: 1),
            decoration: InputDecoration(
              labelText: 'Search users',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: () => _load(page: 1),
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
          const SizedBox(height: 16),
          PagerBar(
            page: _page,
            pageSize: _pageSize,
            totalCount: _totalCount,
            hasNextPage: _hasNextPage,
            onPrevious: _page > 1 ? () => _load(page: _page - 1) : null,
            onNext: _hasNextPage ? () => _load(page: _page + 1) : null,
          ),
          const SizedBox(height: 16),
          if (_users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No users found.'),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('View details')),
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Username')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Blocked')),
                          DataColumn(label: Text('Deleted')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _users.map((user) {
                          final isCurrentUser =
                              currentUserId != null && currentUserId == '${user.id}';
                          return DataRow(
                            cells: [
                              DataCell(
                                TextButton(
                                  onPressed: () => _openUserDetail(user),
                                  child: const Text('View'),
                                ),
                              ),
                              DataCell(Text('${user.id}')),
                              DataCell(Text(user.username)),
                              DataCell(Text(user.email)),
                              DataCell(Text(user.isBlocked ? 'Yes' : 'No')),
                              DataCell(Text(user.isDeleted ? 'Yes' : 'No')),
                              DataCell(
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: isCurrentUser
                                          ? null
                                          : () => _toggleBlocked(user),
                                      child: Text(user.isBlocked ? 'Unblock' : 'Block'),
                                    ),
                                    TextButton(
                                      onPressed: isCurrentUser
                                          ? null
                                          : () => _setDeleted(user, !user.isDeleted),
                                      child: Text(user.isDeleted ? 'Restore' : 'Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
