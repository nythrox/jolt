// ignore_for_file: curly_braces_in_flow_control_structures, prefer_function_declarations_over_variables

/*

// simply no land for old men. it's IMPOSSIBLE to allow for the stream.map.map because even if u solved the IO,
you'd have to manually override every single map function for every single subtype (no type magic allowed :c)

how bout:

Jolt<I,O>.addTransformer<O2>() // Jolt<I,O2>


now using the stream for only ValueEvents,
meaning that other events will have to be normal
method calls

ok so maybe dont have .value as the required param, but some method currentValue()
.derive should work with streams, futures, valueStreams, etc. lots of little mini classes, all being allowed

be able to use .stream operators everywhere: during build, etc. have Auto Disposes
so that u can do a stream.timeout(200).build() or final value = read(eventJolt.stream.timeout(200))


*/

/*

what i want with my lib:

from a single abstraction you can derive
- observables w/ values
- event buses (streams)
- JoltStore (which provides additionals to inner jolts)

it would be cool if u could:
- build new jolt types from each other (be it extension, mixin, function scope composition, or something) 
  - hidateJolt, orDefaultJolt, 
    - should it be through class extend, mixin with, extend(), or get stream => parent.stream  
- compute obsrevables based on other observables from different types
- freely transform this abstraction from observable to changenotifier to stream to future, and let it be operated

JoltBuilder((context, watch) {
  final count = watch(countJolt);
})

- will it be possible to horizontally & automatically compose jolts? HidrateOrDefaultJolt

Riverpod is wrong: you shouldn't have observables that are both computed AND mutable.

also: explain to me how it wouldn't be easier to just
extension Store
  autodispose
  stream events
extension GetStream on ChangeNotifier


Builder((read) {
  read(store, when(old, new => old != new))
  readStream(store.stream.debounce().timeout().when())
  readFutureValue
})


StorageAtom.fromAtom()


question: how is ComputedJolt.fromFuture different from AsyncJolt?
how is AsyncJolt different from Jolt<Future<T>>?

- ComputedJolt is a read-only jolt that computes a new future each time a one of the read() jolts update
- AsyncJolt is a mutable jolt that lets you add Futures and Streams as values
- Jolt<Future<T>> is the same as AsyncJolt except you wouldn't be notified when the future's State changes, only when changing futures

ComputedJolt is purely a stream (derived from others), so maybe it has no reason to be a jolt
(since it doesnt have any setters)

*/

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:riverpod/riverpod.dart';
import 'package:volt/jolt2.dart';

// StateProvider is so weird cuz it allows u to watch others & edit current
final resetter = StateProvider((ref) => false);
final countProvider = StateProvider((ref) {
  ref.watch(resetter);
  return 0;
});

final doubleProvider = StateProvider((ref) => ref.watch(countProvider) * 2);

final futProvider = FutureProvider((ref) async {
  return 2;
});

final StreamProvider<Null> strProvider = StreamProvider((ref) async* {
  final lala = ref.read(futProvider);
  final owo = ref.read(strProvider);
  ref.read(futProvider.future);
});

void main() {
  countProvider.notifier.read().state = 20;
  resetter.notifier.read().state = true;

  final haha3 = ComputedJolt((watch) {
    return 10;
  });

  final haha2 = ComputedJolt.fromFuture((watch) async {
    for (final future in [1, 2, 3, 4, 5]
        .map((i) => Future.delayed(Duration(milliseconds: i * 100)))) {
      await future;
    }
  });

  final haha = ComputedJolt.fromStream((watch) async* {
    for (final future in [1, 2, 3, 4, 5].map(Future.value)) {
      var result = await future;
      yield result;
    }
  });
}

typedef EventListener<T> = void Function(T event);

// Although it’s possible to create classes that extend Stream with more functionality by extending the Stream class and implementing the listen method and the extra functionality on top, that is generally not recommended because it introduces a new type that users have to consider. Instead of a class that is a Stream (and more), you can often make a class that has a Stream (and more).
// https://dart.dev/articles/libraries/creating-streams#creating-a-stream-from-scratch
// Jolt is a ErrorlessStream
class EventJolt<T> {
  final notifier = ValueNotifier<T?>(null);

  @protected
  void add(T value) {
    notifier.value = value;
    notifier.notifyListeners();
  }

  // extend: events from that jolt get transmitted to this jolt
  // attach: listen to that jolt & when this gets disposed, dispose that one

  void extend(EventJolt<T> jolt) {
    extendMap(jolt, (T value) => value);
  }

  void extendMap<U>(EventJolt<U> jolt, T Function(U value) map) {
    watch(jolt, (U event) => add(map(event)), disposeJolt: true);
  }

  void watch<U>(
    EventJolt<U> jolt,
    void Function(U value) onListen, {
    bool disposeJolt = false,
  }) {
    jolt.addListener(onListen);
    onDispose(() {
      jolt.removeListener(onListen);
      if (disposeJolt) jolt.dispose();
    });
  }

  final List<FutureOr<void> Function()> onDisposeCallbacks = [];
  void onDispose(FutureOr<void> Function() fn) => onDisposeCallbacks.add(fn);

  Future<void> dispose() async {
    await Future.wait(onDisposeCallbacks.map((fn) => Future.value(fn())));
    notifier.dispose();
  }

  /// Only creates a StreamController if necessary (if .stream getter gets called)
  StreamController<T>? _controller;

  // check how this works after cancelling, re-subscribing, if it works for multiple streams
  Stream<T> get stream {
    final controller = _controller ??= () {
      final controller = StreamController<T>.broadcast(sync: true);
      final listener = (T event) => controller.add(event);
      controller.onListen = () => addListener(listener);
      Future<void> onCancel() {
        removeListener(listener);
        _controller = null;
        return controller.close();
      }

      controller.onCancel = onCancel;
      onDispose(onCancel);
      return controller;
    }();
    return controller.stream;
  }

  final _listeners = <EventListener<T>, VoidCallback>{};

  void addListener(EventListener<T> listener) {
    return notifier.addListener(
        _listeners[listener] = () => listener(notifier.value as T));
  }

  void removeListener(EventListener<T> listener) {
    notifier.removeListener(_listeners[listener]!);
    _listeners.remove(listener);
  }
}

class ActionJolt<T> extends EventJolt<T> {
  void call(T value) => add(value);
}

abstract class ValueJolt<T> extends EventJolt<T> {
  T get value;
}

abstract class SettableJolt<T> extends EventJolt<T> {
  set value(T value);
}

extension Tap<T> on Stream<T> {
  void tap(void Function(T value) action) {
    // WARNING: is this auto-disposed
    map(action);
  }
}

class ValueEvent<T> {
  final T newValue;
  ValueEvent(this.newValue);
}

mixin UniqueSubscriptions on EventJolt {}

typedef Exec = U Function<U>(ValueJolt<U> jolt);
typedef Calc<T> = T Function(Exec exec);

class ComputedJolt<T> extends ValueJolt<T> {
  final StateJolt<T> jolt = StateJolt.late();

  @override
  T get value => jolt.value;

  final Set<EventJolt> watching = {};

  ComputedJolt._() {
    extend(jolt);
  }

  run<R>(Calc<R> calc, void Function(R) handleValue) {
    U handleCalc<U>(ValueJolt<U> jolt) {
      if (!watching.contains(jolt)) {
        final listener = (U value) => handleValue(calc(handleCalc));
        jolt.addListener(listener);
        onDispose(() => jolt.removeListener(listener));
      }
      return jolt.value;
    }

    handleValue(calc(handleCalc));
  }

  ComputedJolt(Calc<T> calc) {
    void handleValue(T value) => jolt.value = value;
    run(calc, handleValue);
  }

  // note: should switchMap future (after every handleValue, needs to ignore the last one)
  static ComputedJolt<AsyncSnapshot<T>> fromFuture<T>(Calc<Future<T>> calc) {
    final computed = ComputedJolt<AsyncSnapshot<T>>._();
    computed.jolt.value = const AsyncSnapshot.waiting();

    void handleValue(Future<T> value) {
      value
          .then((value) => computed.jolt.value =
              AsyncSnapshot.withData(ConnectionState.active, value))
          .catchError((error) => computed.jolt.value =
              AsyncSnapshot.withError(ConnectionState.active, error));
    }

    computed.run(calc, handleValue);
    return computed;
  }

  static ComputedJolt<AsyncSnapshot<T>> fromStream<T>(
      Stream<T> Function(Exec) calc) {
    final computed = ComputedJolt<AsyncSnapshot<T>>._();
    computed.jolt.value = const AsyncSnapshot.waiting();

    void handleValue(Stream<T> value) {
      final sub = value.listen(
        (value) => computed.jolt.value =
            AsyncSnapshot.withData(ConnectionState.active, value),
        onError: (error) => computed.jolt.value =
            AsyncSnapshot.withError(ConnectionState.active, error),
      );
      final prevSub = computed._subscriptions[computed];
      if (prevSub != null) {
        prevSub.cancel();
      }
      computed._subscriptions[computed] = sub;
    }

    computed.run(calc, handleValue);

    return computed;
  }
}

class FutureComputedJolt<T> extends ValueJolt<AsyncSnapshot<T>> {
  final AsyncJolt<T> jolt = AsyncJolt();
  late final ComputedJolt<Future<T>> computedJolt;

  @override
  AsyncSnapshot<T> get value => jolt.value;

  FutureComputedJolt(Calc<Future<T>> calc) {
    computedJolt = ComputedJolt(calc);
    watch(computedJolt, (Future<T> future) => jolt.future = future,
        disposeJolt: true);
    extend(jolt);
  }
}

class StreamComputedJolt<T> extends ValueJolt<AsyncSnapshot<T>> {
  final AsyncJolt<T> jolt = AsyncJolt();
  late final ComputedJolt<Stream<T>> computedJolt;

  @override
  AsyncSnapshot<T> get value => jolt.value;

  StreamComputedJolt(Calc<Stream<T>> calc) {
    computedJolt = ComputedJolt(calc);
    watch(computedJolt, (Stream<T> stream) => jolt.stream = stream,
        disposeJolt: true);
    extend(jolt);
  }
}

class StateJolt<T> extends ValueJolt<T> implements SettableJolt<T> {
  late T _value;

  @override
  T get value => _value;

  StateJolt(this._value);
  StateJolt.late();

  @override
  set value(T value) {
    _value = value;
    add(value);
  }
}

// a Mutable Async Jolt that can accept futures, streams and values
class AsyncJolt<T> extends ValueJolt<AsyncSnapshot<T>>
    implements SettableJolt<AsyncSnapshot<T>> {
  final StateJolt<AsyncSnapshot<T>> jolt =
      StateJolt(const AsyncSnapshot.nothing());

  AsyncJolt() {
    extend(jolt);
  }

  factory AsyncJolt.fromFuture(Future<T> future) =>
      AsyncJolt()..future = future;

  factory AsyncJolt.fromStream(Stream<T> stream) =>
      AsyncJolt()..stream = stream;

  @override
  AsyncSnapshot<T> get value => jolt.value;

  ConnectionState get status => value.connectionState;

  @override
  set value(AsyncSnapshot<T> value) {
    // WARNING: AsyncSnapshot.nothing .loading could be non const
    jolt.value = value;
  }

  dynamic _externalSubscription;

  Future<T> get future {
    Future<T> handleSnapshot(AsyncSnapshot<T> snapshot) {
      return snapshot.hasData
          ? Future.value(snapshot.data)
          : Future.error(snapshot.error ??
              Exception(
                  "[FutureJolt<$T>]: Expected error from failed future."));
    }

    if (value == const AsyncSnapshot.waiting() ||
        value == const AsyncSnapshot.nothing())
      return stream.first.then(handleSnapshot);
    return handleSnapshot(value);
  }

  set future(Future<T> future) {
    _externalSubscription = null;
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

  set stream(Stream<T> stream) {
    _externalSubscription = null;
    value = const AsyncSnapshot.waiting();
    late final StreamSubscription subscription;
    // WARNING:
    // If you use StreamController, the onListen callback is called before the listen call returns the StreamSubscription. Don’t let the onListen callback depend on the subscription already existing. For example, in the following code, an onListen event fires (and handler is called) before the subscription variable has a valid value.
    // https://dart.dev/articles/libraries/creating-streams#creating-a-stream-from-scratch
    subscription = stream.listen(
      (value) => _externalSubscription == subscription
          ? jolt.value = AsyncSnapshot.withData(ConnectionState.active, value)
          : null,
      onError: (error) => _externalSubscription == subscription
          ? jolt.value = AsyncSnapshot.withError(ConnectionState.done, error)
          : null,
      onDone: () => _externalSubscription == subscription
          ? jolt.value = const AsyncSnapshot.nothing()
          : null,
    );
    _externalSubscription = subscription;
  }
}

class JoltBuilder {
  final EventJolt jolt;
  const JoltBuilder(this.jolt); 
}

final jolt = JoltBuilder();


class myFirstStore extends EventJolt {
  final num = jolt(0);
  late final double = jolt.computed((watch) => watch(num) * 2);
  late final futr = jolt.computed.future((watch) async => 2);
}
void alal() {
  jolt(0);
  jolt.computed((_) => 2);
  jolt.computed.future((exec) async => 2);
  jolt.late();
  jolt.future(Future.value(2));
}

extension s<T> on EventJolt<T> {
  JoltBuilder get jolt => JoltBuilder(this);
}

class StateJoltBuilder {
  const StateJoltBuilder();

  StateJolt<T> call<T>(T value) => StateJolt(value);

  StateJolt<T> late<T>() => StateJolt.late();
}

class AsyncJoltBuilder {
  const AsyncJoltBuilder();
  AsyncJolt<T> call<T>() => AsyncJolt();
  AsyncJolt<T> stream<T>(Stream<T> stream) => AsyncJolt.fromStream(stream);
  AsyncJolt<T> future<T>(Future<T> future) => AsyncJolt.fromFuture(future);
}

class ComputedJoltBuilder {
  const ComputedJoltBuilder();

  ComputedJolt<T> call<T>(Calc<T> calc) => ComputedJolt(calc);
  ComputedJolt<AsyncSnapshot<T>> future<T>(Calc<Future<T>> calc) =>
      ComputedJolt.fromFuture(calc);
  ComputedJolt<AsyncSnapshot<T>> stream<T>(Calc<Stream<T>> calc) =>
      ComputedJolt.fromStream(calc);
}

extension Stuff on JoltBuilder {
  // State
  StateJoltBuilder get state => const StateJoltBuilder();
  StateJolt<T> call<T>(T value) => state(value);
  StateJolt<T> late<T>() => state.late();

  // Async
  AsyncJoltBuilder get async => const AsyncJoltBuilder();
  AsyncJolt<T> stream<T>(Stream<T> stream) => async.stream(stream);
  AsyncJolt<T> future<T>(Future<T> future) => async.future(future);

  // Event
  EventJolt<T> events<T>() => EventJolt();

  // Computed
  ComputedJoltBuilder get computed => const ComputedJoltBuilder();
}
