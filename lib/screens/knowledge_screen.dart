// Knowledge Screen: browse the 24-entry clinical knowledge base.
// Search + category filter; tap an entry for content, tips and source.
// Read-only view over KnowledgeBaseService — no logic changes.

import 'package:material_ui/material_ui.dart';

import '../services/knowledge_base_service.dart';
import 'sources_screen.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  // All entries loaded once from the bundled JSON asset.
  List<KbEntry> _entries = [];

  // Search box controller.
  final TextEditingController _searchController = TextEditingController();

  // Active category filter ('All' = no filter).
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    // Load the knowledge base in the background.
    KnowledgeBaseService.load().then((list) {
      if (mounted) setState(() => _entries = list);
    });
    // Refresh the list on every keystroke.
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Distinct categories for the filter chips, 'All' first.
  List<String> get _categories {
    final set = <String>{};
    for (final e in _entries) {
      set.add(e.category);
    }
    return ['All', ...set];
  }

  // Entries matching the search text and category filter.
  List<KbEntry> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _entries.where((e) {
      // Category must match unless 'All' is selected.
      if (_category != 'All' && e.category != _category) return false;
      if (q.isEmpty) return true;
      // Match topic, condition or any keyword.
      if (e.topic.toLowerCase().contains(q)) return true;
      if (e.condition.toLowerCase().contains(q)) return true;
      return e.keywords.any((k) => k.contains(q));
    }).toList();
  }

  // Show full entry details in a bottom sheet (existing formatted text).
  void _showEntry(KbEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.topic} (${entry.condition})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(entry.category, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Text(entry.content),
              if (entry.tips.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Tips:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final tip in entry.tips) Text('- $tip'),
              ],
              if (entry.seeDoctorIf.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'See a doctor if:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(entry.seeDoctorIf),
              ],
              if (entry.source.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Source: ${entry.source}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                KnowledgeBaseService.disclaimer,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar matching the app style.
      appBar: AppBar(
        title: const Text('Knowledge Base'),
        centerTitle: true,
        actions: [
          // Jump to the verifiable sources catalog.
          IconButton(
            icon: const Icon(Icons.library_books_outlined),
            tooltip: 'Sources',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SourcesScreen()),
              );
            },
          ),
        ],
      ),
      body: _entries.isEmpty
          // Spinner while the JSON asset loads.
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  // Search across topics, conditions and keywords.
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search topics, e.g. malaria',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                // Horizontally scrollable category filter chips.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      for (final c in _categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ),
                        ),
                    ],
                  ),
                ),
                // Filtered entry list.
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No topics match.'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final e = _filtered[i];
                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.health_and_safety_outlined,
                                ),
                                title: Text(e.topic),
                                subtitle: Text(
                                  '${e.condition} - ${e.category}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _showEntry(e),
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
