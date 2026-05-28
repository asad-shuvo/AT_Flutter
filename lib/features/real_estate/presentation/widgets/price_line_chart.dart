import 'dart:math' as math;

import 'package:filip_at_flutter/features/real_estate/data/property_valuation_entry.dart';
import 'package:flutter/material.dart';

class PriceLineChart extends StatelessWidget {
  const PriceLineChart({
    super.key,
    required this.entries,
    required this.isRent,
    required this.isValuation,
  });

  final List<PropertyValuationEntry> entries;
  final bool isRent;
  final bool isValuation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasData = entries.any((e) {
      if (isValuation) {
        final r = isRent ? e.rentGrossRange : e.salePriceRange;
        return r != null;
      }
      final p = isRent ? e.rentGross : e.salePrice;
      return p != null && p > 0;
    });

    if (!hasData) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            'No chart data available',
            style: TextStyle(
              fontFamily: 'Calibri',
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: CustomPaint(
        painter: _LineChartPainter(
          entries: entries,
          isRent: isRent,
          isValuation: isValuation,
          primaryColor: scheme.primary,
          secondaryColor: scheme.secondary,
          gridColor: scheme.outlineVariant,
          labelColor: scheme.onSurfaceVariant,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.entries,
    required this.isRent,
    required this.isValuation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<PropertyValuationEntry> entries;
  final bool isRent;
  final bool isValuation;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;
  final Color labelColor;

  double? _mainPrice(PropertyValuationEntry e) =>
      isRent ? e.rentGross : e.salePrice;
  double? _lower(PropertyValuationEntry e) =>
      isRent ? e.rentGrossRange?.lower : e.salePriceRange?.lower;
  double? _upper(PropertyValuationEntry e) =>
      isRent ? e.rentGrossRange?.upper : e.salePriceRange?.upper;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final allVals = <double>[];
    for (final e in entries) {
      if (isValuation) {
        final l = _lower(e);
        final u = _upper(e);
        if (l != null && l > 0) allVals.add(l);
        if (u != null && u > 0) allVals.add(u);
      } else {
        final p = _mainPrice(e);
        if (p != null && p > 0) allVals.add(p);
      }
    }
    if (allVals.isEmpty) return;

    var minV = allVals.reduce(math.min);
    var maxV = allVals.reduce(math.max);
    if (maxV - minV < 1) {
      minV -= 1;
      maxV += 1;
    }
    final pad = (maxV - minV) * 0.1;
    minV -= pad;
    maxV += pad;

    const lm = 58.0, rm = 12.0, tm = 12.0, bm = 36.0;
    final cw = size.width - lm - rm;
    final ch = size.height - tm - bm;

    double toY(double v) => tm + ch * (1.0 - (v - minV) / (maxV - minV));
    double toX(int i) {
      final n = entries.length - 1;
      return n <= 0 ? lm : lm + cw * i / n;
    }

    final gridP = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final lStyle = TextStyle(
      fontFamily: 'Calibri',
      fontSize: 9,
      color: labelColor,
    );
    for (int i = 0; i <= 4; i++) {
      final y = tm + ch * i / 4;
      canvas.drawLine(Offset(lm, y), Offset(lm + cw, y), gridP);
      final val = maxV - (maxV - minV) * i / 4;
      final tp = TextPainter(
        text: TextSpan(text: _fmtAxis(val), style: lStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: lm - 4);
      tp.paint(canvas, Offset(lm - tp.width - 4, y - tp.height / 2));
    }

    const mo = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    for (int i = 0; i < entries.length; i++) {
      if (i % 2 != 0) continue;
      final d = entries[i].valuationDate;
      if (d.length < 7) continue;
      final mn = int.tryParse(d.substring(5, 7));
      if (mn == null || mn < 1 || mn > 12) continue;
      final label = '${mo[mn - 1]} ${d.substring(2, 4)}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: lStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(toX(i), size.height - bm + 6);
      canvas.rotate(-math.pi / 6);
      tp.paint(canvas, Offset(-tp.width / 2, 0));
      canvas.restore();
    }

    if (isValuation) {
      _drawLine(canvas, entries, toX, toY, _upper, const Color(0xFF6D1874));
      _drawLine(canvas, entries, toX, toY, _lower, secondaryColor);
    } else {
      _drawLine(canvas, entries, toX, toY, _mainPrice, primaryColor);
    }

    if (entries.length > 5) {
      final ce = entries[5];
      final cp = isValuation
          ? ((_upper(ce) ?? 0) + (_lower(ce) ?? 0)) / 2
          : _mainPrice(ce);
      if (cp != null && cp > 0) {
        final cx = toX(5);
        final cy = toY(cp);
        final dc = isValuation ? const Color(0xFF6D1874) : primaryColor;
        canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = dc);
        canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = Colors.white);
      }
    }
  }

  void _drawLine(
    Canvas canvas,
    List<PropertyValuationEntry> es,
    double Function(int) toX,
    double Function(double) toY,
    double? Function(PropertyValuationEntry) getP,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    bool started = false;
    for (int i = 0; i < es.length; i++) {
      final p = getP(es[i]);
      if (p == null || p == 0) continue;
      if (!started) {
        path.moveTo(toX(i), toY(p));
        started = true;
      } else {
        path.lineTo(toX(i), toY(p));
      }
    }
    if (started) canvas.drawPath(path, paint);
  }

  String _fmtAxis(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.entries != entries ||
      old.isValuation != isValuation ||
      old.isRent != isRent;
}
