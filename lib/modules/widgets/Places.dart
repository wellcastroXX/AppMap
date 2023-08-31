import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<List<Place>> fetchNearbyPlaces(LatLng position) async {
  final apiKey = "AIzaSyAwGngdf18HBCy037e-OFKYfg1mIFJuxPc";
  final endpoint = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";
  final response = await http.get(Uri.parse("$endpoint?location=${position.latitude},${position.longitude}&radius=1500&key=$apiKey"));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return (data['results'] as List).map((place) => Place.fromJson(place)).toList();
  } else {
    throw Exception('Failed to load nearby places');
  }
}

class Place {
  final String name;
  final String address;

  Place({required this.name, required this.address});

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['name'],
      address: json['vicinity'],
    );
  }
}
