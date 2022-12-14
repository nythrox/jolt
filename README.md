# Jolt
Extensible, lightweight, ultra-flexible state management for flutter.

#### Features
- Declarative state like riverpod
- Atomic observable state like mobx, getx and ValueNotifier
- Streams, events, reactive-functional programming (compatibility with stream operators/transformers) like flutter_bloc, rxdart and stream_transform
- State machines like cubit and StateNotifier
- Create custom jolts for specific use cases (ex. OfflineJolt, ValidationJolt, TextControllerJolt, HiveJolt), or to simplify the usage of data types (ex. FutureJolt)
- Effortlessly extend your state when needed to add complex behaviour without having to rewrite your code (interoperability between jolts of different types)
 
### Why Jolt? In a nutshell.

Jolt's biggest advantage over other libraries is it's near infinite flexibility: you can build your state according to your specific needs for each part of the app, as complex or simple as the use case demands. 

You can structure your state according to your actual business flows: create custom jolts to suit your needs, have a store using multiple styles and types of jolts, add complex behaviour and modify existing stores without having to rewrite your existing code.

With Jolt, you can always use the right state model to represent your domain. But with great power comes great responsibility, so use it thoughtfully.

### Showcase
Create a store using Jolts
```dart
class GithubSearch with Store {

    final query = jolt("");

    late final repositories = jolt.computed.future((watch) async {
        final name = watch(query.debounce(Duration(milliseconds: 300)));
        if (name.length == 0) {
            return [];
        }
        else return await api.searchUsers(name: name);
    });

}
```

Consume jolt in a widget:
```dart
JoltBuilder((context, watch) {
    final result = watch.value(store.repositories);
    return result.when(
        loading: () => CircularProgressIndicator(),
        error: (e) => Text("Somethinng went wrong! Error: $e"),
        data: (repositories) {
            return ListView(
                children: repositories.map((repo) => Text(repo.name)).toList(),
            );
        },
    )
});
```

Observe jolts from anywhere
```dart
store.users
    .when((result) => result.hasData)
    .listen((result) {
        final repositories = result.data.map((repository) => repository.name);
        print("Found github repositories: $repositories");
    });
```

### Jolt (abstraction)
Jolt is a very simple primitive that can be extended in a multitude of ways in order to encapsule almost any existing state model.

The Jolt interface abstracts over Streams and StateNotifiers. Classes that implement it follow the principles of strongly typed functional-reactive programming. Having a common Jolt interface allows for the interoperability of all different types of jolts. 

You may think of Jolt as a Stream that may have a sync current value (its state), and that emits events or notifications (when its state changes).

Jolt implementations use ValueNotifiers under the hood in order to stay lightweight and performant.

Jolts guarantee interopability with existing stream liberaries (dart core and external packages) by being able to be operated on using Stream transformers.

### Examples

#### Observable State

```dart
class Counter with Store {
    final count = jolt(0);

    void increment() => count++;
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
    void login() async {
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

#### Simple cubit
```dart
class Counter extends StateView<int> {
    Counter() : super(0);

    increment() => emit(state + 1);
}
```

#### Stream operators
You can use stream operators inside a Computed, listening directly to the stream and attaching it (to be disposed together with the store) in the constructor or on the jolt declaration.

```dart
class Example with Store {
    final count = jolt(0)
                   ..debounce(Duration(milliseconds: 300))
                   .listen(print)
                   .attach(this);
               
    Example() {
        final dispose = count
            .debounce(Duration(milliseconds: 300))
            .listen(print);
        dispose();
    }
    
    
    final debouncedCount = count.transform((str) => str.debounce(Duration(milliseconds: 300)));
    final _ = jolt.computed((read) {
        final count = read(debouncedCount, initialValue: count.value);{
        // alternatively:
        // final count = read.value(count, signal: (str) => str.debounce(Duration(milliseconds: 300)), initialValue: count.value);
        print(count);
    });
}
             

```dart

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
class LoginState {
    Initial()
    Loading()
    Success(user)
    Error(error)
}

class LoginStore extends StateView<LoginState> {
    LoginStore() : super(LoginState.initial());

    void login(String email, String password) async {
        emit(LoginState.loading());
        try {
            final user = await api.login(email, password);
            emit(LoginState.success(user));
        }
        catch (e) {
            emit(LoginState.error(e));
        }
    }
}

```dart
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

---
























#### Derived States (Riverpod, jotai, mobx)
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

#### Mixing different types of jolts
```dart
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
    

### Guidelines

We recommend you to start as simple as possible (StateJolt) and if needed, use more complex jolts for complex domains: extend StateView for State Machines, use EventJolt for stream
##### Creating jolts
ComputedView allows you to create a custom jolt by composing others, and emitting a value whenether any one of them changes
StateView allows you to create a custom jolt by emitting events when there is a change. It saves the current value whenether a new event is emitted.


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
