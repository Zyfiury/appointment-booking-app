import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/map_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';


class ProviderLocationScreen extends StatefulWidget {
  const ProviderLocationScreen({super.key});

  @override
  State<ProviderLocationScreen> createState() => _ProviderLocationScreenState();
}

class _ProviderLocationScreenState extends State<ProviderLocationScreen> {
  final ApiService _apiService = ApiService();
  final MapService _mapService = MapService();
  final TextEditingController _addressController = TextEditingController();
  
  GoogleMapController? _mapController;
  Position? _selectedPosition;
  bool _loading = false;
  bool _saving = false;
  String? _currentAddress;
  double? _currentLat;
  double? _currentLng;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _loading = true;
    });

    try {
      // Get user profile to load existing location
      final response = await _apiService.get('/users/profile');
      final profile = response.data;
      
      if (profile['latitude'] != null && profile['longitude'] != null) {
        _currentLat = (profile['latitude'] as num).toDouble();
        _currentLng = (profile['longitude'] as num).toDouble();
        _selectedPosition = Position(
          latitude: _currentLat!,
          longitude: _currentLng!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _addressController.text = profile['address'] ?? '';
        _currentAddress = profile['address'];
        
        // Get address from coordinates if address is missing
        if (_currentAddress == null || _currentAddress!.isEmpty) {
          _currentAddress = await _mapService.getAddressFromCoordinates(
            _currentLat!,
            _currentLng!,
          );
          _addressController.text = _currentAddress ?? '';
        }
      } else {
        // Get current device location
        final position = await _mapService.getCurrentLocation();
        if (position != null) {
          _selectedPosition = position;
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          _currentAddress = await _mapService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );
          _addressController.text = _currentAddress ?? '';
        }
      }
    } catch (e) {
      // Try to get device location as fallback
      final position = await _mapService.getCurrentLocation();
      if (position != null) {
        _selectedPosition = position;
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _currentAddress = await _mapService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        _addressController.text = _currentAddress ?? '';
      }
    }

    setState(() {
      _loading = false;
    });

    // Move camera to selected position
    if (_selectedPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_selectedPosition!.latitude, _selectedPosition!.longitude),
          15,
        ),
      );
    }
  }

  Future<void> _searchAddress() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    if (_addressController.text.trim().isEmpty) return;

    setState(() {
      _loading = true;
    });

    try {
      final position = await _mapService.getCoordinatesFromAddress(
        _addressController.text.trim(),
      );
      
      if (position != null) {
        setState(() {
          _selectedPosition = position;
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          _loading = false;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      } else {
        setState(() {
          _loading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Address not found'),
              backgroundColor: colors.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching address: $e'),
            backgroundColor: colors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    setState(() {
      _loading = true;
    });

    try {
      final position = await _mapService.getCurrentLocation();
      if (position != null) {
        final address = await _mapService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        setState(() {
          _selectedPosition = position;
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          _currentAddress = address;
          _addressController.text = address ?? '';
          _loading = false;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      } else {
        setState(() {
          _loading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to get current location'),
              backgroundColor: colors.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveLocation() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a location'),
          backgroundColor: colors.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _apiService.patch(
        '/users/profile',
        data: {
          'latitude': _selectedPosition!.latitude,
          'longitude': _selectedPosition!.longitude,
          'address': _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : _currentAddress,
        },
      );

      // Update auth provider user data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location saved successfully!'),
            backgroundColor: colors.primaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save location: $e'),
            backgroundColor: colors.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('Set Location'),
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition != null
                  ? LatLng(_selectedPosition!.latitude, _selectedPosition!.longitude)
                  : const LatLng(37.7749, -122.4194),
              zoom: _selectedPosition != null ? 15.0 : 12.0,
            ),
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: LatLng(
                        _selectedPosition!.latitude,
                        _selectedPosition!.longitude,
                      ),
                      draggable: true,
                      onDragEnd: (LatLng newPosition) async {
                        setState(() {
                          _selectedPosition = Position(
                            latitude: newPosition.latitude,
                            longitude: newPosition.longitude,
                            timestamp: DateTime.now(),
                            accuracy: 0,
                            altitude: 0,
                            altitudeAccuracy: 0,
                            heading: 0,
                            headingAccuracy: 0,
                            speed: 0,
                            speedAccuracy: 0,
                          );
                          _currentLat = newPosition.latitude;
                          _currentLng = newPosition.longitude;
                        });
                        
                        final address = await _mapService.getAddressFromCoordinates(
                          newPosition.latitude,
                          newPosition.longitude,
                        );
                        setState(() {
                          _currentAddress = address;
                          _addressController.text = address ?? '';
                        });
                      },
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_selectedPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(
                      _selectedPosition!.latitude,
                      _selectedPosition!.longitude,
                    ),
                    15,
                  ),
                );
              }
            },
            onTap: (LatLng position) async {
              setState(() {
                _selectedPosition = Position(
                  latitude: position.latitude,
                  longitude: position.longitude,
                  timestamp: DateTime.now(),
                  accuracy: 0,
                  altitude: 0,
                  altitudeAccuracy: 0,
                  heading: 0,
                  headingAccuracy: 0,
                  speed: 0,
                  speedAccuracy: 0,
                );
                _currentLat = position.latitude;
                _currentLng = position.longitude;
              });

              final address = await _mapService.getAddressFromCoordinates(
                position.latitude,
                position.longitude,
              );
              setState(() {
                _currentAddress = address;
                _addressController.text = address ?? '';
              });
            },
          ),

          // Address Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: FadeInWidget(
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              hintText: 'Enter address or search',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: colors.surfaceColor,
                            ),
                            onSubmitted: (_) => _searchAddress(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _useCurrentLocation,
                          tooltip: 'Use current location',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _searchAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Search Address'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Save Button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: FadeInWidget(
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedPosition != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: colors.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _addressController.text.isNotEmpty
                                  ? _addressController.text
                                  : 'Location selected',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text('Save Location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
