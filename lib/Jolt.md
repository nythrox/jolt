##### Creating jolts

##### Types of Jolts
Jolt is supposed to offer a great flexibility in terms of state management, allowing you to structure your code according to your actual business flows, easily switching from simple mutable state like ChangeNotifier, Observable (from mobx), Rx(from getx), state machines such as Cubit (from flutter_bloc) and StateNotifier (from provider), or more complex reactive solutions using streams like RxDart and Bloc in flutter_bloc.

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

class LoginStore extends StateJolt<LoginState> {
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

```


Simple Mutable State (mobx, ChangeNotifier, getx)

```dart
class LoginStore {
    
    final email = StateJolt("");
    final password = StateJolt("");

    late final isValid = ComputedJolt((watch) {
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
class SearchUserStore {

    final query = StateJolt("");

    // ReadonlyAsyncJolt<List<UserModel>>
    late final users = ComputedJolt.future((watch) async {
        final name = watch.value(query, signal: () => query.stream.debounce(Duration(milliseconds: 300)));
        if (name.length == 0) {
            return [];
        }
        else return await api.searchUsers(name: name);
    });

}
```

Alternatively:

```dart
class SearchUserStore {

    final query = StateJolt("");

    final users = AsyncJolt<List<UserModel>>([]);

    SearchUserJolt() {
        useStream(
            query.stream
            .debounce(Duration(seconds: 300))
            .listen((name) {
                if (name.length == 0) {
                    users.value = [];
                }
                else users.future = api.searchUsers(name: name);
            }),
        );
    }
}
```

### Custom Jolts

ErrorValidationJolt<String>("", (email) => Email.isValid(email) ? "Invalid Email" : null)
ValidationJolt<String>("", Email.isValid)

ValidaitonGroup.fromJolt()
ValidaitonGroup.from({

})