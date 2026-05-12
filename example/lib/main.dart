import 'package:flutter/material.dart';
import 'package:apollon/apollon.dart';

final counterA = Provider((context, container) {
  return CounterA();
});

final counterB = Provider((context, container) {
  final a = container.watch(counterA);
  return ValueNotifier<int>(a.count);
});

typedef CounterB = ValueNotifier<int>;

class CounterA extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  @override
  String toString() {
    return 'CounterA(count: $_count)';
  }
}

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: Center(child: CounterWidget())),
      ),
    ),
  );
}

class CounterWidget extends StatelessWidget {
  const CounterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ListenableBuilder(
          listenable: context.read(counterA),
          builder: (context, child) {
            return Text('Counter A: ${context.read(counterA).count}');
          },
        ),
        ValueListenableBuilder(
          valueListenable: context.read(counterB),
          builder: (context, value, child) {
            return Text('Counter B: $value');
          },
        ),

        ElevatedButton(
          onPressed: () => context.read(counterA).increment(),
          child: const Text('Increment Counter A'),
        ),
        ElevatedButton(
          onPressed: () => context.read(counterB).value++,
          child: const Text('Increment Counter B'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => ApollonDebugScreen())),
          child: const Text('Debug'),
        ),
      ],
    );
  }
}
