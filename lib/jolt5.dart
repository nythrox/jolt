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

Library-wise: 
- unification of StateNotifier and Stream (interchangeability)
- composition problem for creating State Management objects 
  (keep properties & composition through: 
    - extension(statenotifier), 
    - jotai-style computed/decorated (jotai).orElse().compose(FutureJolt.fromJolt), 
    - streams<I,O>.map.flatMap (keep properties))
- operator problem for streams <I,O> keep original properties, modify interior output stream (with operators)
    - ^ u cant keep the same shape (ex BehaviourSubject(0).when(value != 0) so .value shouldn't exist in final stream)
Utility-wise
- atomic mutable state, State, Computed, Future, Stream
- streams: rx operators on ^ & use inside of computed
- store: emits event (stream), methods can come from streams (& use operators), helpers 4 consuming streams
- HiveJolt (with store that redirects HiveJolts.loading)

i wanted 2 things
- unification of StateNotifier and Stream models (impossible!)
  - Stream.fromStateNotifier is possible, but loses initial .value
  - StateNotifier.fromStream is impossible, streams don't have a initial .value
- composition problem: universal exchange system (2ez to add new plugins) impossible in dart type system

what i thought originally: static access of StateNotifier and operators+composition of Streams
  if everything was a BehaviourSubject would still have composition problem
  if everything was StateNotifier would have to re:make operators from zero, and EventStream wouldn't be possible

Streams are a much deeper, temporal-related concept. State is a subset, a series of changes where the time
matters less than the current state.

StateNotifier, Mobx, Jolt etc are sub-sets of Streams.
In order for a .computed to even work, .value must always represent the current state (equivalent of combineLatest)
it doesn't work for different models (ex getting the last event emitted for a event stream)

also: explain to me how it wouldn't be easier to just
extension Store
  autodispose
  stream events
extension GetStream on ChangeNotifier



todo: create mobx when, await when, reaction, (other than autorun), etc for stream jolt (no T value)
and be able to build jolts from that O.O 

we can't allow stream transformations inside of .read() because that would transform it into a Stream (not jolt), losing the .value needed for instant consumption


because I don't want it to be ValueJolt-centered, I'll leave the StreamJolt without a value and flexibilize ComputedJolt subscriptions

computed lazy by default

should all jolts be computed like provider/jotai 

Jolts are objects that can be subscribed to, 
they send out notificatoins to their subscribers with a value,
which can indicate that a value has changed, and event has happened or anything else.
They also have the concept of finality, when dispose() is called there should be no more notifications.
Reactivity is baked into the core of Jolt.
Jolts are hard typed and flexible in how to utilize/consume them. Since it's extremely
type safe, everything you want to do with your jolt should be represented in the type
system (ex: if you want to add errors, create another parameter for errors or represent the value as a Result).
In the joltverse, we have:
- streams: notifies listeners when an event occurs
- mutable states: notifies listeners when there is a state change


there are some primitives for consuming all Jolts: listen, when, react, etc

and some primtiives for creating custom jolts: StateView, JoltView
and some pre-defined jolts: StateJolt, ComputedJolt, AsyncJolt, EventJolt, ActionJolt
and some helpers for handling jolts and streams: Store
using these tools you can start making your own jolts (deriving them or handling listeners and emitting states)


StorageAtom.fromAtom()

extensions: 
ValueJolt<T> extends Jolt<T>.fromStream()
ErrorJolt<T> extends Jolt<Result<T>>.fromErrorStream()
AsyncJolt<T> extends Jolt<AsyncResult<T>>.fromFuture()

all these weird fucking adaptations to be able to consume streams in a ComputedJolt, non-value Jolts 
do they really even have anything in common, shouldnt jolt have its own operators so no black magic needed (then operator problem)
using jolt operators will be easier; preserving the .value but allowing interaction with valueless jolts 
!really: what is the advantage of using an EventJolt over a StreamController, if interop with ComputedJolt is the same,
to play with it you have to .listen and use stream operators to transform it. 
transform, operate, signal

focus on adding good features to Value Jolts: lazy by default, listen, when, react, etc., operators, 
views, composition, 

extending JoltView allows you to consume other jolts internally,
but should allow the user to send you jolts 
ex: AsyncJolt should be able to be build from any Jolt<Future<>>
so AsyncJolt.fromFuture(Future.value()) or AsyncJolt.fromJolt(ComputedJolt((read) => Future.value()))


question: how is ComputedJolt.fromFuture different from AsyncJolt?
how is AsyncJolt different from Jolt<Future<T>>?

- ComputedJolt is a read-only jolt that computes a new future each time a one of the read() jolts update
- AsyncJolt is a mutable jolt that lets you add Futures and Streams as values
- Jolt<Future<T>> is the same as AsyncJolt except you wouldn't be notified when the future's State changes, only when changing futures

problems: solve AsyncJolt vs StreamJolt/FutureJolt(computed) vs StreamJolt/FutureJolt(value)
computed everything? where should computed be.

how should I unify all these. How should I convert betweem them. How should I build one from the other (must I really create a new class?)


No need for readonly (readonly is not STATE)
All atoms with Computed constructors can not have mutable methods
Only atoms with Value constructors can have mutable methods (.value=, .reset(), .future=)

Riverpod only has one type of Provider. 
        Computed Readonly | Stateful | Readonly
Value     () => 0            0.=         0       
Future    () => Future       Future.=    Future
Stream    () => Stream       Stream.=    Stream

^ the number exponentially increased when you have not only those, but also withReset, withStorage, etc.
a universal exchange converter would solve this, but has its owm problems (for transforming outputs, adding prop functionality, and overriding)


It's better to start with a Computed (readonly state), because from that you can derrive Readonly and also Mutable State



Jolt configs(unique, )

watch.get(value) // hasValue, didChange, hasEmitted, previousValue

If everything you do is derived, you only need stateful and derived readonly ones (like Riverpod). 
Since we are facilitating a mobx style, u need mutable helpers too

  Computed, readonly
    - value
    - future
    - stream
  Stateful
    - value (no future handlings)


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
    unless it also has .add(), in this case u could keep .add but would still lose the rest of the interface (ex FutureJolt().withResettable())
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

    Ideal Composition: B(A).chain(C)
        where A StateJolt(0)
        where B(Jolt jolt) extends StreamView computed((read) => read(jolt) * 2)
        where C.from(C)

    so... should i be making composition like ZIO<R,E,A> (composing through .computed and mixins and extension) 
    or can something better exist

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
Too complex, they fundamentally are different models. Ignores the intricacies of different types of streams,
how compute() is not chain() (chain requires .value! always, chain is lazy)
Computed doesn't even work with State.late() since Computed is eager
ignores how streams are lazy and StateNotifiers are eager

that's so fucked

maybe its ok tho, riverpod forces initialValue on streams

multiple different ways to create a store


note: streams don't compose well without HKTs, neither do ValueNotifiers

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
    state++;
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
import 'package:get/get.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

class Whatever extends ComputedView<int> {

  final jolt = StateJolt(0);

  late final owo = jolt.transform((stream) => 
    stream
      .debounceTime(const Duration(seconds: 1))
      .where((event) => event % 2 == 0)
      .skip(3)
      .take(10),
  );

  @override
  int compute(WatchBuilder watch) {
    final value = watch.value(jolt, signal: () => jolt.asStream.where((i) => i % 2 == 0).debounceTime(const Duration(seconds: 1)));
    final value2 = watch(jolt, 0);
    final value3 = watch.transform<int, int>(jolt, 0, transform: (s) => s.debounceTime(const Duration(milliseconds: 300)).map((n) => n * 2));
    // final s = watch.stream(Stream<int>.periodic(Duration(seconds: 1), (i) => i + 1), 0);
    // final w = watch.jolt(EventJolt<void>()); // EventJolt.event
    // final f = watch.jolt(AsyncJolt.fromFuture(Future.value(2))).future;
    return value;
  }

}

final owo = BehaviorSubject();
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
  final test = Rx(0).stream;
  RxString
  debounce(listener, callback)

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

  final name = ComputedJolt((exec) => 2).convert(ComputedView.fromJolt);
}

typedef EventListener<T> = void Function(T event);

// Although it’s possible to create classes that extend Stream with more functionality by extending the Stream class and implementing the listen method and the extra functionality on top, that is generally not recommended because it introduces a new type that users have to consider. Instead of a class that is a Stream (and more), you can often make a class that has a Stream (and more).
// https://dart.dev/articles/libraries/creating-streams#creating-a-stream-from-scratch
// Jolt is a ErrorlessStream

/// lightweight helper for creating objects that implement the [Jolt] contract, using a [ValueNotifier] internally
/// you can extend it or encapsulate it in a class, then route the [Jolt] methods to the [ValueNotifierJoltHelper] values
class ValueNotifierJoltHelper<T> {
  final _notifier = ValueNotifier<T?>(null);

  bool isSet = false;

  T? get lastEmittedValue => _notifier.value;

  @protected
  void addEvent(T value) {
    if (!isSet) isSet = true;
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

mixin ValueNotifierJoltImpl<T> {
  @protected
  final helper = ValueNotifierJoltHelper<T>();

  T get currentValue => helper.lastEmittedValue as T;

  VoidCallback onEvent(EventListener<T> onEvent) => helper.onEvent(onEvent);

  void dispose() => helper.dispose();

  ValueNotifier<T> get asNotifier => ValueNotifier(currentValue);
  
  Stream<T> get asStream => helper.asStream;
  
}

typedef Compute<T> = T Function(WatchBuilder watch);

// for creating ValueJolts
class ValueJoltView<T> extends ComputedView<T> {
  final ValueJolt<T> jolt;
  ValueJoltView.fromJolt(this.jolt);
  ValueJoltView.computed(Compute<T> compute) : jolt = ComputedJolt(compute);
  
  @override
  T compute(WatchBuilder watch) => watch.value(jolt);
}

final lalal = FutureJolt.computed((watch) async {
  return 0;
});


// interfaces for external Jolt consumption, and interfaces for internal jolt construction (ValueJolt, ReadonlyJolt, MutableJolt)

// Some jolts can be represented through computing other jolts, in that case you can extend ComputedView.
// if you want them to share the Computed interface, add a CustomJolt.computed(Computed<T> compute) constructor.
// Other jolts are very specific in when and how they emit new events. In that case, it's better to 
// extend the StateView interface which grants you greater flexibility on how to emit() new events.

/// ComputedView is a abstract class that simplifies the proccess of managing subscriptions to other jolts:
/// you can subscribe to other jolts through the `watch` interface, and every time one of them emits a new value,
/// the `compute` function will be called and it's result will be emitted as the single new value.

// a class that you can publically emit new values
abstract class EventJolt<T> implements Jolt<T>, Sink<T> {

  factory EventJolt() = _SimpleEventJolt;

  factory EventJolt.fromPureStream(Stream<T> stream) = _SimpleEventJolt.fromPureStream; 

  @override
  void add(T value);

  @override 
  void close() => dispose();
}

abstract class MutableJolt<T> implements ValueJolt<T>, EventJolt<T>, Sink<T> {
  @override
  void add(T value);

  void update(T Function(T currentValue) updateFn) => add(updateFn(currentValue));

  @override 
  void close() => dispose();
}

abstract class FutureJolt<T> implements ValueJolt<AsyncSnapshot<T>> {

  AsyncSnapshot<T> get value => currentValue;

  T? get valueOrNull => value.data;

  Object? get errorOrNull => value.error;
  
  T get tryValue => value.data!;
  
  Object get tryError => value.error!;

  factory FutureJolt.computed(Compute<Future<T>> compute) = _ComputedFutureJolt.computed;
  factory FutureJolt.future(Future<T> future) = _ComputedFutureJolt.future;
  factory FutureJolt.value(AsyncSnapshot<T> value) = _ReadonlyFutureJolt;
}

abstract class AsyncJolt<T> with FutureJolt<T>, StreamJolt<T> {

} 

class _ComputedFutureJolt<T> extends ComputedView<AsyncSnapshot<T>> implements FutureJolt<T> {

  final ComputedJolt<Future<T>> computed;

  final AsyncSnapshot<T>? readonlyValue;

  _ComputedFutureJolt.computed(Compute<Future<T>> compute) : computed = ComputedJolt(compute), readonlyValue = null;
  _ComputedFutureJolt.future(Future<T> future) : computed = ComputedJolt((_) => future), readonlyValue = null;

  final state = StateJolt(AsyncSnapshot<T>.waiting());

  late Future<T> _trackingFuture;

  @override
  Future<T> get future => _trackingFuture;

  @override
  AsyncSnapshot<T> get value => currentValue;

  @override
  T? get valueOrNull => value.data;

  @override
  Object? get errorOrNull => value.error;
  
  @override
  T get tryValue => value.data!;
  
  @override
  Object get tryError => value.error!;

  @override
  AsyncSnapshot<T> compute(watch) {
    if (readonlyValue != null) return readonlyValue!;
    final future = watch.value(computed);
    if (_trackingFuture != future) {
      _trackingFuture = future;
      future.then((value) {
        if (_trackingFuture == future) {
          state.value = AsyncSnapshot.withData(ConnectionState.done, value);
        }
      });
      future.catchError((error) {
        if (_trackingFuture == future) {
          state.value = AsyncSnapshot.withError(ConnectionState.done, error);
        }
      });
      state.value = AsyncSnapshot<T>.waiting();
    }
    return watch.value(state);
  }
}

class _ReadonlyFutureJolt<T> extends ComputedView<AsyncSnapshot<T>> implements FutureJolt<T> {
  _ReadonlyFutureJolt(this.value);

  @override
  final AsyncSnapshot<T> value;
  
  @override
  AsyncSnapshot<T> compute(WatchBuilder watch) => value;
  
  @override
  Object? get errorOrNull => value.error;
  
  @override
  Future<T> get future {
    if (value.hasData) return Future.value(value.data);
    if (value.hasError) return Future.error(value.error!);
    else return Completer<T>().future;
  }
  
  @override
  Object get tryError => value.error!;
  
  @override
  T get tryValue => value.data!;
  
  @override
  T? get valueOrNull => value.data;
} 

// BaseJolt for building jolts that can emit events on will

// for building Jolts whoms [value] derived from others
abstract class ComputedView<T> with ValueNotifierJoltImpl<T> implements ValueJolt<T>  {

  // JoltView.late();
  @override
  T get currentValue { 
    if (helper.isSet) return helper.lastEmittedValue!;
    else {
      run();
      return helper.lastEmittedValue!;
    }
  }

  static ComputedView<T> fromJolt<T>(ValueJolt<T> jolt) {
    return ComputedJolt((exec) => exec(jolt));
  }

  static Jolt<U,U> fromStream<U>(Stream<U> stream) {

  }

  final Set<Jolt> _watching = {};

  // use(Jolt(0))
  final Map<Symbol, dynamic> vars = {};

  ComputedView() {
    run();
  }

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

class WatchBuilder {

  final ComputedView owner;

  WatchBuilder(this.owner);
  
  /// Computed always needs a immediate value when consuming Jolts 
  /// watch.value(counter, transform: (stream) => stream.debounce())
  /// watch(event, initialValue: null, transform: (stream) => stream.debounce())
  T call<T>(Jolt<T> jolt, T initialValue, {Object? key}) {
    bool valueSet = false;
    T? value;
    if (!owner._watching.contains(jolt)) {
      final listener = jolt.onEvent((value) {
        value = value;
        valueSet = true;
        owner.run();
      });
      owner.helper.onDispose(listener);
    }
    return valueSet ? value! : initialValue;
  }

  T stream<T>(Stream<T> jolt, T initialValue) {
    bool valueSet = false;
    T? value;
    if (!owner._watching.contains(jolt)) {
      final subscription = jolt.listen((value) {
        value = value;
        valueSet = true;
        owner.run();
      });
      owner.helper.onDispose(subscription.cancel);
    }
    return valueSet ? value! : initialValue;
  }

  /// Uses a stream created from [createStream], updated when [deps] change, always retrived from the same [key] 
  T useStream<T>(Stream<T> Function() createStream, T initialValue, {required Object key, List<Object>? deps}) {

  }

  // ideal would be:
  // watch(jolt.debounce().map()) but need initial value, stream cannot be re-created each time, needs key to save key, and deps to know when to update
  // watch(jolt, transform: (s) => s.debounce().map()) // key is jolt, transform is only a signal, doesn't allow for outside stream-signals

  // Stream<T2> Function(Stream<T>)? transform}
  T value<T>(ValueJolt<T> jolt, {Stream Function()? signal, Object? key}) {
    key??= jolt;
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

class ComputedJolt<T> extends ComputedView<T> {
  final Compute<T> computeFn;

  ComputedJolt(this.computeFn);
  ComputedJolt.late(this.computeFn) : super.late();

  @override
  T compute(WatchBuilder watch) => computeFn(watch);
}

class ResettableJolt<T> extends ComputedView<T> {
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
class FutureComputedJolt<T> extends ComputedView<AsyncSnapshot<T>> {
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

class HiveJolt<T extends JsonSerializable> extends ComputedView<AsyncSnapshot<T>> {
  final asyncJolt = AsyncJolt<T>();
  final T Function(String value) fromJson;

  set value(T value) {}

  @override
  AsyncSnapshot<T> compute(Watch read) {
    return asyncJolt.value;
  }
}

abstract class ValueJolt<T> extends Jolt<T> {
  T get currentValue;  
  ValueNotifier<T> get asNotifier;
}

abstract class Jolt<T> {
  VoidCallback onEvent(EventListener<T> onEvent);
  void dispose();

  //   _JoltFromPureStream(transform(asStream));
  
  Jolt<T2> transform<T2>(Stream<T2> Function(Stream<T> stream) transform);

  Stream<T> get asStream;
}

extension Convertable<T,U> on Jolt<T,U> {
  J convert<T2,U2, J extends Jolt<T2, U2>>(J Function(Jolt<T,U>) converter) {
    return converter(this);
  }

  J chain<T2,U2, J extends Jolt<T2, U2>>(J Function(Stream<U>) converter) {
    return converter(asStream);
  }
}

class StreamJoltHelper<T> extends StreamView<T> {  

  @protected
  final StreamController<T> _controller;
  
  StreamJoltHelper(this._controller) : super(_controller.stream);
  
}

class _SimpleEventJolt<T> extends StreamJoltHelper<T> with EventJolt<T> {

  _SimpleEventJolt(): super(StreamController.broadcast());

  _SimpleEventJolt.fromPureStream() : super();

  @override
  void add(T value) => _controller.add(value);
  
  @override
  Stream<T> get asStream => _controller.stream;
  
  @override
  void dispose() => _controller.close();
  
  @override
  VoidCallback onEvent(EventListener<T> onEvent) {
    final sub = _controller.stream.listen(onEvent);
    return () => sub.cancel();
  }
  
}

class ActionJolt<T> with ValueNotifierJoltImpl<T> implements Jolt<T> {
  void call(T value) => helper.addEvent(value);
}

extension Tap<T> on Stream<T> {
  void tap(void Function(T value) action) {
    // WARNING: is this auto-disposed
    map(action);
  }
}


class StateView<T> with ValueNotifierJoltImpl<T>, Store implements ValueJolt<T> {

  @override T get currentValue => state;

  T get state => helper.lastEmittedValue!;

  @protected 
  void emit(T value) {
    helper.addEvent(value);
  }

  StateView(T value) {
    emit(value);
  }

  StateView.late();

}
 
class StateJolt<T> extends StateView<T> implements MutableJolt<T> {

  T get value => state;
  set value(T value) => emit(value);

  @override
  void add(T value) => this.value = value;

  StateJolt(T value) : super(value);
  StateJolt.late() : super.late();
}

class FutureSubscription<T> {
  final void Function(T) onValue;
  final void Function(Object? error, StackTrace stackTrace) onError;
  FutureSubscription(this.onValue, this.onError);
}

class StreamJolt<T> extends ComputedView<AsyncSnapshot<T>> {
  final StateJolt<AsyncSnapshot<T>> jolt =
      StateJolt(const AsyncSnapshot.waiting());

  final Stream<T> stream;

  late final StreamSubscription subscription;

  StreamJolt(this.stream) {
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
class AsyncJolt<T> extends ComputedView<AsyncSnapshot<T>> {
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
