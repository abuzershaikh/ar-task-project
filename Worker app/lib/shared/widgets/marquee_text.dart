import 'package:flutter/material.dart';

/// A reusable Marquee Text widget that renders text on a single line.
/// If the text length exceeds available container width, it smoothly scrolls horizontally back and forth like a marquee ticker.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  final ScrollController _scrollController = ScrollController();
  bool _shouldScroll = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverflowAndStart();
    });
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkOverflowAndStart();
      });
    }
  }

  void _checkOverflowAndStart() async {
    if (_isDisposed || !mounted || !_scrollController.hasClients) return;

    try {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        if (!_shouldScroll && mounted) {
          setState(() => _shouldScroll = true);
        }
        _startMarqueeLoop();
      } else {
        if (_shouldScroll && mounted) {
          setState(() => _shouldScroll = false);
        }
      }
    } catch (_) {}
  }

  void _startMarqueeLoop() async {
    while (mounted && !_isDisposed && _scrollController.hasClients) {
      try {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll <= 0) break;

        // Pause at start
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted || _isDisposed || !_scrollController.hasClients) break;

        // Scroll to end slowly
        final durationMs = (maxScroll * 40).clamp(2000, 8000).toInt();
        await _scrollController.animateTo(
          maxScroll,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        );

        // Pause at end
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted || _isDisposed || !_scrollController.hasClients) break;

        // Scroll back to start
        await _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        );
      } catch (_) {
        break;
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
