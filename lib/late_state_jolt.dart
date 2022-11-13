


class LateStateJolt<T> extends Jolt<T> {
  late T _value;
  bool valueSet;
  T get value {
    if (valueSet) {
      return _value;
    }
    throw HasNoValueError();
  }

  set value(T value) {
    _value = value;
    if (!valueSet) valueSet = true;
    _controller.emit(value);
  }

  StateJolt(T value)
      : _value = value,
        valueSet = true,
        super();
  StateJolt.late() : valueSet = false;
}