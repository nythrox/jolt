import 'dart:async';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

void main() {

  final loginStore = LoginStore();
  loginStore.email.listen((value) {
    print("---$value---");
  });
  loginStore.email.future = Future.value("hello world");
  print(loginStore.email.value);
  print("done");
}

// typedef Jolt<T> = BehaviorSubject<T>;

typedef Exec = U Function<U>(Jolt<U> jolt);


// loading doesnt notify
// need 2 test with nullable value!

/*
  FutureJolt<T> = Jolt<AsyncResult<T>> {
    get future
  }


  do i want 

  watch(futrObs) to return T or to return asyncResult<T>

 */

// ref, null/future/stream

class FutureSubscription<T> {
  final void Function(T) onValue;
  final void Function(Object? error, StackTrace stackTrace) onError;
  FutureSubscription(this.onValue, this.onError);
}

abstract class Whatever<T> extends StreamView<T> implements EventSink<T> {
  StreamController<T> controller;
  Whatever(this.controller) : super(controller.stream);

  @override
  Future close() async {
    controller.close();
  }
}

/// The error throw by [ValueStream.value] or [ValueStream.error].
class HasNoValueError extends Error {
  HasNoValueError();

  @override
  String toString() {
    return 'Jolt.late() has no value. You should check Jolt.valueSet before accessing Jolt.value.';
  }
}

enum JoltStatus {
  value,
  error,
  loading, // unset
}

// reason why this instead of addStream(): addstream doesnt rewrite it, gives error

// you can take this pretty far, but the problem is that Streams dont support Loading 
// being notified. So you need to have a Stream<Result<T>>. At that point, you might
// as well have different objects

/*
  how it's supposed to be used
  
  jolt.value = 10;
  jolt.loading = true;
  jolt.error = Error();
  jolt.value = 20;

  jolt.future = apiCall();
  jolt.stream = apiCall();

*/
class Jolt<T> extends Whatever<T> {
  T? _value;
  
  dynamic externalSubscription;
  
  JoltStatus _status;
  JoltStatus _previousStatus;
  JoltStatus get status => _status;
  _setStatus(JoltStatus status, [Function()? action]) {
    if (_status != JoltStatus.value && _status == status) return;
    _previousStatus = _status;
    if (status == JoltStatus.value) {
      externalSubscription = null;
      _error = null;
      action?.call();
    }
    // keep the previous value
    if (status == JoltStatus.loading) {
//       _value = null;
      _error = null;
      action?.call();
    }
    // keep the previous value (in case we set error = null)
    if (status == JoltStatus.error) {
      externalSubscription = null;
//       _value = null;
      action?.call();
    }
  }
  
  bool get loading => status == JoltStatus.loading;
  set loading(bool loading) {
    if (loading == false) _setStatus(_previousStatus);
    _setStatus(JoltStatus.loading);
  }
  
  T get value {
    return _value!;
  }

  set value(T value) => add(value);

   Object? _error;
  
   Object? get error => _error;
  
   set error(Object? error) {
     if (error == null) {
       _setStatus(_previousStatus);
     }else {
      addError(error);       
     }
   }
  
  @override
  void add(T data) {
    _setStatus(JoltStatus.value, () {
      _value = data;
      controller.add(data);
    });
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _error = error;
    _setStatus(JoltStatus.error);
    controller.addError(error);
  }

  Future<T> get future {
    final c = Completer<T>();
    late StreamSubscription sub;
    sub = listen((value) {
      c.complete(value);
      sub.cancel();
    }, onError: (err) {
      c.completeError(err);
      sub.cancel();
    },);
    return c.future;
  }
  
  set future(Future<T> future) {
    _setStatus(JoltStatus.loading);
    late final FutureSubscription<T> subscription;
    subscription = FutureSubscription(
      (value) => externalSubscription == subscription ? this.value = value : null,
      (error, stackTrace) => externalSubscription == subscription
          ? this.error = error ?? Error()
          : null,
    );
    future.then(subscription.onValue).catchError(subscription.onError);
    externalSubscription = subscription;
  }
  
  Jolt<T> get stream => this;

  set stream(Stream<T> stream) {
    externalSubscription = null;
    late final StreamSubscription subscription;
    subscription = stream.listen(
      (value) => externalSubscription == subscription ? add(value) : null,
      onError: (error) =>
          externalSubscription == subscription ? addError(error) : null,
    );
    externalSubscription = subscription;
  }
 
 
  
  Jolt([T? value])
      : _value = value,
        _status = JoltStatus.value,
        _previousStatus = JoltStatus.value,
        super(StreamController<T>.broadcast());

  factory Jolt.compute(FutureOr<T> Function(Exec) calc) {
    final List<StreamSubscription> subscriptions = [];
    late Jolt<T> newJolt;
    final value = calc(<U>(Jolt<U> jolt) {
      subscriptions.add(jolt.listen((value) async =>
          newJolt.add(await calc(<U>(Jolt<U> jolt) => jolt.value))));

      return jolt.value;
    });
    newJolt = value is T ? Jolt(value) : Jolt.future(value);
    return newJolt;
  }
  factory Jolt.future(Future<T> future) {
    return Jolt()..future = future;
  }

  handlePreviousSub() {
    final prev = externalSubscription;
    if (prev != null) {
      if (prev is StreamSubscription) {
        prev.cancel();
      }
    }
  }

  // get future<T>
}

final provide = Provider((ref) => 0);
final provideState = StateProvider((ref) => 0);

class LoginStore {
  final email = Jolt("");
  final password = Jolt("");

  late final validateEmail = Jolt.compute((watch) {
    return watch(email).length == 10 && watch(password).length == 6;
  }); // .debounceTime(const Duration(seconds: 3));

  final apiResult = Jolt<bool>();

  late final doSomething = Jolt.compute((exec) {
    final isValid = exec(validateEmail);
    if (isValid) {
      apiResult.future = loginApi(email.value, password.value);
    }
  });
  LoginStore() {}
}

Future<bool> loginApi(String email, String password) {
  return Future.value(true);
}



// fourth attempt with BehaviorSubject

// - high memory
// - need to be disposed (simply use .attach())
// - need wrapper around for better and setter
// - for future to stream (i wonder what the value should be, T i guess)
// - all stream transformations should return Jolt (extensions)
// - should be extensible (try to reproduce jotai)
//   - can have fun interplay with .attach groupings
// - computed should work for future, streams and all. would a Spark<Stream> be a stream stream or just a stream? Use riverpod as ref

// lets try to see how far we can go just doing gambiarra-streams (mixing errors with states with futures with streams) and a simple .value api // this is ZIO isn't it O.O
// then, try your own Jolt (StreamController), sand build on top of it with custom apis (valuejolt, futurejolt, streamjolt) (make it simple)
