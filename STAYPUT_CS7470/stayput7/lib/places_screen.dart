import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'storage_service.dart';
import 'models.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  List<Place> _places = [];

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    List<Place> saved = await StorageService.getPlaces();
    setState(() => _places = saved);
  }

  Future<void> _addOrEditPlace({Place? place, int? index}) async {
    final nameController = TextEditingController(text: place?.name ?? '');
    LatLng? selectedLocation =
        place != null ? LatLng(place.latitude, place.longitude) : null;

    String locationStatus = selectedLocation != null
        ? "Selected: ${selectedLocation.latitude.toStringAsFixed(4)}, ${selectedLocation.longitude.toStringAsFixed(4)}"
        : "No location selected";

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place != null ? "Edit Location" : "Add Location",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),

                  // Name field
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Location Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status
                  Text(
                    locationStatus,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: selectedLocation != null
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Use current location button (M3)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.my_location),
                    label: const Text("Use Current Location"),
                    onPressed: () async {
                      Position pos = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high);
                      selectedLocation = LatLng(pos.latitude, pos.longitude);

                      setDialogState(() {
                        locationStatus =
                            "Selected: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}";
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel")),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              selectedLocation == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Name & location required.")),
                            );
                            return;
                          }

                          final newPlace = Place(
                            name: nameController.text,
                            latitude: selectedLocation!.latitude,
                            longitude: selectedLocation!.longitude,
                          );

                          if (place != null && index != null) {
                            _places[index] = newPlace;
                          } else {
                            _places.add(newPlace);
                          }

                          await StorageService.savePlaces(_places);
                          if (mounted) Navigator.pop(context);
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _deletePlace(int index) async {
    _places.removeAt(index);
    await StorageService.savePlaces(_places);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Locations", style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: _places.length,
                itemBuilder: (context, index) {
                  return _LocationCard(
                    place: _places[index],
                    onEdit: () async {
                      await _addOrEditPlace(
                          place: _places[index], index: index);
                      _loadPlaces();
                    },
                    onDelete: () => _deletePlace(index),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Add button (Material 3)
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Location"),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                await _addOrEditPlace();
                _loadPlaces();
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Place place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LocationCard({
    required this.place,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String lat = place.latitude.toStringAsFixed(4);
    String lng = place.longitude.toStringAsFixed(4);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                ],
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
