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


Builder((watch) {
  watch(store, when(old, new => old != new))
  watch(store.select((n) => n.name))
  watchStream(store.stream.debounce().timeout().when().where())
  watch(future.extract())
})


StorageAtom.fromAtom()


question: how is ComputedJolt.fromFuture different from AsyncJolt?
how is AsyncJolt different from Jolt<Future<T>>?

- ComputedJolt is a read-only jolt that computes a new future each time a one of the read() jolts update
- AsyncJolt is a mutable jolt that lets you add Futures and Streams as values
- Jolt<Future<T>> is the same as AsyncJolt except you wouldn't be notified when the future's State changes, only when changing futures

problems: solve AsyncJolt vs StreamJolt/FutureJolt(computed) vs StreamJolt/FutureJolt(value)
computed everything? where should computed be.

how should I unify all these. How should I convert betweem them. How should I build one from the other (must I really create a new class?)


Riverpod only has one type of Provider. 
  Computed, readonly
    - value
    - future
    - stream
  Stateful
    - value (no future handlings)

If everything you do is derived, you only need stateful and derived readonly ones. 
Since we are facilitating a mobx style, u need mutable helpers too
- Stateful
  - Async
    - Future
    - Stream
  - Value
- Derived readonly (computed)
  - Future
  - Stream
  - Value
- Un-derived readonly << whats the point of having un-derived if you can't mutate it, derived is the same and better (this is inferior, but could be used as a common base)
  - Future
  - Stream
  - Value

  ^^^ do we need all these????? FUCK!!!!!!!!!!!! Provider does it with just Computed
  --------------- but they don't allow for the BEAUTY of AsyncState
  maybe instead of AsyncState, have

  Future.from(future) // readonly
  Future.computed(stream) // computed readonly
  Future.state() // writable

  if we could simply derive NEW jolts from each other this would be intuitive
    - but you CAN'T. Jotai can't do it, Riverpod can't do it. You can only derive T, to 
      change/utilify behaviour you need EXTENSION (be it through class inheritence
      or decorators or dynamic extension (same as decorators but no unification of value, unsafe)).
    - You can't even do it with streams (since they would keep the same interface).
      - in both cases (they r the same (changenotifier/stream).map.transform) you can change T, but not get the xxtra juicy methods

  You're gonna have to have different classes. Because of how dart interfaces work, if u have state = 
  it can't be readonly. Thankfully since they're all Jolt they all interop.

  also: how bout higher interface jolts? will it facilitate with composition?

  to make the InterplanetaryUniversalExchangeInterplayInteropInterface you would need to manually override interfaces, 
  or extend (bad cuz extension through derive is cleaner)

  InterplanetaryExchangeInterplayInteropInterface { } 
    would facilitate not having to create new classes to derive, manually override props or class inherit

    would be for extending empty jolt .computed, since u lose the inner interface
    unless it also has .add(), in this case u could keep .add but would still lose the rest of the interface
    once again the I,O problem (operators not modifying the original object, only the outer stream)

    I Repeat: conversion is only useful when converting from an empty jolt like Computed to a richer one like FutureComputed, because
    or else it erases all the previous jolts extras. adding Maps and etcs will be cool (so u dont have to create new classes) 
    but wont add NEW jolts (properties), which is what we want.

    also, dart problem: even tho u can just have JoltView.fromJolt<T>(Jolt<T>), base classes 
    would have to override() the constructors cuz they don't inherit 

    toStream and fromStream problem: converting into or from a stream always loses the Jolt's attributes 
    unless manually overridden every single time. (no HoT)

    Stream = Jolt = ChangeNotifier, except ChangeNotifier always has .value, jolt always has .value and different .listen, stream may not have .value
    
    so basically, Decorator/Derive/Compute paradigm facilitates (manually) building jolts from each other, but doesn't
    help with converting jolts, exchanging them, composing them through declarative functions (would need HoF)

  Jolts can either be made for extension (StreamView @override inherit) or Decorator Composition (callback params & manual-override) 
  - ideal would be everything through Decorator composition, but you end up having to re-create the same things like in Flutter 
  & lots of object instances.
    through StateJolt and ComputedJolt, you can basically build everything through derivation (writable + readonly).
      extending StateJolt is just messy. Decorator computability composition is cleaner. Remember Jotai doens't 
      have much composition, all is made through computed.
  ^order would always have to be:
    State +extra
    Readonly @override +extra
    Computed.chain(Readonly) // ComputedStreamJolt = StreamJolt.fromJolt<Stream<T>>()
  with extension its the opposite order, start with smallest (readonly -> state -> chained)
  


Question: Technically you can make everything from a primtive _valueNotifier or Stream. But do you
want everything to be made from primitives? No. You want to derive them through declarative jolts,
and have them interop


Stateful is the biggest primitive, since from it you can build computed and un-derived (just hide it!)

the only way to create all of these is composing them from each other (thats the point of 
having decorator composition, abstracting the interfaces and having to rewrite (no way to 
derive new types of jolts without new classesbecause you wouldn't be able to add/remove interface members))


Also, how does the stream vs change notifier vs Jolt unify? ComputedJolt could be purely a stream, while
State (and all derived) could be a simple ChangeNotifier
^ we could base everything on Streams, but would be heavier.

Store will only be helpers for dealing with streams, disposing them, communicating, etc
a Store may or may not be a jolt. if it is a jolt, let it have its own flexibility on defining its uses


Connection of JoltBuilder(), T value and Stream<T>. JoltBuilder will listen to the stream in order to get the .value,
so both must update together. Necessary for computed/derived. 
StreamBuilder and Rx operators will always only get Stream<T>, ignoring T value.

.listen and .value problem: .listen does not need an initial value, only T when updates. 
                            .value always needs a T! value, but many models start as T? 


.asStream
.asChangeNotifier
.asValueNotifier

Things fall apart.
Too complex, they are different models. Ignores the intricacies of different types of streams,
how compute() is not chain() (chain requires .value! always, chain is lazy)
Computed doesn't even work with State.late() since Computed is eager
ignores how streams are lazy and StateNotifiers are eager

that's so fucked

multiple different ways to create a store

// simply a group
Store {
  final count = state(0)
  void increment() {
    count.value++;
  }
}

// new type of StateJolt
CounterStore extends StateJolt<int> {
  CounterStore() : super(0);
  void increment() {
    value++;
  }
}

// wrapper around State jolt
CounterJolt extends JoltView<number> {
  final count = state(0)
  @override int compute(read) => read(count.value);
  void increment() {
    count.value++;
  }
}

// like flutter_bloc

CounterStore extends StateJolt<int> {
  CounterStore() : super(0);
  
  late final increment = ActionJolt<void>().tap((_) {
    value++;
  });
}


DONE
problem: extending computedJolt gives you access to addEvent()
need a way to extend (computed|state|event) jolt and only access it through its interface


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

  final name = ComputedJolt((exec) => 2).convert(JoltView.fromJolt);
}

typedef EventListener<T> = void Function(T event);

// Although it’s possible to create classes that extend Stream with more functionality by extending the Stream class and implementing the listen method and the extra functionality on top, that is generally not recommended because it introduces a new type that users have to consider. Instead of a class that is a Stream (and more), you can often make a class that has a Stream (and more).
// https://dart.dev/articles/libraries/creating-streams#creating-a-stream-from-scratch
// Jolt is a ErrorlessStream

/// lightweight helper for creating objects that implement the [Jolt] contract, using a [ValueNotifier] internally
/// you can extend it or encapsulate it in a class, then route the [Jolt] methods to the [ValueNotifierJoltHelper] values
class ValueNotifierJoltHelper<T> {
  final _notifier = ValueNotifier<T?>(null);

  T? get lastEmittedValue => _notifier.value;

  @protected
  void addEvent(T value) {
    _notifier.value = value;
    _notifier.notifyListeners();
  }

  // // extend: events from that jolt get transmitted to this jolt
  // // attach: listen to that jolt & when this gets disposed, dispose that one

  // void extend(BaseJolt<T> jolt) {
  //   extendMap(jolt, (T value) => value);
  // }

  // void extendMap<U>(BaseJolt<U> jolt, T Function(U value) map) {
  //   watch(jolt, (U event) => addEvent(map(event)), disposeJolt: true);
  // }

  // void watch<U>(
  //   BaseJolt<U> jolt,
  //   void Function(U value) onListen, {
  //   bool disposeJolt = false,
  // }) {
  //   jolt.addListener(onListen);
  //   onDispose(() {
  //     jolt.removeListener(onListen);
  //     if (disposeJolt) jolt.dispose();
  //   });
  // }

  final List<FutureOr<void> Function()> onDisposeCallbacks = [];
  void onDispose(FutureOr<void> Function() fn) => onDisposeCallbacks.add(fn);

  Future<void> dispose() async {
    // await Future.wait(onDisposeCallbacks.map((fn) => Future.value(fn())));
    _notifier.dispose();
  }

  /// Only creates a StreamController if necessary (if .stream getter gets called)
  StreamController<T>? _controller;

  // check how this works after cancelling, re-subscribing, if it works for multiple streams
  Stream<T> get asStream {
    final controller = _controller ??= () {
      final controller = StreamController<T>.broadcast(sync: true);
      final listener = (T event) => controller.add(event);
      VoidCallback? dispose;
      controller.onListen = () => dispose = onEvent(listener);
      Future<void> onCancel() {
        dispose?.call();
        dispose = null;
        _controller = null;
        return controller.close();
      }

      controller.onCancel = onCancel;
      onDispose(onCancel);
      return controller;
    }();
    return controller.stream;
  }

  VoidCallback onEvent(EventListener<T> listener) {
    final l = () => listener(_notifier.value as T);
    _notifier.addListener(l);

    return () => _notifier.removeListener(l);
  }
}

// BaseJolt for building jolts that can emit events on will

// for building Jolts whoms [value] derived from others
abstract class JoltView<T> implements Jolt<T, T> {
  @protected
  final helper = ValueNotifierJoltHelper<T>();

  @override
  VoidCallback onEvent(EventListener<T> onEvent) => helper.onEvent(onEvent);

  static JoltView<T> fromJolt<T>(ValueJolt<T> jolt) {
    return ComputedJolt((exec) => exec(jolt));
  }

  static Jolt<U,U> fromStream<U>(Stream<U> stream) {

  }

  @override
  void dispose() => helper.dispose();
  
  @override Stream<T> get asStream => helper.asStream;

  @override
  T get value => helper
      .lastEmittedValue!; // notifier value will already be set (after constructor call)

  final Set<ValueJolt> _watching = {};

  final Map<Symbol, dynamic> vars = {};

  // use(Jolt(0))

  T compute(Watch watch);

  JoltView() {
    _run<R>(Compute<R> calc, void Function(R) handleValue) {
      U handleCalc<U>(ValueJolt<U> jolt) {
        if (!_watching.contains(jolt)) {
          final listener = jolt.onEvent((_) => handleValue(calc(handleCalc)));
          helper.onDispose(listener);
        }
        return jolt.value;
      }

      handleValue(calc(handleCalc));
    }

    _run(compute, helper.addEvent);
  }
}

typedef ValueJolt<T> = Jolt<T, dynamic>;
typedef Watch = T Function<T>(ValueJolt<T> jolt);
typedef Compute<T> = T Function(Watch exec);

class ComputedJolt<T> extends JoltView<T> {
  final Compute<T> computeFn;

  ComputedJolt(this.computeFn);

  @override
  T compute(Watch watch) => computeFn(watch);
}

class ResettableJolt<T> extends JoltView<T> {
  final StateJolt<T> valueJolt;
  final T defaultValue;

  ResettableJolt(T value, this.defaultValue) : valueJolt = StateJolt(value);

  @override
  T compute(watch) => watch(valueJolt);

  void reset() => valueJolt.value = defaultValue;
}

abstract class JsonSerializable {
  String toJson();
}

// ComputedJolt.map(jolt => AsyncJolt.fromFuture(jolt.future))
class FutureComputedJolt<T> extends JoltView<AsyncSnapshot<T>> {
  final AsyncJolt<T> jolt = AsyncJolt();
  late final ComputedJolt<Future<T>> computedJolt;

  @override
  AsyncSnapshot<T> compute(watch) {
    final future = watch(computedJolt);
    jolt.future = future;
    return watch(jolt);
  }

  FutureComputedJolt(Compute<Future<T>> calc) {
    computedJolt = ComputedJolt(calc);
  }
}

final cache = {};

class HiveJolt<T extends JsonSerializable> extends JoltView<AsyncSnapshot<T>> {
  final asyncJolt = AsyncJolt<T>();
  final T Function(String value) fromJson;

  set value(T value) {}

  @override
  AsyncSnapshot<T> compute(Watch read) {
    return asyncJolt.value;
  }
}

abstract class Jolt<T, U> {
  T get value;
  VoidCallback onEvent(EventListener<U> onEvent);
  void dispose();

  Stream<U> get asStream;
}

extension Convertable<T,U> on Jolt<T,U> {
  J convert<T2,U2, J extends Jolt<T2, U2>>(J Function(Jolt<T,U>) converter) {
    return converter(this);
  }

  J chain<T2,U2, J extends Jolt<T2, U2>>(J Function(Stream<U>) converter) {
    return converter(asStream);
  }
}

class EventJolt<T> extends ValueNotifierJoltHelper<T> implements Jolt<void, T> {
  @override
  get value => {};

  void add(T value) => addEvent(value);
}

class ActionJolt<T> extends EventJolt<T> {
  void call(T value) => add(value);
}

extension Tap<T> on Stream<T> {
  void tap(void Function(T value) action) {
    // WARNING: is this auto-disposed
    map(action);
  }
}

mixin UniqueSubscriptions on ValueNotifierJoltHelper {}

class StateJolt<T> implements Jolt<T, T> {
  @protected
  final helper = ValueNotifierJoltHelper<T>();

  @override Stream<T> get asStream => helper.asStream;

  @override
  T get value => helper.lastEmittedValue!;
  set value(T value) => helper.addEvent(value);

  StateJolt(T value) {
    this.value = value;
  }
  StateJolt.late();

  @override
  void dispose() => helper.dispose();

  @override
  VoidCallback onEvent(EventListener<T> onEvent) => helper.onEvent(onEvent);
}

class FutureSubscription<T> {
  final void Function(T) onValue;
  final void Function(Object? error, StackTrace stackTrace) onError;
  FutureSubscription(this.onValue, this.onError);
}

class StreamJolt<T> extends JoltView<AsyncSnapshot<T>> {
  final StateJolt<AsyncSnapshot<T>> jolt =
      StateJolt(const AsyncSnapshot.waiting());

  final Stream<T> stream;

  late final StreamSubscription subscription;

  StreamJolt(this.stream) {
    // WARNING:
    // If you use StreamController, the onListen callback is called before the listen call returns the StreamSubscription. Don’t let the onListen callback depend on the subscription already existing. For example, in the following code, an onListen event fires (and handler is called) before the subscription variable has a valid value.
    // https://dart.dev/articles/libraries/creating-streams#creating-a-stream-from-scratch
    subscription = stream.listen(
      (value) =>
          jolt.value = AsyncSnapshot.withData(ConnectionState.active, value),
      onError: (error) =>
          jolt.value = AsyncSnapshot.withError(ConnectionState.done, error),
      onDone: () => jolt.value = const AsyncSnapshot.nothing(),
    );
  }

  @override
  AsyncSnapshot<T> compute(Watch watch) {
    return watch(jolt);
  }
}

/// a Mutable Async Jolt that can accept futures, streams and values
/// setting [valueFuture] starts tracking the future
/// setting a [asStream] starts tracking the stream
/// setting [value] sets the value
class AsyncJolt<T> extends JoltView<AsyncSnapshot<T>> {
  final StateJolt<AsyncSnapshot<T>> jolt =
      StateJolt(const AsyncSnapshot.nothing());

  final state = StateJolt(AsyncSnapshot<T>.nothing());

  @override
  AsyncSnapshot<T> compute(watch) => state.value;

  AsyncJolt() : super();

  AsyncJolt.fromFuture(Future<T> future) {
    future = future;
  }

  AsyncJolt.fromStream(Stream<T> stream) {
    stream = stream;
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

  bool _isWaiting(AsyncSnapshot<T> value) =>
      value.connectionState == ConnectionState.waiting ||
      value.connectionState == ConnectionState.none;

  bool get hasData => !_isWaiting(value);

  T get data => state.value.data!;

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

  Stream<T> get stream {
    return asStream
        .where((snapshot) => !_isWaiting(snapshot))
        .map((snapshot) => snapshot.data!);
  }

  set stream(Stream<T> stream) {
    _cancelTracking();
    value = const AsyncSnapshot.waiting();
    late final StreamSubscription subscription;
    // WARNING:
    // If you use StreamController, the onListen callback is called before the listen call returns the StreamSubscription. Don’t let the onListen callback depend on the subscription already existing. For example, in the following code, an onListen event fires (and handler is called) before the subscription variable has a valid value.
    // https://dart.dev/articles/libraries/creating-streams#creating-a-stream-from-scratch
    subscription = stream.listen(
      (value) =>
          jolt.value = AsyncSnapshot.withData(ConnectionState.active, value),
      onError: (error) =>
          jolt.value = AsyncSnapshot.withError(ConnectionState.done, error),
      onDone: () => jolt.value = const AsyncSnapshot.nothing(),
    );
    _externalSubscription = subscription;
  }
}

class JoltBuilder {
  final ValueNotifierJoltHelper jolt;
  const JoltBuilder(this.jolt);
}

final jolt = JoltBuilder();

class myFirstStore extends ValueNotifierJoltHelper {
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

extension s<T> on ValueNotifierJoltHelper<T> {
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
  ValueNotifierJoltHelper<T> events<T>() => ValueNotifierJoltHelper();

  // Computed
  ComputedJoltBuilder get computed => const ComputedJoltBuilder();
}
