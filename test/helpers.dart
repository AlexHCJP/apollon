import 'package:apollon/apollon.dart';
import 'package:flutter/material.dart';

class CounterA extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  @override
  String toString() => 'CounterA(count: $_count)';
}

typedef CounterB = ValueNotifier<int>;

final counterA = Provider<CounterA>((context, container) => CounterA());

final counterB = Provider<CounterB>((context, container) {
  final a = container.watch(counterA);
  return ValueNotifier<int>(a.count);
});

Widget wrap(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);
