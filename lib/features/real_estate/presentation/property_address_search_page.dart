import 'dart:async';

import 'package:filip_at_flutter/features/real_estate/data/place_address_result.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PropertyAddressSearchPage extends StatefulWidget {
  const PropertyAddressSearchPage({
    super.key,
    required this.repository,
    this.initialValue = '',
  });

  final RealEstateRepository repository;
  final String initialValue;

  @override
  State<PropertyAddressSearchPage> createState() =>
      _PropertyAddressSearchPageState();
}

class _PropertyAddressSearchPageState
    extends State<PropertyAddressSearchPage> {
  late final TextEditingController _ctrl;
  Timer? _debounce;
  List<Map<String, String>> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _search(value.trim()),
    );
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final results = await widget.repository.fetchPlaces(query);
      if (mounted) setState(() { _suggestions = results; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onTap(Map<String, String> item) async {
    setState(() { _loading = true; _suggestions = []; });
    try {
      final result = await widget.repository.fetchPlaceDetails(item['placeId']!);
      if (!mounted) return;
      Navigator.of(context).pop(
        result ?? PlaceAddressResult(displayAddress: item['description'] ?? ''),
      );
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop(
          PlaceAddressResult(displayAddress: item['description'] ?? ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEEEEE),
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Color(0xFF333333)),
        ),
        title: const Text(
          'Property Address',
          style: TextStyle(
            fontFamily: 'Calibri',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'Property Address',
                hintStyle: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 14,
                  color: Color(0xFFB4B4B4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(color: AppColors.primaryRed),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(color: AppColors.primaryRed),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                isDense: true,
              ),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ),
          if (_loading)
            const LinearProgressIndicator(
              color: AppColors.primaryRed,
              minHeight: 2,
              backgroundColor: Color(0xFFFFF0F0),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (_, i) {
                final s = _suggestions[i];
                return InkWell(
                  onTap: () => _onTap(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Text(
                      s['description'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
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
    );
  }
}
