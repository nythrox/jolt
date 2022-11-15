/*

// simply no land for old men. it's IMPOSSIBLE to allow for the stream.map.map because even if u solved the IO,
you'd have to manually override every single map function for every single subtype (no type magic allowed :c)

*/
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

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

void emit<T>(Jolt<T> e, data) {
  e._controller.add(data);
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

class Whatever<I, O> extends StreamView<O> implements Sink<I> {
  late StreamController<O>? controller;

  Whatever(StreamController<O> controller)
      : this.controller = controller,
        super(controller.stream);
  Whatever.fromStream(super.stream);

  @override
  void add(I data) {}

  @override
  void close() {
    // TODO: implement close
  }
}

abstract class TransformerHelper<I, O, C extends Jolt<O>> extends StreamView<O>
    implements Sink<I> {
  TransformerHelper(super.stream);

  @override
  TransformerHelper<I, O2, Jolt<O2>> transform<O2>(
      StreamTransformer<O, O2> streamTransformer) {
    return super.transform(transformer);
  }
}

// Jolt is a ErrorlessStream
class Jolt<T> {
  final _controller = StreamController<T>();

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

  @override
  Jolt<T2> fromStream<T2>(Stream<T2> stream) {
    final newJolt = Jolt<T2>();
    late StreamSubscription<T2> sub;
    sub = stream.listen((event) {
      newJolt._controller.add(event);
    }, onDone: () {
      sub.cancel();
      newJolt._controller.close();
    });
    return newJolt;
  }

  @override
  void add(T data) {
    _controller.add(data);
  }

  @override
  void close() {
    _controller.close();
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

class ActionJolt<T> extends Jolt<T> {
  void call(T value) {
    emit(this, ValueEvent(value));
  }
}

abstract class ValueJolt<T> extends Jolt<T> {
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

class StateJolt<T> extends ValueJolt<T> {
  late T _value;

  @override
  T get value => _value;

  StateJolt(this._value);

  set value(T value) {
    _value = value;
    emit(this, ValueEvent(value));
  }
}
