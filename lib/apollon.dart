import 'package:flutter/material.dart';

part 'apollon_tool_screen.dart';

class _ProviderContainer extends ChangeNotifier {
  final _singletons = <Provider<Listenable>, Listenable>{};
  final _dependents = <Provider<Listenable>, Set<Provider<Listenable>>>{};
  final _depListeners = <Provider<Listenable>, VoidCallback>{};
  Provider<Listenable>? _currentlyCreating;
  BuildContext? _currentContext;

  /// Returns an existing singleton for [factory], or creates one on first access.
  T read<T extends Listenable>(Provider<T> factory) {
    if (_singletons.containsKey(factory)) {
      return _singletons[factory] as T;
    }
    return _create(factory);
  }

  /// Instantiates [factory], registers the result as a singleton, and wires up
  /// any dependency listeners that were declared while this provider was being
  /// created.
  T _create<T extends Listenable>(Provider<T> factory) {
    final previous = _currentlyCreating;
    _currentlyCreating = factory;
    final instance = factory.create(_currentContext!, this);
    _currentlyCreating = previous;
    _singletons[factory] = instance;
    if (_depListeners.containsKey(factory)) {
      instance.addListener(_depListeners[factory]!);
    }
    return instance;
  }

  /// Returns the singleton for [factory] and registers it as a dependency of
  /// the provider currently being created, so that the dependent is invalidated
  /// whenever [factory]'s instance notifies its listeners.
  T watch<T extends Listenable>(Provider<T> factory) {
    final dep = _singletons.containsKey(factory)
        ? _singletons[factory] as T
        : _create(factory);

    if (_currentlyCreating != null) {
      final dependent = _currentlyCreating!;
      _dependents
          .putIfAbsent(factory, () => <Provider<Listenable>>{})
          .add(dependent);

      if (!_depListeners.containsKey(factory)) {
        void listener() => _invalidateDependents(factory);
        _depListeners[factory] = listener;
        dep.addListener(listener);
      }
    }

    return dep;
  }

  /// Unmodifiable snapshot of all currently alive provider singletons.
  Map<Provider<Listenable>, Listenable> get entries =>
      Map.unmodifiable(_singletons);

  /// Walks the dependency graph and invalidates every provider that directly
  /// or transitively depends on [dep].
  void _invalidateDependents(Provider<Listenable> dep) {
    List.of(_dependents[dep] ?? <Provider<Listenable>>{}).forEach(_invalidate);
  }

  /// Removes [provider]'s singleton from the cache, detaches its change
  /// listener, cascades invalidation to its dependents, and notifies the
  /// container's own listeners so the widget tree can rebuild.
  void _invalidate(Provider<Listenable> provider) {
    if (!_singletons.containsKey(provider)) return;
    final old = _singletons[provider]!;
    _singletons.remove(provider);
    if (_depListeners.containsKey(provider)) {
      old.removeListener(_depListeners[provider]!);
    }
    _invalidateDependents(provider);
    notifyListeners();
  }

  /// Removes all change listeners from live singletons before the container
  /// is discarded to prevent memory leaks.
  @override
  void dispose() {
    for (final entry in _depListeners.entries) {
      _singletons[entry.key]?.removeListener(entry.value);
    }
    super.dispose();
  }
}

/// Root widget that creates and owns the [_ProviderContainer] for the subtree.
///
/// Place [ProviderScope] near the top of the widget tree (e.g. wrapping
/// [MaterialApp]) so that all descendant widgets can access providers via
/// [ProviderExtension.read].
class ProviderScope extends StatefulWidget {
  /// Creates a [ProviderScope] that hosts a fresh [_ProviderContainer].
  const ProviderScope({required this.child, super.key});

  /// The subtree that can access providers registered in this scope.
  final Widget child;

  @override
  State<ProviderScope> createState() => _ProviderScopeState();
}

class _ProviderScopeState extends State<ProviderScope> {
  late final _ProviderContainer container;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    container = _ProviderContainer();
    container.addListener(_onContainerChanged);
  }

  @override
  void dispose() {
    container
      ..removeListener(_onContainerChanged)
      ..dispose();
    super.dispose();
  }

  void _onContainerChanged() => setState(() => _version++);

  @override
  Widget build(BuildContext context) => _ProviderContainerScope(
    container: container,
    version: _version,
    child: widget.child,
  );
}

class _ProviderContainerScope extends InheritedWidget {
  const _ProviderContainerScope({
    required this.container,
    required this.version,
    required super.child,
  });
  final _ProviderContainer container;
  final int version;

  static _ProviderContainerScope of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_ProviderContainerScope>();
    assert(provider != null, 'No ContainerProvider found in context');
    return provider!;
  }

  @override
  bool updateShouldNotify(_ProviderContainerScope oldWidget) =>
      container != oldWidget.container || version != oldWidget.version;
}

/// Convenience extension that lets any [BuildContext] read a [Provider]
/// without accessing the container directly.
extension ProviderExtension on BuildContext {
  /// Returns the singleton instance of [provider], creating it if needed.
  ///
  /// Call this inside a [StatefulWidget] or a callback where you want a
  /// one-time read. For reactive rebuilds inside a build method prefer
  /// using a [ListenableBuilder] around the value returned here.
  T read<T extends Listenable>(Provider<T> provider) {
    final containerProvider = _ProviderContainerScope.of(this);
    final container = containerProvider.container.._currentContext = this;
    return container.read<T>(provider);
  }
}

/// A factory object that describes how to create a singleton [Listenable] [T].
///
/// Declare providers at the top level (or as static fields) so that the
/// container can use object identity to cache and look up instances:
///
/// ```dart
/// final counterProvider = Provider((context, ref) => CounterNotifier());
/// ```
class Provider<T extends Listenable> {
  /// Creates a [Provider] with the given [create] factory.
  Provider(this.create);

  /// Factory function called once by the container to create the singleton.
  ///
  /// The [BuildContext] grants access to inherited widgets; the second
  /// argument is the container itself, which lets the factory call [_ProviderContainer.watch]
  /// to declare reactive dependencies on other providers.
  // ignore: library_private_types_in_public_api
  T Function(BuildContext, _ProviderContainer) create;
}
