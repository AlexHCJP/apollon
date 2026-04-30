# mini_riverpod

A minimal, dependency-free Riverpod-inspired state management package for Flutter built on top of `Listenable` / `ChangeNotifier`.

---

## Features

- **`Provider<T>`** — declare lazy singleton providers that return any `Listenable`
- **`ProviderScope`** — single widget that owns the container and rebuilds the tree on invalidation
- **`context.mr(provider)`** — read a provider instance from anywhere in the widget tree
- **`container.watch(provider)`** — declare reactive dependencies between providers (dependent is re-created when the dependency changes)
- **`MiniRivirpodScreen`** — built-in debug screen that lists every live provider and its current state

---

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  mini_riverpod: last_version
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
context.mr(counterProvider)
```

The call is lazy: the instance is created on the first access and cached for the lifetime of the `ProviderScope`.

### 3. React to changes

Use Flutter's built-in builders — no custom `Consumer` widget needed:

```dart
ListenableBuilder(
  listenable: context.mr(counterProvider),
  builder: (context, _) => Text('${context.mr(counterProvider).count}'),
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
          listenable: context.mr(counterA),
          builder: (_, __) => Text('A: ${context.mr(counterA).count}'),
        ),
        ValueListenableBuilder(
          valueListenable: context.mr(counterB),
          builder: (_, value, __) => Text('B: $value'),
        ),
        ElevatedButton(
          onPressed: () => context.mr(counterA).increment(),
          child: const Text('Increment A'),
        ),
      ],
    );
  }
}
```

---

## Debug screen

`MiniRivirpodScreen` shows every registered provider with its runtime type and current `toString()` value. Add it to your dev build:

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => MiniRivirpodScreen()),
);
```

---

## API reference

| Symbol | Description |
|---|---|
| `Provider<T extends Listenable>` | Declares a provider with a factory `(BuildContext, ContainerProviders) → T` |
| `ProviderScope` | Widget that owns the `ContainerProviders` and exposes it to the tree |
| `context.mr(provider)` | Reads (and lazily creates) a provider instance |
| `container.watch(provider)` | Inside a factory: registers a reactive dependency |
| `container.entries` | Unmodifiable map of all live provider instances |
| `MiniRivirpodScreen` | Debug widget listing all active providers |

---

## Constraints

- Every provider must return a `Listenable` (`ChangeNotifier`, `ValueNotifier`, etc.).
- Providers are singletons scoped to the nearest `ProviderScope`.
- There is no scoped / overridden provider support — one scope per app.
