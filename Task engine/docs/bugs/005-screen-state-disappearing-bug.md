# Bug Report: BLoC State Inheritance & List Disappearing Bug

## Issue Description
When navigating into any detail screen (such as Worker Detail, Buyer Detail, or Campaign Detail) and then navigating back to the main directory list (Worker Directory, Buyer Directory, or Campaigns List), the list would completely disappear, leaving a blank screen (`SizedBox()`).

## Deep Root Cause Analysis
The app uses a single instance of `WorkersBloc` (and `BuyersBloc`, `OrdersBloc`) registered globally at `main.dart`.
In `WorkersBloc`, the state hierarchy was defined as:
```dart
abstract class WorkersState {}
class WorkersLoading extends WorkersState {}
class WorkersLoaded extends WorkersState { final List<WorkerModel> workers; ... }
class WorkerDetailLoaded extends WorkersState { final WorkerModel worker; ... }
```

1. When `WorkerDirectoryScreen` loads, `WorkersBloc` emits `WorkersLoaded`. The directory screen checks `if (state is WorkersLoaded)` and renders the list of workers.
2. When the user taps a worker to view details, `WorkerDetailScreen` dispatches `LoadWorkerDetailEvent`.
3. `WorkersBloc` emitted `WorkerDetailLoaded`.
4. Because `WorkersBloc` is shared, `WorkerDirectoryScreen`'s `BlocBuilder` also received the state change to `WorkerDetailLoaded`.
5. In `WorkerDirectoryScreen`, `if (state is WorkersLoaded)` evaluated to **`false`** because `WorkerDetailLoaded` did **not** extend `WorkersLoaded`.
6. `WorkerDirectoryScreen` fell through to `return const SizedBox()`, causing the list of workers to completely vanish from the UI!
7. The exact same architectural bug was present in `BuyersBloc` and `OrdersBloc`.

## Solution & Architecture Fix

### 1. State Inheritance Pattern
Updated `WorkerDetailLoading` and `WorkerDetailLoaded` to inherit directly from `WorkersLoaded`:
```dart
class WorkersLoaded extends WorkersState {
  final List<WorkerModel> workers;
  WorkersLoaded(this.workers);
}

class WorkerDetailLoading extends WorkersLoaded {
  WorkerDetailLoading(List<WorkerModel> workers) : super(workers);
}

class WorkerDetailLoaded extends WorkersLoaded {
  final WorkerModel worker;
  final List<dynamic> tasks;
  // ...
  WorkerDetailLoaded({
    required List<WorkerModel> workers,
    required this.worker,
    // ...
  }) : super(workers);
}
```

### 2. In-Memory List Caching in BLoC
Added `_cachedWorkers` (and `_cachedBuyers`, `_cachedOrders`) inside the BLoC instances:
- When loading or refreshing directory lists, `_cachedWorkers` is updated.
- When loading detail views, the BLoC passes `_cachedWorkers` to `WorkerDetailLoading` and `WorkerDetailLoaded`.

### 3. Result
- On `WorkerDirectoryScreen`, `if (state is WorkersLoaded)` evaluates to **`true`** even when `WorkerDetailLoaded` or `WorkerDetailLoading` is active.
- The directory screen continuously has access to `state.workers` and remains fully populated.
- When returning from detail screens, the list is instantly visible without extra network requests or UI flickering.

## Affected Files
- `lib/features/workers/presentation/bloc/workers_bloc.dart`
- `lib/features/buyers/presentation/bloc/buyers_bloc.dart`
- `lib/features/orders/presentation/bloc/orders_bloc.dart`
