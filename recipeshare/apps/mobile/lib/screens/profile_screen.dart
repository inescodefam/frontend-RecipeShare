import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Collection>> _collectionsFuture;

  @override
  void initState() {
    super.initState();
    _collectionsFuture = _loadCollections();
  }

  Future<List<Collection>> _loadCollections() {
    final services = context.read<RecipeShareServices>();
    return services.collections.getMyCollections();
  }

  void _reloadCollections() {
    setState(() {
      _collectionsFuture = _loadCollections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('Log out'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (user != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: user.profileImageUrl.isEmpty
                      ? const CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.person, size: 40),
                        )
                      : CachedNetworkImage(
                          imageUrl: user.profileImageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SizedBox(
                            width: 80,
                            height: 80,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, __, ___) => const CircleAvatar(
                            radius: 40,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          user.bio,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.push('/home/profile/settings'),
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Account settings'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/home/profile/users'),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Find users'),
            ),
            const SizedBox(height: 12),
            Text(
              'Update your photo, username, email, bio, and password.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Private collections', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _createCollection,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Collection>>(
              future: _collectionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  );
                }
                final collections = snapshot.data ?? const [];
                if (collections.isEmpty) {
                  return const Text('No collections yet. Create one to save recipes.');
                }
                return Column(
                  children: collections
                      .map(
                        (collection) => Card(
                          child: ListTile(
                            title: Text(collection.name),
                            subtitle: Text('${collection.recipeCount} recipes'),
                            onTap: () => _showCollectionRecipes(collection),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () => _deleteCollection(collection.id),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ] else
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _createCollection() async {
    final nameController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New collection'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Collection name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (created != true) return;
    try {
      await context.read<RecipeShareServices>().collections.createCollection(nameController.text);
      if (!mounted) return;
      _reloadCollections();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection created')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteCollection(String collectionId) async {
    try {
      await context.read<RecipeShareServices>().collections.deleteCollection(collectionId);
      if (!mounted) return;
      _reloadCollections();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showCollectionRecipes(Collection collection) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CollectionRecipesScreen(collection: collection),
      ),
    );
    if (!mounted) return;
    _reloadCollections();
  }
}

class _CollectionRecipesScreen extends StatefulWidget {
  const _CollectionRecipesScreen({required this.collection});

  final Collection collection;

  @override
  State<_CollectionRecipesScreen> createState() => _CollectionRecipesScreenState();
}

class _CollectionRecipesScreenState extends State<_CollectionRecipesScreen> {
  late Future<List<Recipe>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Recipe>> _load() {
    return context.read<RecipeShareServices>().collections.getCollectionRecipes(widget.collection.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.name)),
      body: FutureBuilder<List<Recipe>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(snapshot.error.toString()),
              ),
            );
          }
          final recipes = snapshot.data ?? const [];
          if (recipes.isEmpty) {
            return const Center(child: Text('This collection is empty.'));
          }
          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return ListTile(
                title: Text(recipe.title),
                subtitle: Text(recipe.categoryLabel ?? ''),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/recipes/${recipe.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
