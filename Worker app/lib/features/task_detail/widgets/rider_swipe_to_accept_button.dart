import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

/// A high-performance, taxi/rider style (Uber / Rapido / Ola) "Swipe to Accept" button.
/// Features:
/// - Smooth 60fps spring-back physics
/// - Dynamic gradient track fill that expands behind the slider thumb
/// - Shimmering animated text wave moving left-to-right
/// - Animated pulsating chevron arrows wave (>>>)
/// - Tactile haptic feedback on touch, slide, and threshold trigger
/// - Crisp swipe sound effect on accept
/// - Automatic loading and success states
class RiderSwipeToAcceptButton extends StatefulWidget {
  final VoidCallback onSwipeComplete;
  final bool isAccepting;
  final bool isAccepted;
  final String title;
  final String subtitle;
  final String loadingTitle;
  final String acceptedTitle;

  const RiderSwipeToAcceptButton({
    super.key,
    required this.onSwipeComplete,
    this.isAccepting = false,
    this.isAccepted = false,
    this.title = 'SWIPE TO ACCEPT TASK',
    this.subtitle = 'Slide to lock task for you',
    this.loadingTitle = 'Locking Task For You...',
    this.acceptedTitle = 'Task Accepted!',
  });

  @override
  State<RiderSwipeToAcceptButton> createState() =>
      _RiderSwipeToAcceptButtonState();
}

class _RiderSwipeToAcceptButtonState extends State<RiderSwipeToAcceptButton>
    with TickerProviderStateMixin {
  // Shimmer animation controller (moves shine across the track)
  late final AnimationController _shimmerController;

  // Arrow pulse wave animation controller
  late final AnimationController _arrowPulseController;

  // Spring snap animation controller (snaps back to 0 or forward to max)
  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;

  AudioPlayer? _audioPlayer;

  double _dragPosition = 0.0;
  bool _isDragging = false;
  bool _hasTriggered = false;
  bool _thresholdHapticGiven = false;

  static const double _buttonHeight = 62.0;
  static const double _thumbSize = 52.0;
  static const double _thumbMargin = 5.0;
  static const double _triggerThreshold = 0.75; // 75% swipe triggers accept

  @override
  void initState() {
    super.initState();

    try {
      _audioPlayer = AudioPlayer();
      _audioPlayer?.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('[RiderSwipe] AudioPlayer init error: $e');
    }

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _arrowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant RiderSwipeToAcceptButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If accepting failed or reset, spring the slider back to 0
    if (oldWidget.isAccepting && !widget.isAccepting && !widget.isAccepted) {
      _snapBackToStart();
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _shimmerController.dispose();
    _arrowPulseController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  void _playSwipeSound() {
    try {
      _audioPlayer?.stop();
      _audioPlayer?.play(
        AssetSource('audio/swipe_accept.wav'),
        volume: 1.0,
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('[RiderSwipe] Error playing swipe sound: $e');
    }
  }

  void _snapBackToStart() {
    _snapAnimation = Tween<double>(
      begin: _dragPosition,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutBack,
    ));

    _snapController.reset();
    _snapController.forward();
    _snapController.addListener(() {
      if (mounted) {
        setState(() {
          _dragPosition = _snapAnimation?.value ?? 0.0;
        });
      }
    });

    setState(() {
      _hasTriggered = false;
      _isDragging = false;
      _thresholdHapticGiven = false;
    });
    HapticFeedback.lightImpact();
  }

  void _snapToFinish(double maxDrag) {
    if (_hasTriggered) return;

    _playSwipeSound();
    HapticFeedback.heavyImpact();

    _snapAnimation = Tween<double>(
      begin: _dragPosition,
      end: maxDrag,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutCubic,
    ));

    _snapController.reset();
    _snapController.forward();
    _snapController.addListener(() {
      if (mounted) {
        setState(() {
          _dragPosition = _snapAnimation?.value ?? maxDrag;
        });
      }
    });

    setState(() {
      _dragPosition = maxDrag;
      _hasTriggered = true;
      _isDragging = false;
    });

    widget.onSwipeComplete();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final maxDrag = max(0.0, totalWidth - _thumbSize - (_thumbMargin * 2));
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        // Auto-stick to end if already accepted or currently accepting
        final currentPosition = (widget.isAccepted || widget.isAccepting)
            ? maxDrag
            : _dragPosition;

        final isLockedState = widget.isAccepting || widget.isAccepted;

        return Container(
          height: _buttonHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_buttonHeight / 2),
            // Sleek luxury dark carbon/slate track
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_buttonHeight / 2),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 1. Dynamic Expanding Green Fill behind thumb
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: currentPosition + (_thumbSize / 2) + _thumbMargin,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLockedState
                            ? const [Color(0xFF059669), Color(0xFF10B981)]
                            : [
                                const Color(0xFF047857),
                                const Color(0xFF059669),
                                const Color(0xFF10B981),
                              ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(_buttonHeight / 2),
                        right: Radius.circular(
                          progress > 0.85 ? _buttonHeight / 2 : 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Center Text & Animated Pulsing Chevron Wave
                Positioned.fill(
                  child: Center(
                    child: isLockedState
                        ? _buildLockedStatusWidget()
                        : Opacity(
                            opacity: (1.0 - (progress * 1.6)).clamp(0.0, 1.0),
                            child: _buildShimmeringTrackLabel(),
                          ),
                  ),
                ),

                // 3. Draggable Rider Slider Thumb (Knob)
                Positioned(
                  left: _thumbMargin + currentPosition,
                  top: _thumbMargin,
                  child: GestureDetector(
                    onHorizontalDragStart: isLockedState
                        ? null
                        : (_) {
                            setState(() => _isDragging = true);
                            HapticFeedback.lightImpact();
                          },
                    onHorizontalDragUpdate: isLockedState
                        ? null
                        : (details) {
                            final newPos = (_dragPosition + details.delta.dx)
                                .clamp(0.0, maxDrag);
                            final currentProgress =
                                maxDrag > 0 ? (newPos / maxDrag) : 0.0;

                            // Tactile snap feedback when crossing the 75% trigger threshold
                            if (currentProgress >= _triggerThreshold &&
                                !_thresholdHapticGiven) {
                              _thresholdHapticGiven = true;
                              HapticFeedback.mediumImpact();
                            } else if (currentProgress < _triggerThreshold &&
                                _thresholdHapticGiven) {
                              _thresholdHapticGiven = false;
                            }

                            setState(() {
                              _dragPosition = newPos;
                            });

                            // If dragged all the way to 96%+, snap and finish immediately
                            if (currentProgress >= 0.96 && !_hasTriggered) {
                              _snapToFinish(maxDrag);
                            }
                          },
                    onHorizontalDragEnd: isLockedState
                        ? null
                        : (_) {
                            if (progress >= _triggerThreshold && !_hasTriggered) {
                              _snapToFinish(maxDrag);
                            } else if (!_hasTriggered) {
                              _snapBackToStart();
                            }
                          },
                    child: _buildSliderThumb(progress, isLockedState),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shimmering track label with moving gradient and ripple arrows
  Widget _buildShimmeringTrackLabel() {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerController, _arrowPulseController]),
      builder: (context, _) {
        final shimmerValue = _shimmerController.value;

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.5, 0),
              end: const Alignment(1.5, 0),
              colors: const [
                Color(0xFF94A3B8), // Muted metallic slate
                Color(0xFFE2E8F0),
                Colors.white,      // Glowing bright core
                Color(0xFF34D399), // Neon emerald flash
                Color(0xFF94A3B8),
              ],
              stops: [
                (shimmerValue - 0.35).clamp(0.0, 1.0),
                (shimmerValue - 0.15).clamp(0.0, 1.0),
                shimmerValue.clamp(0.0, 1.0),
                (shimmerValue + 0.15).clamp(0.0, 1.0),
                (shimmerValue + 0.35).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 32), // Space for thumb
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              // Wave of 3 pulsing chevron arrows
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final phase = (_arrowPulseController.value - (index * 0.22)) % 1.0;
                  final opacity = (0.3 + (phase * 0.7)).clamp(0.2, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Label shown when accepting is underway or completed
  Widget _buildLockedStatusWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isAccepting)
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        Text(
          widget.isAccepting ? widget.loadingTitle : widget.acceptedTitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  /// The circular slider thumb / knob
  Widget _buildSliderThumb(double progress, bool isLockedState) {
    final scale = _isDragging ? 1.06 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: _thumbSize,
        height: _thumbSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Brilliant white circular knob with glowing neon rim
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.55),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLockedState
              ? (widget.isAccepting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Color(0xFF059669),
                      ),
                    )
                  : SvgPicture.asset(
                      'assets/svg/rider_check_icon.svg',
                      width: 22,
                      height: 22,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF059669),
                        BlendMode.srcIn,
                      ),
                    ))
              : SvgPicture.asset(
                  'assets/svg/rider_swipe_chevron.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF059669),
                    BlendMode.srcIn,
                  ),
                ),
        ),
      ),
    );
  }
}
