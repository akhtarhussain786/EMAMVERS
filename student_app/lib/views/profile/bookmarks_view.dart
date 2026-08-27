import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

class BookmarksView extends StatefulWidget {
  const BookmarksView({super.key});

  @override
  State<BookmarksView> createState() => _BookmarksViewState();
}

class _BookmarksViewState extends State<BookmarksView> {
  bool isLoading = true;
  List<dynamic> bookmarks = [];
  String activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() async {
    try {
      final res = await ApiService.get('/v1/bookmarks');
      setState(() {
        bookmarks = res is List ? res : [];
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _deleteBookmark(int id) async {
    try {
      await ApiService.delete('/v1/bookmarks/$id');
      setState(() {
        bookmarks.removeWhere((b) => b['id'] == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookmark removed'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = activeFilter == 'all'
        ? bookmarks
        : bookmarks.where((b) => b['item_type'] == activeFilter).toList();

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.cardDark,
        elevation: 0,
        title: const Text('Saved Items & Bookmarks', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.accentBlue))
          : Column(
              children: [
                // Filter Tabs
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppConstants.cardDark,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Saved'),
                        const SizedBox(width: 8),
                        _buildFilterChip('question', 'Questions'),
                        const SizedBox(width: 8),
                        _buildFilterChip('article', 'Current Affairs'),
                        const SizedBox(width: 8),
                        _buildFilterChip('material', 'Study Notes'),
                      ],
                    ),
                  ),
                ),

                // List View
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_border, size: 64, color: AppConstants.textMuted),
                              const SizedBox(height: 12),
                              const Text('No saved items yet', style: TextStyle(color: Colors.white70, fontSize: 16)),
                              const SizedBox(height: 4),
                              const Text('Bookmark questions, articles & notes for quick revision', style: TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final b = filtered[i];
                            final itemType = b['item_type'] ?? 'question';
                            final title = b['item_title'] ?? 'Saved Item #${b['item_id']}';
                            final notes = b['notes'] ?? '';

                            IconData icon = Icons.help_outline;
                            Color iconColor = AppConstants.accentBlue;
                            if (itemType == 'article') {
                              icon = Icons.newspaper;
                              iconColor = Colors.orangeAccent;
                            } else if (itemType == 'material') {
                              icon = Icons.menu_book;
                              iconColor = Colors.purpleAccent;
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppConstants.cardDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppConstants.cardBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: iconColor.withValues(alpha: 0.15),
                                    child: Icon(icon, color: iconColor, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itemType.toUpperCase(),
                                          style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          title,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (notes.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Note: $notes',
                                            style: const TextStyle(color: AppConstants.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteBookmark(b['id']),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = activeFilter == key;
    return GestureDetector(
      onTap: () => setState(() => activeFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.accentBlue : AppConstants.primaryDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppConstants.accentBlue : AppConstants.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.textMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
