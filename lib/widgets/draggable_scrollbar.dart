import 'package:flutter/material.dart';

class DraggableScrollbar extends StatefulWidget {
  const DraggableScrollbar({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  @override
  State<DraggableScrollbar> createState() => _DraggableScrollbarState();
}

class _DraggableScrollbarState extends State<DraggableScrollbar> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      thickness: 7,
      radius: const Radius.circular(8),
      child: widget.builder(context, _controller),
    );
  }
}
