library auto_complete_widget_flutter;

import 'dart:async';

import 'package:flutter/material.dart';

typedef WidgetBuilder<T> = Widget Function(T, String, bool);
typedef WidgetBuilderChildren<T> = Widget Function(
    FocusNode, TextEditingController);
typedef FuncSort<T> = bool Function(String, T);
typedef StringFunc<T> = String Function(T);
typedef OnResult<T> = void Function(T);

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
  });

  final List<T> values;
  final T? selected;
  final Decoration? decoration;
  final WidgetBuilder<T> builder;
  final FuncSort<T> onSort;
  final Widget? empty;
  final StringFunc result;
  final OnResult onResult;
  final Widget? separatorBuilder;
  final WidgetBuilderChildren? child;

  @override
  State<AutoCompleteField<T>> createState() => _AutoCompleteFieldState<T>();
}

class _AutoCompleteFieldState<T> extends State<AutoCompleteField<T>> {
  final node = FocusNode();
  final controller = TextEditingController();
  late OverlayEntry overlayEntry;
  late T? _selectedValue;
  bool _show = false;
  StreamController<List<T>> controllerValues =
      StreamController.broadcast(sync: true);
  StreamController<T> selected = StreamController.broadcast(sync: true);

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
                        overlayEntry.remove();
                        _show = false;
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
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      node.addListener(() => _listen(context));
      controller.addListener(_listenText);
    });
    super.initState();
    _selectedValue = widget.selected;
  }

  void showOverlay(BuildContext context) {
    _show = true;
    //#region mode
    final sizeThis = context.sizeWidget.height;
    final sizeOverlay = context.sizeWidget.height * 4;
    final sizeDevice = MediaQuery.sizeOf(context).height;
    final positionThis = context.position.dy;
    final sizeShow = sizeDevice - positionThis;
    final sizeShowTop = positionThis + sizeThis;
    bool mode = true;
    if (sizeShow > sizeOverlay) {
      mode = false;
    }
    //#endregion
    overlayEntry = OverlayEntry(
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: () {
            _show = false;
            FocusScope.of(context).unfocus();
            overlayEntry.remove();
          },
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Positioned(
                  top: mode ? null : sizeShowTop,
                  bottom: mode ? sizeShow : null,
                  left: context.position.dx,
                  child: Container(
                    width: context.sizeWidget.width,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                    ),
                    constraints: BoxConstraints(
                      // minHeight: context.sizeWidget.height,
                      maxHeight: sizeOverlay,
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
    Overlay.maybeOf(context)?.insert(overlayEntry);
  }

  @override
  void dispose() {
    if (_show) {
      overlayEntry.remove();
    }
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
    if (node.hasFocus) {
      showOverlay(context);
    } else {
      if (!_show) return;
      overlayEntry.remove();
      _show = false;
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
  Offset get position {
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

  Size get sizeWidget {
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
