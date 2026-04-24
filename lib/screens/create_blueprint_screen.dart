import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class _SectionSpec {
  int collectionId;
  int count;
  String name;

  _SectionSpec({required this.collectionId, required this.count, required this.name});
}

class CreateBlueprintScreen extends StatefulWidget {
  final Book book;

  const CreateBlueprintScreen({super.key, required this.book});

  @override
  State<CreateBlueprintScreen> createState() => _CreateBlueprintScreenState();
}

class _CreateBlueprintScreenState extends State<CreateBlueprintScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_SectionSpec> _sections = [];
  List<Collection> _availableCollections = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final collections = await DatabaseService().getCollections(widget.book.id);
    if (mounted) {
      setState(() {
        _availableCollections = collections.where((c) =>
          c.isSource || c.type == CollectionType.topic || c.type == CollectionType.practiceSet,
        ).toList();
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')), // TODO(l10n)
      );
      return;
    }
    if (_sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one section')), // TODO(l10n)
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final config = jsonEncode({
        'sections': _sections.map((s) => {
          'collectionId': s.collectionId,
          'count': s.count,
          'name': s.name,
        }).toList(),
        'shuffle': true,
      });

      final db = DatabaseService();
      await db.createUserCollection(
        bookId: widget.book.id,
        name: name,
        type: CollectionType.examBlueprint,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      // Get the newly created collection to update its config
      final collections = await db.getCollectionsByType(widget.book.id, CollectionType.examBlueprint);
      final newCollection = collections.firstWhere((c) => c.name == name);
      await db.updateCollectionConfig(newCollection.id, config);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create blueprint: $e')), // TODO(l10n)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSection() {
    if (_availableCollections.isEmpty) return;
    final first = _availableCollections.first;
    setState(() {
      _sections.add(_SectionSpec(
        collectionId: first.id,
        count: 10,
        name: first.name,
      ));
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Exam Blueprint'), // TODO(l10n)
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name', // TODO(l10n)
              hintText: 'e.g. Mock Exam A', // TODO(l10n)
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)', // TODO(l10n)
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Sections', // TODO(l10n)
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addSection,
                icon: const Icon(Icons.add),
                label: const Text('Add Section'), // TODO(l10n)
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_sections.isEmpty)
            Text(
              'Add sections to define your exam structure.', // TODO(l10n)
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          else
            ..._sections.asMap().entries.map((entry) => _buildSectionCard(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(int index, _SectionSpec spec) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: spec.collectionId,
                    decoration: const InputDecoration(labelText: 'Collection'), // TODO(l10n)
                    items: _availableCollections.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final collection = _availableCollections.firstWhere((c) => c.id == value);
                        setState(() {
                          spec.collectionId = value;
                          spec.name = collection.name;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Count'), // TODO(l10n)
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: '${spec.count}'),
                    onChanged: (value) {
                      spec.count = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _removeSection(index),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove'), // TODO(l10n)
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
