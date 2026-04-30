# apollon

A minimal, dependency-free Riverpod-inspired state management package for Flutter built on top of `Listenable` / `ChangeNotifier`.

---

## Features

- **`Provider<T>`** — declare lazy singleton providers that return any `Listenable`
- **`ProviderScope`** — single widget that owns the container and rebuilds the tree on invalidation
- **`context.read(provider)`** — read a provider instance from anywhere in the widget tree
- **`container.watch(provider)`** — declare reactive dependencies between providers (dependent is re-created when the dependency changes)
- **`ApollonDebugScreen`** — built-in debug screen that lists every live provider and its current state

---

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  apollon: last_version
```

Wrap your app with `ProviderScope`:

```dart
void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(home: MyHome()),
    ),
  );
}
```

---

## Usage

### 1. Declare providers

```dart
final counterProvider = Provider((context, container) {
  return CounterNotifier();
});
```

Any `Listenable` works — `ChangeNotifier`, `ValueNotifier`, or your own subclass.

### 2. Read a provider in a widget

```dart
context.read(counterProvider)
```

The call is lazy: the instance is created on the first access and cached for the lifetime of the `ProviderScope`.

### 3. React to changes

Use Flutter's built-in builders — no custom `Consumer` widget needed:

```dart
ListenableBuilder(
  listenable: context.read(counterProvider),
  builder: (context, _) => Text('${context.read(counterProvider).count}'),
),
```

### 4. Reactive dependencies between providers

Call `container.watch(otherProvider)` inside a provider factory. The dependent provider is automatically invalidated whenever the watched provider notifies:

```dart
final counterA = Provider((context, container) => CounterA());

final counterB = Provider((context, container) {
  final a = container.watch(counterA); // re-created when counterA notifies
  return ValueNotifier<int>(a.count);
});
```

### Full example

```dart
final counterA = Provider((context, container) => CounterA());

final counterB = Provider((context, container) {
  final a = container.watch(counterA);
  return ValueNotifier<int>(a.count);
});

class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListenableBuilder(
          listenable: context.read(counterA),
          builder: (_, __) => Text('A: ${context.read(counterA).count}'),
        ),
        ValueListenableBuilder(
          valueListenable: context.read(counterB),
          builder: (_, value, __) => Text('B: $value'),
        ),
        ElevatedButton(
          onPressed: () => context.read(counterA).increment(),
          child: const Text('Increment A'),
        ),
      ],
    );
  }
}
```

---

## Debug screen

`ApollonDebugScreen` shows every registered provider with its runtime type and current `toString()` value. Add it to your dev build:

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => ApollonDebugScreen()),
);
```

---

## API reference

| Symbol | Description |
|---|---|
| `Provider<T extends Listenable>` | Declares a provider with a factory `(BuildContext, container) → T` |
| `ProviderScope` | Widget that owns the container and exposes it to the tree |
| `context.read(provider)` | Reads (and lazily creates) a provider instance |
| `container.watch(provider)` | Inside a factory: registers a reactive dependency |
| `container.entries` | Unmodifiable map of all live provider instances |
| `ApollonDebugScreen` | Debug widget listing all active providers |

---

## Constraints

- Every provider must return a `Listenable` (`ChangeNotifier`, `ValueNotifier`, etc.).
- Providers are singletons scoped to the nearest `ProviderScope`.
- There is no scoped / overridden provider support — one scope per app.
