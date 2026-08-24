import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants.dart';
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

void main() {
  runApp(const ExamVerseApp());
}

class ExamVerseApp extends StatefulWidget {
  const ExamVerseApp({super.key});

  @override
  State<ExamVerseApp> createState() => _ExamVerseAppState();
}

class _ExamVerseAppState extends State<ExamVerseApp> {
  bool isAuthenticated = false;
  int currentTabIndex = 0;

  // Active sub-routes
  int? selectedExamId;
  int? selectedTestId;
  int? activeAttemptId;
  bool isPlayingTest = false;
  bool isViewingResult = false;
  bool isViewingInstructions = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EXAMVERSE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConstants.primaryDark,
        primaryColor: AppConstants.accentBlue,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      routes: {
        '/become-creator': (_) => const BecomeCreatorView(),
        '/creator-dashboard': (_) => const CreatorDashboardView(),
        '/marketplace': (_) => const MarketplaceScreen(),
        '/current-affairs': (_) => const CurrentAffairsView(),
      },
      home: !isAuthenticated
          ? LoginSignupView(onAuthenticated: () => setState(() => isAuthenticated = true))
          : _buildAuthenticatedShell(),
    );
  }

  Widget _buildAuthenticatedShell() {
    if (isPlayingTest && selectedTestId != null) {
      return TestPlayerView(
        testId: selectedTestId!,
        onTestSubmitted: (attId) {
          setState(() {
            isPlayingTest = false;
            activeAttemptId = attId;
            isViewingResult = true;
          });
        },
        onExit: () => setState(() => isPlayingTest = false),
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
          ),
          const MarketplaceScreen(),
          const AiCoachView(),
          const LeaderboardView(),
          const PassportView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTabIndex,
        onTap: (i) => setState(() {
          selectedExamId = null;
          currentTabIndex = i;
        }),
        backgroundColor: AppConstants.cardDark,
        selectedItemColor: AppConstants.accentBlue,
        unselectedItemColor: AppConstants.textMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Marketplace'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI Coach'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Passport'),
        ],
      ),
    );
  }
}
