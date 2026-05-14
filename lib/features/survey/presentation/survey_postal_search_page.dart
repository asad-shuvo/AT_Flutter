import 'dart:async';

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/survey/data/survey_address_repository.dart';
import 'package:filip_at_flutter/features/survey/presentation/widgets/survey_styles.dart';
import 'package:flutter/material.dart';

const int _kPageSize = 10;

class SurveyPostalSearchPage extends StatefulWidget {
  const SurveyPostalSearchPage({
    super.key,
    required this.addressRepository,
  });

  final SurveyAddressRepository addressRepository;

  @override
  State<SurveyPostalSearchPage> createState() => _SurveyPostalSearchPageState();
}

class _SurveyPostalSearchPageState extends State<SurveyPostalSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<PostalSuggestion> _suggestions = const <PostalSuggestion>[];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _currentPage = 0;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    _controller.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _suggestions = const <PostalSuggestion>[];
        _hasMore = false;
        _currentPage = 0;
        _lastQuery = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(text));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  Future<void> _search(String query) async {
    if (query == _lastQuery && _currentPage == 0 && _suggestions.isNotEmpty) return;
    setState(() {
      _loading = true;
      _suggestions = const <PostalSuggestion>[];
      _currentPage = 0;
      _hasMore = false;
      _lastQuery = query;
    });

    final results = await widget.addressRepository.fetchPostalSuggestions(
      query,
      pageNumber: 0,
    );
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _hasMore = results.length >= _kPageSize;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading || _lastQuery.isEmpty) return;
    setState(() => _loadingMore = true);

    final nextPage = _currentPage + 1;
    final results = await widget.addressRepository.fetchPostalSuggestions(
      _lastQuery,
      pageNumber: nextPage,
    );
    if (!mounted) return;
    setState(() {
      _currentPage = nextPage;
      _suggestions = [..._suggestions, ...results];
      _hasMore = results.length >= _kPageSize;
      _loadingMore = false;
    });
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
          l10n.tr('postalZipCode'),
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
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                color: Color(0xFF333333),
              ),
              decoration: InputDecoration(
                hintText: l10n.tr('postalZipCode'),
                hintStyle: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 16,
                  color: Color(0xFFA7A7A7),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFFB23A4D),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFFB23A4D),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: CircularProgressIndicator(color: Color(0xFFB23A4D)),
            )
          else
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                itemCount: _suggestions.length + (_loadingMore ? 1 : 0),
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (_, index) {
                  if (index == _suggestions.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFFB23A4D),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    );
                  }
                  final item = _suggestions[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Text(
                        item.description,
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
    );
  }
}
