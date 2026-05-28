import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchMapCard extends StatefulWidget {
  const SearchMapCard({
    super.key,
    this.lat,
    this.lng,
    required this.radiusKm,
  });

  final double? lat;
  final double? lng;
  final double radiusKm;

  @override
  State<SearchMapCard> createState() => _SearchMapCardState();
}

class _SearchMapCardState extends State<SearchMapCard> {
  GoogleMapController? _controller;

  static const _austria = LatLng(47.516231, 14.550072);

  LatLng get _center => widget.lat != null && widget.lng != null
      ? LatLng(widget.lat!, widget.lng!)
      : _austria;

  bool get _hasLocation => widget.lat != null && widget.lng != null;

  @override
  void didUpdateWidget(covariant SearchMapCard old) {
    super.didUpdateWidget(old);
    if (widget.lat != old.lat ||
        widget.lng != old.lng ||
        widget.radiusKm != old.radiusKm) {
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(_center, _zoom(widget.radiusKm)),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  static double _zoom(double km) {
    if (km <= 1) return 13.0;
    if (km <= 3) return 11.5;
    if (km <= 5) return 10.5;
    if (km <= 10) return 9.5;
    if (km <= 15) return 9.0;
    return 8.5;
  }

  @override
  Widget build(BuildContext context) {
    final center = _center;
    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: _zoom(widget.radiusKm),
        ),
        markers: _hasLocation
            ? {Marker(markerId: const MarkerId('loc'), position: center)}
            : {},
        circles: _hasLocation
            ? {
                Circle(
                  circleId: const CircleId('radius'),
                  center: center,
                  radius: widget.radiusKm * 1000,
                  fillColor: Color.fromARGB(60, 120, 220, 60),
                  strokeColor: const Color(0xFFFF0000),
                  strokeWidth: 2,
                ),
              }
            : {},
        myLocationEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (ctrl) => setState(() => _controller = ctrl),
      ),
    );
  }
}
