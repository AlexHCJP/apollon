part of 'apollon.dart';

/// A debug screen that lists all providers currently alive in the nearest
/// [ProviderScope].
///
/// Each entry shows the runtime type and [toString] value of the provider's
/// [Listenable] instance and updates automatically whenever the container
/// changes. Add this screen to your dev-only routes to inspect state at
/// runtime without attaching a debugger.
class ApollonDebugScreen extends StatelessWidget {
  /// Creates the [ApollonDebugScreen].
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
