import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final categoriesApi = context.watch<HttpAdminCategoriesService?>();
    final tagsApi = context.watch<HttpAdminTagsService?>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RecipeShare Admin'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  user.username,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
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
      body: categoriesApi == null || tagsApi == null
          ? const _ApiRequiredMessage()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NavigationRail(
                  backgroundColor: AppColors.surface,
                  selectedIndex: _navIndex,
                  indicatorColor: AppColors.primary.withValues(alpha: 0.14),
                  selectedIconTheme: const IconThemeData(color: AppColors.primary),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  onDestinationSelected: (int index) {
                    setState(() => _navIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.category_outlined),
                      selectedIcon: Icon(Icons.category),
                      label: Text('Categories'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.label_outline),
                      selectedIcon: Icon(Icons.label),
                      label: Text('Tags'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxContentWidth = constraints.maxWidth * 8 / 12;
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxContentWidth),
                          child: IndexedStack(
                            index: _navIndex,
                            sizing: StackFit.expand,
                            children: [
                              AdminCatalogTab(
                                api: categoriesApi,
                                singular: 'Category',
                              ),
                              AdminCatalogTab(
                                api: tagsApi,
                                singular: 'Tag',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ApiRequiredMessage extends StatelessWidget {
  const _ApiRequiredMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Category and tag management requires the real API. Run the admin app '
            'without USE_MOCK_DATA (default) and point API_BASE_URL at your backend.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class AdminCatalogTab extends StatefulWidget {
  const AdminCatalogTab({
    super.key,
    required this.api,
    required this.singular,
  });

  final AdminCatalogHttp api;
  final String singular;

  @override
  State<AdminCatalogTab> createState() => _AdminCatalogTabState();
}

class _AdminCatalogTabState extends State<AdminCatalogTab> {
  final _search = TextEditingController();
  final _name = TextEditingController();
  List<AdminCatalogRow> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.api.fetchAll();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = widget.api.messageFromError(e);
        });
      }
    }
  }

  List<AdminCatalogRow> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (name.length > 50) {
      _toast('Name must be at most 50 characters.');
      return;
    }
    try {
      await widget.api.create(name);
      _name.clear();
      await _load();
      if (mounted) _toast('${widget.singular} added.');
    } catch (e) {
      if (mounted) _toast(widget.api.messageFromError(e));
    }
  }

  Future<void> _edit(AdminCatalogRow row) async {
    final controller = TextEditingController(text: row.name);
    String? next;
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Edit ${widget.singular}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
            maxLength: 50,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      );
      if (ok == true) next = controller.text.trim();
    } finally {
      controller.dispose();
    }
    if (next == null || !mounted) return;
    if (next.isEmpty || next.length > 50) return;
    try {
      await widget.api.update(row.id, next);
      await _load();
      if (mounted) _toast('Updated.');
    } catch (e) {
      if (mounted) _toast(widget.api.messageFromError(e));
    }
  }

  Future<void> _confirmDelete(AdminCatalogRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Delete "${row.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.api.delete(row.id);
      await _load();
      if (mounted) _toast('Deleted.');
    } catch (e) {
      if (mounted) _toast(widget.api.messageFromError(e));
    }
  }

  Future<void> _toggle(AdminCatalogRow row) async {
    try {
      await widget.api.toggleActive(row.id);
      await _load();
    } catch (e) {
      if (mounted) _toast(widget.api.messageFromError(e));
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
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

    final rows = _filtered;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'New ${widget.singular.toLowerCase()} name',
                    border: const OutlineInputBorder(),
                  ),
                  maxLength: 50,
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton(
                  onPressed: _add,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _search.text.isEmpty ? 'No items yet.' : 'No matches for your search.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
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
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Recipes')),
                          DataColumn(label: Text('Active')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: rows.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Text('${r.id}')),
                              DataCell(Text(r.name)),
                              DataCell(Text('${r.recipeCount}')),
                              DataCell(
                                Switch(
                                  value: r.isActive,
                                  onChanged: (_) => _toggle(r),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _edit(r),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _confirmDelete(r),
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
