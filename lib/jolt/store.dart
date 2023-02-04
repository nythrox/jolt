import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:jolt/jolt/extensions.dart';

import 'standard.dart';
import 'jolt.dart';
import 'views.dart';

// TODO: maybe stores don't need to be dispsoed, the same way mobx observables or getx Rx aren't disposed (the store is just released from memory)
// streams still need to be disposed. extension .attach() on Stream (while we dont have jolt transformations)
// add global observer using .attach system
class Store {

  late final jolt = JoltBuilder(this);

  final List<VoidCallback> callbacks = [];

  void onDispose(VoidCallback onDispose) => callbacks.add(onDispose);

  void dispose() {
    callbacks.forEach((cb) => cb());
  }

  // Attaches a Jolt to this store, disposing it when this store is disposed.
  J attach<T, J extends Jolt<T>>(J jolt) {
    onDispose(jolt.dispose);
    return jolt;
  }
}

extension AutodisposeSubscription<T> on StreamSubscription<T> {
  void attach(Store store) {
    store.onDispose(cancel);
  }
}

// final count = jolt(0);

// I'll have to think this through hehe
// using .stream directly is nice
// but tradeoff is also horrible (all the methods, same with value notifier)
// plus never know if .attach() will be for stream, stream subscription or jolt
// but a good concept: even though Jolt technically represents a stream, let Jolts
// focus on being StreamControllers while streams do the operating (but if no
// extend stream, that means harder operating + volt helpers have to supoprt consuming
// streams since they are using together)

// final owo = jolt("")
//   ..signal((signal) {
//     count
//         .select((n) => n)
//         .distinct()
//         .where((n) => n != 0)
//         .when((previous, next) => next == 2 * previous)
//         .debounce(const Duration(seconds: 1))
//         .attach(signal);
//     count
//         .select((n) => n)
//         .distinct()
//         .where((n) => n != 0)
//         .when((previous, next) => next == 2 * previous)
//         .attach(signal);
//   }).listen((event) {}).attach(null as Store);

// JoltBuilder(WatchBuilder) is always an autorun
// jolt.autorun would be the same as jolt.watch()
// jolt.listen is like .reaction

// autorun(select, ): jolt.transform(stream.select().when().unique())
/* jolt.stream.buildReaction((watch) {
    watch(count.stream.)
})

jolt(0).watch() returns Jolt<Null> 

Store(Watch)
JoltBuilder(Watch)



watch(jolt).transform().select().when().unique().signal()

*/

// JoltBuilder jolts are: Mutable by default (facilitating mobx-style) and if read-only, then computed
class JoltBuilder {
  final Store? store;
  const JoltBuilder([this.store]);

  J attach<T, J extends Jolt<T>>(J jolt) {
    store?.attach(jolt);
    return jolt;
  }

  J configure<T, J extends Jolt<T>>(J jolt, {bool? autodispose}) {
    return jolt;
  }
}

const jolt = JoltBuilder();

class StateJoltBuilder extends JoltBuilder {
  const StateJoltBuilder();

  StateJolt<T> call<T>(T value) => attach(StateJolt(value));

  StateJolt<T> late<T>() => attach(StateJolt.late());
}

class AsyncJoltBuilder extends JoltBuilder {
  const AsyncJoltBuilder(super.store);
  AsyncStateJolt<T> call<T>() => attach(MutableStateJolt());
  AsyncStateJolt<T> stream<T>(Stream<T> stream) => attach(MutableStateJolt.fromStream(stream));
  AsyncStateJolt<T> future<T>(Future<T> future) => attach(MutableStateJolt.fromFuture(future));
}

class ComputedJoltBuilder extends JoltBuilder {
  const ComputedJoltBuilder(super.store);

  ComputedJolt<T> call<T>(Compute<T> calc) => attach((ComputedJolt(calc)));
  AsyncJolt<T> future<T>(Compute<Future<T>> compute) => attach(ComputedFutureJolt(compute));
  AsyncJolt<T> stream<T>(Compute<Stream<T>> compute) => attach(ComputedStreamJolt(compute));
}

extension Stuff on JoltBuilder {
  // State
  StateJoltBuilder get state => const StateJoltBuilder();
  StateJolt<T> call<T>(T value) => state(value);
  StateJolt<T> late<T>() => state.late();

  // Async
  AsyncJoltBuilder get async => AsyncJoltBuilder(store);
  AsyncStateJolt<T> future<T>(Future<T> future) => async.future(future);
  AsyncStateJolt<T> stream<T>(Stream<T> stream) => async.stream(stream);

  // Event
  EventJolt<T> events<T>() => attach(EventJolt());

  // Computed
  ComputedJoltBuilder get computed => ComputedJoltBuilder(store);
}
