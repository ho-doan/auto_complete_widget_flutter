library auto_complete_widget_flutter;

import 'dart:async';

import 'package:flutter/material.dart';

typedef WidgetBuilder<T> = Widget Function(T, String, bool);
typedef WidgetBuilderChildren<T> = Widget Function(
    FocusNode, TextEditingController);
typedef FuncSort<T> = bool Function(String, T);
typedef StringFunc<T> = String Function(T);
typedef OnResult<T> = void Function(T);
typedef ValueX = (double?, double?, double, double, double);

class AutoCompleteField<T> extends StatefulWidget {
  const AutoCompleteField({
    super.key,
    this.values = const [],
    this.selected,
    required this.builder,
    required this.onSort,
    this.empty,
    required this.result,
    this.separatorBuilder,
    required this.onResult,
    this.decoration,
    this.child,
    this.focusNode,
    this.controller,
    this.ctx,
    this.paddingLeft = 0,
  });
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final Widget? separatorBuilder;
  final Decoration? decoration;
  final double paddingLeft;
  final Widget? empty;
  final BuildContext? ctx;
  final List<T> values;
  final T? selected;
  final WidgetBuilder<T> builder;
  final FuncSort<T> onSort;
  final StringFunc<T> result;
  final OnResult<T> onResult;
  final WidgetBuilderChildren<T>? child;

  @override
  State<AutoCompleteField<T>> createState() => _AutoCompleteFieldState<T>();
}

class _AutoCompleteFieldState<T> extends State<AutoCompleteField<T>>
    with WidgetsBindingObserver {
  late FocusNode node;
  late TextEditingController controller;
  OverlayEntry? overlayEntry;
  late T? _selectedValue;
  late ValueX o;
  Timer? _timer;
  bool focus = false;
  StreamController<List<T>> controllerValues = StreamController.broadcast();
  StreamController<ValueX> metrics = StreamController.broadcast();
  StreamController<T> selected = StreamController.broadcast();

  Widget get child => StreamBuilder<List<T>>(
        stream: controllerValues.stream,
        initialData: widget.values,
        builder: (context, values) {
          final v = values.data ?? <T>[];
          if (v.isEmpty) {
            return widget.empty ?? const Text('No data');
          }
          return StreamBuilder<T>(
            initialData: _selectedValue,
            stream: selected.stream,
            builder: (ctx, valueSelected) {
              return SingleChildScrollView(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: v.length,
                  separatorBuilder: (_, __) =>
                      widget.separatorBuilder ?? const SizedBox.shrink(),
                  itemBuilder: (ctx, index) {
                    return GestureDetector(
                      onTap: () {
                        _selectedValue = v[index];
                        final text = widget.result(v[index]);
                        controller.text = text;
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(
                            offset: text.length,
                          ),
                        );
                        selected.sink.add(v[index]);
                        widget.onResult(v[index]);
                        overlayEntry?.remove();
                        overlayEntry = null;
                        FocusScope.of(context).unfocus();
                      },
                      child: widget.builder(
                        v[index],
                        controller.text,
                        valueSelected.data == v[index],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );

  @override
  void didChangeMetrics() {
    _timer?.cancel();
    if (overlayEntry == null && focus) {
      _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
        _timer!.cancel();
        showOverlay(context);
      });
    }
    metrics.sink.add(sizeShow(context));
    super.didChangeMetrics();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    node = widget.focusNode ?? FocusNode();
    controller = widget.controller ?? TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      o = sizeShow(context);
      node.addListener(() => _listen(context));
      controller.addListener(_listenText);
    });
    super.initState();
    _selectedValue = widget.selected;
  }

  ValueX sizeShow(BuildContext context) {
    final sizeThis = context._sizeWidget.height;
    final sizeOverlay = context._sizeWidget.height * 4;
    final sizeDevice = MediaQuery.sizeOf(context).height;
    final positionThis = context._position.dy;
    final sizeShow = sizeDevice - positionThis;
    final sizeShowTop = positionThis + sizeThis;
    bool mode = true;
    if (sizeShow > sizeOverlay) {
      mode = false;
    }
    final bottom = !mode ? sizeShow : null;
    final top = !mode ? null : sizeShowTop;
    final width = (widget.ctx?._sizeWidget.width ?? context._sizeWidget.width) -
        widget.paddingLeft;
    final left = context._position.dx + widget.paddingLeft;
    return (top, bottom, sizeOverlay, width, left);
  }

  void showOverlay(BuildContext context) {
    overlayEntry = OverlayEntry(
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            overlayEntry?.remove();
            overlayEntry = null;
          },
          child: StreamBuilder<ValueX>(
            stream: metrics.stream,
            initialData: o,
            builder: (context, snapshot) {
              return Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    // AnimatedPositioned(
                    Positioned(
                      // duration: const Duration(milliseconds: 10),
                      top: snapshot.data?.$1,
                      bottom: snapshot.data?.$2,
                      left: snapshot.data?.$5,
                      child: Container(
                        width: snapshot.data?.$4,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                        ),
                        constraints: BoxConstraints(
                          // minHeight: context.sizeWidget.height,
                          maxHeight: snapshot.data?.$3 ?? o.$3,
                        ),
                        child: child,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    Overlay.maybeOf(context)?.insert(overlayEntry!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    overlayEntry?.remove();
    overlayEntry = null;
    node.removeListener(() => _listen(context));
    controller.removeListener(_listenText);
    controllerValues.close();
    selected.close();
    super.dispose();
  }

  void _listenText() {
    final text = controller.text;
    if (text.isEmpty) {
      controllerValues.sink.add(widget.values);
      return;
    }
    final values = widget.values
        .where(
          (e) => widget.onSort(text, e),
        )
        .toList();
    controllerValues.sink.add(values);
  }

  void _listen(BuildContext context) {
    focus = node.hasFocus;
    if (!focus) {
      overlayEntry?.remove();
      overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child?.call(node, controller) ??
        TextFormField(
          focusNode: node,
          controller: controller,
        );
  }
}

extension BuildContextX on BuildContext {
  Offset get _position {
    final RenderBox? renderBox = findRenderObject() as RenderBox?;
    final NavigatorState? state = findAncestorStateOfType<NavigatorState>();
    if (state != null) {
      return renderBox?.localToGlobal(
            Offset.zero,
            ancestor: state.context.findRenderObject(),
          ) ??
          Offset.zero;
    }
    return renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  }

  Size get _sizeWidget {
    final RenderBox? renderBox = findRenderObject() as RenderBox?;
    return renderBox?.size ?? Size.zero;
  }
}

extension StringX on String {
  List<(String, bool)> selected(String str) {
    if (this == str) {
      return [(this, true)];
    }
    if (contains(str)) {
      final sArgs = split(str);
      final result = [
        for (final s in sArgs) ...[
          (s, false),
          if (sArgs.last != s) (str, true)
        ],
      ];
      return result;
    }
    return [(this, false)];
  }
}

extension Span on List<(String, bool)> {
  List<TextSpan> get span {
    return [
      for (final s in this)
        TextSpan(
          text: s.$1,
          style: TextStyle(
            color: s.$2 ? Colors.blueAccent : Colors.black,
          ),
        ),
    ];
  }
}
