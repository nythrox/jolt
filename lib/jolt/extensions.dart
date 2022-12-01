import 'package:volt/jolt/views.dart';

import 'jolt.dart';
import 'store.dart';

extension Transform<T> on Jolt<T> {
  Jolt<T2> transform<T2>(Stream<T2> Function(Stream<T> stream) transform) {
    return Jolt.fromPureStream(transform(asStream));
  }
}



// TODO: we should be subscribing through onEvent, not .stream.listen() // we r only doing that cuz of the operators
extension SignalExtension<T> on ValueJolt<T> {
  // TODO: this should be Stream<T> signal(ValueJolt<T>, SignalBuilder) to un-subscribe at correct time (listeners), 

  /// Lets you build a Jolt that gets the value from [ValueJolt] ([this]) whenever any one of the observed jolts emit.
  Jolt<T> signal(SignalBuilder signalBuilder) {
    // TODO: hmmm maybe stick to stream transformations, since Jolt transformations would not only
    // duplicate the whole shit but are hard to get right (with dispose, etc)
    // all transformations will be done using Streams, leave jolts only as Controllers.
    // make it extremely easy to consume streams (since we will be using them)
    return SignalJolt(this, signalBuilder);
  }
}

extension Attach<T> on Stream<T> {
  void attach(SignalJolt jolt) {
    jolt.attachStream(this);
  }
}

class SignalJolt<T> extends JoltView<T> with Store {
  final ValueJolt<T> valueJolt;

  SignalJolt(this.valueJolt, SignalBuilder<T> builder) {
    builder(this);
  }

  void attachStream(Stream stream) {
    final sub = stream.listen((_) => helper.addEvent(valueJolt.currentValue));
    onDispose(sub.cancel);
  }
}

typedef ValueComparer<T> = bool Function(T previousValue, T newValue);

extension JoltWatchers<T> on Stream<T> {
  Stream<T> when(ValueComparer<T> comparator) async* {
    late T previousValue;
    bool hasPreviousValue = false;
    await for (final value in this) {
      if (!hasPreviousValue) {
        previousValue = value;
        hasPreviousValue = true;
        yield value;
      } else if (comparator(previousValue, value)) {
        previousValue = value;
        yield value;
      }
    }
  }

  // TODO: remake copying stream.distinct()
  Stream<T> select<U>(U Function(T) selector,
      [ValueComparer<U>? comparator]) async* {
    late U previousValue;
    bool hasPreviousValue = false;
    await for (final value in this) {
      final selectedValue = selector(value);
      if (!hasPreviousValue) {
        previousValue = selectedValue;
        hasPreviousValue = true;
        yield value;
        continue;
      }
      if (comparator != null
          ? comparator(previousValue, selectedValue)
          : selectedValue != previousValue) {
        previousValue = selectedValue;
        yield value;
      }
    }
  }
}

typedef SignalBuilder<T> = void Function(SignalJolt signal);


// TODO: exchange for converting jolts
// extension Convertable<T,U> on Jolt<T,U> {
//   J convert<T2,U2, J extends Jolt<T2, U2>>(J Function(Jolt<T,U>) converter) {
//     return converter(this);
//   }

//   J chain<T2,U2, J extends Jolt<T2, U2>>(J Function(Stream<U>) converter) {
//     return converter(asStream);
//   }
// }