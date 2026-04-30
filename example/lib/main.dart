import 'package:flutter/material.dart';
import 'package:mini_riverpod/mini_riverpod.dart';



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
        home: Scaffold(
          body: Center(
            child: CounterWidget(),
          ),
        ),
      ),
    ),
  );
}

class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ListenableBuilder(
          listenable: context.mr(counterA),
          builder: (context, child) {
            return Text('Counter A: ${context.mr(counterA).count}');
          },
        ),
        ValueListenableBuilder(
          valueListenable: context.mr(counterB),
          builder: (context, value, child) {
            return Text('Counter B: $value');
          },
        ),
        
        ElevatedButton(
          onPressed: () => context.mr(counterA).increment(),
          child: const Text('Increment Counter A'),
        ),
        ElevatedButton(
          onPressed: () => context.mr(counterB).value++,
          child: const Text('Increment Counter B'),
        ),
        ElevatedButton(onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MiniRivirpodScreen()),
            );
        }, child: Text('Tools')),
      ],
    );
  }
}