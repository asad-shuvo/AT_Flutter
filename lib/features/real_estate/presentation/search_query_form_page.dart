import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/real_estate/data/place_address_result.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/features/real_estate/data/search_query_form_data.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/property_address_search_page.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/search_map_card.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _iconFont = 'filip_at_iconpack_29022024';
const _snIconFont = 'SelectNetwork';

class SearchQueryFormPage extends StatefulWidget {
  const SearchQueryFormPage({
    super.key,
    required this.repository,
    this.initialData,
    this.onSaved,
  });

  final RealEstateRepository repository;
  final SearchQueryFormData? initialData;
  final VoidCallback? onSaved;

  @override
  State<SearchQueryFormPage> createState() => _SearchQueryFormPageState();
}

class _SearchQueryFormPageState extends State<SearchQueryFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _advancedExpanded = false;
  double? _lat;
  double? _lng;

  final _postCodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _minLivingAreaCtrl = TextEditingController(text: '10');
  final _maxLivingAreaCtrl = TextEditingController(text: '800');
  final _minRoomsCtrl = TextEditingController(text: '1');
  final _maxRoomsCtrl = TextEditingController(text: '20');
  final _minBuildingYearCtrl = TextEditingController(text: '1850');
  final _maxBuildingYearCtrl = TextEditingController(text: '2028');
  final _hospitalDistCtrl = TextEditingController();
  final _groceryDistCtrl = TextEditingController();
  final _transitDistCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();

  String _locationDisplay = '';
  String _dealType = '';
  String? _propertyTypeCode;
  bool? _isWheelchairAccessible;
  bool? _hasLift;
  bool? _hasParkingSpaces;

  bool get _isApartment => _propertyTypeCode?.toLowerCase() == 'apartment';
  bool get _isEditMode => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    if (d == null) return;
    _postCodeCtrl.text = d.postCode;
    _cityCtrl.text = d.city;
    _radiusCtrl.text = d.radiusKm > 0 ? d.radiusKm.toStringAsFixed(0) : '1';
    _titleCtrl.text = d.title;
    _minLivingAreaCtrl.text = d.minLivingArea.toStringAsFixed(0);
    _maxLivingAreaCtrl.text = d.maxLivingArea.toStringAsFixed(0);
    _minRoomsCtrl.text = d.minRooms.toString();
    _maxRoomsCtrl.text = d.maxRooms.toString();
    _minBuildingYearCtrl.text = d.minBuildingYear.toString();
    _maxBuildingYearCtrl.text = d.maxBuildingYear.toString();
    if (d.maxDistanceHospital != null) _hospitalDistCtrl.text = d.maxDistanceHospital.toString();
    if (d.maxDistanceGroceryStore != null) _groceryDistCtrl.text = d.maxDistanceGroceryStore.toString();
    if (d.maxDistancePublicTransport != null) _transitDistCtrl.text = d.maxDistancePublicTransport.toString();
    _dealType = d.dealType;
    _propertyTypeCode = d.propertyTypeCode?.toLowerCase();
    _isWheelchairAccessible = d.isWheelchairAccessible;
    _hasLift = d.hasLift;
    _hasParkingSpaces = d.hasParkingSpaces;
    _locationDisplay = [d.postCode, d.city].where((s) => s.isNotEmpty).join(', ');
    _lat = d.lat;
    _lng = d.lng;
    final isSale = d.dealType.toLowerCase() == 'sale';
    if (isSale) {
      if (d.minSalePrice != null) _minPriceCtrl.text = d.minSalePrice.toString();
      if (d.maxSalePrice != null) _maxPriceCtrl.text = d.maxSalePrice.toString();
    } else {
      if (d.minRentGross != null) _minPriceCtrl.text = d.minRentGross.toString();
      if (d.maxRentGross != null) _maxPriceCtrl.text = d.maxRentGross.toString();
    }
    if (_lat == null || _lng == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _geocodeLocation());
    }
  }

  Future<void> _geocodeLocation() async {
    final addr = [_postCodeCtrl.text, _cityCtrl.text]
        .where((s) => s.isNotEmpty)
        .join(' ');
    if (addr.isEmpty) return;
    final coords = await widget.repository.fetchGeocode(addr);
    if (!mounted) return;
    setState(() {
      _lat = coords.lat;
      _lng = coords.lng;
    });
  }


  Future<void> _openAddressSearch() async {
    final result = await Navigator.of(context).push<PlaceAddressResult>(
      MaterialPageRoute(
        builder: (_) => PropertyAddressSearchPage(
          repository: widget.repository,
          initialValue: _locationDisplay,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _locationDisplay = [result.street, result.houseNumber, result.postCode, result.city]
            .where((s) => s.isNotEmpty)
            .join(', ');
        _postCodeCtrl.text = result.postCode;
        _cityCtrl.text = result.city;
        _lat = result.lat;
        _lng = result.lng;
      });
    }
  }

  @override
  void dispose() {
    _postCodeCtrl.dispose();
    _cityCtrl.dispose();
    _radiusCtrl.dispose();
    _titleCtrl.dispose();
    _minLivingAreaCtrl.dispose();
    _maxLivingAreaCtrl.dispose();
    _minRoomsCtrl.dispose();
    _maxRoomsCtrl.dispose();
    _minBuildingYearCtrl.dispose();
    _maxBuildingYearCtrl.dispose();
    _hospitalDistCtrl.dispose();
    _groceryDistCtrl.dispose();
    _transitDistCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dealType.isEmpty || _propertyTypeCode == null) return;

    final personId = await widget.repository.getPersonId();
    if (personId == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final isSale = _dealType.toLowerCase() == 'sale';
      final params = (
        personId: personId,
        title: _titleCtrl.text.trim(),
        postCode: _postCodeCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        radiusKm: double.tryParse(_radiusCtrl.text) ?? 1,
        dealType: _dealType,
        propertyTypeCode: _propertyTypeCode!,
        minLivingArea: double.tryParse(_minLivingAreaCtrl.text) ?? 10,
        maxLivingArea: double.tryParse(_maxLivingAreaCtrl.text) ?? 800,
        minRooms: int.tryParse(_minRoomsCtrl.text) ?? 1,
        maxRooms: int.tryParse(_maxRoomsCtrl.text) ?? 20,
        minBuildingYear: int.tryParse(_minBuildingYearCtrl.text) ?? 1850,
        maxBuildingYear: int.tryParse(_maxBuildingYearCtrl.text) ?? 2028,
        isWheelchairAccessible: _isWheelchairAccessible ?? false,
        maxDistanceHospital: _hospitalDistCtrl.text.isNotEmpty ? int.tryParse(_hospitalDistCtrl.text) : null,
        maxDistanceGroceryStore: _groceryDistCtrl.text.isNotEmpty ? int.tryParse(_groceryDistCtrl.text) : null,
        maxDistancePublicTransport: _transitDistCtrl.text.isNotEmpty ? int.tryParse(_transitDistCtrl.text) : null,
        hasLift: _isApartment ? _hasLift : null,
        hasParkingSpaces: !_isApartment ? _hasParkingSpaces : null,
        minSalePrice: isSale && _minPriceCtrl.text.isNotEmpty ? int.tryParse(_minPriceCtrl.text.replaceAll(',', '')) : null,
        maxSalePrice: isSale && _maxPriceCtrl.text.isNotEmpty ? int.tryParse(_maxPriceCtrl.text.replaceAll(',', '')) : null,
        minRentGross: !isSale && _minPriceCtrl.text.isNotEmpty ? int.tryParse(_minPriceCtrl.text.replaceAll(',', '')) : null,
        maxRentGross: !isSale && _maxPriceCtrl.text.isNotEmpty ? int.tryParse(_maxPriceCtrl.text.replaceAll(',', '')) : null,
      );
      if (_isEditMode) {
        await widget.repository.updateSearchQuery(
          itemId: widget.initialData!.itemId,
          personId: params.personId,
          title: params.title,
          postCode: params.postCode,
          city: params.city,
          radiusKm: params.radiusKm,
          dealType: params.dealType,
          propertyTypeCode: params.propertyTypeCode,
          minLivingArea: params.minLivingArea,
          maxLivingArea: params.maxLivingArea,
          minRooms: params.minRooms,
          maxRooms: params.maxRooms,
          minBuildingYear: params.minBuildingYear,
          maxBuildingYear: params.maxBuildingYear,
          isWheelchairAccessible: params.isWheelchairAccessible,
          maxDistanceHospital: params.maxDistanceHospital,
          maxDistanceGroceryStore: params.maxDistanceGroceryStore,
          maxDistancePublicTransport: params.maxDistancePublicTransport,
          hasLift: params.hasLift,
          hasParkingSpaces: params.hasParkingSpaces,
          minSalePrice: params.minSalePrice,
          maxSalePrice: params.maxSalePrice,
          minRentGross: params.minRentGross,
          maxRentGross: params.maxRentGross,
        );
      } else {
        await widget.repository.saveSearchQuery(
          personId: params.personId,
          title: params.title,
          postCode: params.postCode,
          city: params.city,
          radiusKm: params.radiusKm,
          dealType: params.dealType,
          propertyTypeCode: params.propertyTypeCode,
          minLivingArea: params.minLivingArea,
          maxLivingArea: params.maxLivingArea,
          minRooms: params.minRooms,
          maxRooms: params.maxRooms,
          minBuildingYear: params.minBuildingYear,
          maxBuildingYear: params.maxBuildingYear,
          isWheelchairAccessible: params.isWheelchairAccessible,
          maxDistanceHospital: params.maxDistanceHospital,
          maxDistanceGroceryStore: params.maxDistanceGroceryStore,
          maxDistancePublicTransport: params.maxDistancePublicTransport,
          hasLift: params.hasLift,
          hasParkingSpaces: params.hasParkingSpaces,
          minSalePrice: params.minSalePrice,
          maxSalePrice: params.maxSalePrice,
          minRentGross: params.minRentGross,
          maxRentGross: params.maxRentGross,
        );
      }
      if (!mounted) return;
      widget.onSaved?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('searchPropertySuccessfullyAddedMsg'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('SOMETHING_WENT_WRONG'))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    _buildBasicInfoSection(l10n),
                    _buildPriceMeasurementSection(l10n),
                    _buildAdvancedSection(l10n),
                  ],
                ),
              ),
            ),
            _buildSearchButton(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF555555)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              l10n.tr(_isEditMode ? 'editSearch' : 'searchProperty'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(AppLocalizations l10n) {
    return _SqFormSection(
      iconCode: '',
      iconFont: _iconFont,
      title: l10n.tr('basicInformation'),
      children: [
        GestureDetector(
          onTap: _openAddressSearch,
          child: AbsorbPointer(
            child: TextFormField(
              readOnly: true,
              controller: TextEditingController(text: _locationDisplay),
              decoration: _inputDecoration('${l10n.tr('postalCodeAndCity')} *').copyWith(
                suffixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '',
                    style: TextStyle(fontFamily: _iconFont, fontSize: 20, color: Color(0xFF808080)),
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              validator: (_) => _locationDisplay.isEmpty ? l10n.tr('requiredField') : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        TextFormField(
          controller: _postCodeCtrl,
          readOnly: true,
          decoration: _inputDecoration('${l10n.tr('postCode')} *'),
          validator: (v) => (v == null || v.trim().isEmpty) ? l10n.tr('requiredField') : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cityCtrl,
          readOnly: true,
          decoration: _inputDecoration('${l10n.tr('city')} *'),
          validator: (v) => (v == null || v.trim().isEmpty) ? l10n.tr('requiredField') : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _radiusCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration('${l10n.tr('propertyRadius')} *').copyWith(
            suffixText: 'KM',
            suffixStyle: const TextStyle(fontFamily: 'Calibri', fontWeight: FontWeight.w600, color: Color(0xFF555555)),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l10n.tr('requiredField');
            final n = int.tryParse(v);
            if (n == null || n <= 0) return l10n.tr('invalidValue');
            return null;
          },
        ),
        const SizedBox(height: 8),
        _buildRadiusPresets(),
        const SizedBox(height: 12),
        _buildDealTypeRadio(l10n),
        FormField<String>(
          initialValue: _dealType,
          validator: (_) => _dealType.isEmpty ? l10n.tr('requiredField') : null,
          builder: (field) => field.hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(field.errorText!, style: const TextStyle(color: Color(0xFFD82034), fontSize: 12, fontFamily: 'Calibri')),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _propertyTypeCode,
          dropdownColor: Colors.white,
          decoration: _inputDecoration('${l10n.tr('propertyType')} *'),
          items: [
            DropdownMenuItem(value: 'house', child: Text(l10n.tr('house'), style: _dropdownTextStyle)),
            DropdownMenuItem(value: 'apartment', child: Text(l10n.tr('apartment'), style: _dropdownTextStyle)),
          ],
          onChanged: (v) => setState(() => _propertyTypeCode = v),
          validator: (v) => v == null ? l10n.tr('requiredField') : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleCtrl,
          decoration: _inputDecoration('${l10n.tr('nameOfQuery')} *'),
          validator: (v) => (v == null || v.trim().isEmpty) ? l10n.tr('requiredField') : null,
        ),
        const SizedBox(height: 12),
        SearchMapCard(
          lat: _lat,
          lng: _lng,
          radiusKm: double.tryParse(_radiusCtrl.text) ?? 1,
        ),
      ],
    );
  }

  Widget _buildPriceMeasurementSection(AppLocalizations l10n) {
    return _SqFormSection(
      iconCode: '',
      iconFont: _iconFont,
      title: l10n.tr('propertyPriceAndMeasurement'),
      children: [
        _buildRangeCard(
          iconCode: '',
          iconFont: _snIconFont,
          label: l10n.tr('estimatedLivingArea').toUpperCase(),
          minCtrl: _minLivingAreaCtrl,
          maxCtrl: _maxLivingAreaCtrl,
          minLabel: l10n.tr('minLivingArea'),
          maxLabel: l10n.tr('maxLivingArea'),
          hint: '${l10n.tr('optional')}; Upto 800 m²',
          onReset: () => setState(() {
            _minLivingAreaCtrl.text = '10';
            _maxLivingAreaCtrl.text = '800';
          }),
        ),
        const SizedBox(height: 12),
        _buildRangeCard(
          iconCode: '',
          iconFont: _iconFont,
          label: l10n.tr('selecteNoOfRooms').toUpperCase(),
          minCtrl: _minRoomsCtrl,
          maxCtrl: _maxRoomsCtrl,
          minLabel: l10n.tr('minRoom'),
          maxLabel: l10n.tr('maxRoom'),
          hint: '${l10n.tr('optional')}; e.g 1, 2, 5 etc',
          onReset: () => setState(() {
            _minRoomsCtrl.text = '1';
            _maxRoomsCtrl.text = '20';
          }),
        ),
        if (_dealType.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildPriceCard(l10n),
        ],
      ],
    );
  }

  Widget _buildAdvancedSection(AppLocalizations l10n) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _advancedExpanded = !_advancedExpanded),
          child: Container(
            color: const Color(0xFFFFF3F0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.tr('advanceSearchFilterOptional').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(
                  _advancedExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.primaryRed,
                ),
              ],
            ),
          ),
        ),
        if (_advancedExpanded) ...[
          _SqFormSection(
            iconCode: '',
            iconFont: _iconFont,
            title: l10n.tr('additionalFeatures'),
            children: [
              _buildRangeCard(
                iconCode: '',
                iconFont: _iconFont,
                label: l10n.tr('filterOnBuildingYear').toUpperCase(),
                minCtrl: _minBuildingYearCtrl,
                maxCtrl: _maxBuildingYearCtrl,
                minLabel: l10n.tr('buildingYearFrom'),
                maxLabel: l10n.tr('buildingYearTo'),
                hint: '${l10n.tr('optional')}; Upto 2028',
                onReset: () => setState(() {
                  _minBuildingYearCtrl.text = '1850';
                  _maxBuildingYearCtrl.text = '2028';
                }),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.tr('filterByAmenitiesAtTheProperty'),
                style: const TextStyle(fontFamily: 'Calibri', fontSize: 14, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 8),
              _buildBoolDropdown(
                iconCode: '',
                iconFont: _snIconFont,
                value: _isWheelchairAccessible,
                onChanged: (v) => setState(() => _isWheelchairAccessible = v),
                l10n: l10n,
                label: l10n.tr('wheelchairAccessible'),
              ),
              if (_propertyTypeCode != null) ...[
                const SizedBox(height: 12),
                if (_isApartment)
                  _buildBoolDropdown(
                    iconCode: '',
                    iconFont: _snIconFont,
                    value: _hasLift,
                    onChanged: (v) => setState(() => _hasLift = v),
                    l10n: l10n,
                    label: l10n.tr('lift'),
                  )
                else
                  _buildBoolDropdown(
                    iconCode: '',
                    iconFont: _snIconFont,
                    value: _hasParkingSpaces,
                    onChanged: (v) => setState(() => _hasParkingSpaces = v),
                    l10n: l10n,
                    label: l10n.tr('ParkingLot'),
                  ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.tr('filterByAmenitiesAtTheProperty'),
                style: const TextStyle(fontFamily: 'Calibri', fontSize: 14, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 8),
              _buildDistanceField(
                label: l10n.tr('hospitalWithMaxRange'),
                controller: _hospitalDistCtrl,
                hint: l10n.tr('anyDistance'),
              ),
              const SizedBox(height: 12),
              _buildDistanceField(
                label: l10n.tr('groceryStoreWithMaxRange'),
                controller: _groceryDistCtrl,
                hint: l10n.tr('anyDistance'),
              ),
              const SizedBox(height: 12),
              _buildDistanceField(
                label: l10n.tr('publicTransportWithMaxRange'),
                controller: _transitDistCtrl,
                hint: l10n.tr('anyDistance'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDealTypeRadio(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.tr('propertyLookingFor')} *',
          style: const TextStyle(fontFamily: 'Calibri', fontSize: 13, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _DealTypeOption(label: l10n.tr('buy'), value: 'sale', groupValue: _dealType, onChanged: (v) => setState(() => _dealType = v))),
            const SizedBox(width: 12),
            Expanded(child: _DealTypeOption(label: l10n.tr('rent'), value: 'rent', groupValue: _dealType, onChanged: (v) => setState(() => _dealType = v))),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceCard(AppLocalizations l10n) {
    final isSale = _dealType.toLowerCase() == 'sale';
    final label = isSale ? l10n.tr('salePrice') : l10n.tr('rentGross');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Calibri', fontSize: 13, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(l10n.tr('minPrice')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _maxPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(l10n.tr('maxPrice')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeCard({
    required String iconCode,
    required String iconFont,
    required String label,
    required TextEditingController minCtrl,
    required TextEditingController maxCtrl,
    required String minLabel,
    required String maxLabel,
    required String hint,
    required VoidCallback onReset,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(iconCode, style: TextStyle(fontFamily: iconFont, fontSize: 20, color: const Color(0xFF808080))),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: const TextStyle(fontFamily: 'Calibri', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
              ),
              GestureDetector(
                onTap: onReset,
                child: const Icon(Icons.refresh, color: AppColors.primaryRed, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(minLabel, style: const TextStyle(fontFamily: 'Calibri', fontSize: 12, color: Color(0xFF888888))),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _rangeInputDecoration(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(maxLabel, style: const TextStyle(fontFamily: 'Calibri', fontSize: 12, color: Color(0xFF888888))),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _rangeInputDecoration(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(hint, style: const TextStyle(fontFamily: 'Calibri', fontSize: 11, color: Color(0xFF888888))),
        ],
      ),
    );
  }

  Widget _buildBoolDropdown({
    required String iconCode,
    required String iconFont,
    required bool? value,
    required void Function(bool?) onChanged,
    required AppLocalizations l10n,
    String? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              if (iconCode.isNotEmpty)
                Text(iconCode, style: TextStyle(fontFamily: iconFont, fontSize: 18, color: const Color(0xFF808080))),
              if (iconCode.isNotEmpty) const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontFamily: 'Calibri', fontSize: 13, color: Color(0xFF555555))),
            ],
          ),
          const SizedBox(height: 6),
        ],
        DropdownButtonFormField<bool?>(
          initialValue: value,
          dropdownColor: Colors.white,
          decoration: _inputDecoration(''),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.tr('doesNotMatter'), style: _dropdownTextStyle)),
            DropdownMenuItem(value: true, child: Text(l10n.tr('yes'), style: _dropdownTextStyle)),
            DropdownMenuItem(value: false, child: Text(l10n.tr('no'), style: _dropdownTextStyle)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDistanceField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _inputDecoration(label).copyWith(
        suffixText: 'M',
        suffixStyle: const TextStyle(fontFamily: 'Calibri', fontWeight: FontWeight.w600, color: Color(0xFF555555)),
      ),
    );
  }

  Widget _buildSearchButton(AppLocalizations l10n) {
    return Container(
      color: AppColors.screenBackground,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Text(
                l10n.tr('search').toUpperCase(),
                style: const TextStyle(fontFamily: 'Calibri', fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
    );
  }

  static const _dropdownTextStyle = TextStyle(fontFamily: 'Calibri', fontSize: 14);

  static InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontFamily: 'Calibri', fontSize: 14, color: Color(0xFF808080)),
      hintStyle: const TextStyle(fontFamily: 'Calibri', fontSize: 13, color: Color(0xFFB4B4B4)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD0D0D0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD0D0D0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.primaryRed)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD82034))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD82034))),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    );
  }

  Widget _buildRadiusPresets() {
    const presets = [1, 3, 5, 10, 15, 20];
    final current = int.tryParse(_radiusCtrl.text) ?? 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((km) {
          final selected = current == km;
          return GestureDetector(
            onTap: () => setState(() => _radiusCtrl.text = km.toString()),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryRed : Colors.white,
                border: Border.all(
                  color: selected ? AppColors.primaryRed : const Color(0xFFCCCCCC),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$km km',
                style: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF666666),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static InputDecoration _rangeInputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD0D0D0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD0D0D0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.primaryRed)),
      isDense: true,
    );
  }
}


class _SqFormSection extends StatelessWidget {
  const _SqFormSection({required this.iconCode, required this.iconFont, required this.title, required this.children});

  final String iconCode;
  final String iconFont;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(iconCode, style: TextStyle(fontFamily: iconFont, fontSize: 24, color: AppColors.primaryRed)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontFamily: 'Calibri', fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DealTypeOption extends StatelessWidget {
  const _DealTypeOption({required this.label, required this.value, required this.groupValue, required this.onChanged});

  final String label;
  final String value;
  final String groupValue;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: selected ? AppColors.primaryRed : const Color(0xFFCCCCCC)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.primaryRed : const Color(0xFFAAAAAA), width: 1.5),
              ),
              child: selected
                  ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle)))
                  : null,
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontFamily: 'Calibri', fontSize: 14, color: Color(0xFF333333))),
          ],
        ),
      ),
    );
  }
}

