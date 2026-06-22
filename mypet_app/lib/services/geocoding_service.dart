import 'dart:convert';
import 'package:http/http.dart' as http;

/// Geocodificação via Nominatim (OpenStreetMap) — converte um endereço em
/// coordenadas (lat/lng). Grátis e sem chave; respeita a política de uso
/// enviando um User-Agent identificável e 1 requisição por vez.
class GeocodingService {
  static Future<({double lat, double lng})?> geocode(String address) async {
    final q = address.trim();
    if (q.isEmpty) return null;
    final uri =
        Uri.parse('https://nominatim.openstreetmap.org/search').replace(
      queryParameters: {
        'format': 'json',
        'limit': '1',
        'countrycodes': 'br',
        'q': q,
      },
    );
    try {
      final res = await http.get(uri, headers: {
        'User-Agent': 'MyPetApp/1.0 (mypet@example.com)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      final first = list.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lng = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lng == null) return null;
      return (lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }
}
