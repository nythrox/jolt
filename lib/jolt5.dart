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
class BaseJolt<T> {
  final notifier = ValueNotifier<T?>(null);

  @protected
  void addEvent(T value) {
    notifier.value = value;
    notifier.notifyListeners();
  }

  // extend: events from that jolt get transmitted to this jolt
  // attach: listen to that jolt & when this gets disposed, dispose that one

  void extend(BaseJolt<T> jolt) {
    extendMap(jolt, (T value) => value);
  }

  void extendMap<U>(BaseJolt<U> jolt, T Function(U value) map) {
    watch(jolt, (U event) => addEvent(map(event)), disposeJolt: true);
  }

  void watch<U>(
    BaseJolt<U> jolt,
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

abstract class Trackable<T, U> {
  T get value;
  void addListener(EventListener<U> callback);
  void removeListener(EventListener<U> callback);
  void dispose();
}

class EventJolt<T> extends BaseJolt<T> implements Trackable<void, T> {
  @override
  get value => {};

  void add(T value) => addEvent(value);
}

class ActionJolt<T> extends BaseJolt<T> {
  void call(T value) => addEvent(value);
}

extension Tap<T> on Stream<T> {
  void tap(void Function(T value) action) {
    // WARNING: is this auto-disposed
    map(action);
  }
}

mixin UniqueSubscriptions on BaseJolt {}

typedef ValueJolt<T> = Trackable<T, dynamic>;
typedef Exec = T Function<T>(ValueJolt<T> jolt);
typedef Compute<T> = T Function(Exec exec);

class ComputedJolt<T> extends BaseJolt<T> implements Trackable<T, T> {
  late T _value;

  @override
  T get value => _value;

  final Set<ValueJolt> watching = {};

  late final Compute<T> compute;

  ComputedJolt.fromHelpers(this.compute);

  ComputedJolt() {
    void handleValue(T value) {
      _value = value;
      addEvent(value);
    }

    _run(compute, handleValue);
  }
  _run<R>(Compute<R> calc, void Function(R) handleValue) {
    U handleCalc<U>(ValueJolt<U> jolt) {
      if (!watching.contains(jolt)) {
        final listener = (_) => handleValue(calc(handleCalc));
        jolt.addListener(listener);
        onDispose(() => jolt.removeListener(listener));
      }
      return jolt.value;
    }

    handleValue(calc(handleCalc));
  }
}

class StateJolt<T> extends BaseJolt<T> implements Trackable<T, T> {
  late T _value;

  @override
  T get value => _value;

  StateJolt(this._value);
  StateJolt.late();

  set value(T value) {
    _value = value;
    addEvent(value);
  }
}

class FutureSubscription<T> {
  final void Function(T) onValue;
  final void Function(Object? error, StackTrace stackTrace) onError;
  FutureSubscription(this.onValue, this.onError);
}

// a Mutable Async Jolt that can accept futures, streams and values
class AsyncJolt<T> extends ComputedJolt<AsyncSnapshot<T>> {
  final StateJolt<AsyncSnapshot<T>> jolt =
      StateJolt(const AsyncSnapshot.nothing());

  final state = StateJolt(AsyncSnapshot<T>.nothing());

  @override
  get compute => (get) => state.value;

  AsyncJolt() : super();

  AsyncJolt.fromFuture(Future<T> future) {
    this.future = future;
  }

  AsyncJolt.fromStream(Stream<T> stream) {
    this.stream = stream;
  }

  @override
  AsyncSnapshot<T> get value => jolt.value;

  ConnectionState get status => value.connectionState;

  set value(AsyncSnapshot<T> value) {
    _cancelTracking();
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

  void _cancelTracking() {
    final sub = _externalSubscription;
    if (sub is StreamSubscription) {
      sub.cancel();
    }
    _externalSubscription = null;
  }

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

  set stream(Stream<T> stream) {
    _cancelTracking();
    value = const AsyncSnapshot.waiting();
    late final StreamSubscription subscription;
    // WARNING:
    // If you use StreamController, the onListen callback is called before the listen call returns the StreamSubscription. Don’t let the onListen callback depend on the subscription already existing. For example, in the following code, an onListen event fires (and handler is called) before the subscription variable has a valid value.
    // https://dart.dev/articles/libraries/creating-streams#creating-a-stream-from-scratch
    subscription = stream.listen(
      (value) => jolt.value = AsyncSnapshot.withData(ConnectionState.active, value),
      onError: (error) => jolt.value = AsyncSnapshot.withError(ConnectionState.done, error),
      onDone: () => jolt.value = const AsyncSnapshot.nothing(),
    );
    _externalSubscription = subscription;
  }
}

class JoltBuilder {
  final BaseJolt jolt;
  const JoltBuilder(this.jolt);
}

final jolt = JoltBuilder();

class myFirstStore extends BaseJolt {
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

extension s<T> on BaseJolt<T> {
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

  ComputedJolt<T> call<T>(Compute<T> calc) => ComputedJolt(calc);
  ComputedJolt<AsyncSnapshot<T>> future<T>(Compute<Future<T>> calc) =>
      ComputedJolt.fromFuture(calc);
  ComputedJolt<AsyncSnapshot<T>> stream<T>(Compute<Stream<T>> calc) =>
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
  BaseJolt<T> events<T>() => BaseJolt();

  // Computed
  ComputedJoltBuilder get computed => const ComputedJoltBuilder();
}
