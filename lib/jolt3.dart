// class Jolt<I,O> {

// }

// for a futrue experimentation: make subscriptions truly flexible, u can have any time of relation (more than up down)
// next step: we want to be able to derive jolts from jolts, and we want those jolts to be able to be debounced and streamed,
// so we must be able to derive a Jolt from a Stream which is a pure JoltStream
// also be able to debounce jolts from inside derives

// also, Eventable (jolts) cannot extend directly from Stream, because when we debounce and etc it (transform/operate on it)
// we only want the ValueEvents, so .stream getter is necessary (or throw away dynamic events), which might be ideal

// TODO:
/* 

final count = Jolt(0);
final double = count.stream.timeout(300).calc(n => n * 2) // Jolt<int>
final double = derive((exec) {
  final count = exec(count.timeout(300))
  return count * 2
})


final iwish = Jolt("0").map(int.parse) // Jolt<String, int> 
^^
StateJolt<String,String>("0").useTransformer<int>(MapTransformer(int.parse)) // StateJolt<String, int>

class StateJolt<I,O> extends Jolt<I,O> {
  // Transformer<A,B> = Stream<A> => Stream<B>
  StateJolt<I,O2> fromTransformer<O2>(Transformer<O, O2> transformer) {
    return StateJolt(transformOutput: transformer)    
  }
}

*/
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  print(" hello world ");
  final store = LoginStore();
  store.email.value = "bkabab";

  store.submit(LoginEvent());
}

class Subscription {
  final Eventable eventable;
  final Direction direction;
  Subscription(this.eventable, this.direction);
}

enum Direction { upstream, downstream }

class Event<T> {
  final Eventable source;
  final T event;
  Event(this.source, this.event);
}

class DisposeEvent {}

void emit<T>(Eventable e, data) {
  e._controller.add(Event(e, data));
}

void onEvent<T>(Eventable e, void Function(Event<T> data) listener) {
  e._internalSubs.add(e._controller.stream.listen((event) {
    if (event is Event<T>) {
      listener(event);
    }
  }));
}

@protected
void extend(Eventable e, Jolt jolt) {
  e._internalSubs.add(jolt._controller.stream.listen((event) {
    e._controller.add(event.event);
  }));
  onEvent<DisposeEvent>(e, (data) {
    emit(e, DisposeEvent());
  });
}

@protected
void subscribe(Eventable e, Jolt jolt) {
  e._internalSubs.add(jolt._controller.stream.listen((event) {
    e._controller.add(event.event);
  }));
}

class Eventable {
  final _controller = StreamController<Event>();
  // Relations may repass events to each other
  // final _relations = <Subscription>[];

  final _internalSubs = <StreamSubscription<Event>>[];

  /// ErrorlessStream
  Eventable() {
    onEvent<DisposeEvent>(this, (data) {
      for (final sub in _internalSubs) {
        sub.cancel();
      }
      _controller.close();
    });
  }

  void dispose() {
    emit(this, DisposeEvent());
  }

  // final List<Eventable> subscribers = [];

  // @protected
  // void subscribe(Eventable eventable) {
  //   subscribers.add(eventable);
  // }

  // @protected
  // void propagate(Event event) {
  //   for (final subscription in subscribers) {
  //     subscription._controller.add(event);
  //   }
  // }

}

class EventJolt<T> extends ValueEventJolt<T> {
  void add(T value) {
    emit(this, ValueEvent(value));
  }
}

class ActionJolt<T> extends ValueEventJolt<T> {
  void call(T value) {
    emit(this, ValueEvent(value));
  }
}

abstract class ValueEventJolt<T> extends Eventable {
  Stream<T> get stream {
    final controller = StreamController<T>();
    onEvent<ValueEvent<T>>(this, (data) {
      controller.add(data.event.newValue);
    });

    onEvent<DisposeEvent>(this, (data) {
      controller.close();
    });
    return controller.stream;
  }

  ValueEventJolt<T2> fromStream<T2>(Stream<T2> stream) {
    
  }
}

abstract class Jolt<T> extends ValueEventJolt<T> {
  T get value;
}

extension Tap<T> on Stream<T> {
  void tap(void Function(T value) action) {
    // automatically disposed thanks to Jolt.stream onEvent<DisposeEvent>
    map(action);
  }
}

class ValueEvent<T> {
  final T newValue;
  ValueEvent(this.newValue);
}

class StateJolt<T> extends Jolt<T> {
  late T _value;

  @override
  T get value => _value;

  StateJolt(this._value);

  set value(T value) {
    _value = value;
    emit(this, ValueEvent(value));
  }
}

typedef Read = U Function<U>(Jolt<U> jolt);
typedef Calc<T> = T Function(Read read);

class DerivedJolt<T> extends Jolt<T> {
  late final StateJolt state;
  @override
  T get value => state.value;

  DerivedJolt(Calc<T> calc) {
    extend(this, state);
    void recalculate() {
      state.value = calc(<U>(Jolt<U> jolt) {
        subscribe(this, jolt);
        return jolt.value;
      });
    }

    recalculate();
    onEvent<ValueEvent>(this, (data) {
      if (data.source != state) {
        recalculate();
      }
    });
  }
}

class ErrorEvent<T> {
  final T error;
  ErrorEvent(this.error);
}

class FutureSubscription<T> {
  final void Function(T) onValue;
  final void Function(Object? error, StackTrace stackTrace) onError;
  FutureSubscription(this.onValue, this.onError);
}

enum FutureStatus {
  loading,
  value,
  error,
}

class FutureJolt<T> extends Jolt<T> {
  final valueJolt = StateJolt<T?>(null);
  final loadingJolt = StateJolt<bool>(true);
  final errorJolt = StateJolt<Object?>(null);
  final _trackingFutureJolt = StateJolt<Future<T>?>(null);

  FutureStatus status;

  FutureSubscription<T>? _trackingFuture;

  @override
  T get value => valueJolt.value!;

  set value(T value) {
    valueJolt.value =
  }

  Future<T> get future {
    if (_trackingFutureJolt.value != null) return _trackingFutureJolt.value;
    if (status == FutureStatus.value)
      return Future.value(valueJolt.value);
    else if (status == FutureStatus.error) return Future.error(errorJolt.value);
    final c = Completer<T>();
    late StreamSubscription sub;
    onEvent<ValueEvent>(this, (data) {
      if (data.source == valueJolt) {}
      if (data.source == loadingJolt) {}
      if (data.source == errorJolt) {}
    });

    return c.future;
  }

  set future(Future<T> future) {
    late final FutureSubscription<T> subscription;
    subscription = FutureSubscription(
      (value) => _trackingFuture == subscription ? this.value = value : null,
      (error, stackTrace) => _trackingFuture == subscription
          ? this.error = error ?? Error()
          : null,
    );
    future.then(subscription.onValue).catchError(subscription.onError);
    _trackingFuture = subscription;
  }

  factory FutureJolt.value(T value) {
    return FutureJolt(Future.value(value));
  } 
  factory FutureJolt.error(Object error) {
    return FutureJolt(Future.error(error));
  } 

  FutureJolt(Future<T>? future) {
    extend(valueJolt);
    extend(loadingJolt);
    extend(errorJolt);
    if (future != null) this.future = future;
    onEvent<ValueEvent>(this, (data) {
      if (data.source == valueJolt) {}
      if (data.source == loadingJolt) {}
      if (data.source == errorJolt) {}
    });
  }
}

extension Do<T> on Eventable {
  @protected
  DerivedJolt<T> derive(Calc<T> calc) {
    return DerivedJolt(calc);
  }
}

class LoginEvent {
  String email;
  String password;
}

class LoginStore {
  final email = StateJolt("");
  final password = StateJolt("");

  late final validateEmail = DerivedJolt((watch) {
    return watch(email).length == 10 && watch(password).length == 6;
  })
    ..stream.tap(print);

  late final result = FutureJolt<bool>.value(false);

  // this timeout would work if i can modify the input
  // alternative would be a .do() that preserves the original jolt, and timeOut() that does too
  late final submit = ActionJolt<LoginEvent>()
    ..stream.timeout(const Duration(seconds: 1)).where((_) => true).tap(
      (_) async {
        // result.loading = true;
        // try {
        //   final isValid = validateEmail.value;
        //   if (isValid) {
        //     result.value = await loginApi(email.value, password.value);
        //   }
        // } catch (e) {
        //   result.error = e;
        //   result.loading = false;
        // }
        final isValid = validateEmail.value;
        if (isValid) {
          result.future = loginApi(email.value, password.value);
        }
      },
    );
}

Future<bool> loginApi(String email, String password) {
  return Future.value(true);
}
