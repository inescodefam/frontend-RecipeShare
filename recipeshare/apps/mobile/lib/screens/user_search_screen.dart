import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _controller = TextEditingController();
  List<User> _results = const [];
  final Map<String, bool> _followingByUserId = {};
  final Set<String> _loadingUserIds = {};
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _followingByUserId.clear();
        _error = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final services = context.read<RecipeShareServices>();
      final auth = context.read<AuthProvider>();
      final currentUserId = auth.user?.id;
      final users = await services.users.searchUsers(query);
      final filtered = currentUserId == null
          ? users
          : users.where((u) => u.id != currentUserId).toList();
      final map = <String, bool>{};
      if (currentUserId != null) {
        for (final u in filtered) {
          map[u.id] = await services.users.isFollowing(currentUserId, u.id);
        }
      }
      if (!mounted) return;
      setState(() {
        _results = filtered;
        _followingByUserId
          ..clear()
          ..addAll(map);
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleFollow(User user) async {
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.user?.id;
    if (currentUserId == null) return;
    final services = context.read<RecipeShareServices>();
    final isFollowing = _followingByUserId[user.id] ?? false;
    setState(() {
      _loadingUserIds.add(user.id);
    });
    try {
      if (isFollowing) {
        await services.users.unfollow(currentUserId, user.id);
      } else {
        await services.users.follow(currentUserId, user.id);
      }
      if (!mounted) return;
      setState(() {
        _followingByUserId[user.id] = !isFollowing;
        _loadingUserIds.remove(user.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingUserIds.remove(user.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find users')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Search by username',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _searching ? null : _search,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_searching) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('Search users to follow'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        final isFollowing = _followingByUserId[user.id] ?? false;
                        final isLoading = _loadingUserIds.contains(user.id);
                        return ListTile(
                          leading: UserAvatar(
                            imageUrl: user.profileImageUrl,
                            nameForInitials: user.username,
                            radius: 18,
                          ),
                          title: Text(user.username),
                          trailing: FilledButton.tonal(
                            onPressed: isLoading ? null : () => _toggleFollow(user),
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(isFollowing ? 'Unfollow' : 'Follow'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
