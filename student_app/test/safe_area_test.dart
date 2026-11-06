import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/core/constants.dart';
import 'package:student_app/widgets/premium_nav_bar.dart';

/// Insets of a phone that draws edge to edge: a status bar / notch at the top
/// and a gesture bar at the bottom. Android 15 and later always do this, so
/// anything pinned to an edge has to account for it.
const _insets = EdgeInsets.only(top: 48, bottom: 36);

Widget _framed(Widget child) => MediaQuery(
      data: const MediaQueryData(
        size: Size(412, 915),
        padding: _insets,
        viewPadding: _insets,
        devicePixelRatio: 1.0,
      ),
      child: MaterialApp(home: child),
    );

void main() {
  group('PremiumNavBar', () {
    testWidgets('sits above the gesture bar instead of inside it',
        (tester) async {
      await tester.pumpWidget(_framed(
        Scaffold(
          extendBody: true,
          body: const SizedBox.expand(),
          bottomNavigationBar: PremiumNavBar(
            currentIndex: 0,
            onTap: (_) {},
            items: const [
              PremiumNavBarItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home'),
              PremiumNavBarItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Passport'),
            ],
          ),
        ),
      ));

      // The decorated pill is the bar's own Container.
      final pill = tester.widgetList<Container>(find.byType(Container)).first;
      final margin = pill.margin as EdgeInsets;
      expect(margin.bottom, PremiumNavBar.bottomGap + _insets.bottom,
          reason: 'the bar must clear the gesture inset, not use a fixed gap');
    });

    testWidgets('spaceFor reports bar height, gap and the device inset',
        (tester) async {
      late double reported;
      await tester.pumpWidget(_framed(Builder(builder: (context) {
        reported = PremiumNavBar.spaceFor(context);
        return const SizedBox();
      })));
      expect(
          reported,
          PremiumNavBar.barHeight +
              PremiumNavBar.bottomGap +
              _insets.bottom);
      expect(reported, greaterThan(100),
          reason: 'the old hardcoded 100 was short on a device with a '
              'gesture bar, which is what hid the last row');
    });
  });

  group('screens honour the device insets', () {
    /// Every direct child of a Scaffold body that is pinned to an edge should
    /// be inside a SafeArea, so nothing lands under the status or gesture bar.
    testWidgets('a bare Scaffold body would overlap, SafeArea prevents it',
        (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(_framed(Scaffold(
        backgroundColor: AppConstants.primaryDark,
        body: SafeArea(child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(key: key, width: 10, height: 10),
        )),
      )));
      final topLeft = tester.getTopLeft(find.byKey(key));
      expect(topLeft.dy, _insets.top,
          reason: 'content must start below the status bar');
    });
  });
}
