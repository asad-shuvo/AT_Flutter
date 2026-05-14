import 'package:filip_at_flutter/features/survey/presentation/widgets/survey_styles.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SurveyTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SurveyTopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(FilipIcons.back, color: Color(0xFF808080), size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 4,
      title: Text(title, style: SurveyStyles.topBarTitle),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFD8D8D8)),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

class SurveyActionButton extends StatelessWidget {
  const SurveyActionButton({
    super.key,
    required this.label,
    this.onTap,
    this.outlined = false,
    this.leading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(6);
    final foreground = outlined ? AppColors.primaryRed : Colors.white;
    final background = outlined ? Colors.white : AppColors.primaryRed;

    return Material(
      color: background,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: SurveyStyles.borderColor, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                    letterSpacing: 0.12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: foreground, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class SurveyQuestionCard extends StatelessWidget {
  const SurveyQuestionCard({
    super.key,
    required this.serial,
    required this.question,
    required this.child,
  });

  final String serial;
  final String question;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(serial.toUpperCase(), style: SurveyStyles.questionSerial),
          const SizedBox(height: 8),
          Text(question, style: SurveyStyles.questionText),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: SurveyStyles.softCard,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}
