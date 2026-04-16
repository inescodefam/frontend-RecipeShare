import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../providers/auth_provider.dart';

class _IngRow {
  _IngRow()
      : name = TextEditingController(),
        quantity = TextEditingController();

  final TextEditingController name;
  final TextEditingController quantity;

  void dispose() {
    name.dispose();
    quantity.dispose();
  }
}

class RecipeEditorScreen extends StatefulWidget {
  const RecipeEditorScreen({super.key, this.recipeId});

  final String? recipeId;

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _prep = TextEditingController(text: '15');
  final _cook = TextEditingController(text: '15');
  final _servings = TextEditingController(text: '2');

  Difficulty _difficulty = Difficulty.easy;
  String? _categoryId;
  final Set<String> _tagIds = {};

  final List<_IngRow> _ingredients = [_IngRow(), _IngRow()];
  final List<TextEditingController> _steps = [
    TextEditingController(),
    TextEditingController(),
  ];

  List<CategoryTag> _categories = [];
  List<CategoryTag> _tags = [];

  bool _loadingMeta = true;
  bool _loadingRecipe = false;
  bool _saving = false;
  String? _error;

  List<int>? _pendingImageBytes;
  String? _pendingImageName;

  bool get _isEdit => widget.recipeId != null && widget.recipeId!.isNotEmpty;

  void _closeEditor([Object? result]) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.go('/home/feed');
    }
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final services = context.read<RecipeShareServices>();
    try {
      final cats = await services.recipes.listRecipeCategories();
      final tags = await services.recipes.listRecipeTags();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _tags = tags;
        _categoryId = cats.isNotEmpty ? cats.first.id : null;
        _loadingMeta = false;
      });
      if (_isEdit) {
        await _loadRecipe(services);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingMeta = false;
      });
    }
  }

  Future<void> _loadRecipe(RecipeShareServices services) async {
    setState(() => _loadingRecipe = true);
    try {
      final r = await services.recipes.getRecipeById(widget.recipeId!);
      _title.text = r.title;
      _description.text = r.description;
      _prep.text = '${r.prepTime}';
      _cook.text = '${r.cookTime}';
      _servings.text = '${r.servings}';
      _difficulty = r.difficulty;
      _categoryId = r.categoryId;
      _tagIds.clear();
      if (r.tagIds.isNotEmpty) {
        _tagIds.addAll(r.tagIds);
      } else {
        for (final t in _tags) {
          if (r.tagLabels.contains(t.name)) {
            _tagIds.add(t.id);
          }
        }
      }
      for (final row in _ingredients) {
        row.dispose();
      }
      _ingredients
        ..clear()
        ..addAll(
          r.ingredients.isEmpty
              ? [_IngRow(), _IngRow()]
              : r.ingredients.map((i) {
                  final row = _IngRow();
                  row.name.text = i.name;
                  row.quantity.text = i.amount == i.amount.roundToDouble()
                      ? '${i.amount.toInt()}'
                      : '${i.amount}';
                  return row;
                }).toList(),
        );
      for (final c in _steps) {
        c.dispose();
      }
      _steps
        ..clear()
        ..addAll(
          r.steps.isEmpty
              ? [TextEditingController(), TextEditingController()]
              : r.steps.map((s) => TextEditingController(text: s.description)).toList(),
        );
    } finally {
      if (mounted) setState(() => _loadingRecipe = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _prep.dispose();
    _cook.dispose();
    _servings.dispose();
    for (final r in _ingredients) {
      r.dispose();
    }
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 88);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pendingImageBytes = bytes;
      _pendingImageName = file.name;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null || _categoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a category')),
      );
      return;
    }
    final prep = int.tryParse(_prep.text.trim()) ?? 1;
    final cook = int.tryParse(_cook.text.trim()) ?? 0;
    final serv = int.tryParse(_servings.text.trim()) ?? 1;

    final ingInputs = <RecipeIngredientInput>[];
    var o = 1;
    for (final row in _ingredients) {
      final n = row.name.text.trim();
      final q = row.quantity.text.trim();
      if (n.isEmpty && q.isEmpty) continue;
      if (n.isEmpty || q.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Each ingredient needs a name and quantity')),
        );
        return;
      }
      ingInputs.add(
        RecipeIngredientInput(
          name: n,
          quantity: q,
          unit: null,
          order: o++,
        ),
      );
    }
    if (ingInputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one ingredient')),
      );
      return;
    }

    final stepInputs = <RecipeStepInput>[];
    o = 1;
    for (final c in _steps) {
      final d = c.text.trim();
      if (d.isEmpty) continue;
      stepInputs.add(RecipeStepInput(description: d, order: o++));
    }
    if (stepInputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one step')),
      );
      return;
    }

    final payload = RecipeWritePayload(
      title: _title.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      prepTimeMinutes: prep.clamp(1, 1440),
      cookTimeMinutes: cook.clamp(0, 1440),
      servings: serv.clamp(1, 100),
      difficulty: _difficulty,
      categoryId: _categoryId!,
      tagIds: _tagIds.toList(),
      ingredients: ingInputs,
      steps: stepInputs,
    );

    final services = context.read<RecipeShareServices>();
    final auth = context.read<AuthProvider>();

    setState(() => _saving = true);
    try {
      String id;
      if (_isEdit) {
        await services.recipes.updateRecipeWithPayload(widget.recipeId!, payload);
        id = widget.recipeId!;
      } else {
        id = await services.recipes.createRecipeWithPayload(
          payload,
          ownerUserId: auth.user?.id,
        );
      }
      if (_pendingImageBytes != null) {
        await services.recipes.uploadRecipeImage(
          id,
          _pendingImageBytes!,
          filename: _pendingImageName,
        );
      }
      if (!mounted) return;
      if (_isEdit) {
        _closeEditor(true);
      } else {
        context.pushReplacement('/recipes/$id');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingMeta) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recipe')),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit recipe' : 'New recipe'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _closeEditor,
        ),
      ),
      body: _loadingRecipe
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) =>
                          v == null || v.trim().length < 3 ? 'At least 3 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _prep,
                            decoration: const InputDecoration(labelText: 'Prep (min)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cook,
                            decoration: const InputDecoration(labelText: 'Cook (min)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _servings,
                            decoration: const InputDecoration(labelText: 'Servings'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Difficulty>(
                      value: _difficulty,
                      decoration: const InputDecoration(labelText: 'Difficulty'),
                      items: Difficulty.values
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _difficulty = v ?? Difficulty.easy),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _categories.any((c) => c.id == _categoryId)
                          ? _categoryId
                          : (_categories.isNotEmpty ? _categories.first.id : null),
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    const SizedBox(height: 8),
                    Text('Tags', style: Theme.of(context).textTheme.titleSmall),
                    Wrap(
                      spacing: 6,
                      runSpacing: 0,
                      children: _tags.map((t) {
                        final sel = _tagIds.contains(t.id);
                        return FilterChip(
                          label: Text(t.name),
                          selected: sel,
                          onSelected: (_) {
                            setState(() {
                              if (sel) {
                                _tagIds.remove(t.id);
                              } else {
                                _tagIds.add(t.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ingredients', style: Theme.of(context).textTheme.titleSmall),
                        TextButton(
                          onPressed: () => setState(() => _ingredients.add(_IngRow())),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    ...List.generate(_ingredients.length, (i) {
                      final row = _ingredients[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: row.name,
                                decoration: const InputDecoration(labelText: 'Name'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: row.quantity,
                                decoration: const InputDecoration(labelText: 'Qty'),
                              ),
                            ),
                            IconButton(
                              onPressed: _ingredients.length <= 1
                                  ? null
                                  : () => setState(() {
                                        row.dispose();
                                        _ingredients.removeAt(i);
                                      }),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Steps', style: Theme.of(context).textTheme.titleSmall),
                        TextButton(
                          onPressed: () => setState(() => _steps.add(TextEditingController())),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    ...List.generate(_steps.length, (i) {
                      final c = _steps[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12, right: 8),
                              child: Text('${i + 1}.'),
                            ),
                            Expanded(
                              child: TextField(
                                controller: c,
                                decoration: const InputDecoration(
                                  labelText: 'Step description',
                                ),
                                maxLines: 2,
                              ),
                            ),
                            IconButton(
                              onPressed: _steps.length <= 1
                                  ? null
                                  : () => setState(() {
                                        c.dispose();
                                        _steps.removeAt(i);
                                      }),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_outlined),
                      label: Text(_pendingImageBytes == null ? 'Choose cover image' : 'Image selected'),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEdit ? 'Save changes' : 'Create recipe'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
