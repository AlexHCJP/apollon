part of 'apollon.dart';

class ApollonDebugScreen extends StatelessWidget {
  const ApollonDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final container = _ProviderContainerScope.of(context).container;

    return Scaffold(
      appBar: AppBar(title: const Text('Apollon')),
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
