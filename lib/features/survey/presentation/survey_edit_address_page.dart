import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/survey/data/survey_address_repository.dart';
import 'package:filip_at_flutter/features/survey/presentation/survey_postal_search_page.dart';
import 'package:filip_at_flutter/features/survey/presentation/widgets/survey_styles.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:flutter/material.dart';

class SurveyEditAddressResult {
  const SurveyEditAddressResult({
    required this.street,
    required this.postalCode,
    required this.cityState,
    required this.country,
  });

  final String street;
  final String postalCode;
  final String cityState;
  final String country;
}

class SurveyEditAddressPage extends StatefulWidget {
  const SurveyEditAddressPage({
    super.key,
    required this.addressRepository,
    required this.customerInfo,
  });

  final SurveyAddressRepository addressRepository;
  final SurveyCustomerInfo customerInfo;

  @override
  State<SurveyEditAddressPage> createState() => _SurveyEditAddressPageState();
}

class _SurveyEditAddressPageState extends State<SurveyEditAddressPage> {
  late final TextEditingController _streetController;
  late final TextEditingController _cityStateController;
  late final TextEditingController _postalController;
  late final TextEditingController _countryController;

  String _selectedCountryCode = '';
  List<CountryOption> _countryList = const <CountryOption>[];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final info = widget.customerInfo;
    _streetController = TextEditingController(text: info.street);
    _cityStateController = TextEditingController(text: info.cityState);
    _postalController = TextEditingController(text: info.postalCode);
    _selectedCountryCode = info.country;
    _countryController = TextEditingController(text: info.country);
    _loadCountries();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityStateController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    final list = await widget.addressRepository.fetchCountryList();
    if (!mounted) return;
    setState(() {
      _countryList = list;
      if (_selectedCountryCode.isNotEmpty) {
        final match = list.where((c) => c.code == _selectedCountryCode).firstOrNull;
        if (match != null) _countryController.text = match.name;
      }
    });
  }

  Future<void> _pickPostalCode() async {
    final result = await Navigator.of(context).push<PostalSuggestion>(
      MaterialPageRoute<PostalSuggestion>(
        builder: (_) => SurveyPostalSearchPage(
          addressRepository: widget.addressRepository,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _postalController.text = result.code;
      _cityStateController.text = result.city;
    });
  }

  Future<void> _pickCountry() async {
    final selected = await showModalBottomSheet<CountryOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(countries: _countryList),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedCountryCode = selected.code;
      _countryController.text = selected.name;
    });
  }

  bool get _isValid =>
      _postalController.text.trim().isNotEmpty &&
      _cityStateController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);

    final info = widget.customerInfo;
    final street = _streetController.text.trim();
    final cityState = _cityStateController.text.trim();
    final postalCode = _postalController.text.trim();
    final country = _selectedCountryCode;

    final fullPersonData = Map<String, dynamic>.from(info.rawPersonData)
      ..['ItemId'] = info.itemId
      ..['DisplayName'] = info.displayName
      ..['Email'] = info.email
      ..['PhoneNumber'] = info.phoneNumber;

    final ok = await widget.addressRepository.updatePersonAddress(
      itemId: info.itemId,
      street: street,
      cityState: cityState,
      postalCode: postalCode,
      country: country,
      addressLine1: info.addressLine1,
      fullPersonData: fullPersonData,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop(
        SurveyEditAddressResult(
          street: street,
          postalCode: postalCode,
          cityState: cityState,
          country: country,
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.tr('SOMETHING_WENT_WRONG'))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: SurveyStyles.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.tr('editAddress'),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AddressField(
                      label: l10n.tr('street'),
                      controller: _streetController,
                    ),
                    const SizedBox(height: 16),
                    _AddressField(
                      label: l10n.tr('city'),
                      controller: _cityStateController,
                    ),
                    const SizedBox(height: 16),
                    _AddressLabel(label: l10n.tr('postalZipCode')),
                    const SizedBox(height: 6),
                    _TappableAddressField(
                      controller: _postalController,
                      hintText: l10n.tr('postalZipCode'),
                      trailing: const Icon(
                        FilipIcons.edit,
                        color: Color(0xFFB23A4D),
                        size: 20,
                      ),
                      onTap: _pickPostalCode,
                    ),
                    const SizedBox(height: 16),
                    _AddressLabel(label: '${l10n.tr('selectCountry')} *'),
                    const SizedBox(height: 6),
                    _TappableAddressField(
                      controller: _countryController,
                      hintText: l10n.tr('selectCountry'),
                      trailing: const Icon(
                        SelectNetworkIcons.arrowDown,
                        color: Color(0xFFB23A4D),
                        size: 18,
                      ),
                      onTap: _pickCountry,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isValid && !_submitting) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD82034),
                  disabledBackgroundColor: SurveyStyles.submitDisabled,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l10n.tr('confirm').toUpperCase(),
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

class _AddressLabel extends StatelessWidget {
  const _AddressLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF808080),
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AddressLabel(label: label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: Color(0xFF808080),
          ),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: SurveyStyles.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFB23A4D), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _TappableAddressField extends StatelessWidget {
  const _TappableAddressField({
    required this.controller,
    required this.hintText,
    required this.trailing,
    required this.onTap,
  });
  final TextEditingController controller;
  final String hintText;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: SurveyStyles.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.text.isNotEmpty ? controller.text : hintText,
                style: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: controller.text.isNotEmpty
                      ? const Color(0xFF808080)
                      : const Color(0xFFA7A7A7),
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.countries});
  final List<CountryOption> countries;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  late List<CountryOption> _filtered;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
    _search.addListener(_filter);
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.countries
          : widget.countries
              .where((c) => c.name.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenHeight = MediaQuery.of(context).size.height;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: SizedBox(
        height: screenHeight * 0.78,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD2D2D2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                style: const TextStyle(fontFamily: 'Calibri', fontSize: 16),
                decoration: InputDecoration(
                  hintText: l10n.tr('selectCountry'),
                  hintStyle: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    color: Color(0xFFA7A7A7),
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFB23A4D)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: SurveyStyles.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide:
                        const BorderSide(color: Color(0xFFB23A4D), width: 1.5),
                  ),
                ),
              ),
            ),
            if (widget.countries.isEmpty)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFB23A4D)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  itemBuilder: (ctx, index) {
                    final country = _filtered[index];
                    return InkWell(
                      onTap: () => Navigator.of(ctx).pop(country),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Text(
                          country.name,
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 16,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
