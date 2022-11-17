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

  void dispose() {
    notifier.dispose();
  }

  // check how this works after cancelling, re-subscribing, if it works for multiple streams
  Stream<T> get stream {
    final controller = StreamController<T>.broadcast(sync: true);
    var listener = (event) => controller.add(event);
    controller.onListen = () => listen(listener);
    controller.onCancel = () => removeListener(listener);
    return controller.stream;
  }

  final _listeners = <EventListener<T>, VoidCallback>{};

  void listen(EventListener<T> listener) {
    return notifier.addListener(
        _listeners[listener] = () => listener(notifier.value as T));
  }

  void removeListener(EventListener<T> listener) {
    return notifier.removeListener(_listeners[listener]!);
  }
}

class ActionJolt<T> extends EventJolt<T> {
  void call(T value) => add(value);
}

abstract class ValueJolt<T> extends EventJolt<T> {
  T get value;
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

class ComputedJolt<T> extends ValueJolt<T> {
  late T _value;

  @override
  T get value => _value;

  final Map<Jolt, StreamSubscription> _subscriptions = {};

  ComputedJolt._();

  ComputedJolt(T Function(Exec) calc) {
    void handleValue(T value) {
      _value = value;
      add(_value);
    }

    U handleCalc<U>(Jolt<U> jolt) {
      _subscriptions[jolt] ??=
          jolt.listen((value) => handleValue(calc(handleCalc)));
      return jolt.value;
    }

    handleValue(calc(handleCalc));
  }

  static ComputedJolt<AsyncSnapshot<T>> fromFuture<T>(
      Future<T> Function(Exec) calc) {
    final computed = ComputedJolt<AsyncSnapshot<T>>._();
    computed._value = const AsyncSnapshot.waiting();
    computed.add(computed._value);

    void handleValue(Future<T> value) {
      value.then((value) {
        computed._value = AsyncSnapshot.withData(ConnectionState.active, value);
        computed.add(computed._value);
      }).catchError((error) {
        computed._value =
            AsyncSnapshot.withError(ConnectionState.active, error);
        computed.add(computed._value);
      });
    }

    U handleCalc<U>(Jolt<U> jolt) {
      computed._subscriptions[jolt] ??=
          jolt.listen((value) => handleValue(calc(handleCalc)));
      return jolt.value;
    }

    handleValue(calc(handleCalc));

    return computed;
  }

  static ComputedJolt<AsyncSnapshot<T>> fromStream<T>(
      Stream<T> Function(Exec) calc) {
    final computed = ComputedJolt<AsyncSnapshot<T>>._();
    computed._value = const AsyncSnapshot.waiting();
    computed.add(computed._value);

    void handleValue(Stream<T> value) {
      final sub = value.listen(
        (value) {
          computed._value =
              AsyncSnapshot.withData(ConnectionState.active, value);
          computed.add(computed._value);
        },
        onError: (error) {
          computed._value =
              AsyncSnapshot.withError(ConnectionState.active, error);
          computed.add(computed._value);
        },
      );
      final prevSub = computed._subscriptions[computed];
      if (prevSub != null) {
        prevSub.cancel();
      }
      computed._subscriptions[computed] = sub;
    }

    U handleCalc<U>(Jolt<U> jolt) {
      computed._subscriptions[jolt] ??=
          jolt.listen((value) => handleValue(calc(handleCalc)));
      return jolt.value;
    }

    handleValue(calc(handleCalc));

    return computed;
  }
}

class StateJolt<T> extends ValueJolt<T> {
  late T _value;

  @override
  T get value => _value;

  StateJolt(this._value);

  set value(T value) {
    _value = value;
    add(value);
  }
}

// actually a MutableStateJolt, since it can have its value set
class FutureJolt<T> extends ValueJolt<AsyncSnapshot<T>> {
  FutureJolt([Future<T>? future]) {
    if (future != null)
      this.future = future;
    else
      _value = const AsyncSnapshot.nothing();
  }

  late AsyncSnapshot<T> _value;

  @override
  AsyncSnapshot<T> get value => _value;

  set value(AsyncSnapshot<T> value) {
    // WARNING: AsyncSnapshot.nothing .loading could be non const
    _value = value;
    add(value);
  }

  var _externalSubscription;

  Future<T> get future {
    Future<T> handleSnapshot(AsyncSnapshot<T> snapshot) {
      return snapshot.hasData
          ? Future.value(snapshot.data)
          : Future.error(snapshot.error ??
              Exception(
                  "[FutureJolt<$T>]: Expected error from failed future."));
    }

    if (_value == const AsyncSnapshot.waiting() ||
        _value == const AsyncSnapshot.nothing())
      return stream.first.then(handleSnapshot);
    return handleSnapshot(_value);
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
      (value) => _externalSubscription == subscription ? add(value) : null,
      onError: (error) =>
          _externalSubscription == subscription ? addError(error) : null,
    );
    _externalSubscription = subscription;
  }
}
