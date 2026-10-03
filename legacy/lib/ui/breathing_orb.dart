import 'package:flutter/material.dart';
import '../session/session_plan.dart';
import '../theme/app_theme.dart';

class BreathingOrb extends StatelessWidget {
  const BreathingOrb({super.key, this.frame, this.reduceMotion = false});
  final SessionFrame? frame;
  final bool reduceMotion;
  @override
  Widget build(BuildContext context) {
    final f = frame;
    var scale = 1.0;
    if (f != null && !reduceMotion) {
      final local = (f.elapsed.inMilliseconds % 19000) / 1000;
      scale = switch (f.phase) {
        BreathPhase.inhale => .8 + .2 * (local / 4),
        BreathPhase.hold => 1,
        BreathPhase.exhale => 1 - .2 * ((local - 11) / 8),
        _ => .9,
      };
    }
    return ExcludeSemantics(
      child: SizedBox(
        width: 134,
        height: 134,
        child: OverflowBox(
          maxWidth: 164,
          maxHeight: 164,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: f?.phase == BreathPhase.complete ? 0.5 : 1,
              child: Image.asset(
                'assets/visual/orb_${context.assetTheme}.png',
                width: 164,
                height: 164,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
