import 'dart:async';

import 'package:flutter/material.dart';
import 'package:volt/jolt/value_notifier_helper.dart';
import 'package:volt/jolt/views.dart';

import 'jolt.dart';
import 'store.dart';

class ActionJolt<T> extends JoltView<T> implements Jolt<T> {
  void call(T value) => helper.addEvent(value);
}

class EventJolt<T> extends JoltView<T> with SinkJolt<T> {
  @override
  void add(T value) => helper.addEvent(value);
}

// ReadonlyJoltFromPureStream
// PureStream is a stream that does not receive errors through [Stream.addError] (from the [EventSink] interface)
class JoltFromPureStream<T> extends JoltView<T> implements Jolt<T> {
  final Stream<T> pureStream;
  late final StreamSubscription sub;

  JoltFromPureStream(this.pureStream) {
    sub = pureStream.listen(helper.addEvent);
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }
}

class JoltFromListenable<T extends Listenable> extends JoltView<T>
    implements Jolt<T> {
  final T listenable;
  late final VoidCallback listener;

  JoltFromListenable(this.listenable) {
    listener = () => helper.addEvent(listenable);
    listenable.addListener(listener);
  }

  @override
  void dispose() {
    listenable.removeListener(listener);
    super.dispose();
  }
}

class JoltFromValueNotifier<T> extends ValueJoltView<T>
    implements ValueJolt<T> {
  final ValueNotifier<T> notifier;
  late final VoidCallback listener;

  JoltFromValueNotifier(this.notifier) {
    listener = () => helper.addEvent(notifier.value);
    notifier.addListener(listener);
  }

  @override
  void dispose() {
    notifier.removeListener(listener);
    super.dispose();
  }
}

class StateJolt<T> extends StateView<T> with MutableValueJolt<T>, SinkJolt<T> {
  T get value => state;
  set value(T value) => emit(value);

  @override
  void add(T value) => this.value = value;

  StateJolt(T value) : super(value);
  StateJolt.late() : super.late();
}

class ComputedJolt<T> extends ComputedView<T> {
  final Compute<T> computeFn;

  ComputedJolt(this.computeFn);

  @override
  T compute(WatchBuilder watch) => computeFn(watch);
}

// ComputedJolt.map(jolt => AsyncJolt.fromFuture(jolt.future))
class ComputedFutureJolt<T> extends ComputedView<AsyncSnapshot<T>> with Store implements AsyncJolt<T> {
  late final AsyncStateJolt<T> _jolt = jolt.async();
  late final ComputedJolt<Future<T>> computedJolt;

  @override
  AsyncSnapshot<T> compute(watch) {
    final future = watch.value(computedJolt);
    _jolt.future = future;
    return watch.value(_jolt);
  }

  ComputedFutureJolt(Compute<Future<T>> calc) {
    computedJolt = jolt.computed(calc);
  }
  
  @override
  T get data => _jolt.data;
  
  @override
  Future<T> get future => _jolt.future;
  
  @override
  bool get hasData => _jolt.hasData;
  
  @override
  ConnectionState get status => _jolt.status;
  
  @override
  Stream<T> get stream => _jolt.stream;
  
  @override
  AsyncSnapshot<T> get value => _jolt.value;
  
}

class ComputedStreamJolt<T> extends ComputedView<AsyncSnapshot<T>> with Store implements AsyncJolt<T> {
  late final AsyncStateJolt<T> _jolt = jolt.async();
  late final ComputedJolt<Stream<T>> computedJolt;

  @override
  AsyncSnapshot<T> compute(watch) {
    final stream = watch.value(computedJolt);
    _jolt.stream = stream;
    return watch.value(_jolt);
  }

  ComputedStreamJolt(Compute<Stream<T>> calc) {
    computedJolt = jolt.computed(calc);
  }
  
  @override
  T get data => _jolt.data;
  
  @override
  Future<T> get future => _jolt.future;
  
  @override
  bool get hasData => _jolt.hasData;
  
  @override
  ConnectionState get status => _jolt.status;
  
  @override
  Stream<T> get stream => _jolt.stream;
  
  @override
  AsyncSnapshot<T> get value => _jolt.value;
}

class FutureSubscription<T> {
  final void Function(T) onValue;
  final void Function(Object? error, StackTrace stackTrace) onError;
  FutureSubscription(this.onValue, this.onError);
}

abstract class AsyncJolt<T> implements ValueJolt<AsyncSnapshot<T>> {
  AsyncSnapshot<T> get value;

  ConnectionState get status;

  bool get hasData;

  T get data;
  Stream<T> get stream;
  Future<T> get future;
}

abstract class AsyncStateJolt<T> implements ValueJolt<AsyncSnapshot<T>> {
  AsyncSnapshot<T> get value;
  set value(AsyncSnapshot<T> value);

  ConnectionState get status;

  bool get hasData;

  T get data;
  void set data(T value);
  Stream<T> get stream;
  set stream(Stream<T> stream);
  Future<T> get future;
  set future(Future<T> future);

}

/// a Mutable Async Jolt that can accept futures, streams and values
/// setting [valueFuture] starts tracking the future
/// setting a [asStream] starts tracking the stream
/// setting [value] sets the value
class MutableStateJolt<T> extends ComputedView<AsyncSnapshot<T>> with Store implements AsyncStateJolt<T> {
  final stateJolt = jolt.state(AsyncSnapshot<T>.nothing());

  final state = jolt.state(AsyncSnapshot<T>.nothing());

  @override
  AsyncSnapshot<T> compute(watch) => state.currentValue;

  MutableStateJolt() : super();

  MutableStateJolt.fromFuture(Future<T> future) {
    future = future;
  }

  MutableStateJolt.fromStream(Stream<T> stream) {
    stream = stream;
  }

  @override
  AsyncSnapshot<T> get value => currentValue;

  @override
  ConnectionState get status => value.connectionState;

  @override
  set value(AsyncSnapshot<T> value) {
    _cancelTracking();
    // WARNING: AsyncSnapshot.nothing .loading could be non const
    stateJolt.add(value);
  }

  dynamic _externalSubscription;

  bool _isWaiting(AsyncSnapshot<T> value) =>
      value.connectionState == ConnectionState.waiting ||
      value.connectionState == ConnectionState.none;

  @override
  bool get hasData => !_isWaiting(value);

  @override
  T get data => state.currentValue.data!;

  @override
  set data(T value) => this.value = AsyncSnapshot.withData(ConnectionState.done, value);

  @override
  Future<T> get future {
    Future<T> handleSnapshot(AsyncSnapshot<T> snapshot) {
      return snapshot.hasData
          ? Future.value(snapshot.data)
          : Future.error(snapshot.error ??
              Exception(
                  "[FutureJolt<$T>]: Expected error from failed future."));
    }

    // waiting for a value
    if (_isWaiting(value))
      return asStream
          .firstWhere((value) => !_isWaiting(value))
          .then(handleSnapshot);
    else
      return handleSnapshot(value);
  }

  void _cancelTracking() {
    final sub = _externalSubscription;
    if (sub is StreamSubscription) {
      sub.cancel();
    }
    _externalSubscription = null;
  }

  @override
  set future(Future<T> future) {
    _cancelTracking();
    value = const AsyncSnapshot.waiting();
    late final FutureSubscription<T> subscription;
    subscription = FutureSubscription(
      (value) => _externalSubscription == subscription
          ? this.value = AsyncSnapshot.withData(ConnectionState.none, value)
          : null,
      (error, stackTrace) => _externalSubscription == subscription
          ? value =
              AsyncSnapshot.withError(ConnectionState.done, error ?? Error())
          : null,
    );
    future.then(subscription.onValue).catchError(subscription.onError);
    _externalSubscription = subscription;
  }

  @override
  Stream<T> get stream {
    return asStream
        .where((snapshot) => !_isWaiting(snapshot))
        .map((snapshot) => snapshot.data!);
  }

  @override
  set stream(Stream<T> stream) {
    _cancelTracking();
    value = const AsyncSnapshot.waiting();
    late final StreamSubscription subscription;
    // WARNING:
    // If you use StreamController, the onListen callback is called before the listen call returns the StreamSubscription. Don’t let the onListen callback depend on the subscription already existing. For example, in the following code, an onListen event fires (and handler is called) before the subscription variable has a valid value.
    // https://dart.dev/articles/libraries/creating-streams#creating-a-stream-from-scratch
    subscription = stream.listen(
      (value) =>
          stateJolt.add(AsyncSnapshot.withData(ConnectionState.active, value)),
      onError: (error) =>
          stateJolt.add(AsyncSnapshot.withError(ConnectionState.done, error)),
      onDone: () => stateJolt.add(const AsyncSnapshot.nothing()),
    );
    _externalSubscription = subscription;
  }
}




// question: how to share as much code between Readonly/Computed/Mutable(Future|Stream|Async|Int|Double|Bool)
// we will have to use extension/mixins/override interface, since that's what dart's type system allows for
// Future/Stream are already values that change over time (states, jolts), so they would be treated differently
// than immutable primitives. What about List and Store?

// abstract class FutureJolt<T> implements ValueJolt<AsyncSnapshot<T>> {

//   AsyncSnapshot<T> get value;

//   Future<T> get future;

//   T? get valueOrNull;

//   Object? get errorOrNull;
  
//   T get tryValue;
  
//   Object get tryError;

//   factory FutureJolt.computed(Compute<Future<T>> compute) = _ComputedFutureJolt.computed;
//   factory FutureJolt.future(Future<T> future) = _ComputedFutureJolt.future;
//   factory FutureJolt.value(AsyncSnapshot<T> value) = _ReadonlyFutureJolt;
// }

// abstract class AsyncJolt<T> implements FutureJolt<T>, MutableValueJolt<AsyncSnapshot<T>> {

// } 


// class _ComputedFutureJolt<T> extends ComputedView<AsyncSnapshot<T>> implements FutureJolt<T> {

//   final ComputedJolt<Future<T>> computed;

//   final AsyncSnapshot<T>? readonlyValue;

//   _ComputedFutureJolt.computed(Compute<Future<T>> compute) : computed = ComputedJolt(compute), readonlyValue = null;
//   _ComputedFutureJolt.future(Future<T> future) : computed = ComputedJolt((_) => future), readonlyValue = null;

//   final state = StateJolt(AsyncSnapshot<T>.waiting());

//   late Future<T> _trackingFuture;

//   @override
//   Future<T> get future => _trackingFuture;

//   @override
//   AsyncSnapshot<T> get value => currentValue;

//   @override
//   T? get valueOrNull => value.data;

//   @override
//   Object? get errorOrNull => value.error;
  
//   @override
//   T get tryValue => value.data!;
  
//   @override
//   Object get tryError => value.error!;

//   @override
//   AsyncSnapshot<T> compute(watch) {
//     if (readonlyValue != null) return readonlyValue!;
//     final future = watch.value(computed);
//     if (_trackingFuture != future) {
//       _trackingFuture = future;
//       future.then((value) {
//         if (_trackingFuture == future) {
//           state.add(AsyncSnapshot.withData(ConnectionState.done, value));
//         }
//       });
//       future.catchError((error) {
//         if (_trackingFuture == future) {
//           state.add(AsyncSnapshot.withError(ConnectionState.done, error));
//         }
//       });
//       state.add(AsyncSnapshot<T>.waiting());
//     }
//     return watch.value(state);
//   }
// }

// class _ReadonlyFutureJolt<T> extends ComputedView<AsyncSnapshot<T>> implements FutureJolt<T> {
//   _ReadonlyFutureJolt(this.value);

//   @override
//   final AsyncSnapshot<T> value;
  
//   @override
//   AsyncSnapshot<T> compute(WatchBuilder watch) => value;
  
//   @override
//   Object? get errorOrNull => value.error;
  
//   @override
//   Future<T> get future {
//     if (value.hasData) return Future.value(value.data);
//     if (value.hasError) return Future.error(value.error!);
//     else return Completer<T>().future;
//   }
  
//   @override
//   Object get tryError => value.error!;
  
//   @override
//   T get tryValue => value.data!;
  
//   @override
//   T? get valueOrNull => value.data;
// } 



// class ComputedStreamJolt<T> extends ComputedView<AsyncSnapshot<T>> {
//   final StateJolt<AsyncSnapshot<T>> jolt =
//       StateJolt(const AsyncSnapshot.waiting());

//   final Stream<T> stream;

//   late final StreamSubscription subscription;

//   ComputedStreamJolt(this.stream) {
//     subscription = stream.listen(
//       (value) =>
//           jolt.add(AsyncSnapshot.withData(ConnectionState.active, value)),
//       onError: (error) =>
//           jolt.add(AsyncSnapshot.withError(ConnectionState.done, error)),
//       onDone: () => jolt.add(AsyncSnapshot<T>.nothing()),
//     );
//   }

//   @override
//   AsyncSnapshot<T> compute(WatchBuilder watch) {
//     return watch.value(jolt);
//   }
// }