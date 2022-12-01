// Although it’s possible to create classes that extend Stream with more functionality by extending the Stream class and implementing the listen method and the extra functionality on top, that is generally not recommended because it introduces a new type that users have to consider. Instead of a class that is a Stream (and more), you can often make a class that has a Stream (and more).
// https://dart.dev/articles/libraries/creating-streams#creating-a-stream-from-scratch
// Jolt is a ErrorlessStream

import 'dart:async';

import 'package:flutter/material.dart';

import 'jolt.dart';

/// lightweight helper for creating objects that implement the [Jolt] contract, using a [ValueNotifier] internally
/// you can extend it or encapsulate it in a class, then route the [Jolt] methods to the [ValueNotifierJoltHelper] values
class ValueNotifierJoltHelper<T> extends ValueNotifier<T?> {
  ValueNotifierJoltHelper() : super(null);

  bool isSet = false;

  T? get lastEmittedValue => value;

  void addEvent(T value) {
    if (!isSet) isSet = true;
    this.value = value;
    notifyListeners();
  }

  // // extend: events from that jolt get transmitted to this jolt
  // // attach: listen to that jolt & when this gets disposed, dispose that one

  // void extend(BaseJolt<T> jolt) {
  //   extendMap(jolt, (T value) => value);
  // }

  // void extendMap<U>(BaseJolt<U> jolt, T Function(U value) map) {
  //   watch(jolt, (U event) => addEvent(map(event)), disposeJolt: true);
  // }

  // void watch<U>(
  //   BaseJolt<U> jolt,
  //   void Function(U value) onListen, {
  //   bool disposeJolt = false,
  // }) {
  //   jolt.addListener(onListen);
  //   onDispose(() {
  //     jolt.removeListener(onListen);
  //     if (disposeJolt) jolt.dispose();
  //   });
  // }

  final List<FutureOr<void> Function()> onDisposeCallbacks = [];
  void onDispose(FutureOr<void> Function() fn) => onDisposeCallbacks.add(fn);

  /// Only creates a StreamController if necessary (if .stream getter gets called)
  StreamController<T>? _controller;

  // check how this works after cancelling, re-subscribing, if it works for multiple streams
  Stream<T> get asStream {
    final controller = _controller ??= () {
      final controller = StreamController<T>.broadcast(sync: true);
      final listener = (T event) => controller.add(event);
      VoidCallback? dispose;
      controller.onListen = () => dispose = onEvent(listener);
      Future<void> onCancel() {
        dispose?.call();
        dispose = null;
        _controller = null;
        return controller.close();
      }

      controller.onCancel = onCancel;
      onDispose(onCancel);
      return controller;
    }();
    return controller.stream;
  }

  VoidCallback onEvent(EventListener<T> listener) {
    final l = () => listener(value as T);
    addListener(l);

    return () => removeListener(l);
  }
}


// mixin ValueNotifierMixinHelper<T> implements ValueNotifier<T> {
//   @override
//   T value;

//   @override
//   void addListener(VoidCallback listener) {
//     // TODO: implement addListener
//   }

//   @override
//   void dispose() {
//     // TODO: implement dispose
//   }

//   @override
//   // TODO: implement hasListeners
//   bool get hasListeners => throw UnimplementedError();

//   @override
//   void notifyListeners() {
//     // TODO: implement notifyListeners
//   }

//   @override
//   void removeListener(VoidCallback listener) {
//     // TODO: implement removeListener
//   }
  
// }



mixin JoltStreamMixinHelper<T> implements Stream<T>  {
  
  @override
  Future<bool> any(bool Function(T element) test) {
    // TODO: implement any
    throw UnimplementedError();
  }

  @override
  Stream<T> asBroadcastStream({void Function(StreamSubscription<T> subscription)? onListen, void Function(StreamSubscription<T> subscription)? onCancel}) {
    // TODO: implement asBroadcastStream
    throw UnimplementedError();
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(T event) convert) {
    // TODO: implement asyncExpand
    throw UnimplementedError();
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) {
    // TODO: implement asyncMap
    throw UnimplementedError();
  }

  @override
  Stream<R> cast<R>() {
    // TODO: implement cast
    throw UnimplementedError();
  }

  @override
  Future<bool> contains(Object? needle) {
    // TODO: implement contains
    throw UnimplementedError();
  }

  @override
  Stream<T> distinct([bool Function(T previous, T next)? equals]) {
    // TODO: implement distinct
    throw UnimplementedError();
  }

  @override
  Future<E> drain<E>([E? futureValue]) {
    // TODO: implement drain
    throw UnimplementedError();
  }

  @override
  Future<T> elementAt(int index) {
    // TODO: implement elementAt
    throw UnimplementedError();
  }

  @override
  Future<bool> every(bool Function(T element) test) {
    // TODO: implement every
    throw UnimplementedError();
  }

  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert) {
    // TODO: implement expand
    throw UnimplementedError();
  }

  @override
  // TODO: implement first
  Future<T> get first => throw UnimplementedError();

  @override
  Future<T> firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    // TODO: implement firstWhere
    throw UnimplementedError();
  }

  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, T element) combine) {
    // TODO: implement fold
    throw UnimplementedError();
  }

  @override
  Future forEach(void Function(T element) action) {
    // TODO: implement forEach
    throw UnimplementedError();
  }

  @override
  Stream<T> handleError(Function onError, {bool Function(dynamic error)? test}) {
    // TODO: implement handleError
    throw UnimplementedError();
  }

  @override
  // TODO: implement isBroadcast
  bool get isBroadcast => throw UnimplementedError();

  @override
  // TODO: implement isEmpty
  Future<bool> get isEmpty => throw UnimplementedError();

  @override
  Future<String> join([String separator = ""]) {
    // TODO: implement join
    throw UnimplementedError();
  }

  @override
  // TODO: implement last
  Future<T> get last => throw UnimplementedError();

  @override
  Future<T> lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    // TODO: implement lastWhere
    throw UnimplementedError();
  }

  @override
  // TODO: implement length
  Future<int> get length => throw UnimplementedError();

  @override
  StreamSubscription<T> listen(void Function(T event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    // TODO: implement listen
    throw UnimplementedError();
  }

  @override
  Stream<S> map<S>(S Function(T event) convert) {
    // TODO: implement map
    throw UnimplementedError();
  }

  @override
  Future pipe(StreamConsumer<T> streamConsumer) {
    // TODO: implement pipe
    throw UnimplementedError();
  }

  @override
  Future<T> reduce(T Function(T previous, T element) combine) {
    // TODO: implement reduce
    throw UnimplementedError();
  }

  @override
  // TODO: implement single
  Future<T> get single => throw UnimplementedError();

  @override
  Future<T> singleWhere(bool Function(T element) test, {T Function()? orElse}) {
    // TODO: implement singleWhere
    throw UnimplementedError();
  }

  @override
  Stream<T> skip(int count) {
    // TODO: implement skip
    throw UnimplementedError();
  }

  @override
  Stream<T> skipWhile(bool Function(T element) test) {
    // TODO: implement skipWhile
    throw UnimplementedError();
  }

  @override
  Stream<T> take(int count) {
    // TODO: implement take
    throw UnimplementedError();
  }

  @override
  Stream<T> takeWhile(bool Function(T element) test) {
    // TODO: implement takeWhile
    throw UnimplementedError();
  }

  @override
  Stream<T> timeout(Duration timeLimit, {void Function(EventSink<T> sink)? onTimeout}) {
    // TODO: implement timeout
    throw UnimplementedError();
  }

  @override
  Future<List<T>> toList() {
    // TODO: implement toList
    throw UnimplementedError();
  }

  @override
  Future<Set<T>> toSet() {
    // TODO: implement toSet
    throw UnimplementedError();
  }

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) {
    // TODO: implement transform
    throw UnimplementedError();
  }

  @override
  Stream<T> where(bool Function(T event) test) {
    // TODO: implement where
    throw UnimplementedError();
  }

}
