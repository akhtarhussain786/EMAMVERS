import 'package:flutter/material.dart';
import 'learning_theme.dart';
import 'onboarding_view.dart';
import 'learning_home_view.dart';
import 'my_courses_view.dart';
import 'course_detail_view.dart';

import '../auth/login_signup_view.dart';
import '../discovery/exam_detail_view.dart';
import '../test_engine/test_instructions_view.dart';
import '../test_engine/test_player_view.dart';
import '../results/result_view.dart';
import '../leaderboard/leaderboard_view.dart';
import '../profile/passport_view.dart';
import '../marketplace/marketplace_screen.dart';

class LearningAppShell extends StatefulWidget {
  const LearningAppShell({super.key});

  @override
  State<LearningAppShell> createState() => _LearningAppShellState();
}

class _LearningAppShellState extends State<LearningAppShell> {
  bool _hasSeenOnboarding = false;
  bool _isViewingLogin = false;
  int _currentTabIndex = 0;

  // Sub-route State Navigation for Backend APIs
  int? _selectedExamId;
  int? _selectedTestId;
  int? _activeAttemptId;
  bool _isPlayingTest = false;
  bool _isViewingResult = false;
  bool _isViewingInstructions = false;
  bool _isViewingCourseDetail = false;
  String _selectedCourseTitle = 'UI/UX Design Fundamentals';

  @override
  Widget build(BuildContext context) {
    // 0. Show Login Screen if requested
    if (_isViewingLogin) {
      return LoginSignupView(
        onAuthenticated: () {
          setState(() {
            _isViewingLogin = false;
            _hasSeenOnboarding = true;
          });
        },
      );
    }

    // 1. Show Onboarding Flow if not completed
    if (!_hasSeenOnboarding) {
      return ELearningOnboardingView(
        onFinishOnboarding: () {
          setState(() => _hasSeenOnboarding = true);
        },
        onLoginPressed: () {
          setState(() => _isViewingLogin = true);
        },
      );
    }

    // 2. BACKEND TEST PLAYER VIEW
    if (_isPlayingTest && _selectedTestId != null) {
      return TestPlayerView(
        testId: _selectedTestId!,
        onTestSubmitted: (attId) {
          setState(() {
            _isPlayingTest = false;
            _activeAttemptId = attId;
            _isViewingResult = true;
          });
        },
        onExit: () => setState(() => _isPlayingTest = false),
      );
    }

    // 3. BACKEND TEST INSTRUCTIONS VIEW
    if (_isViewingInstructions && _selectedTestId != null) {
      return TestInstructionsView(
        testId: _selectedTestId!,
        onProceedToTest: () {
          setState(() {
            _isViewingInstructions = false;
            _isPlayingTest = true;
          });
        },
        onCancel: () => setState(() => _isViewingInstructions = false),
      );
    }

    // 4. BACKEND TEST RESULT VIEW
    if (_isViewingResult && _activeAttemptId != null) {
      return ResultView(
        attemptId: _activeAttemptId!,
        onHome: () {
          setState(() {
            _isViewingResult = false;
            _selectedExamId = null;
            _selectedTestId = null;
            _activeAttemptId = null;
            _currentTabIndex = 0;
          });
        },
      );
    }

    // 5. BACKEND EXAM DETAIL VIEW
    if (_selectedExamId != null) {
      return ExamDetailView(
        examId: _selectedExamId!,
        onStartTest: (testId) {
          setState(() {
            _selectedTestId = testId;
            _isViewingInstructions = true;
          });
        },
        onBack: () => setState(() => _selectedExamId = null),
      );
    }

    // 6. COURSE DETAIL VIEW
    if (_isViewingCourseDetail) {
      return CourseDetailView(
        courseTitle: _selectedCourseTitle,
        onBack: () {
          setState(() => _isViewingCourseDetail = false);
        },
      );
    }

    // 7. MAIN SHELL (Home, My Courses, Marketplace/Explore, Leaderboard, Passport/Profile)
    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          LearningHomeView(
            onSelectExam: (examId) => setState(() => _selectedExamId = examId),
            onSelectTest: (testId) {
              setState(() {
                _selectedTestId = testId;
                _isViewingInstructions = true;
              });
            },
            onOpenCourseDetail: () {
              setState(() {
                _selectedCourseTitle = 'UI/UX Design Fundamentals';
                _isViewingCourseDetail = true;
              });
            },
            onOpenMyCourses: () {
              setState(() => _currentTabIndex = 1);
            },
          ),
          MyCoursesView(
            onSelectCourse: (title) {
              setState(() {
                _selectedCourseTitle = title;
                _isViewingCourseDetail = true;
              });
            },
          ),
          const MarketplaceScreen(),
          const LeaderboardView(),
          PassportView(
            onLogout: () {
              setState(() {
                _hasSeenOnboarding = false;
                _isViewingLogin = true;
              });
            },
          ),
        ],
      ),

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (idx) {
            setState(() {
              _selectedExamId = null;
              _currentTabIndex = idx;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: LearningTheme.primaryPurple,
          unselectedItemColor: LearningTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded, color: LearningTheme.primaryPurple),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school_rounded, color: LearningTheme.primaryPurple),
              label: 'My Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded, color: LearningTheme.primaryPurple),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_outlined),
              activeIcon: Icon(Icons.leaderboard_rounded, color: LearningTheme.primaryPurple),
              label: 'Ranks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded, color: LearningTheme.primaryPurple),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
