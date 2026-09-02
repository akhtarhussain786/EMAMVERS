import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../widgets/design_system_widgets.dart';
import 'submit_question_view.dart';
import 'my_questions_view.dart';

/// Home screen for a teacher account. Teachers author questions; they do not
/// take tests, so this is a separate shell from the student experience.
class TeacherDashboardView extends StatefulWidget {
  final VoidCallback onLogout;
  const TeacherDashboardView({super.key, required this.onLogout});

  @override
  State<TeacherDashboardView> createState() => _TeacherDashboardViewState();
}

class _TeacherDashboardViewState extends State<TeacherDashboardView> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

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
      final res = await ApiService.get('/v1/teacher/dashboard');
      if (!mounted) return;
      setState(() {
        _data = res as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load(); // Counts change after submitting, so refresh on return.
  }

  @override
  Widget build(BuildContext context) {
    final teacher = _data?['teacher'] as Map<String, dynamic>?;
    final stats = _data?['stats'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        elevation: 0,
        title: const Text('Teacher Panel',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppConstants.accentRose),
            tooltip: 'Sign out',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.accentCyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Question', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _open(const SubmitQuestionView()),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
            : _error != null
                ? EmptyStateWidget(
                    icon: Icons.cloud_off,
                    title: 'Could not load your panel',
                    description: _error!,
                    buttonLabel: 'Try again',
                    onButtonPressed: _load,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppConstants.accentCyan,
                    child: ListView(
                      padding: const EdgeInsets.all(AppConstants.space20),
                      children: [
                        Text('Welcome, ${teacher?['display_name'] ?? teacher?['full_name'] ?? 'Teacher'}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        if (teacher?['specialisation'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(teacher!['specialisation'].toString(),
                                style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13)),
                          ),
                        const SizedBox(height: AppConstants.space24),

                        Row(children: [
                          _statCard('Awaiting Review', stats?['pending_review'] ?? 0, AppConstants.accentAmber),
                          const SizedBox(width: 12),
                          _statCard('Approved', stats?['approved'] ?? 0, AppConstants.accentEmerald),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          _statCard('Rejected', stats?['rejected'] ?? 0, AppConstants.accentRose),
                          const SizedBox(width: 12),
                          _statCard(
                            'Approval Rate',
                            stats?['approval_rate'] == null ? '—' : '${stats!['approval_rate']}%',
                            AppConstants.accentPurple,
                          ),
                        ]),
                        const SizedBox(height: AppConstants.space24),

                        ExamVerseCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.list_alt, color: AppConstants.accentCyan),
                            title: const Text('My Submissions',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Track what is approved, pending or needs changes',
                                style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5)),
                            trailing: const Icon(Icons.chevron_right, color: AppConstants.textMuted),
                            onTap: () => _open(const MyQuestionsView()),
                          ),
                        ),
                        const SizedBox(height: AppConstants.space20),

                        const Text('Recent Submissions',
                            style: TextStyle(
                                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ..._recentTiles(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
      ),
    );
  }

  List<Widget> _recentTiles() {
    final recent = (_data?['recent_submissions'] as List?) ?? [];
    if (recent.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('Nothing submitted yet. Tap “New Question” to add your first one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
        )
      ];
    }
    return recent.map<Widget>((q) {
      final status = (q['status'] ?? '').toString();
      return ExamVerseCard(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q['question_text']?.toString() ?? '(no text)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4)),
              const SizedBox(height: 6),
              Text(q['subject_name']?.toString() ?? '—',
                  style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
            ]),
          ),
          const SizedBox(width: 10),
          StatusChip(status: status),
        ]),
      );
    }).toList();
  }

  Widget _statCard(String label, Object value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.space16),
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value',
              style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11.5)),
        ]),
      ),
    );
  }
}

/// Colour-coded badge for a submission's review state.
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    switch (status) {
      case 'published':
        color = AppConstants.accentEmerald;
        label = 'Approved';
        break;
      case 'rejected':
        color = AppConstants.accentRose;
        label = 'Needs changes';
        break;
      case 'review':
        color = AppConstants.accentAmber;
        label = 'In review';
        break;
      default:
        color = AppConstants.textMuted;
        label = status.isEmpty ? 'Draft' : status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
