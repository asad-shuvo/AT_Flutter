import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/data/place_address_result.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_form_data.dart';
import 'package:filip_at_flutter/features/real_estate/data/property_item.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/property_address_search_page.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _iconFont = 'filip_at_iconpack_29022024';
const _snIconFont = 'SelectNetwork';

class PropertyFormPage extends StatefulWidget {
  const PropertyFormPage({
    super.key,
    required this.source,
    required this.repository,
    this.initialData,
    this.onSaved,
  });

  final PropertyListSource source;
  final RealEstateRepository repository;
  final PropertyFormData? initialData;
  final VoidCallback? onSaved;

  @override
  State<PropertyFormPage> createState() => _PropertyFormPageState();
}

class _PropertyFormPageState extends State<PropertyFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _postCodeCtrl;
  late final TextEditingController _houseNumberCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _livingAreaCtrl;
  late final TextEditingController _landAreaCtrl;
  late final TextEditingController _gardenAreaCtrl;
  late final TextEditingController _balconyAreaCtrl;

  String _propertyAddress = '';
  String _propertyTypeCode = 'HOUSE';
  String _dealType = '';
  double? _lat;
  double? _lng;
  int _numberOfRooms = 1;
  int? _numberOfFloorsInBuilding;
  int? _floorNumber;
  int _buildingYear = 1850;
  int _numberOfBathrooms = 1;
  int _numberOfIndoorParkingSpaces = 0;
  int _numberOfOutdoorParkingSpaces = 0;
  bool _isNew = false;
  bool _hasPool = false;
  bool _hasSauna = false;
  bool _hasLift = false;

  int _kitchenQuality = 0;
  int _bathroomsQuality = 0;
  int _flooringQuality = 0;
  int _windowsQuality = 0;
  int _masonryQuality = 0;

  int _kitchenCondition = 0;
  int _bathroomsCondition = 0;
  int _flooringCondition = 0;
  int _windowsCondition = 0;
  int _masonryCondition = 0;

  bool get _isApartment => _propertyTypeCode == 'APARTMENT';
  bool get _isEditMode => widget.initialData?.propertyId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _titleCtrl = TextEditingController(text: d?.title ?? '');
    _purchasePriceCtrl = TextEditingController(
      text: d?.purchasePrice != null ? d!.purchasePrice!.toStringAsFixed(0) : '',
    );
    _streetCtrl = TextEditingController(text: d?.street ?? '');
    _postCodeCtrl = TextEditingController(text: d?.postCode ?? '');
    _houseNumberCtrl = TextEditingController(text: d?.houseNumber ?? '');
    _cityCtrl = TextEditingController(text: d?.city ?? '');
    _livingAreaCtrl = TextEditingController(
      text: d?.livingArea != null ? d!.livingArea!.toStringAsFixed(0) : '10',
    );
    _landAreaCtrl = TextEditingController(
      text: d?.landArea != null ? d!.landArea!.toStringAsFixed(0) : '50',
    );
    _gardenAreaCtrl = TextEditingController(
      text: d?.gardenArea != null ? d!.gardenArea!.toStringAsFixed(0) : '',
    );
    _balconyAreaCtrl = TextEditingController(
      text: d?.balconyArea != null ? d!.balconyArea!.toStringAsFixed(0) : '',
    );
    if (d != null) {
      _propertyTypeCode = d.propertyTypeCode.toUpperCase();
      _dealType = d.dealType;
      _numberOfRooms = d.numberOfRooms;
      _numberOfFloorsInBuilding = d.numberOfFloorsInBuilding;
      _floorNumber = d.floorNumber;
      _buildingYear = d.buildingYear;
      _numberOfBathrooms = d.numberOfBathrooms ?? 1;
      _numberOfIndoorParkingSpaces = d.numberOfIndoorParkingSpaces ?? 0;
      _numberOfOutdoorParkingSpaces = d.numberOfOutdoorParkingSpaces ?? 0;
      _isNew = d.isNew;
      _hasPool = d.hasPool;
      _hasSauna = d.hasSauna;
      _hasLift = d.hasLift;
      _kitchenQuality = d.kitchenQuality;
      _bathroomsQuality = d.bathroomsQuality;
      _flooringQuality = d.flooringQuality;
      _windowsQuality = d.windowsQuality;
      _masonryQuality = d.masonryQuality;
      _kitchenCondition = d.kitchenCondition;
      _bathroomsCondition = d.bathroomsCondition;
      _flooringCondition = d.flooringCondition;
      _windowsCondition = d.windowsCondition;
      _masonryCondition = d.masonryCondition;
      if (d.street.isNotEmpty || d.city.isNotEmpty) {
        _propertyAddress = [d.street, d.houseNumber, d.postCode, d.city]
            .where((s) => s.isNotEmpty)
            .join(', ');
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _streetCtrl.dispose();
    _postCodeCtrl.dispose();
    _houseNumberCtrl.dispose();
    _cityCtrl.dispose();
    _livingAreaCtrl.dispose();
    _landAreaCtrl.dispose();
    _gardenAreaCtrl.dispose();
    _balconyAreaCtrl.dispose();
    super.dispose();
  }

  Future<void> _openAddressSearch() async {
    final result = await Navigator.of(context).push<PlaceAddressResult>(
      MaterialPageRoute(
        builder: (_) => PropertyAddressSearchPage(
          repository: widget.repository,
          initialValue: _propertyAddress,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _propertyAddress = result.displayAddress;
        _streetCtrl.text = result.street;
        _houseNumberCtrl.text = result.houseNumber;
        _cityCtrl.text = result.city;
        _postCodeCtrl.text = result.postCode;
        _lat = result.lat;
        _lng = result.lng;
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _dealType.isEmpty) return;

    final personId = await widget.repository.getPersonId();
    if (personId == null || !mounted) return;

    setState(() => _isSaving = true);

    final data = PropertyFormData(
      propertyId: widget.initialData?.propertyId,
      title: _titleCtrl.text.trim(),
      propertyTypeCode: _propertyTypeCode,
      dealType: _dealType,
      purchasePrice: double.tryParse(_purchasePriceCtrl.text.replaceAll(',', '')),
      street: _streetCtrl.text.trim(),
      postCode: _postCodeCtrl.text.trim(),
      houseNumber: _houseNumberCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      lat: _lat,
      lng: _lng,
      livingArea: double.tryParse(_livingAreaCtrl.text),
      landArea: _isApartment ? null : double.tryParse(_landAreaCtrl.text),
      gardenArea: double.tryParse(_gardenAreaCtrl.text),
      balconyArea: double.tryParse(_balconyAreaCtrl.text),
      numberOfRooms: _numberOfRooms,
      numberOfFloorsInBuilding: _isApartment ? _numberOfFloorsInBuilding : null,
      floorNumber: _isApartment ? _floorNumber : null,
      buildingYear: _buildingYear,
      numberOfBathrooms: _numberOfBathrooms,
      numberOfIndoorParkingSpaces: _numberOfIndoorParkingSpaces,
      numberOfOutdoorParkingSpaces: _numberOfOutdoorParkingSpaces,
      isNew: _isNew,
      hasPool: _isApartment ? false : _hasPool,
      hasSauna: _isApartment ? false : _hasSauna,
      hasLift: _isApartment ? _hasLift : false,
      kitchenQuality: _kitchenQuality,
      bathroomsQuality: _bathroomsQuality,
      flooringQuality: _flooringQuality,
      windowsQuality: _windowsQuality,
      masonryQuality: _masonryQuality,
      kitchenCondition: _kitchenCondition,
      bathroomsCondition: _bathroomsCondition,
      flooringCondition: _flooringCondition,
      windowsCondition: _windowsCondition,
      masonryCondition: _masonryCondition,
      existingTags: widget.initialData?.existingTags,
    );

    final tag = widget.source == PropertyListSource.observation
        ? 'Is-A-Observation'
        : 'Is-A-Valuation';

    try {
      await widget.repository.saveProperty(
        data: data,
        personId: personId,
        tag: tag,
        language: _toLanguageValue(context.l10n.locale.languageCode),
      );
      if (!mounted) return;
      widget.onSaved?.call();
      Navigator.of(context).pop(true);
      final msgKey = widget.source == PropertyListSource.observation
          ? 'observePropertySuccessfullyaddedMsg'
          : 'valuationPropertySuccessfullyaddedMsg';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr(msgKey))),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tr('SOMETHING_WENT_WRONG'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isObs = widget.source == PropertyListSource.observation;
    final pageTitle = _isEditMode
        ? l10n.tr(isObs ? 'editObservePreoperty' : 'editValuationPreoperty')
        : l10n.tr(isObs ? 'observeNewProperty' : 'valuationNewProperty');
    final submitLabel = l10n.tr(isObs ? 'observe' : 'valuate');

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _FormHeader(
              title: pageTitle,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _FormSection(
                      iconCode: '',
                      iconFont: _iconFont,
                      title: l10n.tr('basicInformation'),
                      children: [
                        _buildTitleField(l10n),
                        const SizedBox(height: 12),
                        _buildPropertyTypeDropdown(l10n),
                        const SizedBox(height: 12),
                        _buildDealTypeRadio(l10n),
                        const SizedBox(height: 12),
                        _buildNumberField(
                          controller: _purchasePriceCtrl,
                          label: l10n.tr('propertyPriceOptional'),
                          hint: l10n.tr('purchasePriceInEuro'),
                          required: false,
                        ),
                      ],
                    ),
                    _FormSection(
                      iconCode: '',
                      iconFont: _iconFont,
                      title: l10n.tr('propertyInformationAndAddress'),
                      children: [
                        _buildAddressSearchField(l10n),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _streetCtrl,
                          label: l10n.tr('street'),
                          required: true,
                          maxLength: 50,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _postCodeCtrl,
                          label: l10n.tr('postCode'),
                          required: true,
                          keyboardType: TextInputType.number,
                          maxLength: 50,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _houseNumberCtrl,
                          label: l10n.tr('houseNumber'),
                          required: true,
                          maxLength: 50,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _cityCtrl,
                          label: l10n.tr('city'),
                          required: true,
                          maxLength: 50,
                        ),
                        const SizedBox(height: 12),
                        _buildCountryField(l10n),
                      ],
                    ),
                    _FormSection(
                      iconCode: '',
                      iconFont: _snIconFont,
                      title: l10n.tr('propertyMeasurementAndBuildingYear'),
                      children: [
                        _buildIntDropdown(
                          label: l10n.tr('selecteNoOfRooms'),
                          value: _numberOfRooms,
                          items: List.generate(10, (i) => i + 1),
                          onChanged: (v) => setState(() => _numberOfRooms = v!),
                          required: true,
                          prefixIconCode: '',
                        ),
                        if (_isApartment) ...[
                          const SizedBox(height: 12),
                          _buildIntDropdown(
                            label: l10n.tr('NoOfFloors'),
                            value: _numberOfFloorsInBuilding,
                            items: List.generate(50, (i) => i + 1),
                            onChanged: (v) => setState(() {
                              _numberOfFloorsInBuilding = v;
                              if (_floorNumber != null &&
                                  v != null &&
                                  _floorNumber! > v) {
                                _floorNumber = v;
                              }
                            }),
                            required: false,
                          ),
                          const SizedBox(height: 12),
                          _buildIntDropdown(
                            label: l10n.tr('fllorNumber'),
                            value: _floorNumber,
                            items: List.generate(
                              _numberOfFloorsInBuilding ?? 50,
                              (i) => i + 1,
                            ),
                            onChanged: (v) => setState(() => _floorNumber = v),
                            required: false,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              l10n.tr('floorInstruction'),
                              style: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 13,
                                color: Color(0xFF808080),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildNumberField(
                          controller: _livingAreaCtrl,
                          label: l10n.tr('estimatedLivingArea'),
                          required: true,
                          min: 10,
                          max: 800,
                        ),
                        if (_isApartment) ...[
                          const SizedBox(height: 12),
                          _buildNumberField(
                            controller: _gardenAreaCtrl,
                            label: l10n.tr('gardenArea'),
                            required: false,
                            min: 0,
                            max: 200,
                          ),
                        ],
                        if (!_isApartment) ...[
                          const SizedBox(height: 12),
                          _buildNumberField(
                            controller: _landAreaCtrl,
                            label: l10n.tr('estimatedLandArea'),
                            required: true,
                            min: 50,
                            max: 5000,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildYearDropdown(l10n),
                        const SizedBox(height: 12),
                        _buildNumberField(
                          controller: _balconyAreaCtrl,
                          label: l10n.tr('balconyArea'),
                          required: false,
                          min: 0,
                          max: 200,
                        ),
                      ],
                    ),
                    _FormSection(
                      iconCode: '',
                      iconFont: _iconFont,
                      title: l10n.tr('additionalFeatures'),
                      children: [
                        _buildIntDropdown(
                          label: l10n.tr('selecteNoOfBathRooms'),
                          value: _numberOfBathrooms,
                          items: List.generate(5, (i) => i + 1),
                          onChanged: (v) => setState(() => _numberOfBathrooms = v ?? 1),
                          required: false,
                          prefixIconCode: '',
                        ),
                        const SizedBox(height: 12),
                        _buildIntDropdown(
                          label: l10n.tr('garageSpaces'),
                          value: _numberOfIndoorParkingSpaces,
                          items: List.generate(7, (i) => i),
                          onChanged: (v) => setState(
                              () => _numberOfIndoorParkingSpaces = v ?? 0),
                          required: false,
                          prefixIconCode: '',
                        ),
                        const SizedBox(height: 12),
                        _buildIntDropdown(
                          label: l10n.tr('parkingSpace'),
                          value: _numberOfOutdoorParkingSpaces,
                          items: List.generate(7, (i) => i),
                          onChanged: (v) => setState(
                              () => _numberOfOutdoorParkingSpaces = v ?? 0),
                          required: false,
                          prefixIconCode: '',
                          prefixIconFont: _snIconFont,
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureCheckbox(
                          label: l10n.tr('isNewBuilding'),
                          value: _isNew,
                          iconCode: '',
                          iconFont: _iconFont,
                          onChanged: (v) => setState(() => _isNew = v),
                        ),
                        if (!_isApartment) ...[
                          const SizedBox(height: 8),
                          _buildFeatureCheckbox(
                            label: l10n.tr('swimingPool'),
                            value: _hasPool,
                            iconCode: '',
                            iconFont: _snIconFont,
                            onChanged: (v) => setState(() => _hasPool = v),
                          ),
                          const SizedBox(height: 8),
                          _buildFeatureCheckbox(
                            label: l10n.tr('sauna'),
                            value: _hasSauna,
                            iconCode: '',
                            iconFont: _snIconFont,
                            onChanged: (v) => setState(() => _hasSauna = v),
                          ),
                        ],
                        if (_isApartment) ...[
                          const SizedBox(height: 8),
                          _buildFeatureCheckbox(
                            label: l10n.tr('HasLift'),
                            value: _hasLift,
                            iconCode: '',
                            iconFont: _iconFont,
                            onChanged: (v) => setState(() => _hasLift = v),
                          ),
                        ],
                      ],
                    ),
                    _FormSection(
                      iconCode: '',
                      iconFont: _iconFont,
                      title: l10n.tr('qualityAndCondition'),
                      children: [
                        _buildQualityConditionCard(
                          label: l10n.tr('kitchen'),
                          quality: _kitchenQuality,
                          condition: _kitchenCondition,
                          onQualityChanged: (v) =>
                              setState(() => _kitchenQuality = v),
                          onConditionChanged: (v) =>
                              setState(() => _kitchenCondition = v),
                          l10n: l10n,
                        ),
                        const SizedBox(height: 8),
                        _buildQualityConditionCard(
                          label: l10n.tr('bathroom'),
                          quality: _bathroomsQuality,
                          condition: _bathroomsCondition,
                          onQualityChanged: (v) =>
                              setState(() => _bathroomsQuality = v),
                          onConditionChanged: (v) =>
                              setState(() => _bathroomsCondition = v),
                          l10n: l10n,
                        ),
                        const SizedBox(height: 8),
                        _buildQualityConditionCard(
                          label: l10n.tr('floor'),
                          quality: _flooringQuality,
                          condition: _flooringCondition,
                          onQualityChanged: (v) =>
                              setState(() => _flooringQuality = v),
                          onConditionChanged: (v) =>
                              setState(() => _flooringCondition = v),
                          l10n: l10n,
                        ),
                        const SizedBox(height: 8),
                        _buildQualityConditionCard(
                          label: l10n.tr('window'),
                          quality: _windowsQuality,
                          condition: _windowsCondition,
                          onQualityChanged: (v) =>
                              setState(() => _windowsQuality = v),
                          onConditionChanged: (v) =>
                              setState(() => _windowsCondition = v),
                          l10n: l10n,
                        ),
                        if (!_isApartment) ...[
                          const SizedBox(height: 8),
                          _buildQualityConditionCard(
                            label: l10n.tr('masonry'),
                            quality: _masonryQuality,
                            condition: _masonryCondition,
                            onQualityChanged: (v) =>
                                setState(() => _masonryQuality = v),
                            onConditionChanged: (v) =>
                                setState(() => _masonryCondition = v),
                            l10n: l10n,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: AppColors.screenBackground,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        submitLabel.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSearchField(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _openAddressSearch,
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          decoration: _inputDecoration(
            l10n.tr('propertyAddress'),
            hint: l10n.tr('propertyAddress'),
          ).copyWith(
            suffixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '',
                style: TextStyle(
                  fontFamily: _iconFont,
                  fontSize: 20,
                  color: Color(0xFF808080),
                ),
              ),
            ),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          controller: TextEditingController(text: _propertyAddress),
          style: _inputTextStyle,
        ),
      ),
    );
  }

  Widget _buildCountryField(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: 'Austria',
      decoration: _inputDecoration(l10n.tr('country')).copyWith(
        fillColor: const Color(0xFFF0F0F0),
      ),
      items: const [
        DropdownMenuItem(
          value: 'Austria',
          child: Text('Austria',
              style: TextStyle(
                  fontFamily: 'Calibri', fontSize: 14, color: Color(0xFF808080))),
        ),
      ],
      onChanged: null,
      style: _inputTextStyle.copyWith(color: const Color(0xFF808080)),
    );
  }

  Widget _buildTitleField(AppLocalizations l10n) {
    return TextFormField(
      controller: _titleCtrl,
      maxLength: 200,
      decoration:
          _inputDecoration(l10n.tr('titleName'), hint: l10n.tr('enterTheNameOfquery')),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? l10n.tr('titleName') : null,
      style: _inputTextStyle,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool required,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      buildCounter: maxLength != null ? (_, {required currentLength, required isFocused, maxLength}) => null : null,
      decoration: _inputDecoration(label),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return label;
        if (maxLength != null && v != null && v.trim().length > maxLength) {
          return '$label: max $maxLength';
        }
        return null;
      },
      style: _inputTextStyle,
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required bool required,
    double? min,
    double? max,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
      decoration: _inputDecoration(label, hint: hint),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return label;
        if (v != null && v.trim().isNotEmpty) {
          final d = double.tryParse(v.replaceAll(',', ''));
          if (d == null) return label;
          if (min != null && d < min) return '$label: min $min';
          if (max != null && d > max) return '$label: max $max';
        }
        return null;
      },
      style: _inputTextStyle,
    );
  }

  Widget _buildPropertyTypeDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _propertyTypeCode,
      dropdownColor: Colors.white,
      decoration: _inputDecoration(l10n.tr('propertyType')),
      items: [
        DropdownMenuItem(
            value: 'HOUSE',
            child: Text(l10n.tr('house'), style: _inputTextStyle)),
        DropdownMenuItem(
            value: 'APARTMENT',
            child: Text(l10n.tr('apartment'), style: _inputTextStyle)),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _propertyTypeCode = v);
      },
      validator: (v) =>
          (v == null || v.isEmpty) ? l10n.tr('propertyType') : null,
      style: _inputTextStyle,
    );
  }

  Widget _buildDealTypeRadio(AppLocalizations l10n) {
    final label = widget.source == PropertyListSource.observation
        ? l10n.tr('reasonToObserve')
        : l10n.tr('dealType');
    return FormField<String>(
      initialValue: _dealType,
      validator: (v) => (v == null || v.isEmpty) ? label : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label *',
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 13,
              color: Color(0xFF808080),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RadioBox(
                  label: l10n.tr('sellProperty'),
                  value: 'sale',
                  groupValue: _dealType,
                  onChanged: (v) {
                    setState(() => _dealType = v!);
                    field.didChange(v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RadioBox(
                  label: l10n.tr('rentProperty'),
                  value: 'rent',
                  groupValue: _dealType,
                  onChanged: (v) {
                    setState(() => _dealType = v!);
                    field.didChange(v);
                  },
                ),
              ),
            ],
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                field.errorText!,
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 12,
                  color: Color(0xFFD82034),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildYearDropdown(AppLocalizations l10n) {
    final currentYear = DateTime.now().year;
    final years =
        List.generate(currentYear + 3 - 1850 + 1, (i) => currentYear + 3 - i);
    return DropdownButtonFormField<int>(
      initialValue: _buildingYear,
      dropdownColor: Colors.white,
      decoration: _inputDecoration(l10n.tr('buildingYear')),
      icon: const Text(
        '',
        style: TextStyle(
          fontFamily: _iconFont,
          fontSize: 20,
          color: Color(0xFF808080),
        ),
      ),
      items: years
          .map((y) => DropdownMenuItem(
              value: y,
              child: Text(y.toString(), style: _inputTextStyle)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _buildingYear = v);
      },
      validator: (v) => v == null ? l10n.tr('buildingYear') : null,
      style: _inputTextStyle,
    );
  }

  Widget _buildIntDropdown({
    required String label,
    required int? value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
    required bool required,
    String? hint,
    String? prefixIconCode,
    String prefixIconFont = _iconFont,
  }) {
    final decoration = prefixIconCode != null
        ? _inputDecoration(label, hint: hint).copyWith(
            prefixIcon: Center(
              widthFactor: 1.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  prefixIconCode,
                  style: TextStyle(
                    fontFamily: prefixIconFont,
                    fontSize: 24,
                    color: const Color(0xFF808080),
                  ),
                ),
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 48, minHeight: 48),
          )
        : _inputDecoration(label, hint: hint);

    return DropdownButtonFormField<int>(
      initialValue: value,
      dropdownColor: Colors.white,
      decoration: decoration,
      hint: Text(label, style: _inputTextStyle),
      items: items
          .map((v) => DropdownMenuItem(
              value: v,
              child: Text(v.toString(), style: _inputTextStyle)))
          .toList(),
      onChanged: onChanged,
      validator: required ? (v) => v == null ? label : null : null,
      style: _inputTextStyle,
    );
  }

  Widget _buildFeatureCheckbox({
    required String label,
    required bool value,
    required String iconCode,
    required String iconFont,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD0D0D0)),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(
                  color: value ? AppColors.primaryRed : const Color(0xFFB4B4B4),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
                color: value ? AppColors.primaryRed : Colors.white,
              ),
              child: value
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              iconCode,
              style: TextStyle(
                fontFamily: iconFont,
                fontSize: 22,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: _inputTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityConditionCard({
    required String label,
    required int quality,
    required int condition,
    required ValueChanged<int> onQualityChanged,
    required ValueChanged<int> onConditionChanged,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StarRating(value: quality, max: 4, onChanged: onQualityChanged),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quality > 0
                      ? _qualityLabel(quality, l10n)
                      : l10n.tr('rateQuality'),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 13,
                    color: Color(0xFF808080),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _StarRating(
                  value: condition, max: 3, onChanged: onConditionChanged),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  condition > 0
                      ? _conditionLabel(condition, l10n)
                      : l10n.tr('rateCondition'),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 13,
                    color: Color(0xFF808080),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _qualityLabel(int v, AppLocalizations l10n) {
    switch (v) {
      case 1:
        return l10n.tr('simple');
      case 2:
        return l10n.tr('normal');
      case 3:
        return l10n.tr('highQuality');
      case 4:
        return l10n.tr('luxury');
      default:
        return '';
    }
  }

  static String _conditionLabel(int v, AppLocalizations l10n) {
    switch (v) {
      case 1:
        return l10n.tr('renovationNeeded');
      case 2:
        return l10n.tr('wellMaintained');
      case 3:
        return l10n.tr('recentlyRenovated');
      default:
        return '';
    }
  }

  static InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
          fontFamily: 'Calibri', fontSize: 14, color: Color(0xFF808080)),
      hintStyle: const TextStyle(
          fontFamily: 'Calibri', fontSize: 13, color: Color(0xFFB4B4B4)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.primaryRed),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD82034)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD82034)),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    );
  }

  static String _toLanguageValue(String code) {
    const map = {'en': 'en-US', 'de': 'de-DE', 'cz': 'cs-CZ', 'sk': 'sk-SK'};
    return map[code] ?? 'en-US';
  }

  static const TextStyle _inputTextStyle = TextStyle(
    fontFamily: 'Calibri',
    fontSize: 14,
    color: Color(0xFF333333),
  );
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.close, size: 20, color: Color(0xFF6C6C6C)),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.iconCode,
    required this.iconFont,
    required this.title,
    required this.children,
  });

  final String iconCode;
  final String iconFont;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                iconCode,
                style: TextStyle(
                  fontFamily: iconFont,
                  fontSize: 20,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _RadioBox extends StatelessWidget {
  const _RadioBox({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD0D0D0)),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.primaryRed
                      : const Color(0xFFD0D0D0),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final filled = i < value;
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              filled ? Icons.star : Icons.star_border,
              color: filled ? const Color(0xFFC45417) : const Color(0xFFDADADA),
              size: 22,
            ),
          ),
        );
      }),
    );
  }
}
