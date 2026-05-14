import 'package:flutter/material.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';

const TextStyle signupInputStyle = TextStyle(
  fontFamily: 'Calibri',
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: Color(0xFF2F2F2F),
);

Widget signupFieldLabel(String label) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(
      label,
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 13,
        color: Color(0xFF666666),
      ),
    ),
  );
}

InputDecoration signupInputDecoration(
  String hint, {
  Widget? suffixIcon,
  bool readOnly = false,
}) {
  final borderColor = readOnly ? const Color(0xFFE8E8E8) : const Color(0xFFC9C9C9);
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Calibri',
      fontSize: 15,
      color: Color(0xFFAAAAAA),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    filled: readOnly,
    fillColor: readOnly ? const Color(0xFFF9F9F9) : null,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
      borderSide: BorderSide(color: borderColor, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
      borderSide: const BorderSide(color: Color(0xFFD91F32), width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
      borderSide: const BorderSide(color: Color(0xFFD91F32), width: 1.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
      borderSide: const BorderSide(color: Color(0xFFD91F32), width: 1.2),
    ),
    suffixIcon: suffixIcon,
  );
}

Widget signupBottomButton({
  required String label,
  required bool isEnabled,
  required VoidCallback onTap,
  bool isLoading = false,
}) {
  return GestureDetector(
    onTap: isEnabled && !isLoading ? onTap : null,
    child: Container(
      height: 56,
      width: double.infinity,
      color: isEnabled ? const Color(0xFFD91F32) : const Color(0xFFE8A0A8),
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
    ),
  );
}

Widget signupSectionHeader(String title, Widget icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ],
    ),
  );
}

Widget signupSectionDivider() {
  return Container(
    height: 1,
    color: const Color(0xFFE8E8E8),
    margin: const EdgeInsets.symmetric(vertical: 20),
  );
}

