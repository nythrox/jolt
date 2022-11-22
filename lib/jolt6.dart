/*


// to have the simplicity of Jotai,
// you must have a Jolt.fromStream(derive(() { watch(a) + watch(b) + watch(c) }))
// and allow for custom methods, that add directly to the initial stream

function asyncJotai() {
  final value = atom(AsyncSnapshot.nothing()) // read write
  final tracking = atom<Future | Stream | null>() // read write
  final result = atom((get) { // read only
    if (tracking is Future) return tracking.futureState.map({ loading: loading, done; done, error: error })
    if (tracking is Stream) return tracking.streamState.map({ loading: loading, done; done, error: error })
    else return value
  }) 
  return [
    result,
    {
    setFuture(future) => tracking.value = future
    setStream(stream) => tracking.value = stream
    setValue(value) => tracking.value = null
  }]
}

a Jolt is a Super-Stream Controller
  that allows you to watch multiple values
  add multiple inputs (methods)
  and return a single output

a Jolt is a type of StreamController: can have .value, has custom methods other than add() (.value=, .future=), and contains no addError()

you can make some derivations:
Jolt<AsyncValue<T>> computeFuture<T>(Exec<Future<T>> exec) {
  return compute(exec).pipe()
}

if u want it to be a custom jolt:



Stream()
Jolt() // compute from other Jotais
StateJotai() // 


Problem: can't access class members in constructor


 */

import 'dart:async';

import 'package:flutter/material.dart';

// implements Sink<T>
class Whatever<T> extends StreamView<T> {
  final StreamController<T> _controller;
  Whatever(this._controller) : super(_controller.stream);

  // @override
  // void add(T data) {
  //   _controller.add(data);
  // }

  // @override
  void close() {
    _controller.close();
  }
}

abstract class ReadableAtom<T> implements StreamView<T> {
  T get value;

  void close();
}

typedef Exec = U Function<U>(BaseJolt<U> jolt);
typedef Calc<T> = T Function(Exec exec);

class ComputedJolt<T> extends BaseJolt<T> {
  late T _value;
  @override
  T get value => _value;
  final Map<BaseJolt, StreamSubscription> subscriptions = {};

  @override
  void close() {
    for (final entry in subscriptions.entries) {
      entry.value.cancel();
      subscriptions.remove(entry.key);
    }
    super.close();
  }

  ComputedJolt(Calc<T> calc) : super._() {
    void recalculate() {
      _value = calc(<U>(BaseJolt<U> jolt) {
        subscriptions[jolt] ??= jolt.listen((value) {
          recalculate();
        });
        return jolt.value;
      });
      _controller.add(_value);
    }

    recalculate();
  }
}

void lala() {
  final count = StateJolt(2);
  final double = ComputedJolt((get) => get(count) * 2); 
}

abstract class BaseJolt<T> extends Whatever<T> {
  T get value;
  BaseJolt._() : super(StreamController<T>.broadcast());
}

class StateJolt<T> extends BaseJolt<T> {
  late T _value;

  @override
  T get value => _value;

  set value(T value) {
    _value = value;
    _controller.add(value);
  }

  StateJolt(this._value) : super._();
  StateJolt.late() : super._();
}


class AsyncJolt<T> extends ComputedJolt<AsyncSnapshot<T>> {
  
  final currentValue = StateJolt(const AsyncSnapshot.nothing());
  final tracking = StateJolt<dynamic>(null); // Stream or Future or Null

  
  AsyncJolt() : super((get) {
    if(get(tracking) is Future) {

    }
  });
}
