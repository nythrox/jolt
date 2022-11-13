// class Jolt<I,O> {

// }

// for a futrue experimentation: make subscriptions truly flexible, u can have any time of relation (more than up down)


import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';


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
  final _relations = <Subscription>[];

  final _internalSubs = <StreamSubscription<Event>>[];

  /// ErrorlessStream
  Eventable() : super(StreamController()) {
    on((DisposeEvent event, source) {
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
  on<T extends Event>(void Function(T event, Eventable source) listener) {
    _internalSubs.add(listen((event) {
      if (event.event is T) {
        listener(event.event, event.source);
      }
    }));
  }

  @protected
  void propagate(Event event, Direction direction) {
    for (final subscription in _relations) {
      if (subscription.direction == direction) {
        subscription.eventable.emit(event);
      }
    }
  }

  @protected
  void subscribe(Eventable eventable, Direction direction) {
    _relations.add(Subscription(eventable, direction));
  }
}

abstract class Jolt<T> extends Eventable {
  T get value;

  @protected
  void extend(Jolt jolt) {
    jolt.subscribe(this, Direction.downstream);
  }
  
  @protected
  void attach(Jolt jolt) {
    jolt.subscribe(this, Direction.upstream);
  }
}

class ValueEvent<T> {
  final T newValue;
  ValueEvent(this.newValue);
}

class StateJolt<T> extends Jolt<T> {
  late T _value;
  T get value => _value;

  StateJolt(this._value) {
   on(ValueEvent<T> event, source) {
     if (source == this) {
        _value = event.newValue;
       propagate(event, );
     }
   } 
  }

  set value(T value) {
    emit(ValueEvent(value));
  }
}

typedef Exec = U Function<U>(Jolt<U> jolt);
typedef Calc<T> = T Function(Exec exec);

class DerivedJolt<T> extends Jolt<T> {
  late final StateJolt state;
  @override
  T get value => state.value;

  DerivedJolt(Calc<T> calc) {
    extend(state);
    void recalculate() {
      state.value = calc(<U>(Jolt<U> jolt) {
        extend(jolt);
        return jolt.value;
      });
    }

    recalculate();
    on((ValueEvent event, source) {
      if (source != this) {
        recalculate();
      }
    });
  }
}

