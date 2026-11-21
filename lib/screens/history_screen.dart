// History Screen (Week 5): per-user search history from SQLite.
// Header shows profile details (name + email), list shows past queries,
// Clear button wipes only this user's rows after confirmation.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../services/local_db_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Auth + database services.
  final AuthService _auth = AuthService();
  final LocalDbService _db = LocalDbService.instance;

  // Loaded profile + rows, null while loading.
  AppUser? _user;
  List<Map<String, dynamic>>? _rows;

  @override
  void initState() {
    super.initState();
    // Load profile first, then that user's history.
    _load();
  }

  // Load current user and their recent queries.
  Future<void> _load() async {
    // Chrome web has no SQLite: show profile with empty-history notice.
    final user = await _auth.currentUser();
    if (!mounted) return;
    setState(() => _user = user);

    // Skip DB read on web.
    if (kIsWeb) {
      setState(() => _rows = []);
      return;
    }
    try {
      final email = user?.email ?? '';
      if (email.isEmpty) {
        setState(() => _rows = []);
        return;
      }
      final rows = await _db.recentHistory(email, limit: 50);
      if (mounted) setState(() => _rows = rows);
    } catch (_) {
      if (mounted) setState(() => _rows = []);
    }
  }

  // Ask for confirmation, then clear only this user's history.
  Future<void> _clear() async {
    final email = _user?.email ?? '';
    if (email.isEmpty) return;

    // Confirm dialog so taps don't wipe by accident.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This deletes all your saved searches.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Delete rows and reload the empty list.
    try {
      await _db.clearHistory(email);
    } catch (_) {
      // Ignore DB errors, still refresh.
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar with clear action (disabled when list is empty).
      appBar: AppBar(
        title: const Text('My History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear history',
            onPressed: (_rows == null || _rows!.isEmpty) ? null : _clear,
          ),
        ],
      ),
      body: _rows == null
          // Spinner while profile + history load.
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile header card: name + email + query count.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar with first letter of name.
                        CircleAvatar(
                          child: Text(
                            (_user?.name.isNotEmpty == true)
                                ? _user!.name[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User display name.
                              Text(
                                _user?.name.isNotEmpty == true
                                    ? _user!.name
                                    : 'Guest',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Login email.
                              Text(
                                _user?.email ?? 'Not logged in',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              // Count of saved searches.
                              Text(
                                '${_rows!.length} saved searches',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Web notice: history needs the phone app.
                if (kIsWeb)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'History is stored on-device (phone). Chrome uses temporary storage only.',
                      ),
                    ),
                  ),

                // Empty state when no queries saved yet.
                if (!kIsWeb && _rows!.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'No searches yet. Ask about sleep, water, malaria or fever and they will appear here.',
                      ),
                    ),
                  ),

                // One card per saved query: query + topic/intent + time.
                for (final r in _rows!)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(r['query']?.toString() ?? ''),
                      subtitle: Text(
                        '${r['topic'] ?? ''} - ${r['intent'] ?? ''}\n${r['created_at'] ?? ''}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
              ],
            ),
    );
  }
}
