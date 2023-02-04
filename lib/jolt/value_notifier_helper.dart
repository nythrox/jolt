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
