# Jolt
Extensible, lightweight, ultra-flexible state management for flutter.

### Why Jolt? In a nutshell.

#### Jolt advantages
model
Jot allows you to model your state according to your needs, and easily replace or extend jolts when needed.
- Declarative state like riverpod and mobx
- Observable state like mobx, getx and ChangeNotifier
- Streams, events, reactive programming like flutter_bloc and rxdart
- Create custom jolts to suit your domain-specific purposes
- Easy to modify or extend your code thanks to jolts of different types being interchangeable

Jolt allows you to have the declarative state from Riverpod/mobx/getx, use reactive-functional programming operators from StreamControllers, flutter_bloc, rxdart, stream_transform, create State Machines like Cubit(flutter_bloc), ValueNotifier, StateNotifier, and use simple, mutable state from mobx, getx, ChangeNotifier and etc. Additionally, Jolt allows you to easily extend it and create your own Jolts for specific use-cases (such as a HiveJolt), or facilitating dealing with data types (FutureJolt).
Offering a library of ...

You can build your state according to your specific needs for each part of the app. Jolt offers near infinite flexibility so you can use a state model that's as complex or as simple as the situation demands, while always keeping interchangeability with all other modes.

Jolt is a type-safe/strongly typed primitive that abstracts over/under Streams, ValueNotifiers (and consequentially StateNotifiers). 
It also focuses on bringing ease to creating new types of Jolts (using the riverpod/jotai model of deriving state units from others reactively) and composing, transforming and exchanging those types. 
The default/builtin/standard Jolts allow use of dealing with Streams and handling Futures    
it is also Lightweight since default implementations use ValueNotifier under the hood 

Because the Jolt interface is extremely flexible, it allows you to program your state management in ways similar to Provider (with ChangeNotifier/StateNotiifer), GetX and Mobx, Bloc (flutter_blox), RxDart or stream_transform (using StreamControllers/consuming Streams) and everything else, without having to switch libraries or even re-write your State Management to build a feature in a specific way, or simply use a feature that your library's state management model doesn't support. 


Because , allows for flexibility extremely extensive reactive variants (ValueJolt, MutableJolt, Streams, etc)
all of them following the principles of reactive, strongly typed programming.

the Jolt standard library offers a complete toolkit for dealing with derived state, mutable state, streams, futures and more.

Additionally, Jolts have a special relation with Streams. In order to guarantee greater interopability with the extensive stream operators (from dart core and from packages) that already exist, jolt transformations are done through Streams.

You may think of Jolt as a StreamController that allows for 

keywords: interchangeability, reactive, functional, strongly-typed

must be: intuitive (easy interfaces for extending, composing, etc), and very simple defaults (jolt builder 4 the win), late-first

##### Creating jolts

##### Types of Jolts
Jolt is supposed to offer a great flexibility in terms of state management, allowing you to structure your code according to your actual business flows, easily switching from simple mutable state like ChangeNotifier, Observable (from mobx), Rx(from getx), state machines such as Cubit (from flutter_bloc) and StateNotifier (from provider), or more complex reactive solutions using streams like RxDart and Bloc in flutter_bloc.



Simple Mutable State (mobx, ChangeNotifier, getx)

```dart
class Counter with Store {
    final counter = jolt(0);

    void increment() => counter++;
}
```

```dart
class LoginStore with Store {
    
    final email = jolt("");
    final password = jolt("");

    late final isValid = jolt.computed((watch) {
        return watch.value(email).length == 10 && watch.value(password).length == 6;
    });

    late final result = FutureJolt<bool>.value(false);

    void login() {
        result.future = api.login(email.state, value.state);
    }

    // Or, alternatively: 
    void submit() async {
        result.loading = true;
        try {
            if (isValid.value) {
                result.value = await api.login(email.value, password.value);
            }
            else {
                result.error = "Invalid email or password";
            }
        } catch (e) {
            result.error = e;
        }
    }
}

``` 

Streams (rxdart, flutter_bloc)
```dart
class SearchUserStore with Store {

    final query = jolt("");

    // ReadonlyAsyncJolt<List<UserModel>>
    late final users = jolt.computed.future((watch) async {
        final name = watch.value(query, signal: () => query.stream.debounce(Duration(milliseconds: 300)));
        if (name.length == 0) {
            return [];
        }
        else return await api.searchUsers(name: name);
    });

}

// Alternatively:
class SearchUserStore with Store {

    final query = StateJolt("");

    final users = AsyncJolt<List<UserModel>>([]);

    SearchUserJolt() {
        query
            .stream
            .debounce(Duration(seconds: 300))
            .listen((name) {
                if (name.length == 0) {
                    users.value = [];
                }
                else users.future = api.searchUsers(name: name);
            })
            .attach(this)
    }
}
```

State Machines (Cubit, StateNotifier)
```dart
class Counter extends StateView<int> {
    Counter() : super(0);

    increment() => emit(state + 1);
}

class LoginState {
    Initial()
    Loading()
    Success(user)
    Error(error)
}

class LoginStore extends StateView<LoginState> {
    LoginStore() : super(LoginState.initial());

    void login(String email, String password) async {
        state = LoginState.loading();
        try {
            final user = await api.login(email, password);
            state = LoginState.success(user);
        }
        catch (e) {
            state = LoginState.error(e)
        }
    }
}

class GithubSearchState {
    Empty(),
    Loading(),
    Success(items),
    Error(error),
}

class GithubSearchStore extends StateView<GithubSearchState> with Store {
    GithubSearchStore() : Super(GithubSearchState.empty())

    late final query = jolt("")
        // this can also be done inside the constructor or in a separate method, using listen and attach
        ..stream
        .debounce(Duration(milliseconds: 300))
        .listen((query) async {
            if (query.isEmpty) return emit(GithubSearchState.empty());
            
            emit(GithubSearchState.loading());

            try {
                final results = await githubRepository.search(searchTerm);
                emit(GithubSearchState.success(results.items));
            } catch (error) {
                emit(error is SearchResultError
                    ? GithubSearchState.error(error.message)
                    : GithubSearchState.error('something went wrong'));
            }
        }).attach(this);

}

// Or, even
class GithubSearchStore extends ComputedView<GithubSearchState> {
    GithubSearchStore() : Super(GithubSearchState.empty());

    final query = jolt("");

    late final result = jolt.computed.future((watch) async {
        final query = watch.value(jolt, signal: jolt.stream.debounce(Duration(millisecondsL 300)))
        if (query.isEmpty) return null;
        else return githubRepository.search(searchTerm);
    })

    @override
    GithubSearchState compute(read) {
        final snapshot = read.value(result);
        return snapshot.map(
            success: (value) => value == null ? GithubSearchState.empty : GithubSearchState.success(value),
            error: (error, stackTrace) => error is SearchResultError
                ? GithubSearchState.error(error.message)
                : GithubSearchState.error('something went wrong'),
            loading: () => GithubSearchState.loading(),
        )
    }

}

```


Derived States (Riverpod, jotai, mobx)
```dart
class Counter extends ComputedView<int> {
    final _counter = StateJolt(0);

    @override
    int compute(watch) {
        return watch.value(_counter);
    }

    increment() => _counter.value++;
}
```


### ComputedJolt and ComputedView
Computed jolts allow for declarative state management, allowing you to derive new state - or new types of jolts - reactively from other jolts, encapsulating business logic into simple, composable units of state. 

### Custom Jolts

TODO:

ErrorValidationJolt<String>("", (email) => Email.isValid(email) ? "Invalid Email" : null)
ValidationJolt<String>("", Email.isValid)

ValidaitonGroup.fromJolt()
ValidaitonGroup.from({

})

```dart


class TestJolt {

  final count = HiveJolt(0, int.parse, #count);
  final user = HiveJolt<User?>(null, User.fromJson, #user);

  TestJolt() {
    count.value = 10;
    user.value = User(name: "jason");
  }

}

class HiveJolt<T> extends ComputedView<AsyncSnapshot<T>> {
  final asyncJolt = jolt.async<T>();
  
  final T Function(String value) fromJson;

  late final FutureOr<Box<String>> box;
  
  final T initialValue;

  Future<void> clear() async {
    return (await box).delete(key);
  }

  @override 
  void lazyInit() async {

    asyncJolt.future = Hive.openBox<String>("HiveJolt").then((box) async {
      box = box;
      final maybeValue = box.get(key);
      if (maybeValue == null) return initialValue;
      else return fromJson(maybeValue);
    });
    
    onDispose(() {
      Future.value(box).then((box) => box.close());
    });
  }

  final dynamic key;

  HiveJolt(this.initialValue, this.fromJson, this.key);

  set value(T value) {
    asyncJolt.future = Future.value(box).then((box) async {
      await box.put(key, jsonEncode(value));
      return value;
    });
  }

  @override
  AsyncSnapshot<T> compute(watch) {
    return asyncJolt.value;
  }
}

```

#### Adding your class to JoltBuilder


### Store
Store is a helper mixin that allows you to manage your Jolt subscriptions
onDispose()
attach() // auto disposes jolt
extend() // when the jolt emits, adds the event to the store
JoltBuilder // easy way to create jolts, automatically managed (disposed when the Store is disposed)


#### JoltBuilder
Since there are many types of jolts, many for very specific use-cases, and because many more can easily be added, [JoltBuilder] facilitates the instanciation of Jolts.

It's important to use the [JoltBuilder] from [Store] when using jolts scoped inside of a disposable class, since Store will automatically dispose the jolts created from the JoltBuilder (offered by the store)

If you are creating jolts that should be disposed manually, you can use the global `jolt` constant or `configure(jolt, autodispose: false)` a jolt created inside of a store (through the Store's joltbuilder).

```dart
class TestStore with Store {
    final counter = jolt(0);
    final double = jolt.computed((watch) => watch.value(counter) * 2);
    final users = jolt.async<List<User>>();
}
```

JoltBuilder by default offers constructors for all the standard Jolts offered by the library, but can and should be extended when custom jolts are created.

```dart
class JoltBuilder {
    
    // Most commonly used jolts
    StateJolt<T> jolt(T value);
    StateJolt<T> jolt.late();
    ComputedJolt<T> jolt.computed(Compute<T> compute);
    ComputedFutureJolt<T> jolt.computed.stream(Compute<Stream<T>> compute);
    ComputedStreamJolt<T> jolt.computed.future(Compute<Stream<T>> compute);
    AsyncJolt<T> jolt.async([AsyncSnapshot<T> value]);
    AsyncJolt<T> jolt.future(Future<T> future);
    AsyncJolt<T> jolt.stream(Stream<T> stream);
    
    // More specific ways to call the jolts above
    // ComputedFutureJolt<T> jolt.stream.computed(Compute<Stream<T>> compute);
    // ComputedStreamJolt<T> jolt.future.computed(Compute<Stream<T>> compute);
    // StateJolt<T> jolt.state(T value);
    // AsyncJolt<T> jolt.async.late();
    // AsyncJolt<T> jolt.async.value(AsyncSnapshot<T> value);
    // AsyncJolt<T> jolt.async.future(Future<T> future);
    // AsyncJolt<T> jolt.async.stream(Stream<T> stream);
    // StateJolt<T> jolt.state(T value);

    // Readonly Jolts are redundant since it's the same as using a Computed without watching any other jolts.
    // They are only here for playground purposes.
    // ValueJolt<T> jolt.readonly.state(T value);
    // ReadonlyAsyncJolt jolt.readonly.future(Future<T> value);
    // ReadonlyAsyncJolt jolt.readonly.stream(Stream<T> value);
    
}
```

### Disposing Jolts and Stores
Jolts can be disposed at will .by calling `jolt.dispose()`. But they only **MUST** be disposed to avoid memory leaks when they are being listened to through their `asStream` interface. In that case, you can may: 
- manually dispose the jolt calling `dispose()` on it
- `attach` the jolt to a `Store`, so when the Store is disposed it will be too (together with its subscriptions)
- `attach` the stream subscription to a `Store`, so when the Store is disposed the subscription will be cancelled too (this way the Jolt can be cleared by the garbage collector)
- manually dispose the stream subscription by calling `cancel()` on it



### Jolt and Streams
Jolt uses Stream operators when needing to transform itself, that way keeping greater compatibility with already-needing streams, and having less need for conversion.

support:
    watch.stream(stream)
    watch.useStream(() => stream, key)
