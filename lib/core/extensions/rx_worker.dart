import 'package:get/get.dart';

mixin RxWorkerMixin on GetxController {
  final List<Worker> _workers = [];

  Worker _addWorker(Worker worker) {
    _workers.add(worker);
    return worker;
  }

  @override
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    super.dispose();
  }

  Worker everWithDisposal<T>(
    RxInterface<T> listener,
    WorkerCallback<T> callback, {
    condition = true,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _addWorker(ever<T>(listener, callback,
          condition: condition,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError));

  Worker everAllWithDisposal(
    List<RxInterface> listeners,
    WorkerCallback callback, {
    condition = true,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _addWorker(everAll(listeners, callback,
          condition: condition,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError));
}
