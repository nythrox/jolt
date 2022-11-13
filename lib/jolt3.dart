// class Jolt<I,O> {

// }

// for a futrue experimentation: make subscriptions truly flexible, u can have any time of relation (more than up down)

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  print(" hello world ");
  final count = StateJolt(0);
  final double = DerivedJolt((exec) {
    return exec(count) * 2;
  });
  count.value++;
  double.listen(print);
  count.value++;
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

class ErrorlessStream<T> extends StreamView<T> {
  @protected
  final StreamController<T> _controller;
  ErrorlessStream(this._controller) : super(_controller.stream);
}

class DisposeEvent {}

class Eventable extends ErrorlessStream<Event> {
  // Relations may repass events to each other
  // final _relations = <Subscription>[];

  final _internalSubs = <StreamSubscription<Event>>[];

  /// ErrorlessStream
  Eventable() : super(StreamController()) {
    onEvent<DisposeEvent>((data) {
      for (final sub in _internalSubs) {
        sub.cancel();
      }
      _controller.close();
    });
  }

  void dispose() {
    emit(DisposeEvent());
  }

  @protected
  void emit(data) {
    _controller.add(Event(this, data));
  }

  @protected
  void onEvent<T>(void Function(Event<T> data) listener) {
    _internalSubs.add(listen((event) {
      if (event is Event<T>) {
        listener(event);
      }
    }));
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

  @protected
  void extend(Jolt jolt) {
    _internalSubs.add(jolt.listen((event) {
      _controller.add(event.event);
    }));
    onEvent<DisposeEvent>((data) {
      jolt.emit(DisposeEvent());
    });
  }

  @protected
  void subscribe(Jolt jolt) {
    _internalSubs.add(jolt.listen((event) {
      _controller.add(event.event);
    }));
  }
}

class EventJolt<T> extends Eventable {
  void add(T value) {
    emit(ValueEvent(value));
  }
}

class ActionJolt<T> extends Eventable {
  final void Function(T value) action;

  ActionJolt(this.action);

  void call(T value) {
    emit(ValueEvent(value));
  }
}

abstract class Jolt<T> extends Eventable {
  T get value;
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
    emit(ValueEvent(value));
  }
}

typedef Read = U Function<U>(Jolt<U> jolt);
typedef Calc<T> = T Function(Read read);

class DerivedJolt<T> extends Jolt<T> {
  late final StateJolt state;
  @override
  T get value => state.value;

  DerivedJolt(Calc<T> calc) {
    extend(state);
    void recalculate() {
      state.value = calc(<U>(Jolt<U> jolt) {
        subscribe(jolt);
        return jolt.value;
      });
    }

    recalculate();
    onEvent<ValueEvent>((data) {
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
  final errorJolt = StateJolt<dynamic>(null);
  final _trackingFutureJolt = StateJolt<Future<T>?>(null);

  FutureStatus status;

  FutureSubscription<T>? _trackingFuture;

  @override
  T get value => valueJolt.value!;

  Future<T> get future {
    if (_trackingFutureJolt.value != null) return _trackingFutureJolt.value;
    if (status == FutureStatus.value)
      return Future.value(valueJolt.value);
    else if (status == FutureStatus.error) return Future.error(errorJolt.value);
    final c = Completer<T>();
    late StreamSubscription sub;
    onEvent<ValueEvent>((data) {
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

  FutureJolt([Future<T>? future]) {
    extend(valueJolt);
    extend(loadingJolt);
    extend(errorJolt);
    if (future != null) this.future = future;
    onEvent<ValueEvent>((data) {
      if (data.source == valueJolt) {}
      if (data.source == loadingJolt) {}
      if (data.source == errorJolt) {}
    });
  }
}

extension Do<T> on Eventable {
  DerivedJolt<T> derive(Calc<T> calc) {
    return DerivedJolt(calc);
  }
}

class LoginStore extends FutureJolt<bool> {
  final email = StateJolt("");
  final password = StateJolt("");

  late final validateEmail = DerivedJolt((watch) {
    return watch(email).length == 10 && watch(password).length == 6;
  });


  // this timeout would work if i can modify the input
  // alternative would be a .do() that preserves the original jolt, and timeOut() that does too
  late final submit = ActionJolt<void>((_) {
    final isValid = validateEmail.value;
    if (isValid) {
      future = loginApi(email.value, password.value);
    }
  }).timeout(const Duration(seconds: 3));
}

Future<bool> loginApi(String email, String password) {
  return Future.value(true);
}
