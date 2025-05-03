import 'package:flutter/material.dart';

class AnimationDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration verySlow = Duration(milliseconds: 800);
}

class AnimationCurves {
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve bounce = Curves.easeOutCubic;
  static const Curve smooth = Curves.easeInOut;
}

class AnimationConfigs {
  static const pageTransition = PageTransitionConfig(
    duration: AnimationDurations.normal,
    curve: AnimationCurves.standard,
  );

  static const dialogTransition = DialogTransitionConfig(
    duration: AnimationDurations.normal,
    curve: AnimationCurves.standard,
  );

  static const fadeTransition = FadeTransitionConfig(
    duration: AnimationDurations.normal,
    curve: AnimationCurves.standard,
  );

  static const slideTransition = SlideTransitionConfig(
    duration: AnimationDurations.normal,
    curve: AnimationCurves.bounce,
  );

  static const scaleTransition = ScaleTransitionConfig(
    duration: AnimationDurations.normal,
    curve: AnimationCurves.standard,
  );

  static const pulseAnimation = PulseAnimationConfig(
    duration: AnimationDurations.verySlow,
    curve: AnimationCurves.smooth,
  );
}

class PageTransitionConfig {
  final Duration duration;
  final Curve curve;

  const PageTransitionConfig({
    required this.duration,
    required this.curve,
  });
}

class DialogTransitionConfig {
  final Duration duration;
  final Curve curve;

  const DialogTransitionConfig({
    required this.duration,
    required this.curve,
  });
}

class FadeTransitionConfig {
  final Duration duration;
  final Curve curve;

  const FadeTransitionConfig({
    required this.duration,
    required this.curve,
  });
}

class SlideTransitionConfig {
  final Duration duration;
  final Curve curve;

  const SlideTransitionConfig({
    required this.duration,
    required this.curve,
  });
}

class ScaleTransitionConfig {
  final Duration duration;
  final Curve curve;

  const ScaleTransitionConfig({
    required this.duration,
    required this.curve,
  });
}

class PulseAnimationConfig {
  final Duration duration;
  final Curve curve;

  const PulseAnimationConfig({
    required this.duration,
    required this.curve,
  });
}