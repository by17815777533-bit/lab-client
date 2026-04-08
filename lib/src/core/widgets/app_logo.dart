import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_environment.dart';

enum AppLogoTone { light, dark }

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 56,
    this.showText = true,
    this.tone = AppLogoTone.dark,
  });

  final double size;
  final bool showText;
  final AppLogoTone tone;

  @override
  Widget build(BuildContext context) {
    final titleColor = tone == AppLogoTone.light
        ? Colors.white
        : const Color(0xFF12223A);
    final subtitleColor = tone == AppLogoTone.light
        ? Colors.white.withValues(alpha: 0.82)
        : const Color(0xFF6D7B92);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SvgPicture.asset(
          'assets/branding/app_mark.svg',
          width: size,
          height: size,
        ),
        if (showText) ...<Widget>[
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                AppEnvironment.schoolName,
                style: TextStyle(
                  color: titleColor,
                  fontSize: size >= 64 ? 24 : 18,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '实验室管理平台',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: size >= 64 ? 14 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
