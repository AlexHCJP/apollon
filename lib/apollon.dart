import 'package:flutter/material.dart';

part 'apollon_tool_screen.dart';

class _ProviderContainer extends ChangeNotifier {
  final _singletons = <Provider<Listenable>, Listenable>{};
  final _dependents = <Provider<Listenable>, Set<Provider<Listenable>>>{};
  final _depListeners = <Provider<Listenable>, VoidCallback>{};
  Provider<Listenable>? _currentlyCreating;
  BuildContext? _currentContext;

  T read<T extends Listenable>(Provider<T> factory) {
    if (_singletons.containsKey(factory)) {
      return _singletons[factory] as T;
    }
    return _create(factory);
  }

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

  T watch<T extends Listenable>(Provider<T> factory) {
    final dep = _singletons.containsKey(factory)
        ? _singletons[factory] as T
        : _create(factory);

    if (_currentlyCreating != null) {
      final dependent = _currentlyCreating!;
      _dependents.putIfAbsent(factory, () => <Provider<Listenable>>{}).add(dependent);

      if (!_depListeners.containsKey(factory)) {
        void listener() => _invalidateDependents(factory);
        _depListeners[factory] = listener;
        dep.addListener(listener);
      }
    }

    return dep;
  }

  Map<Provider<Listenable>, Listenable> get entries => Map.unmodifiable(_singletons);

  void _invalidateDependents(Provider<Listenable> dep) {
    for (final dependent in List.of(_dependents[dep] ?? <Provider<Listenable>>{})) {
      _invalidate(dependent);
    }
  }

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

  @override
  void dispose() {
    for (final entry in _depListeners.entries) {
      _singletons[entry.key]?.removeListener(entry.value);
    }
    super.dispose();
  }
}

class ProviderScope extends StatefulWidget {
  final Widget child;

  const ProviderScope({super.key, required this.child});

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
    container.removeListener(_onContainerChanged);
    container.dispose();
    super.dispose();
  }

  void _onContainerChanged() => setState(() => _version++);

  @override
  Widget build(BuildContext context) {
    return _ProviderContainerScope(
      container: container,
      version: _version,
      child: widget.child,
    );
  }
}

class _ProviderContainerScope extends InheritedWidget {
  final _ProviderContainer container;
  final int version;

  const _ProviderContainerScope({
    required this.container,
    required this.version,
    required super.child,
  });

  static _ProviderContainerScope of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<_ProviderContainerScope>();
    assert(provider != null, 'No ContainerProvider found in context');
    return provider!;
  }

  @override
  bool updateShouldNotify(_ProviderContainerScope oldWidget) {
    return container != oldWidget.container || version != oldWidget.version;
  }
}

extension ProviderExtension on BuildContext {
  T read<T extends Listenable>(Provider<T> provider) {
    final containerProvider = _ProviderContainerScope.of(this);
    final container = containerProvider.container;
    container._currentContext = this;
    return container.read<T>(provider);
  }
}

class Provider<T extends Listenable> {
  Provider(this.create);

  T Function(BuildContext, _ProviderContainer) create;
}
