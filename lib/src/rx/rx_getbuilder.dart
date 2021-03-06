import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/src/instance/get_instance.dart';
import 'package:get/src/root/smart_management.dart';
import 'rx_impl.dart';
import 'rx_interface.dart';

class GetX<T extends DisposableInterface> extends StatefulWidget {
  final Widget Function(T) builder;
  final bool global;
  // final Stream Function(T) stream;
  // final StreamController Function(T) streamController;
  final bool autoRemove;
  final bool assignId;
  final void Function(State state) initState, dispose, didChangeDependencies;
  final void Function(GetX oldWidget, State state) didUpdateWidget;
  final T init;
  const GetX({
    this.builder,
    this.global = true,
    this.autoRemove = true,
    this.initState,
    this.assignId = false,
    //  this.stream,
    this.dispose,
    this.didChangeDependencies,
    this.didUpdateWidget,
    this.init,
    // this.streamController
  });
  GetImplXState<T> createState() => GetImplXState<T>();
}

class GetImplXState<T extends DisposableInterface> extends State<GetX<T>> {
  RxInterface _observer;
  T controller;
  bool isCreator = false;
  StreamSubscription subs;

  @override
  void initState() {
    _observer = Rx();
    bool isPrepared = GetInstance().isPrepared<T>();
    bool isRegistred = GetInstance().isRegistred<T>();
    if (widget.global) {
      if (isPrepared) {
        if (GetConfig.smartManagement != SmartManagement.keepFactory) {
          isCreator = true;
        }
        controller = GetInstance().find<T>();
      } else if (isRegistred) {
        controller = GetInstance().find<T>();
        isCreator = false;
      } else {
        controller = widget.init;
        isCreator = true;
        GetInstance().put<T>(controller);
      }
    } else {
      controller = widget.init;
      isCreator = true;
      controller?.onStart();
    }
    if (widget.initState != null) widget.initState(this);
    // if (isCreator && GetConfig.smartManagement == SmartManagement.onlyBuilder) {
    //   controller?.onStart();
    // }
    subs = _observer.subject.stream.listen((data) => setState(() {}));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.didChangeDependencies != null) {
      widget.didChangeDependencies(this);
    }
  }

  @override
  void didUpdateWidget(GetX oldWidget) {
    super.didUpdateWidget(oldWidget as GetX<T>);
    if (widget.didUpdateWidget != null) widget.didUpdateWidget(oldWidget, this);
  }

  @override
  void dispose() {
    if (widget.dispose != null) widget.dispose(this);
    if (isCreator || widget.assignId) {
      if (widget.autoRemove && GetInstance().isRegistred<T>()) {
        GetInstance().delete<T>();
      }
    }
    subs.cancel();
    _observer.close();
    controller = null;
    isCreator = null;
    super.dispose();
  }

  Widget get notifyChilds {
    final observer = getObs;
    getObs = _observer;
    final result = widget.builder(controller);
    if (!_observer.canUpdate) {
      throw """
      [Get] the improper use of a GetX has been detected. 
      You should only use GetX or Obx for the specific widget that will be updated.
      If you are seeing this error, you probably did not insert any observable variables into GetX/Obx 
      or insert them outside the scope that GetX considers suitable for an update 
      (example: GetX => HeavyWidget => variableObservable).
      If you need to update a parent widget and a child widget, wrap each one in an Obx/GetX.
      """;
    }
    getObs = observer;
    return result;
  }

  @override
  Widget build(BuildContext context) => notifyChilds;
}
