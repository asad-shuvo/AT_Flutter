import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ContractsAddFormSheet extends StatelessWidget {
  const ContractsAddFormSheet({
    super.key,
    required this.title,
    required this.child,
    required this.onSubmit,
    required this.submitLabel,
    this.isSubmitting = false,
    this.submitEnabled = true,
    this.showSubmitButton = true,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSubmit;
  final String submitLabel;
  final bool isSubmitting;
  final bool submitEnabled;
  final bool showSubmitButton;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = bottomInset > 0;

    return SafeArea(
      top: true,
      child: Container(
        height: screenHeight * 0.94,
        width: double.infinity,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 14, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'Calibri',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    splashRadius: 20,
                    icon: const Icon(Icons.close, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE7E7E7)),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 12 + bottomInset),
                child: child,
              ),
            ),
            if (showSubmitButton && !keyboardOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting || !submitEnabled ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      disabledBackgroundColor: AppColors.primaryRed.withValues(
                        alpha: 0.55,
                      ),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            submitLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontFamily: 'Calibri',
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ContractsFormSectionTitle extends StatelessWidget {
  const ContractsFormSectionTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'Calibri',
          fontWeight: FontWeight.w700,
          color: Color(0xFF8C8C8C),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class ContractsTextField extends StatelessWidget {
  const ContractsTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.textInputAction,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.suffixText,
    this.required = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? suffixText;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        scrollPadding: const EdgeInsets.only(bottom: 320),
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction: textInputAction,
        enabled: enabled,
        readOnly: readOnly,
        onTap: () {
          onTap?.call();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final renderObject = context.findRenderObject();
            if (renderObject != null) {
              Scrollable.ensureVisible(
                context,
                alignment: 0.1,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
              );
            }
          });
        },
        style: enabled ? _fieldStyle() : _disabledFieldStyle(),
        decoration: _contractsInputDecoration(
          label: required ? '$label *' : label,
          hint: hint,
          suffixText: suffixText,
          disabled: !enabled,
        ),
      ),
    );
  }
}

class ContractsDropdownField<T> extends StatelessWidget {
  const ContractsDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.hint,
    this.required = false,
  });

  final String label;
  final List<T> items;
  final String Function(T item) itemLabel;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final String? hint;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = value == null ? null : itemLabel(value as T);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FormField<T>(
        key: ValueKey<T?>(value),
        initialValue: value,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        builder: (state) {
          final hasValue = state.value != null;

          return InkWell(
            onTap: !enabled
                ? null
                : () async {
                    final picked = await _showPickerSheet<T>(
                      context: context,
                      title: label,
                      items: items,
                      itemLabel: itemLabel,
                      selected: state.value,
                    );
                    if (picked != null) {
                      state.didChange(picked);
                      onChanged?.call(picked);
                    }
                  },
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              isEmpty: !hasValue,
              decoration: _contractsInputDecoration(
                label: required ? '$label *' : label,
                hint: hint,
                errorText: state.errorText,
                suffixIcon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: !enabled ? const Color(0xFFAAAAAA) : null,
                ),
                disabled: !enabled,
              ),
              child: Text(
                hasValue ? itemLabel(state.value as T) : '',
                style: !enabled
                    ? const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF808080),
                        height: 1.1,
                      )
                    : hasValue
                        ? const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1F1F1F),
                            height: 1.1,
                          )
                        : const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF999999),
                            height: 1.1,
                          ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ContractsDateField extends StatelessWidget {
  const ContractsDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.validator,
    this.enabled = true,
    this.placeholder,
    this.required = false,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? placeholder;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : '${value!.day.toString().padLeft(2, '0')}.${value!.month.toString().padLeft(2, '0')}.${value!.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FormField<String>(
        validator: validator == null ? null : (_) => validator!(text),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        builder: (state) {
          return InkWell(
            onTap: enabled
                ? () {
                    state.didChange(text);
                    onTap();
                  }
                : null,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              isEmpty: text.isEmpty,
              decoration: _contractsInputDecoration(
                label: required ? '$label *' : label,
                hint: placeholder,
                errorText: state.errorText,
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: !enabled ? const Color(0xFFAAAAAA) : const Color(0xFF777777),
                ),
                disabled: !enabled,
              ),
              child: Text(
                text.isEmpty ? '' : text,
                style: !enabled
                    ? _disabledFieldStyle()
                    : text.isEmpty
                        ? const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 15,
                            color: Color(0xFF808080),
                          )
                        : _fieldStyle(),
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<T?> _showPickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T item) itemLabel,
  required T? selected,
}) {
  final l10n = context.l10n;
  final selectedIndex = selected == null ? -1 : items.indexOf(selected);
  const rowExtent = 66.0;
  final selectedItemKey = GlobalKey();
  final scrollController = ScrollController();

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
    ),
    builder: (sheetContext) {
      if (selectedIndex > 0) {
        final initialOffset = (selectedIndex * rowExtent) - (rowExtent * 0.25);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            final max = scrollController.position.maxScrollExtent;
            scrollController.jumpTo(initialOffset.clamp(0.0, max));
          }
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = selectedItemKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.02,
            duration: const Duration(milliseconds: 1),
            curve: Curves.easeOut,
          );
        }
      });

      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                controller: scrollController,
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFE5E5E5)),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selected == item;
                  return SizedBox(
                    height: rowExtent,
                    child: ListTile(
                      key: isSelected ? selectedItemKey : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(
                        itemLabel(item),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primaryRed,
                              size: 34,
                            )
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(item),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E5E5)),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: AppColors.primaryRed,
                ),
                child: Text(
                  l10n.tr('tns.cancel'),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<DateTime?> showContractsWheelDatePicker(
  BuildContext context,
  DateTime? initialDate,
) {
  final now = DateTime.now();
  final first = DateTime(now.year - 50);
  final last = DateTime(now.year + 80);
  final initial = initialDate != null &&
          initialDate.isAfter(first) &&
          initialDate.isBefore(last)
      ? initialDate
      : now;
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: Color(0xFFD91F32)),
      ),
      child: child!,
    ),
  );
}

InputDecoration _contractsInputDecoration({
  required String label,
  String? hint,
  Widget? suffixIcon,
  String? suffixText,
  String? errorText,
  bool disabled = false,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    suffixText: suffixText,
    errorText: errorText,
    labelStyle: TextStyle(
      fontFamily: 'Calibri',
      fontSize: 14,
      color: disabled ? const Color(0xFFAAAAAA) : const Color(0xFF737373),
    ),
    hintStyle: const TextStyle(
      fontFamily: 'Calibri',
      fontSize: 15,
      color: Color(0xFFB0B0B0),
    ),
    errorStyle: const TextStyle(
      fontFamily: 'Calibri',
      fontSize: 12,
      color: AppColors.primaryRed,
    ),
    filled: true,
    fillColor: disabled ? const Color(0xFFF2F2F2) : const Color(0xFFF8F8F8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE1E1E1)),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primaryRed),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primaryRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primaryRed),
    ),
  );
}

TextStyle _fieldStyle() {
  return const TextStyle(
    fontFamily: 'Calibri',
    fontSize: 16,
    color: Color(0xFF333333),
    height: 1.15,
  );
}

TextStyle _disabledFieldStyle() {
  return const TextStyle(
    fontFamily: 'Calibri',
    fontSize: 16,
    color: Color(0xFF808080),
    height: 1.15,
  );
}

