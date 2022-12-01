// all commands are sync
// they do not return futures, they update stores with loading (at max be cancellable)
// they can start other commands or restart themselves

// question: what about non-global commands?
// question: is there ever a need for a command to be observed? to emit an event that can be overved or handled asynchronously? untraceably? 
        // the only case i can think for this is to avoid callbacks. to decouple behaviour like Navigator.push. this can be done w callbacks or by accepting context

/*

LoginStore {
  String email;
  String password;

  bool get isValid => Email.isValid(email) && Password.isvalid(password)

  bool loading = false;

  String? error;

}

void LoginCommand(BuildContext context) {
  if (loginStore.isValid)
    loading = true;
    await login(store.email, store.password)
    NavigateTo(context, blablabla) 
}

extension toStream<T> on ChangeNotifier<T> {
  
}

CompleteToolkit

- Store { useStream(), events, action }
- StateNotifier, ComputedNotifier, AsyncNotifier { toStream() }
- Commands w DI & Recurrent Commands (observing store streams) - how to handle takedown? how to manage context?

*/

class Store {

}