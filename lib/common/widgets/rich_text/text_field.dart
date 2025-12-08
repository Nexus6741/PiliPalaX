import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controller.dart';

/// 富文本输入框组件
class RichTextField extends StatefulWidget {
  final RichTextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final TextStyle? style;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool expands;
  final int? maxLength;
  final VoidCallback? onTap;
  final bool onTapAlwaysCalled;
  final List<TextInputFormatter>? inputFormatters;
  final bool? showCursor;
  final String obscuringCharacter;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enableInteractiveSelection;
  final TextSelectionControls? selectionControls;

  const RichTextField({
    Key? key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.maxLines = 1,
    this.minLines,
    this.style,
    this.keyboardType = TextInputType.multiline,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.expands = false,
    this.maxLength,
    this.onTap,
    this.onTapAlwaysCalled = false,
    this.inputFormatters,
    this.showCursor,
    this.obscuringCharacter = '•',
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableInteractiveSelection = true,
    this.selectionControls,
  }) : super(key: key);

  @override
  State<RichTextField> createState() => RichTextFieldState();
}

class RichTextFieldState extends State<RichTextField> {
  late FocusNode _focusNode;
  bool _showCaret = true;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(RichTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    widget.onChanged?.call(widget.controller.text);
  }

  void scheduleShowCaretOnScreen({bool withAnimation = false}) {
    // 这个方法用于在插入富文本后显示光标
    // 在这个简化版本中，我们只需要确保光标可见
    _showCaret = true;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      style: widget.style,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      obscureText: widget.obscureText,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      expands: widget.expands,
      maxLength: widget.maxLength,
      onTap: widget.onTap,
      inputFormatters: widget.inputFormatters,
      showCursor: widget.showCursor ?? _showCaret,
      obscuringCharacter: widget.obscuringCharacter,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      selectionControls: widget.selectionControls,
      // 关键：使用 buildCounter 来支持 WidgetSpan
      buildCounter: widget.maxLength != null
          ? (context,
              {required currentLength,
              required isFocused,
              required maxLength}) {
              return null;
            }
          : null,
    );
  }
}
