import 'package:apollon/apollon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('Provider singleton', () {
    testWidgets('read returns the same instance on repeated calls', (
      tester,
    ) async {
      late CounterA first;
      late CounterA second;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              first = context.read(counterA);
              second = context.read(counterA);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(identical(first, second), isTrue);
    });

    testWidgets('different providers return different instances', (
      tester,
    ) async {
      late CounterA a;
      late CounterB b;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              a = context.read(counterA);
              b = context.read(counterB);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('Provider initial value', () {
    testWidgets('CounterA starts at 0', (tester) async {
      late CounterA a;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              a = context.read(counterA);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(a.count, 0);
    });

    testWidgets('CounterB mirrors CounterA initial value', (tester) async {
      late CounterB b;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              b = context.read(counterB);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(b.value, 0);
    });
  });

  group('State mutation', () {
    testWidgets('incrementing CounterA updates its count', (tester) async {
      late CounterA a;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              a = context.read(counterA);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      a.increment();
      expect(a.count, 1);
    });

    testWidgets('UI reflects CounterA after increment via button', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              final a = context.read(counterA);
              return Column(
                children: [
                  ListenableBuilder(
                    listenable: a,
                    builder: (_, _) => Text('count:${a.count}'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.read(counterA).increment(),
                    child: const Text('inc'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('count:0'), findsOneWidget);

      await tester.tap(find.text('inc'));
      await tester.pump();

      expect(find.text('count:1'), findsOneWidget);
    });
  });

  group('entries getter', () {
    testWidgets('contains all providers that have been read', (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              context
                ..read(counterA)
                ..read(counterB);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // The ProviderScope State is reused on pumpWidget with the same root
      // type, so the container still holds counterA and counterB.
      await tester.pumpWidget(wrap(const ApollonDebugScreen()));

      expect(find.byType(ListTile), findsWidgets);
    });
  });
}
