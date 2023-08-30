library auto_complete_widget_flutter;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef WidgetBuilder<T> = Widget Function(T, String, bool);
typedef WidgetBuilderChildren<T> = Widget Function(
    FocusNode, TextEditingController);
typedef FuncSort<T> = bool Function(String, T);
typedef StringFunc<T> = String Function(T);
typedef OnResult<T> = void Function(T);

typedef ValueX = (
  /// bottom
  double? top,

  /// top
  double?,

  /// sizeOverlay
  double,

  /// width
  double,

  /// left
  double,
);

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
    this.paddingLeft,
  });
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final Widget? separatorBuilder;
  final Decoration? decoration;
  final double? paddingLeft;
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
                dragStartBehavior: DragStartBehavior.down,
                child: ListView.separated(
                  dragStartBehavior: DragStartBehavior.down,
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
      _timer = Timer.periodic(
        const Duration(milliseconds: 100),
        (timer) {
          _timer!.cancel();
          showOverlay(context);
        },
      );
    }
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
    final sizeShow = sizeDevice - positionThis - kToolbarHeight;
    final sizeShowTop = positionThis;
    bool mode = true;
    if (sizeShow > sizeOverlay) {
      mode = false;
    }
    final top = !mode ? sizeShowTop + sizeThis : null;
    final bottom = !mode ? null : sizeDevice - sizeShowTop;
    final width = (widget.ctx != null
        ? widget.ctx!._sizeWidget.width - (widget.paddingLeft ?? 0)
        : context._sizeWidget.width);
    final left = widget.paddingLeft ?? context._position.dx;
    return (bottom, top, sizeOverlay, width, left);
  }

  void showOverlay(BuildContext context) {
    final value = sizeShow(context);
    overlayEntry = OverlayEntry(
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            overlayEntry?.remove();
            overlayEntry = null;
          },
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Positioned(
                  top: value.$2,
                  bottom: value.$1,
                  left: value.$5,
                  child: Container(
                    width: value.$4,
                    decoration: widget.decoration ??
                        BoxDecoration(
                          color: Colors.blue[100],
                        ),
                    constraints: BoxConstraints(
                      maxHeight: value.$3,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
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
    return Builder(builder: (context) {
      return widget.child?.call(node, controller) ??
          TextFormField(
            focusNode: node,
            controller: controller,
          );
    });
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
