// the Jolt class is Read-only and emits [T] value
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'standard.dart';

typedef EventListener<T> = void Function(T event);

abstract class Jolt<T> {
  VoidCallback onEvent(EventListener<T> onEvent);

  void dispose();

  Stream<T> get asStream;

  // TODO: transform that may return ValueJolt, MutableJolt, EventJolt, etc. Remove the need of stream transformations, use jolt transformations
  // or: implement Stream<T> and allow for transformations
  // or: implement stream methods but returning different types of Jolts (maybe do this through extension functions)
  // same for Listenable, ChangeNotifier, ValueNotifier
  // TODO also: maybe (String|Bool]Int|Double|Num|List|Map|Set)Jolt

  //// a PureStream is a stream that does not receive errors through [Stream.addError] (from the [EventSink] interface)
  /// errors could be represented in a type-safe way using a class such as Result<T> (which codes a possible error in the type system,
  /// but still allows for easy access to the values through methods)
  factory Jolt.fromPureStream(Stream<T> stream) = JoltFromPureStream;
  static Jolt<L> fromListenable<L extends Listenable>(L listenable) => JoltFromListenable(listenable);
}

// interfaces for external Jolt consumption, and interfaces for internal jolt construction (ValueJolt, ReadonlyJolt, MutableJolt)

// Some jolts can be represented through computing other jolts, in that case you can extend ComputedView.
// if you want them to share the Computed interface, add a CustomJolt.computed(Computed<T> compute) constructor.
// Other jolts are very specific in when and how they emit new events. In that case, it's better to
// extend the StateView interface which grants you greater flexibility on how to emit() new events.

/// ComputedView is a abstract class that simplifies the proccess of managing subscriptions to other jolts:
/// you can subscribe to other jolts through the `watch` interface, and every time one of them emits a new value,
/// the `compute` function will be called and it's result will be emitted as the single new value.

// a jolt that you can publicly emit new values
abstract class SinkJolt<T> implements Jolt<T>, Sink<T> {
  @override
  void add(T value);

  @override
  void close() => dispose();
}

/// Allows for synchronous access to a [currentValue], which represents the current value of the state
abstract class ValueJolt<T> implements Jolt<T> { // , ValueNotifier<T>
  T get currentValue;

  // for now, no asNotifier until LazyValueNotifier is ready 
  // (won't force the Jolt to compute value until there are listeners)
  // ValueNotifier<T> get asNotifier;

  factory ValueJolt.fromValueNotifier(ValueNotifier<T> notifier) = JoltFromValueNotifier;
}

// Starting point for Jolts that represent a reactive State (mutable value that can change over time, where the current
// state can be accessed synchronously)
abstract class MutableValueJolt<T> implements ValueJolt<T>, SinkJolt<T> {
  void update(T Function(T currentValue) updateFn) => add(updateFn(currentValue));
}
