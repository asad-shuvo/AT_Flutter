class SqlQueryBuilder {
  const SqlQueryBuilder._();

  static const _opMap = {
    '=': '__eql',
    '>': '__gt',
    '>=': '__gte',
    '<': '__lt',
    '<=': '__lte',
    '!=': '__ne',
    'contains': '__in',
    '!contains': '__nin',
    'range': '__inc',
    'search': '__reg',
    '|': '__or',
    '&': '__and',
  };

  static String _expr(String property, String operator, dynamic value) {
    final op = _opMap[operator] ?? '__eql';
    final val = value is List ? value.join(',') : value.toString();
    return '$property=$op($val)';
  }

  static String _filters(List<Map<String, dynamic>> filters) {
    return filters
        .where((f) {
          final v = f['value'];
          if (v == null || v == '') return false;
          if (v is List) return v.isNotEmpty;
          return true;
        })
        .map((f) => _expr(f['property'] as String, f['operator'] as String, f['value']))
        .join(' & ');
  }

  static String prepareQuery({
    required String entity,
    required List<String> fields,
    required List<Map<String, dynamic>> filters,
    String? orderBy,
    required int pageNumber,
    required int pageSize,
  }) {
    final fieldStr = fields.join(',');
    var q = 'Select <$fieldStr>from<$entity>';

    final filterStr = _filters(filters);
    if (filterStr.isNotEmpty) q += 'where<$filterStr>';
    if (orderBy != null) q += 'Orderby<$orderBy>';

    q += 'pageNumber=<$pageNumber>pageSize= <$pageSize>';
    return q;
  }
}
