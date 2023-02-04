import 'package:flutter/foundation.dart';

import 'jolt.dart';
import 'store.dart';
import 'value_notifier_helper.dart';

// Views are utility classes that help you build custom jolts in a certain way,
// facilitating the construction of custom jolts

/// Utility mixin for creating a raw jolt using [ValueNotifierJoltHelper] that implements the [Jolt] interface
abstract class JoltView<T> with Store
    implements Jolt<T> {
  @protected
  final helper = ValueNotifierJoltHelper<T>();

  bool _initialized = false;

  @protected
  void lazyInit() {}

  @override
  VoidCallback onEvent(EventListener<T> onEvent) {
    if (!_initialized) {
      lazyInit();
      _initialized = true;
    }
    return helper.onEvent(onEvent);
  }

  @override
  void dispose() {
    super.dispose();
    helper.dispose();
  }

  @override
  Stream<T> get asStream => helper.asStream;
}

// todo: extend ValueNotifierJoltHelper to use less memory, but dont allow the methods to leak
/// Utility mixin for creating a raw jolt using [ValueNotifierJoltHelper] that implements the [ValueJolt] interface
abstract class ValueJoltView<T> extends JoltView<T> implements ValueJolt<T> {
  // with ValueNotifierMixinHelper<T>

  @override
  T get currentValue => helper.lastEmittedValue as T;
}

/**
 * 
 * TODO: (Future|Stream)ComputedView (?)
 * 
 * JoltView (@override get jolt), just shorthand for ComputedView @override compute => watch.value(jolt)
 * 
 */

/// Interface that facilitates the creation of [ValueJolt] through [emit] new values.
class StateView<T> extends ValueJoltView<T> implements ValueJolt<T> {
  T get state => currentValue;

  @protected
  void emit(T value) => helper.addEvent(value);

  StateView(T value) {
    emit(value);
  }

  StateView.late();
}

// All jolts are **LAZY**. They only start emitting events, or for ComputedViews: tracking
// their streams, once onEvent or stream.listen() is called.
// ^ this is wrong. they should track streams instantly, just like any stream transformer

// INTERESTING:
// there is a mismatch with ComputeStream/StreamTransformers: when the user believes debounce() and etc start tracking
// (as soon as .debounce() is called) vs when it actually starts: after the first .listener
// this seems to be ok, since it only starts mattering after the first listener (when widget wants to build)
// this is weird (probably even for BehaviourSubjects) since you can add events (which should be debounced)
// and accesss the value synchronously even before any listeners. Interplay between synchronous .value access
// and asynchronous post-listen streams is interesting.
// This problem seems to exist with BehaviourSubject, since setting the value is synchronous, before emitting
// and the value gets set even if the event gets discarded

// ComputedViews are **LAZY**. They don't start tracking their dependencies until their
// .value is called (which could be through a .asStream(startWithValue: true)).
// if you want to start tracking them instantly, .build or .autorun or
//
// it makes sense that its lazy until .value is explicitly called, since the .onEvent part of
// jolt does not require a initial value. But this may be confusing when someone subscribes to a stream
// (expected to already be running) and it does not update (until value is called). After all, if it subscribes
// to the Stream/StreamController contract, it should start running as soon as there is a subscriber.
//
// therefore: ComputedViews can't be Lazy, since we use streams to transform them
//
// problem: .listen() called from anywhere non directly, (not from build widget)

// Question: is there such a thing as a Stream that also has a synchronous value?
// shouldn't this be implemented using streams and not jolt (since it's a transformer, lazy,
// cancel/pause should be adequately handled)?
// There must be a reason why RxDart uses StreamController with value, and not Stream with value

// BaseJolt for building jolts that can emit events on will

// for building Jolts whoms [value] derived from others

// i thought u would be able to create Jolts from all complexities using ComputedView,
// but it has a lot of difficulty managing subscriptions from Jolts (no value),
// adding/removing subscriptions dynamically/conditionally,
// allowing for the creation/transformation of new jolts and streams. Would have to have a full
// fledged keyed-hook system, so i guess its better to just use ValueJoltFromValueNotifierHelper in those cases

/// Helpful interface for creating jolts using derived from other jolts (jotai or riverpod-style)
///
/// Computed jolts are **lazy**, so they will only start tracking other jolts once [onEvent] is called (or [Stream.listen]).
/// This means that ComputedJolts can watch [StateJolt.late] and other jolts that may not have their [currentValue]
/// set, and will only call them once they are forced to compute.
abstract class ComputedView<T> extends ValueJoltView<T>
    implements ValueJolt<T> {
  // JoltView.late();
  @override
  T get currentValue {
    if (_initialized)
      return super.currentValue;
    else {
      lazyInit();
      return super.currentValue;
    }
  }

  final Set<Jolt> _watching = {};

  // use(Jolt(0))
  final Map<Symbol, dynamic> _vars = {};

  @override
  lazyInit() => run();

  T compute(WatchBuilder watch);

  @protected
  void run() => _run(compute, helper.addEvent);

  late final _builder = WatchBuilder(this);

  void _run<R>(Compute<R> calc, void Function(R) handleValue) {
    handleValue(calc(_builder));
  }
}

// Builder((watch) {
//   watch(store, when: (old, new) => old != new)
//   watch(store, select: (n) => n.name)
//   watch.stream(store.stream.debounce().timeout().when().where())
//   watch.jolt(future).extract()
// })

extension Default<T> on T? {
  T orDefault(T value) {
    return this ?? value;
  }
}

// TODO: maybe watch.stream returns what a StreamBuilder would return? AsyncSnapshot? same for Future and FutureBuilder
class WatchBuilder {
  final ComputedView owner;

  WatchBuilder(this.owner);

  /// Computed always needs a immediate value when consuming Jolts
  /// watch.value(counter, transform: (stream) => stream.debounce())
  /// watch(event, initialValue: null, transform: (stream) => stream.debounce())
  T? call<T>(Jolt<T> jolt, {Object? key}) {
    // bool valueSet = false;
    T? value;
    if (!owner._watching.contains(jolt)) {
      final listener = jolt.onEvent((value) {
        value = value;
        // valueSet = true;
        owner.run();
      });
      owner.helper.onDispose(listener);
    }
    return value;
  }

  // stop allowing streams to be consumed now that we have Transform with PureStream
  // T stream<T>(Stream<T> jolt, T initialValue) {
  //   bool valueSet = false;
  //   T? value;
  //   if (!owner._watching.contains(jolt)) {
  //     final subscription = jolt.listen((value) {
  //       value = value;
  //       valueSet = true;
  //       owner.run();
  //     });
  //     owner.helper.onDispose(subscription.cancel);
  //   }
  //   return valueSet ? value! : initialValue;
  // }

  // TODO: build this (for using keyed-hooks inside of a Compute function)
  /// Uses a stream created from [createStream], updated when [deps] change, always retrived from the same [key]
  // T useStream<T>(Stream<T> Function() createStream, T initialValue, {required Object key, List<Object>? deps}) {

  // }

  // ideal would be:
  // watch(jolt.debounce().map()) but need initial value, stream cannot be re-created each time, needs key to save key, and deps to know when to update
  // watch(jolt, transform: (s) => s.debounce().map()) // key is jolt, transform is only a signal, doesn't allow for outside stream-signals

  // Stream<T2> Function(Stream<T>)? transform}
  T value<T>(ValueJolt<T> jolt, {Stream Function()? signal, Object? key}) {
    key ??= jolt;
    if (!owner._watching.contains(jolt)) {
      final listener = jolt.onEvent((_) => owner.run());
      owner.helper.onDispose(listener);
    }
    return jolt.currentValue;
  }

  // J jolt<T, J extends Jolt<T>>(J jolt) {
  //   return jolt;
  // }

  // T stream<T, S extends Stream<T>>(S stream, T initialValue) {
  //   return istream;
  // }

  // S controller<T, S extends StreamController<T>>(S controller) {
  //   return controller;
  // }

  // T notifier<T, N extends ValueNotifier<T>>(N notifier) {
  //   return notifier.value;
  // }

  // L listenable<L extends Listenable>(L listenable) {
  //   return listenable;
  // }

}

typedef Compute<T> = T Function(WatchBuilder exec);
