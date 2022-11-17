// ignore_for_file: prefer_function_declarations_over_variables

// first problem: if i were to simply have a special Controller<I,O>
// `I` would not be able to be debounced, treated as a stream, etc. 
// because it is a simple add(), so at most it can be synchronously transformed(A -> B)
// but not more than that (temporal).

// therefore, I think it would simply be enough to preserve the I, and only transform the O
// so you can always keep the original object, but get a different result

// still want 2 see this work nicely

import 'dart:async';

final Transform<String, int> ab = (input) {
  final controller = StreamController<int>(sync: true);
  final subscription = input.listen((data) => controller.add(int.parse(data)));
  controller.onCancel = subscription.cancel;
  return controller.stream;
};

final Transform<int, double> bc = (input) {
  final controller = StreamController<double>(sync: true);
  final subscription = input.listen((data) => controller.add(data.toDouble()));
  controller.onCancel = subscription.cancel;
  return controller.stream;
};

final Transform<String, double> ac = (str) {
  return bc(ab(str));
};

class BuilderStream<I, O> implements Sink<I> {
  final StreamController<O> controller = StreamController();
  final StreamTransformer<I, O> transformer;

  BuilderStream(this.transformer);

  BuilderStream.id() : transformer = StreamTran sformer.fromHandlers();

  @override
  void add(I data) {
    
  }

  @override
  void close() {}
}
