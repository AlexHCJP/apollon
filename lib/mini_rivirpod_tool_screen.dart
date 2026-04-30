import 'package:flutter/material.dart';
import 'mini_riverpod.dart';

class MiniRivirpodScreen extends StatelessWidget {
  const MiniRivirpodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final container = ContainerProvider.of(context).container;

    return Scaffold(
      appBar: AppBar(title: const Text('Mini Riverpod')),
      body: ListenableBuilder(
        listenable: container,
        builder: (context, _) {
          final entries = container.entries.entries.toList();

          if (entries.isEmpty) {
            return const Center(child: Text('No providers registered'));
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final value = entries[index].value;
              return ListTile(
                title: Text(value.runtimeType.toString()),
                subtitle: Text(value.toString()),
              );
            },
          );
        },
      ),
    );
  }
}
