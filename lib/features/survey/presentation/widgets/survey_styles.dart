import 'package:flutter/material.dart';

class SurveyStyles {
  static const Color pageBackground = Color(0xFFF2F2F2);
  static const Color sectionBackground = Colors.white;
  static const Color titleColor = Color(0xFF333333);
  static const Color subtitleColor = Color(0xFF666666);
  static const Color borderColor = Color(0xFFCCCCCC);
  static const Color softCard = Color(0xFFFBFBFB);
  static const Color submitDisabled = Color(0xFFD78694);

  static const TextStyle topBarTitle = TextStyle(
    fontFamily: 'Calibri',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: subtitleColor,
  );

  static const TextStyle questionSerial = TextStyle(
    fontFamily: 'Calibri',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black,
    letterSpacing: 0.1,
  );

  static const TextStyle questionText = TextStyle(
    fontFamily: 'Calibri',
    fontSize: 15,
    fontWeight: FontWeight.w300,
    color: titleColor,
    height: 1.15,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Calibri',
    fontSize: 15,
    fontWeight: FontWeight.w300,
    color: subtitleColor,
    height: 1.15,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: 'Calibri',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: subtitleColor,
    height: 1.15,
  );
}
