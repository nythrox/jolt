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



solution:

// Primitives:
ComputedJolt // read only (computed)
StateJolt // read & write (set state)

// Custom:

class AsyncJolt extends CustomJolt {

  @override get jolt => ComputedJolt(() => {})

}


this works because:
- as many inputs as u want (by instancing them (autodispose) or by .reading and transforming them)
- always a single output with no messy multiple .listens that can fire at random unordered times 
- jolt is always a stream


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

  late final Calc<T> calc;

  ComputedJolt(this.calc) : super._() {
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

  ComputedJolt.custom() : super._() {

  }
}

void lala() {
  final count = StateJolt(2);
  final double = ComputedJolt((get) => get(count) * 2); 
}

abstract class BaseJolt<T> extends Whatever<T> {
  T get value;
  BaseJolt() : super(StreamController<T>.broadcast());
}

class StateJolt<T> extends BaseJolt<T> {
  late T _value;

  @override
  T get value => _value;

  set value(T value) {
    _value = value;
    _controller.add(value);
  }

  StateJolt(this._value) : super();
  StateJolt.late() : super();
}


class AsyncJolt<T> extends ComputedJolt<AsyncSnapshot<T>> {
  
  final currentValue = StateJolt(const AsyncSnapshot.nothing());
  late final tracking = StateJolt<dynamic>(null); // Stream or Future or Null

  
  AsyncJolt() : super((get) {
    if(get(tracking) is Future) {

    }
  });
}

/*






So far we've found ways to build new jolts through

(jolt2.dart)
AsyncJolt extends StateJolt {
  value = ...
  set future
  set stream
}

(jolt6.dart)
AsyncJolt extends ComputedJolt(() => ...) {
  set future
  set stream
}

(jolt5.dart) // most flexible, .listen .listen .listen, multiple custom inheritance, but ugly to use (not as simply extend from derived)
AsyncJolt extends Jolt {
  state = StateJolt()
  extend(state)
    // OR
  watch(state, (event) => this.add(state))
}


(jolt3.dart) weird doesn'twork onEvent, .extend()



by extending ComputedJolt, you don't need to wrap it like a decorator (hiding settors), or manually set events (extend or listen)

Decorator method is most flexible
 - most flexible (custom single(1) OR multiple .listen with .add
 - but: you have to override @value, or .add, and other methods

Class Extension is most clean (Want a new jolt? extend Computed)


@override compute is the same thing as .fromStream or extend(Compute())



class AsyncJolt<T> extends Jolt<AsyncSnapshot<T>>{
   StateJolt<AsyncSnapshot<T>> _state;
   StateJolt<AsyncSnapshot<T>> _currentJolt;

   @override 
   AsyncSnapshot<T> compute(get) {
     
   }


}

class ResettableJolt<T> extends ComputedJolt<T> implements StateJolt<T> {

  final StateJolt<T> state;
  final T default;

  ResettableJolt(T state, this.default) : state = StateJolt(value);
  
  @override T compute(get) {
     return get(value);
  }

  @override
  set value(T value) => state.value = value;

  void reset() {
    state.value = default;
  }

}



class ResettableJolt<T> extends StateJolt<T> {

  final T default;

  RessetableJolt(super.value, this.default) 

  void reset() {
    value = default;
  }

}




 */