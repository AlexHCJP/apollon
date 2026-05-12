import 'package:apollon/apollon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

// ---------------------------------------------------------------------------
// Three-level chain: _z → _chainA (watches z) → _chainB (watches chainA)
//
// Used to exercise two code paths that require an intermediate provider to be
// invalidated and then re-created:
//   • _create  line 30 — re-attaches existing listener to the new instance
//   • _invalidate line 77 — removes old listener from the discarded instance
// ---------------------------------------------------------------------------

class _CounterZ extends ChangeNotifier {
  int _value = 0;
  int get value => _value;
  void increment() {
    _value++;
    notifyListeners();
  }
}

final _z = Provider<_CounterZ>((_, _) => _CounterZ());

// _chainA watches _z so it becomes a dependent of _z.
final _chainA = Provider<CounterA>((_, container) {
  container.watch(_z);
  return CounterA();
});

// _chainB watches _chainA so it becomes a dependent of _chainA.
final _chainB = Provider<CounterB>((_, container) {
  final a = container.watch(_chainA);
  return ValueNotifier<int>(a.count);
});

void main() {
  group('watch — dependency tracking', () {
    // When counterA notifies, the container invalidates counterB. On the next
    // build the Builder re-reads counterB, which is re-created with the new
    // counterA value.
    testWidgets('CounterB value follows CounterA after invalidation', (
      tester,
    ) async {
      late CounterA a;
      int? counterBValue;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              a = context.read(counterA);
              counterBValue = context.read(counterB).value;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(counterBValue, 0);

      a.increment();
      await tester.pump();

      expect(counterBValue, 1);
    });

    testWidgets('multiple increments keep CounterB in sync', (tester) async {
      late CounterA a;
      int? counterBValue;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              a = context.read(counterA);
              counterBValue = context.read(counterB).value;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      for (var i = 1; i <= 3; i++) {
        a.increment();
        await tester.pump();
        expect(counterBValue, i);
      }
    });
  });

  group('watch — three-level chain (intermediate re-creation)', () {
    // When _z notifies:
    //   1. _chainA is invalidated → old listener removed from old instance (line 77)
    //   2. _chainB is invalidated → container notifies → Builder rebuilds
    //   3. _chainA is re-created → existing listener re-attached to new instance (line 30)
    //
    // The second z.increment() proves the listener survived re-attachment:
    // if line 30 were broken, the widget would not rebuild on the second call.
    testWidgets(
      'listener is re-attached after intermediate provider re-creation',
      (tester) async {
        _CounterZ? z;
        var buildCount = 0;

        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) {
                buildCount++;
                z = context.read(_z);
                context.read(_chainB);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(buildCount, 1);

        z!.increment();
        await tester.pump();
        expect(buildCount, 2);

        // Verifies line 30: listener was re-attached → second change still triggers a rebuild.
        z!.increment();
        await tester.pump();
        expect(buildCount, 3);
      },
    );
  });
}
