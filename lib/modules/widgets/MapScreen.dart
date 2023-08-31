import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:appmap/modules/widgets/Places.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  List<Place> places = [];
  LatLng? currentLocation;
  bool isLoading = true;
  String _mapStyle = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation().then((location) {
      if (location != null) {
        print('Getting the location');
        fetchNearbyPlaces(location).then((fetchedPlaces) {
          setState(() {
            places = fetchedPlaces;
            currentLocation = location;
            isLoading = false;
          });
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    });
    DefaultAssetBundle.of(context).loadString('assets/map_style.txt').then((value) => {
      _mapStyle = value
    });
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
        print('Checking location permissions');
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
            print('Location permissions are denied. Requesting permissions...');
            permission = await Geolocator.requestPermission();

            if (permission == LocationPermission.deniedForever) {
                print("Location permissions are permanently denied. Cannot request permissions.");
                await Geolocator.openAppSettings(); // Optionally open app settings
                return null;
            } 
            if (permission == LocationPermission.denied) {
                print("Location permissions are denied temporarily. You can request them again later.");
                return null;
            }
        }

        print('Getting the current location using Geolocator');
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        print('Location fetched: ${position.latitude}, ${position.longitude}');
        return LatLng(position.latitude, position.longitude);

    } catch (e) {
        print("Error getting location with Geolocator: $e");
        return null;
    }
  }

  Future<List<Place>> fetchNearbyPlaces(LatLng position) async {
    print('Started get the places');
    final apiKey = "AIzaSyAwGngdf18HBCy037e-OFKYfg1mIFJuxPc"; // Consider storing this securely.
    final endpoint = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";
    final response = await http.get(Uri.parse("$endpoint?location=${position.latitude},${position.longitude}&radius=1500&key=$apiKey"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Getting the places');
      return (data['results'] as List).map((place) => Place.fromJson(place)).toList();
    } else {
      throw Exception('Failed to load nearby places');
    }
  }

  Widget _buildBottomSheet(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
    ),
    height: 300,
    child: Column(
      children: [
        // Icon indicating a modal sheet.
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.drag_handle, color: Colors.grey[400]),
        ),
        // ListView inside Expanded to prevent overflow.
        Expanded(
          child: ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              return Card(
                color: Color(0xFFF3F6FD),
                child: ListTile(
                  title: Text(places[index].name),
                  subtitle: Text(places[index].address),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    GoogleMapController mapController;
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                mapController.setMapStyle(_mapStyle);
              },  
              initialCameraPosition: CameraPosition(
                target: currentLocation!,
                zoom: 14.4746,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: _buildBottomSheet,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
            ),
          );
        },
        child: Icon(Icons.place),
      ),
    );
  }
}