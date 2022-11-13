import 'dart:async';

import 'package:rxdart/rxdart.dart';

// when editing the input, BuildableStream.fromInputStream()
// when editing the output, BuildableStream.transform()

class BuildableStream<I, O> implements Sink<I> {
  late final StreamController<O> controller;

  late Stream<O> stream;

  BuildableStream.fromStream(this.stream);

  BuildableStream() {
    controller = StreamController();
    stream = controller.stream;
  }
  
  add(I data) {
    controller.add(data);
  }

  BuildableStream<I2, O> transformInput<I2>(StreamTransformer<I2, I> transformer) {
    BuildableStream<I2,I>().stream.listen((event) {
      add(event);
    });
    return BuildableStream<I2, O>.fromStream(stream);
  }

  BuildableStream<I, O2> transformOutput<O2>(StreamTransformer<O, O2> transformer) {
    return BuildableStream.fromStream(stream.transform(transformer));
  }
  
  @override
  void close() {
    controller.close();
  }
}

class Whatever<T> extends StreamView<T> implements Sink<T> {
  StreamController<T> controller;
  Whatever(this.controller) : super(controller.stream);

  @override
  void add(T data) {
    controller.add(data);
  }

  @override
  void close() {
    controller.close();
  }
}
