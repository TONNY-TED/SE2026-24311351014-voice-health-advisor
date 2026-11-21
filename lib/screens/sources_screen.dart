// Sources Screen: lists the real authorities behind every answer.
// Each card shows what to verify there and the API when one exists.

import 'package:material_ui/material_ui.dart';

import '../services/source_registry.dart';

class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  // Loaded authorities, null while reading the asset.
  List<HealthSource>? _sources;

  @override
  void initState() {
    super.initState();
    // Load the 6-authority catalog once.
    SourceRegistry.load().then((list) {
      if (mounted) setState(() => _sources = list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar with back button.
      appBar: AppBar(title: const Text('Knowledge Sources'), centerTitle: true),
      body: _sources == null
          // Spinner while the JSON asset loads.
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _sources!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                // One card per authority.
                final s = _sources![i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Authority name.
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Homepage URL (copy into browser to verify).
                        SelectableText(
                          s.url,
                          style: const TextStyle(color: Color(0xFF1E3A8A)),
                        ),
                        const SizedBox(height: 6),
                        Text('Use for: ${s.useFor}'),
                        const SizedBox(height: 4),
                        Text(s.how, style: const TextStyle(color: Colors.grey)),
                        // API endpoint chip when the source has one.
                        if (s.api != null) ...[
                          const SizedBox(height: 6),
                          SelectableText(
                            'API: ${s.api}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
