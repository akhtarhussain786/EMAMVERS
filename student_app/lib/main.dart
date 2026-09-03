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

  @override
  void initState() {
    super.initState();
    // A rejected token anywhere in the app returns the user to the login screen
    // instead of surfacing repeated "Unauthorized" errors.
    ApiService.onUnauthorized = _handleSessionExpired;
  }

  @override
  void dispose() {
    ApiService.onUnauthorized = null;
    super.dispose();
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
}
