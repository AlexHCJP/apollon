import 'package:apollon/apollon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('ApollonDebugScreen', () {
    testWidgets('shows "No providers registered" when container is empty', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const ApollonDebugScreen()));

      expect(find.text('No providers registered'), findsOneWidget);
    });

    testWidgets('lists live providers after they are read', (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              context.read(counterA);
              return const ApollonDebugScreen();
            },
          ),
        ),
      );

      await tester.pump();

      expect(find.text('No providers registered'), findsNothing);
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('subtitle shows provider toString output', (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              context.read(counterA);
              return const ApollonDebugScreen();
            },
          ),
        ),
      );

      await tester.pump();

      expect(find.text('CounterA(count: 0)'), findsOneWidget);
    });
  });
}
