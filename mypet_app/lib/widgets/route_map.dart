import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/colors.dart';
import '../core/geo.dart';
import '../services/routing_service.dart';

/// Mapa OSM mostrando o trajeto entre [origin] (coleta) e [destination]
/// (destino), com marcadores e a rota real (OSRM). Sem chave de API.
class RouteMap extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String originLabel;
  final String destinationLabel;
  final double height;

  const RouteMap({
    super.key,
    required this.origin,
    required this.destination,
    this.originLabel = 'Coleta',
    this.destinationLabel = 'Destino',
    this.height = 240,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  RouteResult? _route;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final r = await RoutingService.route(widget.origin, widget.destination);
    if (!mounted) return;
    setState(() {
      _route = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final points = _route?.points ?? [widget.origin, widget.destination];
    final bounds = LatLngBounds.fromPoints([
      widget.origin,
      widget.destination,
      ...points,
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(40),
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mypet.app',
                    ),
                    if (_route != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _route!.points,
                            strokeWidth: 4,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.origin,
                          width: 38,
                          height: 38,
                          child: const _Pin(
                              icon: Icons.store, color: AppColors.estab),
                        ),
                        Marker(
                          point: widget.destination,
                          width: 38,
                          height: 38,
                          child: const _Pin(
                              icon: Icons.home, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_loading)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_route != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.route, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '${formatKm(_route!.distanceKm)} • ~${_route!.durationMin.round()} min de carro',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.dark,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Pin({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
