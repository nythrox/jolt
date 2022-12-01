import 'dart:convert';

import 'package:hive/hive.dart';

import 'store.dart';

// ignore_for_file: curly_braces_in_flow_control_structures, prefer_function_declarations_over_variables

/*

https://chornthorn.github.io/getx-docs/state-management/reactive-state-manager/index/#declaring-a-reactive-variable
https://mobx.netlify.app/api/observable/
https://pub.dev/packages/rxdart
https://pub.dev/packages/flutter_bloc
https://bloclibrary.dev/#/coreconcepts?id=cubit
https://bloclibrary.dev/#/flutterangulargithubsearch
https://riverpod.dev
https://riverpod.dev/docs/concepts/combining_providers/
https://riverpod.dev/docs/concepts/reading/
https://twitter.com/remi_rousselet/status/1294273161580752898?lang=en
https://github.com/felangel/bloc/issues/1429
https://pub.dev/packages/state_notifier
https://refactoring.guru/design-patterns/decorator
https://stackoverflow.com/questions/57014576/how-do-i-convert-a-valuenotifier-into-a-stream
https://stackoverflow.com/questions/54623289/dart-streams-vs-valuenotifiers
https://www.reddit.com/r/FlutterDev/comments/okzw09/for_which_use_case_would_one_use_changenotifier/
https://www.reddit.com/r/FlutterDev/comments/nj5f23/why_streams_are_not_a_good_choice_for_the_state/
https://www.reddit.com/r/FlutterDev/comments/okzw09/comment/h5shbry/?utm_source=share&utm_medium=web2x&context=3
https://jotai.org/docs/guides/composing-atoms#syncing-atom-values-with-external-values
https://jotai.org/docs/basics/concepts
https://codesandbox.io/s/github/pmndrs/jotai/tree/main/examples/hacker_news?file=/src/App.tsx
https://jotai.org/docs/introduction
https://jotai.org/docs/utils/select-atom
https://jotai.org/docs/utils/atom-with-reset
https://github.com/pmndrs/jotai/blob/17408e9ef413964798b1437159c166c7a20837ca/src/utils/atomWithReset.ts
https://www.learnrxjs.io/learn-rxjs/operators/combination/combinelatest
https://rxjs.dev/guide/observable
https://rxjs.dev/guide/operators
https://mobx.netlify.app/api/reaction/#autorun
https://mobx.js.org/computeds-with-args.html

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

Temporarily, allow all Jolts to be computed & stateful (like in riverpod)

^ the number exponentially increased when you have not only those, but also withReset, withStorage, etc.
a universal exchange converter would solve this, but has its owm problems (for transforming outputs, adding prop functionality, and overriding)


It's better to start with a Computed (readonly state), because from that you can derrive Readonly and also Mutable State

todo: ChangeNotifier api (ChangeNotifierView) that has [this] as T. same for ValueNotifier which is the same as State, Flutter_Bloc, Mobx, Getx, Provider, etc. 

Jolt configs(unique, )

watch.get(value) // hasValue, didChange, hasEmitted, previousValue



Jolt stream operators shouldn't be used to build new jolts because they uselessly always discard .value 
(bad for computed and others). Ideal jolt operators would only lose it when there is actually a chance (.when .where etc)
Ok to use then when planning a reaction, or autorun with ValueJolt sync initial value;
^ that's exactly what .signal is for btw.

sad! i wanted to use operators as freely as we can use jolts

maybe also AnimationJolt, TextController jolt (what would be the use? autodispose?)

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
import 'package:volt/jolt/views.dart';

import 'jolt.dart';
import 'standard.dart';

// class Whatever extends ComputedView<int> {

//   final jolt = MutableValueJolt(0);

//   late final owo = jolt.transform((stream) => 
//     stream
//       .debounceTime(const Duration(seconds: 1))
//       .where((event) => event % 2 == 0)
//       .skip(3)
//       .take(10),
//   );

//   @override
//   int compute(WatchBuilder watch) {
//     final value = watch.value(jolt, signal: () => jolt.asStream.where((i) => i % 2 == 0).debounceTime(const Duration(seconds: 1)));
//     final value2 = watch(jolt, 0);
//     final value3 = watch.transform<int, int>(jolt, 0, transform: (s) => s.debounceTime(const Duration(milliseconds: 300)).map((n) => n * 2));
//     // final s = watch.stream(Stream<int>.periodic(Duration(seconds: 1), (i) => i + 1), 0);
//     // final w = watch.jolt(EventJolt<void>()); // EventJolt.event
//     // final f = watch.jolt(AsyncJolt.fromFuture(Future.value(2))).future;
//     return value;
//   }

// }

final owo = BehaviorSubject();
// StateProvider is so weird cuz it allows u to watch others & edit current
final resetter = StateProvider((ref) => false).select((value) => null);
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

// class ResettableJolt<T> extends ComputedView<T> {
//   final StateJolt<T> valueJolt;
//   final T defaultValue;

//   ResettableJolt(T value, this.defaultValue) : valueJolt = StateJolt(value);

//   @override
//   T compute(watch) => watch(valueJolt);

//   void reset() => valueJolt.value = defaultValue;
// }

abstract class JsonSerializable {
  String toJson();
}

final cache = {};

class User {
  String? name;
  int? age;
  String? id;

  User({this.name, this.age, this.id});

  User.fromJson(dynamic json) {
    name = json['name'];
    age = json['age'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['age'] = this.age;
    data['id'] = this.id;
    return data;
  }
}


class TestJolt {

  final count = HiveJolt(0, int.parse, #count);
  final user = HiveJolt<User?>(null, User.fromJson, #user);

  TestJolt() {
    count.value = 10;
    user.value = User(name: "jason");
  }

}

class HiveJolt<T> extends ComputedView<AsyncSnapshot<T>> {
  final asyncJolt = jolt.async<T>();
  
  final T Function(String value) fromJson;

  late final FutureOr<Box<String>> box;
  
  final T initialValue;

  Future<void> clear() async {
    return (await box).delete(key);
  }

  @override 
  void lazyInit() async {

    asyncJolt.future = Hive.openBox<String>("HiveJolt").then((box) async {
      box = box;
      final maybeValue = box.get(key);
      if (maybeValue == null) return initialValue;
      else return fromJson(maybeValue);
    });
    
    onDispose(() {
      Future.value(box).then((box) => box.close());
    });
  }

  final dynamic key;

  HiveJolt(this.initialValue, this.fromJson, this.key);

  set value(T value) {
    asyncJolt.future = Future.value(box).then((box) async {
      await box.put(key, jsonEncode(value));
      return value;
    });
  }

  @override
  AsyncSnapshot<T> compute(watch) {
    return asyncJolt.value;
  }
}
