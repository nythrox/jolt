import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

// sadly will always have error, because Streams have error.
// but can type: must always have an initial value, adding errors is impermissable, separate Value from Future from Stream

// try 2 be cool: instead of unecessary cloning on each operation, edit the inner stream
// about this, we cant * internally * update the stream (or else that would map its own operation)
// operators should work on the .sink (modify inputs) or the .stream (modify outputs)
// maybe every Jolt should have two controllers, a sink and a stream, that way you can individually control each one

// attention: computedJolt can throw, so should be a Result<T>

// in order to facilitate conversions of Streams<value?, error> to Sinks<value!> and the use of operators
// how bout: make all jolts deeply late and lazy, that way they are "compatible" with streams, only execute compute once a .value is called or a .subscribe is made
// stream.toJolt() will have nullable tolerance (because lazy, but thrown exception), but will have no exception tollerance unless toResultJolt, toFutureJolt, etc.

// being able to mix imperative, synchronous, readable, easy to orchestrate events with
// async, declarative, descentralized events that use reactive programming features

// extensions and tools for playing around with streams, a stronger type interface, synchronous and access to state 


// difficulty thats going on: interplay / transformation between streams
// most jolts are built on StateJolt, which has a setter. if
// you use an operator on one, it turns into a stream, and when attempted to
// transform back into a jolt, it should not have a setter

class Whatever<T> extends StreamView<T> implements Sink<T> {
  StreamController<T> controller;
  Whatever(this.controller) : super(controller.stream);

  @override
  void add(T data) {
    controller.add(data);
  }

  @override
  void close() {
    controller.close();
  }
}

// every jolt is a ValueJolt
// need to have a stream To jolt (which will have a late error, orElse, seeded, etc)
abstract class Jolt<T> extends Whatever<T> {
  T get value;
  Jolt() : super(StreamController<T>.broadcast());
}

class StateJolt<T> extends Jolt<T> {
  late T _value;

  @protected
  bool valueSet = false;

  @override
  T get value => _value;

  set value(T value) => add(value);

  @override
  void add(T data) {
    valueSet = true;
    _value = data;
    super.add(data);
  }

  StateJolt(T value) {
    add(value);
  }
}

enum ResultStatus {
  loading,
  value,
  error,
}

// todo: test with nullable value
class AsyncResult<T> {
  final ResultStatus status;
  late T _value;
  T get value => status == ResultStatus.value ? _value : throw HasNoValueError();
  T? get tryValue => _value;
  final dynamic error;

  AsyncResult.loading()
      : status = ResultStatus.loading,
        error = null;
  AsyncResult.error(this.error)
      : status = ResultStatus.error;
  AsyncResult(T value)
      : _value = value,
        error = null,
        status = ResultStatus.value;
}

// if FutureJolt<T> is Jolt<AsyncResult<T>>
// should T get/set value be AsyncResult or Future?
// should i just use extensions?
// should set value T and set future Future<T> be separated?
// FutureJolt is the only one that can accept outside streams since it can represent in its type system Errors and Loading

class FutureJolt<T> extends StateJolt<AsyncResult<T>> {
  Object? subscription;
  T? previousValue;

  /// Tries to get the current value or a previous one, if it exists.
  T? get tryValue => valueSet ? value.tryValue : previousValue;

  FutureJolt(Future<T> future) : super(AsyncResult<T>.loading()) {
    this.future = future;
  }

  FutureJolt.fromStream(Stream<T> stream) : super(AsyncResult<T>.loading()) {
    this.stream = stream;
  }

  @override
  void add(AsyncResult<T> data) {
    _cancelPreviousSubscription();
    final currValue = valueSet ? value.tryValue : data.tryValue;
    previousValue = currValue;
    super.add(data);
  }

  void _cancelPreviousSubscription() {
    if (subscription is StreamSubscription) (subscription as StreamSubscription).cancel();
    subscription = null;
  }

  @override
  void close() {
    _cancelPreviousSubscription();
    super.close();
  }

  Future<T> get future {
    if (value.status == ResultStatus.loading) {
      return controller.stream
          .firstWhere((element) => element.status != ResultStatus.loading)
          .then((value) =>
              value.status == ResultStatus.error ? value.error : value.value);
    }
    return Future.value(
        value.status == ResultStatus.error ? value.error : value.value);
  }

  set future(Future<T> future) {
    _cancelPreviousSubscription();
    late final FutureSubscription subscription;
    subscription = FutureSubscription<T>(
      (value) => this.subscription == subscription
          ? this.value = AsyncResult(value)
          : null,
      (error, stackTrace) => this.subscription == subscription
          ? value = AsyncResult.error(error)
          : null,
    );
    add(AsyncResult.loading());
    future.then(subscription.onValue).catchError(subscription.onError);
    this.subscription = subscription;
  }

  set stream(Stream<T> stream) {
    _cancelPreviousSubscription();
    late final StreamSubscription subscription;
    add(AsyncResult.loading());
    subscription = stream.listen(
      (value) => subscription == subscription ? add(AsyncResult(value)) : null,
      onError: (error) =>
          subscription == subscription ? add(AsyncResult.error(error)) : null,
    );
    this.subscription = subscription;
  }
  
}

// can be: unset, error, value. once set, will never become unset
class StreamJolt<T> extends Jolt<T?> {

}

typedef Exec = U Function<U>(Jolt<U> jolt);
typedef Calc<T> = T Function(Exec exec);


// this jolt is CLEAN, PURE. does not accept errors or async or other streams (all inpure)
class ComputedJolt<T> extends Jolt<T> {
  late T _value;
  @override
  T get value => _value;
  final Map<Jolt, StreamSubscription> subscriptions = {};

  @override
  void close() {
    for (final entry in subscriptions.entries) {
      entry.value.cancel();
      subscriptions.remove(entry.key);
    }
    super.close();
  }

  ComputedJolt(Calc<T> calc) {
    void recalculate() {
      _value = calc(<U>(Jolt<U> jolt) {
        subscriptions[jolt] ??= jolt.listen((value) {
          recalculate();
        });
        return jolt.value;
      });
      add(_value);
    }

    recalculate();
  }
}

class FutureSubscription<T> {
  final void Function(T) onValue;
  final void Function(Object? error, StackTrace stackTrace) onError;
  FutureSubscription(this.onValue, this.onError);
}

/// The error throw by [ValueStream.value] or [ValueStream.error].
class HasNoValueError extends Error {
  HasNoValueError();

  @override
  String toString() {
    return 'Jolt.late() has no value. You should check Jolt.valueSet before accessing Jolt.value.';
  }
}

// group
abstract class Store {
  final sinks = <Sink>[];

  Sink<T> addSink<T>(Sink<T> sink) {
    sinks.add(sink);
    return sink;
  }

  void dispose() {
    for (final sink in sinks) {
      sink.close();
    }
  }
}

class EventJolt<T> extends Whatever<T> {
  EventJolt() : super(StreamController<T>.broadcast());
}

extension ww on Store {
  FutureJolt<T> future<T>(Future<T> future) =>
      addSink(FutureJolt(future)) as FutureJolt<T>;
  StateJolt<T> state<T>(T value) => addSink(StateJolt(value)) as StateJolt<T>;
  ComputedJolt<T> computed<T>(Calc<T> calc) =>
      addSink(ComputedJolt(calc)) as ComputedJolt<T>;
  FutureJolt<T> computedFuture<T>(Calc<Future<T>> calc) =>
      addSink(FutureJolt(ComputedJolt(calc).value))
          as FutureJolt<T>;
  EventJolt<T> eventsJolt<T>() => addSink(EventJolt()) as EventJolt<T>;
}

abstract class LoginEvent {}

class LoginSuccess extends LoginEvent {}

class LoginStore with Store {
  late final events = eventsJolt();

  late final email = state("");
  late final password = state("");

  late final suggestions = computedFuture((exec) async {
    final email = exec(this.email.transform(streamTransformer));
    DebounceStreamTransformer
    return await emailSuggestions(email);
  });

  // email.compute, asyncCompute
  // email.transform(
  //    debounceTime(duration(milliseconds: 300))
  //    
  // )

  late final suggestions_ = email
      .debounceTime(const Duration(milliseconds: 300))
      .switchMap((email) => emailSuggestions(email).toStream());

  late final validateEmail = computed((exec) {
    final email = exec(this.email);
    final password = exec(this.password);
    return email.length == 10 && password.length == 6;
  });

  void login() {

    events.add(LoginSuccess());
  }
}

Future<bool> apiLogin(String email, String password) async {
  if (email == "jason.p08514@gmail.com" && password == "123123123")
    return true;
  else
    return false;
}

Future<List<String>> emailSuggestions(String query) async {
  return [query];
}

extension ToStream<T> on Future<T> {
  Stream<T> toStream() {
    return Stream.fromFuture(this);
  }
  FutureJolt<T> toJolt() {
    return FutureJolt(this);
  }
}

extension ToFutureJolt<T> on Stream<T> {
  ComputedJolt<AsyncResult<T>> toJolt() {
    // return ComputedJolt((exec) => exec(FutureJolt(Future.value())..future = first));
  }
}
