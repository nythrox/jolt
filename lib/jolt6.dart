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

ErrorlessStream { listen(T) }
Jolt { T value } extends ErrorlessStream 

EventStream(controller) extends ErrorlessStream 
  or
EventJolt extends Jolt<Null>


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


yes, you will always have to re-add set value (if you can set the value of your jolt)
the reason for that is because 
there is no need for a WritableAtom interface/hierarchy. you can just create and use any method you want. that's the point of it


or: if you extend a atom thats not ComputedJolt, you're on your own.
no need to extend StateJolt, this isn't Jotai where you have to reuse a single callback


good reason to not extend StreamView:
1 - performance
2 - we can force .fromStream in order to .compute, that way correctly handling errors


2do:
find hierarchy correct for eventjolt (write only), (computed) jolt (read only) and state jolt (read write)
 must: have default implementation for notify/listening/2stream for max performance (not that u cant use others)

typedef ValueCallback<T> = void Function(T value);

abstract class Trackable<T> {
  T get value;
  void addListener(ValueCallback<dynamic> callback);
  void removeListener(ValueCallback<dynamic> callback);
  void close();
}

abstract class Streamable<T> {
  get stream<T>

}

class BaseJolt<T> extends Trackable<Null> {
  @protected
  add(T value)

  @override addListener T
  @override removeListener T
}

EventJolt<T> extends  {

  @override addListener T
  @override removeListener T
} 

Jolt extends Trackable<T> {
  @compute => trackers;
  @override addListener T
  @override removeListener T
}



 */

import 'dart:async';

import 'package:flutter/material.dart';



// implements Sink<T>
class Whatever<T> extends StreamView<T> {
  @protected
  final StreamController<T> controller;

  Whatever(this.controller) : super(controller.stream);

  @override
  StreamSubscription<T> listen(void onData(T event)?,
      {Function? onError, bool? cancelOnError});


  void close() {
    controller.close();
  }
}

class EventJolt<T> extends Whatever<T> implements Trackable<Null> {
  
  @override
  Null get value => null;

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

  ComputedJolt(this.calc) {
    void recalculate() {
      _value = calc(<U>(BaseJolt<U> jolt) {
        subscriptions[jolt] ??= jolt.listen((value) {
          recalculate();
        });
        return jolt.value;
      });
      controller.add(_value);
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
  BaseJolt() : super(StreamController<T>.broadcast());
}

class StateJolt<T> extends BaseJolt<T> {
  late T _value;

  @override
  T get value => _value;

  set value(T value) {
    _value = value;
    controller.add(value);
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