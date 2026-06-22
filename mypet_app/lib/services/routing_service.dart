import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;
  RouteResult(this.points, this.distanceKm, this.durationMin);
}

/// Rotas via OSRM (servidor público de demonstração) — sem chave de API.
class RoutingService {
  static Future<RouteResult?> route(LatLng origin, LatLng dest) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${dest.longitude},${dest.latitude}'
      '?overview=full&geometries=geojson',
    );
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final r = routes.first as Map<String, dynamic>;
      final coords = ((r['geometry'] as Map)['coordinates'] as List)
          .map((c) =>
              LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      return RouteResult(
        coords,
        (r['distance'] as num).toDouble() / 1000,
        (r['duration'] as num).toDouble() / 60,
      );
    } catch (_) {
      return null;
    }
  }
}
