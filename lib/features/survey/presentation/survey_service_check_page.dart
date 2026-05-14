import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/profile/captcha_bottom_sheet.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/profile/update_email_controller.dart';
import 'package:filip_at_flutter/features/profile/update_email_form.dart';
import 'package:filip_at_flutter/features/profile/update_phone_controller.dart';
import 'package:filip_at_flutter/features/profile/update_phone_form.dart';
import 'package:filip_at_flutter/features/profile/verification_code_sheet.dart';
import 'package:filip_at_flutter/features/survey/data/survey_address_repository.dart';
import 'package:filip_at_flutter/features/survey/presentation/survey_complete_bottom_sheet.dart';
import 'package:filip_at_flutter/features/survey/presentation/survey_edit_address_page.dart';
import 'package:filip_at_flutter/features/survey/presentation/widgets/survey_common_widgets.dart';
import 'package:filip_at_flutter/features/survey/presentation/widgets/survey_styles.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:flutter/material.dart';

class SurveyServiceCheckPage extends StatefulWidget {
  const SurveyServiceCheckPage({
    super.key,
    required this.dashboardRepository,
    this.profileRepository,
    this.surveyAddressRepository,
  });

  final DashboardRepository dashboardRepository;
  final ProfileRepository? profileRepository;
  final SurveyAddressRepository? surveyAddressRepository;

  @override
  State<SurveyServiceCheckPage> createState() => _SurveyServiceCheckPageState();
}

class _SurveyServiceCheckPageState extends State<SurveyServiceCheckPage> {
  final Map<int, String> _singleAnswers = <int, String>{};
  final Set<String> _questionFiveSelections = <String>{};
  final Set<String> _questionTwoSelections = <String>{};
  final TextEditingController _questionTwoOtherController =
      TextEditingController();
  final TextEditingController _questionFourController = TextEditingController();
  bool _isSubmitting = false;
  String? _serviceCheckId;
  SurveyCustomerInfo? _customerInfo;
  UpdateEmailController? _emailController;
  UpdatePhoneController? _phoneController;

  void _setSingleAnswer(int questionIndex, String answer) {
    setState(() {
      _singleAnswers[questionIndex] = answer;
    });
  }

  void _toggleQuestionFive(String key) {
    setState(() {
      if (_questionFiveSelections.contains(key)) {
        _questionFiveSelections.remove(key);
      } else {
        _questionFiveSelections.add(key);
      }
    });
  }

  bool _isQuestionFiveSelected(String key) =>
      _questionFiveSelections.contains(key);

  bool get _isFormValid {
    final q2Yes = _singleAnswers[2] == 'yes';
    final q4Yes = _singleAnswers[4] == 'yes';
    final q2HasSelection = _questionTwoSelections.isNotEmpty;
    final q2OtherNeedsText = _questionTwoSelections.contains('q2other') &&
        _questionTwoOtherController.text.trim().isEmpty;
    final q4NeedsText = q4Yes && _questionFourController.text.trim().isEmpty;

    return _singleAnswers[1] != null &&
        _singleAnswers[2] != null &&
        _singleAnswers[3] != null &&
        _singleAnswers[4] != null &&
        _singleAnswers[6] != null &&
        (!q2Yes || (q2HasSelection && !q2OtherNeedsText)) &&
        !q4NeedsText;
  }

  @override
  void initState() {
    super.initState();
    _singleAnswers[5] = 'yes';
    _questionTwoOtherController.addListener(() => setState(() {}));
    _questionFourController.addListener(() => setState(() {}));
    final repo = widget.profileRepository;
    if (repo != null) {
      _emailController = UpdateEmailController(repository: repo);
      _phoneController = UpdatePhoneController(repository: repo);
    }
    _loadData();
  }

  @override
  void dispose() {
    _questionTwoOtherController.dispose();
    _questionFourController.dispose();
    _emailController?.dispose();
    _phoneController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      widget.dashboardRepository.fetchSurveyCustomerInfo(),
      widget.dashboardRepository.fetchServiceCheckRecord(),
    ]);
    if (!mounted) return;
    final customer = results[0] as SurveyCustomerInfo?;
    final record = results[1] as SurveyServiceCheckRecord?;
    setState(() {
      _customerInfo = customer;
      _serviceCheckId = record?.itemId;
    });
  }

  static const Map<String, String> _q2ConstMap = <String, String>{
    'q2marriage': 'MARRIAGE_PARTNERSHIP',
    'q2family': 'NEW_ADDITION_TO_THE_FAMILY',
    'q2careeradv': 'CAREER_ADVANCEMENT_INCREASE_OF_SALARY',
    'q2careerchange': 'CAREER_CHANGE',
    'q2education': 'CHILDRENS_EDUCATION_COMPLETED',
    'q2movingout': 'CHILDREN_MOVING_OUT',
    'q2employed': 'CHILDREN_BEING_EMPLOYED',
    'q2death': 'DEATH_IN_THE_FAMILY',
    'q2inheritance': 'INHERITANCE',
    'q2divorce': 'SEPARATION_DIVORCE',
    'q2payoff': 'PAYOFF_OF_FINANCE',
    'q2pet': 'NEW_PET',
    'q2hobby': 'NEW_HOBBY',
  };

  static const Map<String, String> _q5ConstMap = <String, String>{
    'q5retirement1': 'REVIEW_OF_EXISTING_PROVISIONS',
    'q5retirement2': 'I_WOULD_LIKE_TO_SET_UP_A_PROVISION_SAVING_PLAN',
    'q5retirement3': 'I_WOULD_LIKE_TO_PLAN_FOR_MY_CHILDRENS_FUTURE',
    'q5coverage1': 'REVIEW_OF_EXISTING_COVERAGE',
    'q5coverage2': 'I_WOULD_LIKE_TO_SECURE_MY_INCOME',
    'q5coverage3': 'I_WOULD_LIKE_TO_SECURE_THE_FUTURE_OF_MY_DEPENDENTS',
    'q5financing1': 'NEW_LEASE_FINANCING',
    'q5financing2': 'REVIEW_OF_EXISTING_FINANCING',
    'q5investment1': 'MONTHLY_SAVING',
    'q5investment2': 'INVESTING_A_LUMP_SUM_AMOUNT',
    'q5realestate1': 'REAL_ESTATE_PURCHASE',
    'q5realestate2': 'REAL_ESTATE_SALE',
    'q5realestate3': 'INVESTMENT_PROPERTY_DEVELOPER_MODEL',
  };

  String _guid() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final micros = DateTime.now().microsecondsSinceEpoch;
    return '$millis-$micros';
  }

  String _joinSelected(List<String> keys) {
    final selected = <String>[];
    for (final key in keys) {
      if (_questionFiveSelections.contains(key)) {
        final constValue = _q5ConstMap[key];
        if (constValue != null) selected.add(constValue);
      }
    }
    return selected.join(',');
  }

  String _joinQuestionTwoSelected(List<String> keys) {
    final selected = <String>[];
    for (final key in keys) {
      if (_questionTwoSelections.contains(key)) {
        if (key == 'q2other') {
          final text = _questionTwoOtherController.text.trim();
          if (text.isNotEmpty) selected.add(text);
        } else {
          final constValue = _q2ConstMap[key];
          if (constValue != null) selected.add(constValue);
        }
      }
    }
    return selected.join(',');
  }

  void _showErrorCode(BuildContext context, String? code) {
    if (code == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(code)));
  }

  // ── Email change flow ─────────────────────────────────────────────────────

  Future<void> _startEmailUpdateFlow(BuildContext context) async {
    final controller = _emailController;
    if (controller == null) return;
    controller.resetFlow();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => CaptchaBottomSheet(
        controller: controller,
        onVerified: (captchaCode) => _openUpdateEmailSheet(context, captchaCode),
      ),
    );
  }

  Future<void> _openUpdateEmailSheet(BuildContext context, String captchaCode) async {
    final controller = _emailController;
    if (controller == null) return;
    final currentEmail = _customerInfo?.email ?? '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UpdateEmailForm(
        controller: controller,
        currentEmail: currentEmail,
        onConfirm: (newEmail) async {
          final ok = await controller.startEmailFlow(
            currentEmail: currentEmail,
            newEmail: newEmail,
            captchaVerificationCode: captchaCode,
            language: Localizations.localeOf(context).languageCode == 'de'
                ? 'de-DE'
                : 'en-US',
          );
          if (!ok || !mounted) {
            _showErrorCode(context, controller.flowErrorCode);
            return;
          }
          _openEmailVerificationSheet(context);
        },
      ),
    );
  }

  Future<void> _openEmailVerificationSheet(BuildContext context) async {
    final controller = _emailController;
    if (controller == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) => VerificationCodeSheet(
        controller: controller,
        title: 'Update Email Address',
        icon: SelectNetworkIcons.email,
        descriptionText:
            'Please enter the 4 digit code sent to ${controller.newEmail}',
        onConfirm: (code) async {
          final ok = await controller.confirmVerificationCode(code);
          if (!ok || !mounted) {
            _showErrorCode(context, controller.flowErrorCode);
            return;
          }
          if (!mounted) return;
          setState(() {
            final c = _customerInfo;
            if (c != null) {
              _customerInfo = SurveyCustomerInfo(
                personId: c.personId,
                customerId: c.customerId,
                itemId: c.itemId,
                displayName: c.displayName,
                email: controller.newEmail,
                phoneNumber: c.phoneNumber,
                address: c.address,
                street: c.street,
                postalCode: c.postalCode,
                cityState: c.cityState,
                country: c.country,
                addressLine1: c.addressLine1,
                rawPersonData: c.rawPersonData,
              );
            }
          });
          if (mounted) Navigator.of(context).pop();
        },
        onResend: () async {
          if (!mounted) return;
          Navigator.of(context).pop();
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            builder: (_) => CaptchaBottomSheet(
              controller: controller,
              onVerified: (captchaCode) async {
                final ok = await controller.resendVerificationCode(captchaCode);
                if (!mounted) return;
                if (!ok) {
                  _showErrorCode(context, controller.flowErrorCode);
                  return;
                }
                _openEmailVerificationSheet(context);
              },
            ),
          );
        },
      ),
    );
  }

  // ── Phone change flow ─────────────────────────────────────────────────────

  Future<void> _startPhoneUpdateFlow(BuildContext context) async {
    final controller = _phoneController;
    if (controller == null) return;
    controller.resetFlow();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => CaptchaBottomSheet(
        controller: controller,
        onVerified: (captchaCode) => _openUpdatePhoneSheet(context, captchaCode),
      ),
    );
  }

  Future<void> _openUpdatePhoneSheet(BuildContext context, String captchaCode) async {
    final controller = _phoneController;
    if (controller == null) return;
    final currentPhone = _customerInfo?.phoneNumber ?? '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UpdatePhoneForm(
        controller: controller,
        currentPhone: currentPhone,
        onConfirm: (newPhone) async {
          final ok = await controller.startPhoneFlow(
            currentPhone: currentPhone,
            newPhone: newPhone,
            captchaVerificationCode: captchaCode,
            language: Localizations.localeOf(context).languageCode == 'de'
                ? 'de-DE'
                : 'en-US',
          );
          if (!ok || !mounted) {
            _showErrorCode(context, controller.flowErrorCode);
            return;
          }
          _openPhoneVerificationSheet(context);
        },
      ),
    );
  }

  Future<void> _openPhoneVerificationSheet(BuildContext context) async {
    final controller = _phoneController;
    if (controller == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) => VerificationCodeSheet(
        controller: controller,
        title: 'Update Phone Number',
        icon: SelectNetworkIcons.phone,
        descriptionText:
            'Please enter the 4 digit code sent to ${controller.newPhone}',
        onConfirm: (code) async {
          final ok = await controller.confirmVerificationCode(code);
          if (!ok || !mounted) {
            _showErrorCode(context, controller.flowErrorCode);
            return;
          }
          if (!mounted) return;
          setState(() {
            final c = _customerInfo;
            if (c != null) {
              _customerInfo = SurveyCustomerInfo(
                personId: c.personId,
                customerId: c.customerId,
                itemId: c.itemId,
                displayName: c.displayName,
                email: c.email,
                phoneNumber: controller.newPhone,
                address: c.address,
                street: c.street,
                postalCode: c.postalCode,
                cityState: c.cityState,
                country: c.country,
                addressLine1: c.addressLine1,
                rawPersonData: c.rawPersonData,
              );
            }
          });
          if (mounted) Navigator.of(context).pop();
        },
        onResend: () async {
          if (!mounted) return;
          Navigator.of(context).pop();
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            builder: (_) => CaptchaBottomSheet(
              controller: controller,
              onVerified: (captchaCode) async {
                final ok = await controller.resendPhoneCode(captchaCode);
                if (!mounted) return;
                if (!ok) {
                  _showErrorCode(context, controller.flowErrorCode);
                  return;
                }
                _openPhoneVerificationSheet(context);
              },
            ),
          );
        },
      ),
    );
  }

  // ── Address edit flow ────────────────────────────────────────────────────

  Future<void> _startAddressEditFlow(BuildContext context) async {
    final repo = widget.surveyAddressRepository;
    final info = _customerInfo;
    if (repo == null || info == null) return;
    final result = await Navigator.of(context).push<SurveyEditAddressResult>(
      MaterialPageRoute<SurveyEditAddressResult>(
        builder: (_) => SurveyEditAddressPage(
          addressRepository: repo,
          customerInfo: info,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final addressParts = <String>[
      if (result.street.isNotEmpty) result.street,
      if (result.postalCode.isNotEmpty) result.postalCode,
      if (result.cityState.isNotEmpty) result.cityState,
      if (result.country.isNotEmpty) result.country,
    ];
    setState(() {
      _customerInfo = SurveyCustomerInfo(
        personId: info.personId,
        customerId: info.customerId,
        itemId: info.itemId,
        displayName: info.displayName,
        email: info.email,
        phoneNumber: info.phoneNumber,
        address: addressParts.join(', '),
        street: result.street,
        postalCode: result.postalCode,
        cityState: result.cityState,
        country: result.country,
        addressLine1: info.addressLine1,
        rawPersonData: <String, dynamic>{
          ...info.rawPersonData,
          'Street': result.street,
          'PostalCode': result.postalCode,
          'State': result.cityState,
          'City': result.cityState,
          'Country': result.country,
          'AddressLine1': info.addressLine1,
        },
      );
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_isFormValid || _customerInfo == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final payload = <String, dynamic>{
      'ServiceCheckId': _serviceCheckId ?? _guid(),
      'Tags': <String>['Is-A-ServiceCheck'],
      'Pnr': _customerInfo!.customerId,
      'QuesOneAnswer': _singleAnswers[1] == 'yes',
      'QuesTwoAnswer': _singleAnswers[2] == 'yes',
      'QuesThreeAnswer': _singleAnswers[3] == 'yes',
      'QuesFourAnswer': _singleAnswers[4] == 'yes',
      'QuesFiveAnswer': true,
      'QuesSixAnswer': _singleAnswers[6] == 'yes',
      'QuesOneDescription': <String, dynamic>{
        'Name': _customerInfo!.displayName,
        'Email': _customerInfo!.email,
        'PhoneNumber': _customerInfo!.phoneNumber,
        'Address': _customerInfo!.address,
      },
      'QuesTwoDescription': _singleAnswers[2] == 'yes'
          ? _joinQuestionTwoSelected(const <String>[
              'q2marriage',
              'q2family',
              'q2careeradv',
              'q2careerchange',
              'q2education',
              'q2movingout',
              'q2employed',
              'q2death',
              'q2inheritance',
              'q2divorce',
              'q2payoff',
              'q2pet',
              'q2hobby',
              'q2other',
            ])
          : '',
      'QuesThreeDescription': '',
      'QuesFourDescription':
          _singleAnswers[4] == 'yes' ? _questionFourController.text.trim() : '',
      'QuesFiveDescription': <String, dynamic>{
        'Retirement': _joinSelected(const <String>[
          'q5retirement1',
          'q5retirement2',
          'q5retirement3',
        ]),
        'Coverage': _joinSelected(const <String>[
          'q5coverage1',
          'q5coverage2',
          'q5coverage3',
        ]),
        'Financing': _joinSelected(const <String>[
          'q5financing1',
          'q5financing2',
        ]),
        'Investment': _joinSelected(const <String>[
          'q5investment1',
          'q5investment2',
        ]),
        'Realestate': _joinSelected(const <String>[
          'q5realestate1',
          'q5realestate2',
          'q5realestate3',
        ]),
      },
      'QuesSixDescription': '',
    };

    final ok = await widget.dashboardRepository.updateServiceCheck(payload);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (_) => SurveyCompleteBottomSheet(l10n: l10n),
      );
      if (mounted) Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.tr('SOMETHING_WENT_WRONG'))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canSubmit = _isFormValid && !_isSubmitting;

    return Scaffold(
      backgroundColor: SurveyStyles.pageBackground,
      appBar: SurveyTopBar(title: l10n.tr('SERVICE_CHECK')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  SurveyQuestionCard(
                    serial: l10n.tr('QUES_ONE'),
                    question: l10n.tr('QUES_ONE_TITLE'),
                    child: _ReadOnlyDetailsCard(
                      customerInfo: _customerInfo,
                      selectedAnswer: _singleAnswers[1],
                      onSelect: (answer) => _setSingleAnswer(1, answer),
                      onEmailEditTap: _emailController != null
                          ? () => _startEmailUpdateFlow(context)
                          : null,
                      onPhoneEditTap: _phoneController != null
                          ? () => _startPhoneUpdateFlow(context)
                          : null,
                      onAddressEditTap: widget.surveyAddressRepository != null
                          ? () => _startAddressEditFlow(context)
                          : null,
                    ),
                  ),
                  SurveyQuestionCard(
                    serial: l10n.tr('QUES_TWO'),
                    question: l10n.tr('QUES_TWO_TITLE'),
                    child: Column(
                      children: [
                        _YesNoRow(
                          selectedAnswer: _singleAnswers[2],
                          onSelect: (answer) => _setSingleAnswer(2, answer),
                        ),
                        if (_singleAnswers[2] == 'yes') ...[
                          const SizedBox(height: 10),
                          _QuestionTwoDetails(
                            selected: _questionTwoSelections,
                            otherController: _questionTwoOtherController,
                            onToggle: (key) {
                              setState(() {
                                if (_questionTwoSelections.contains(key)) {
                                  _questionTwoSelections.remove(key);
                                } else {
                                  _questionTwoSelections.add(key);
                                }
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  SurveyQuestionCard(
                    serial: l10n.tr('QUES_THREE'),
                    question: l10n.tr('QUES_THREE_TITLE'),
                    child: _YesNoRow(
                      selectedAnswer: _singleAnswers[3],
                      onSelect: (answer) => _setSingleAnswer(3, answer),
                    ),
                  ),
                  SurveyQuestionCard(
                    serial: l10n.tr('QUES_FOUR'),
                    question: l10n.tr('QUES_FOUR_TITLE'),
                    child: Column(
                      children: [
                        _YesNoRow(
                          selectedAnswer: _singleAnswers[4],
                          onSelect: (answer) => _setSingleAnswer(4, answer),
                        ),
                        if (_singleAnswers[4] == 'yes') ...[
                          const SizedBox(height: 10),
                          _SpecifyField(controller: _questionFourController),
                        ],
                      ],
                    ),
                  ),
                  SurveyQuestionCard(
                    serial: l10n.tr('QUES_FIVE'),
                    question: l10n.tr('QUES_FIVE_TITLE'),
                    child: _CheckListCard(
                      isSelected: _isQuestionFiveSelected,
                      onToggle: _toggleQuestionFive,
                    ),
                  ),
                  SurveyQuestionCard(
                    serial: l10n.tr('QUES_SIX'),
                    question: l10n.tr('QUES_SIX_TITLE'),
                    child: _YesNoColumn(
                      selectedAnswer: _singleAnswers[6],
                      onSelect: (answer) => _setSingleAnswer(6, answer),
                    ),
                  ),
                  Text(
                    l10n.tr('DISCLAIMER_TEXT'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      color: SurveyStyles.subtitleColor,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: SizedBox(
              height: 50,
              width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: SurveyStyles.submitDisabled,
                    backgroundColor: canSubmit
                        ? const Color(0xFFD82034)
                        : SurveyStyles.submitDisabled,
                    foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n.tr('SUBMIT').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyDetailsCard extends StatelessWidget {
  const _ReadOnlyDetailsCard({
    required this.customerInfo,
    required this.selectedAnswer,
    required this.onSelect,
    this.onEmailEditTap,
    this.onPhoneEditTap,
    this.onAddressEditTap,
  });

  final SurveyCustomerInfo? customerInfo;
  final String? selectedAnswer;
  final ValueChanged<String> onSelect;
  final VoidCallback? onEmailEditTap;
  final VoidCallback? onPhoneEditTap;
  final VoidCallback? onAddressEditTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChoiceTile(
          text: l10n.tr('Q1YES'),
          selected: selectedAnswer == 'yes',
          onTap: () => onSelect('yes'),
        ),
        SizedBox(height: 10),
        _ChoiceTile(
          text: l10n.tr('Q1NO'),
          selected: selectedAnswer == 'no',
          onTap: () => onSelect('no'),
        ),
        SizedBox(height: 12),
        _FieldTile(text: customerInfo?.displayName ?? ''),
        SizedBox(height: 10),
        _FieldTile(
          text: customerInfo?.email ?? '',
          showEdit: selectedAnswer == 'no',
          onTap: selectedAnswer == 'no' ? onEmailEditTap : null,
        ),
        SizedBox(height: 10),
        _FieldTile(
          text: customerInfo?.phoneNumber ?? '',
          showEdit: selectedAnswer == 'no',
          onTap: selectedAnswer == 'no' ? onPhoneEditTap : null,
        ),
        SizedBox(height: 10),
        _FieldTile(
          text: customerInfo?.address ?? '',
          showEdit: selectedAnswer == 'no',
          onTap: selectedAnswer == 'no' ? onAddressEditTap : null,
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            l10n.tr('QUESONE_FOOTERTEXT'),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: SurveyStyles.subtitleColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.text, this.showEdit = false, this.onTap});
  final String text;
  final bool showEdit;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SurveyStyles.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 15,
                color: SurveyStyles.titleColor,
              ),
            ),
          ),
          if (showEdit)
            const Icon(
              FilipIcons.edit,
              color: Color(0xFFB23A4D),
              size: 20,
            ),
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: tile,
      );
    }
    return tile;
  }
}

class _YesNoRow extends StatelessWidget {
  const _YesNoRow({required this.selectedAnswer, required this.onSelect});

  final String? selectedAnswer;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _ChoiceTile(
            text: l10n.tr('YES'),
            selected: selectedAnswer == 'yes',
            onTap: () => onSelect('yes'),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _ChoiceTile(
            text: l10n.tr('NO'),
            selected: selectedAnswer == 'no',
            onTap: () => onSelect('no'),
          ),
        ),
      ],
    );
  }
}

class _YesNoColumn extends StatelessWidget {
  const _YesNoColumn({required this.selectedAnswer, required this.onSelect});

  final String? selectedAnswer;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        _ChoiceTile(
          text: l10n.tr('Q6YES'),
          selected: selectedAnswer == 'yes',
          onTap: () => onSelect('yes'),
        ),
        SizedBox(height: 10),
        _ChoiceTile(
          text: l10n.tr('Q6NO'),
          selected: selectedAnswer == 'no',
          onTap: () => onSelect('no'),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.text,
    this.selected = false,
    this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFFB23A4D);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF5F6) : Colors.white,
            border: Border.all(
              color: selected ? selectedColor : Colors.black,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected ? selectedColor : Colors.black,
                    width: 1.2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: selected
                        ? selectedColor
                        : SurveyStyles.titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckListCard extends StatelessWidget {
  const _CheckListCard({
    required this.isSelected,
    required this.onToggle,
  });

  final bool Function(String key) isSelected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const textStyle = TextStyle(
      fontFamily: 'Calibri',
      fontSize: 14,
      fontWeight: FontWeight.w300,
      color: SurveyStyles.subtitleColor,
    );
    const sectionStyle = TextStyle(
      fontFamily: 'Calibri',
      fontSize: 12,
      fontWeight: FontWeight.w300,
      color: SurveyStyles.subtitleColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tr('RETIREMENT'), style: sectionStyle),
        const SizedBox(height: 10),
        _CheckTile(
          itemKey: 'q5retirement1',
          text: l10n.tr('REVIEW_OF_EXISTING_PROVISIONS'),
          style: textStyle,
          selected: isSelected('q5retirement1'),
          onTap: () => onToggle('q5retirement1'),
        ),
        _CheckTile(
          itemKey: 'q5retirement2',
          text: l10n.tr('I_WOULD_LIKE_TO_SET_UP_A_PROVISION_SAVING_PLAN'),
          style: textStyle,
          selected: isSelected('q5retirement2'),
          onTap: () => onToggle('q5retirement2'),
        ),
        _CheckTile(
          itemKey: 'q5retirement3',
          text: l10n.tr('I_WOULD_LIKE_TO_PLAN_FOR_MY_CHILDRENS_FUTURE'),
          style: textStyle,
          selected: isSelected('q5retirement3'),
          onTap: () => onToggle('q5retirement3'),
        ),
        const SizedBox(height: 10),
        Text(l10n.tr('COVERAGE'), style: sectionStyle),
        const SizedBox(height: 10),
        _CheckTile(
          itemKey: 'q5coverage1',
          text: l10n.tr('REVIEW_OF_EXISTING_COVERAGE'),
          style: textStyle,
          selected: isSelected('q5coverage1'),
          onTap: () => onToggle('q5coverage1'),
        ),
        _CheckTile(
          itemKey: 'q5coverage2',
          text: l10n.tr('I_WOULD_LIKE_TO_SECURE_MY_INCOME'),
          style: textStyle,
          selected: isSelected('q5coverage2'),
          onTap: () => onToggle('q5coverage2'),
        ),
        _CheckTile(
          itemKey: 'q5coverage3',
          text: l10n.tr('I_WOULD_LIKE_TO_SECURE_THE_FUTURE_OF_MY_DEPENDENTS'),
          style: textStyle,
          selected: isSelected('q5coverage3'),
          onTap: () => onToggle('q5coverage3'),
        ),
        const SizedBox(height: 10),
        Text(l10n.tr('FINANCING'), style: sectionStyle),
        const SizedBox(height: 10),
        _CheckTile(
          itemKey: 'q5financing1',
          text: l10n.tr('NEW_LEASE_FINANCING'),
          style: textStyle,
          selected: isSelected('q5financing1'),
          onTap: () => onToggle('q5financing1'),
        ),
        _CheckTile(
          itemKey: 'q5financing2',
          text: l10n.tr('REVIEW_OF_EXISTING_FINANCING'),
          style: textStyle,
          selected: isSelected('q5financing2'),
          onTap: () => onToggle('q5financing2'),
        ),
        const SizedBox(height: 10),
        Text(l10n.tr('INVESTMENT'), style: sectionStyle),
        const SizedBox(height: 10),
        _CheckTile(
          itemKey: 'q5investment1',
          text: l10n.tr('MONTHLY_SAVING'),
          style: textStyle,
          selected: isSelected('q5investment1'),
          onTap: () => onToggle('q5investment1'),
        ),
        _CheckTile(
          itemKey: 'q5investment2',
          text: l10n.tr('INVESTING_A_LUMP_SUM_AMOUNT'),
          style: textStyle,
          selected: isSelected('q5investment2'),
          onTap: () => onToggle('q5investment2'),
        ),
        const SizedBox(height: 10),
        Text(l10n.tr('REALESTATE'), style: sectionStyle),
        const SizedBox(height: 10),
        _CheckTile(
          itemKey: 'q5realestate1',
          text: l10n.tr('REAL_ESTATE_PURCHASE'),
          style: textStyle,
          selected: isSelected('q5realestate1'),
          onTap: () => onToggle('q5realestate1'),
        ),
        _CheckTile(
          itemKey: 'q5realestate2',
          text: l10n.tr('REAL_ESTATE_SALE'),
          style: textStyle,
          selected: isSelected('q5realestate2'),
          onTap: () => onToggle('q5realestate2'),
        ),
        _CheckTile(
          itemKey: 'q5realestate3',
          text: l10n.tr('INVESTMENT_PROPERTY_DEVELOPER_MODEL'),
          style: textStyle,
          selected: isSelected('q5realestate3'),
          onTap: () => onToggle('q5realestate3'),
        ),
      ],
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.itemKey,
    required this.text,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final String itemKey;
  final String text;
  final TextStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFFB23A4D);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFF5F6) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? selectedColor : const Color(0xFFD2D2D2),
                  width: 1,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: selectedColor)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: style.copyWith(
                  color: selected ? selectedColor : style.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionTwoDetails extends StatelessWidget {
  const _QuestionTwoDetails({
    required this.selected,
    required this.otherController,
    required this.onToggle,
  });

  final Set<String> selected;
  final TextEditingController otherController;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <MapEntry<String, String>>[
      MapEntry('q2marriage', l10n.tr('MARRIAGE_PARTNERSHIP')),
      MapEntry('q2family', l10n.tr('NEW_ADDITION_TO_THE_FAMILY')),
      MapEntry('q2careeradv', l10n.tr('CAREER_ADVANCEMENT_INCREASE_OF_SALARY')),
      MapEntry('q2careerchange', l10n.tr('CAREER_CHANGE')),
      MapEntry('q2education', l10n.tr('CHILDRENS_EDUCATION_COMPLETED')),
      MapEntry('q2movingout', l10n.tr('CHILDREN_MOVING_OUT')),
      MapEntry('q2employed', l10n.tr('CHILDREN_BEING_EMPLOYED')),
      MapEntry('q2death', l10n.tr('DEATH_IN_THE_FAMILY')),
      MapEntry('q2inheritance', l10n.tr('INHERITANCE')),
      MapEntry('q2divorce', l10n.tr('SEPARATION_DIVORCE')),
      MapEntry('q2payoff', l10n.tr('PAYOFF_OF_FINANCE')),
      MapEntry('q2pet', l10n.tr('NEW_PET')),
      MapEntry('q2hobby', l10n.tr('NEW_HOBBY')),
      MapEntry('q2other', l10n.tr('OTHER')),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SurveyStyles.softCard,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('QUESTION_TWO_DESC_TEXT'),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: SurveyStyles.subtitleColor,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((entry) {
            final isSelected = selected.contains(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onToggle(entry.key),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFD8495B) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD2D2D2)),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: SurveyStyles.subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (selected.contains('q2other'))
            _SpecifyField(
              controller: otherController,
              hintText: l10n.tr('pleaseSpecify'),
            ),
        ],
      ),
    );
  }
}

class _SpecifyField extends StatelessWidget {
  const _SpecifyField({required this.controller, this.hintText});

  final TextEditingController controller;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText ?? l10n.tr('pleaseSpecify'),
        hintStyle: const TextStyle(
          fontFamily: 'Calibri',
          fontSize: 15,
          color: Color(0xFFA7A7A7),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SurveyStyles.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SurveyStyles.borderColor),
        ),
      ),
    );
  }
}


