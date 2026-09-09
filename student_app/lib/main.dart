import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/api_service.dart';
import 'core/constants.dart';
import 'widgets/premium_nav_bar.dart';
import 'views/auth/login_signup_view.dart';
import 'views/home/home_view.dart';
import 'views/discovery/exam_detail_view.dart';
import 'views/test_engine/test_instructions_view.dart';
import 'views/test_engine/test_player_view.dart';
import 'views/results/result_view.dart';
import 'views/leaderboard/leaderboard_view.dart';
import 'views/ai_coach/ai_coach_view.dart';
import 'views/profile/passport_view.dart';
import 'views/marketplace/marketplace_screen.dart';
import 'views/creator/become_creator_view.dart';
import 'views/creator/creator_dashboard_view.dart';
import 'views/current_affairs/current_affairs_view.dart';
import 'views/teacher/teacher_dashboard_view.dart';
import 'views/teacher/become_teacher_view.dart';
import 'views/map_learning/map_learning_home_view.dart';
import 'views/notebook/mistake_notebook_view.dart';
import 'views/practice/build_practice_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Resume a stored session so "Remember me" survives an app restart.
  final hasSession = await ApiService.restoreSession();
  runApp(ExamVerseApp(initiallyAuthenticated: hasSession));
}

class ExamVerseApp extends StatefulWidget {
  final bool initiallyAuthenticated;
  const ExamVerseApp({super.key, this.initiallyAuthenticated = false});

  @override
  State<ExamVerseApp> createState() => _ExamVerseAppState();
}

class _ExamVerseAppState extends State<ExamVerseApp> {
  late bool isAuthenticated = widget.initiallyAuthenticated;
  // Teachers author questions and never take tests, so they get their own shell.
  late String accountType = ApiService.accountType;
  int currentTabIndex = 0;

  // Active sub-routes
  int? selectedExamId;
  int? selectedTestId;
  int? activeAttemptId;
  bool isPlayingTest = false;
  bool isBuildingPractice = false;
  // Set when the player should resume an already-assembled custom paper.
  int? practiceAttemptId;
  int? practiceDurationMinutes;
  bool isViewingResult = false;
  bool isViewingInstructions = false;

  Timer? _tourTimer;
  int _tourIndex = 0;

  @override
  void initState() {
    super.initState();
    // A rejected token anywhere in the app returns the user to the login screen
    // instead of surfacing repeated "Unauthorized" errors.
    ApiService.onUnauthorized = _handleSessionExpired;
    _startAutomatedTour();
  }

  void _startAutomatedTour() {
    _tourTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      setState(() {
        _tourIndex++;
        switch (_tourIndex % 11) {
          case 0: // 1. Home Dashboard
            isAuthenticated = true;
            accountType = 'student';
            selectedExamId = null;
            selectedTestId = null;
            isPlayingTest = false;
            isViewingInstructions = false;
            isViewingResult = false;
            currentTabIndex = 0;
            break;
          case 1: // 2. Exam Detail (SSC CGL)
            selectedExamId = 1;
            isPlayingTest = false;
            isViewingInstructions = false;
            isViewingResult = false;
            break;
          case 2: // 3. Test Instructions (Mock 01)
            selectedExamId = null;
            selectedTestId = 1;
            isViewingInstructions = true;
            isPlayingTest = false;
            isViewingResult = false;
            break;
          case 3: // 4. CBT Test Player (Real Questions & Timer)
            selectedExamId = null;
            selectedTestId = 1;
            isPlayingTest = true;
            isViewingInstructions = false;
            isViewingResult = false;
            break;
          case 4: // 5. Scorecard & Result Analytics
            isPlayingTest = false;
            isViewingInstructions = false;
            activeAttemptId = 1;
            isViewingResult = true;
            break;
          case 5: // 6. AI Coach Mentor / Exam Twin
            isViewingResult = false;
            selectedExamId = null;
            currentTabIndex = 2;
            break;
          case 6: // 7. National Leaderboard
            isViewingResult = false;
            selectedExamId = null;
            currentTabIndex = 3;
            break;
          case 7: // 8. Student Passport / Profile
            isViewingResult = false;
            selectedExamId = null;
            currentTabIndex = 4;
            break;
          case 8: // 9. Marketplace Study Store
            isViewingResult = false;
            selectedExamId = null;
            currentTabIndex = 1;
            break;
          case 9: // 10. Mistake Notebook
            isViewingResult = false;
            selectedExamId = null;
            currentTabIndex = 0;
            break;
          case 10: // 11. Home Refresh
            isViewingResult = false;
            selectedExamId = null;
            currentTabIndex = 0;
            break;
        }
      });
    });
  }

  void _handleSessionExpired() {
    if (!mounted || !isAuthenticated) return;
    ApiService.clearSession();
    setState(() {
      isAuthenticated = false;
      accountType = 'student';
      isPlayingTest = false;
      isBuildingPractice = false;
      practiceAttemptId = null;
      isViewingResult = false;
      isViewingInstructions = false;
      selectedExamId = null;
      selectedTestId = null;
      activeAttemptId = null;
    });
  }

  @override
  void dispose() {
    _tourTimer?.cancel();
    ApiService.onUnauthorized = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EXAMVERSE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppConstants.primaryDark,
        primaryColor: AppConstants.accentYellow,
        cardColor: AppConstants.cardDark,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
            .apply(bodyColor: AppConstants.textPrimary, displayColor: AppConstants.textPrimary),
        colorScheme: const ColorScheme.light(
          primary: AppConstants.accentYellow,
          onPrimary: AppConstants.onAccent,
          secondary: AppConstants.accentYellowDeep,
          onSecondary: AppConstants.onAccent,
          surface: AppConstants.cardDark,
          onSurface: AppConstants.textPrimary,
        ),
        // Chrome must not fall back to Material's dark defaults.
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.scaffoldDark,
          foregroundColor: AppConstants.textPrimary,
          elevation: 0,
          iconTheme: IconThemeData(color: AppConstants.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppConstants.textPrimary),
        dividerColor: AppConstants.cardBorder,
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppConstants.accentYellow),
        useMaterial3: true,
      ),
      routes: {
        '/become-creator': (_) => const BecomeCreatorView(),
        '/creator-dashboard': (_) => const CreatorDashboardView(),
        '/marketplace': (_) => const MarketplaceScreen(),
        '/current-affairs': (_) => const CurrentAffairsView(),
      },
      home: !isAuthenticated
          ? LoginSignupView(
              onAuthenticated: (type) => setState(() {
                isAuthenticated = true;
                accountType = type;
              }),
            )
          : accountType == 'teacher'
              ? TeacherDashboardView(onLogout: _handleSessionExpired)
              : _buildAuthenticatedShell(),
    );
  }

  Widget _buildAuthenticatedShell() {
    if (isPlayingTest && (selectedTestId != null || practiceAttemptId != null)) {
      return TestPlayerView(
        testId: selectedTestId ?? 0,
        existingAttemptId: practiceAttemptId,
        existingDurationMinutes: practiceDurationMinutes,
        onTestSubmitted: (attId) {
          setState(() {
            isPlayingTest = false;
            practiceAttemptId = null;
            practiceDurationMinutes = null;
            activeAttemptId = attId;
            isViewingResult = true;
          });
        },
        onExit: () => setState(() {
          isPlayingTest = false;
          practiceAttemptId = null;
          practiceDurationMinutes = null;
        }),
      );
    }

    if (isBuildingPractice) {
      return BuildPracticeView(
        onStarted: (attemptId, minutes) {
          setState(() {
            isBuildingPractice = false;
            practiceAttemptId = attemptId;
            practiceDurationMinutes = minutes;
            isPlayingTest = true;
          });
        },
      );
    }

    if (isViewingInstructions && selectedTestId != null) {
      return TestInstructionsView(
        testId: selectedTestId!,
        onProceedToTest: () {
          setState(() {
            isViewingInstructions = false;
            isPlayingTest = true;
          });
        },
        onCancel: () => setState(() => isViewingInstructions = false),
      );
    }

    if (isViewingResult && activeAttemptId != null) {
      return ResultView(
        attemptId: activeAttemptId!,
        onHome: () {
          setState(() {
            isViewingResult = false;
            selectedExamId = null;
            selectedTestId = null;
            activeAttemptId = null;
            currentTabIndex = 0;
          });
        },
      );
    }

    if (selectedExamId != null) {
      return ExamDetailView(
        examId: selectedExamId!,
        onStartTest: (testId) {
          setState(() {
            selectedTestId = testId;
            isViewingInstructions = true;
          });
        },
        onBack: () => setState(() => selectedExamId = null),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      extendBody: true,
      body: IndexedStack(
        index: currentTabIndex,
        children: [
          HomeView(
            onSelectExam: (examId) => setState(() => selectedExamId = examId),
            onSelectTest: (testId) {
              setState(() {
                selectedTestId = testId;
                isViewingInstructions = true;
              });
            },
            onOpenAiCoach: () => setState(() => currentTabIndex = 2),
            onOpenLeaderboard: () => setState(() => currentTabIndex = 3),
            onBuildPractice: () => setState(() => isBuildingPractice = true),
            onResumeAttempt: (attemptId) => setState(() {
              practiceAttemptId = attemptId;
              isPlayingTest = true;
            }),
          ),
          const MarketplaceScreen(),
          const AiCoachView(),
          const LeaderboardView(),
          PassportView(onLogout: () => setState(() => isAuthenticated = false)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton.extended(
          elevation: 4,
          backgroundColor: AppConstants.accentCyan,
          icon: const Icon(Icons.science, color: Colors.white, size: 20),
          label: const Text('QA Modules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          onPressed: () => _showQaModuleMenu(context),
        ),
      ),
      bottomNavigationBar: PremiumNavBar(
        currentIndex: currentTabIndex,
        onTap: (i) => setState(() {
          selectedExamId = null;
          currentTabIndex = i;
        }),
        items: const [
          PremiumNavBarItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
          PremiumNavBarItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront, label: 'Market'),
          PremiumNavBarItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'AI Twin'),
          PremiumNavBarItem(icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard_rounded, label: 'Ranks'),
          PremiumNavBarItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Passport'),
        ],
      ),
    );
  }

  void _showQaModuleMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppConstants.cardBorder, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🚀 Live Module Test Selector', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppConstants.textPrimary)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _qaTile(ctx, '1. 🏠 Home Dashboard', Icons.home, () {
                    Navigator.pop(ctx);
                    setState(() { selectedExamId = null; isPlayingTest = false; isViewingInstructions = false; isViewingResult = false; currentTabIndex = 0; });
                  }),
                  _qaTile(ctx, '2. 📚 SSC CGL Exam Detail', Icons.school, () {
                    Navigator.pop(ctx);
                    setState(() { selectedExamId = 1; isPlayingTest = false; isViewingInstructions = false; isViewingResult = false; });
                  }),
                  _qaTile(ctx, '3. 📝 Test Instructions (Mock 01)', Icons.assignment, () {
                    Navigator.pop(ctx);
                    setState(() { selectedTestId = 1; isViewingInstructions = true; isPlayingTest = false; isViewingResult = false; });
                  }),
                  _qaTile(ctx, '4. ⏱️ CBT Test Player (Active)', Icons.timer, () {
                    Navigator.pop(ctx);
                    setState(() { selectedTestId = 1; isPlayingTest = true; isViewingInstructions = false; isViewingResult = false; });
                  }),
                  _qaTile(ctx, '5. 📊 Result & Scorecard (Attempt #1)', Icons.analytics, () {
                    Navigator.pop(ctx);
                    setState(() { activeAttemptId = 1; isViewingResult = true; isPlayingTest = false; isViewingInstructions = false; });
                  }),
                  _qaTile(ctx, '6. 📔 Mistake Notebook', Icons.auto_fix_high, () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MistakeNotebookView()));
                  }),
                  _qaTile(ctx, '7. 🗺️ Map Learning (State Explorer)', Icons.map, () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MapLearningHomeView()));
                  }),
                  _qaTile(ctx, '8. 📰 Current Affairs & Daily Quiz', Icons.newspaper, () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrentAffairsView()));
                  }),
                  _qaTile(ctx, '9. 🤖 AI Coach Mentor', Icons.auto_awesome, () {
                    Navigator.pop(ctx);
                    setState(() { selectedExamId = null; currentTabIndex = 2; });
                  }),
                  _qaTile(ctx, '10. 🛍️ Marketplace Study Store', Icons.storefront, () {
                    Navigator.pop(ctx);
                    setState(() { selectedExamId = null; currentTabIndex = 1; });
                  }),
                  _qaTile(ctx, '11. 🏆 National Leaderboard', Icons.leaderboard, () {
                    Navigator.pop(ctx);
                    setState(() { selectedExamId = null; currentTabIndex = 3; });
                  }),
                  _qaTile(ctx, '12. 👤 Student Passport', Icons.person, () {
                    Navigator.pop(ctx);
                    setState(() { selectedExamId = null; currentTabIndex = 4; });
                  }),
                  _qaTile(ctx, '13. 👨‍🏫 Teacher KYC Application', Icons.verified_user, () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BecomeTeacherView()));
                  }),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qaTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppConstants.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.cardBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppConstants.accentCyan),
        title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppConstants.textMuted),
        onTap: onTap,
      ),
    );
  }
}
