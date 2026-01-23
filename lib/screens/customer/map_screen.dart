import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../models/provider.dart' as provider_model;
import 'package:provider/provider.dart';
import '../../services/service_service.dart';
import '../../services/map_service.dart';
import '../../services/search_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/rating_widget.dart';
import '../../widgets/custom_marker.dart';
import '../../utils/map_styles.dart';
import 'book_appointment_screen.dart';
import '../../providers/theme_provider.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ServiceService _serviceService = ServiceService();
  final MapService _mapService = MapService();
  final SearchService _searchService = SearchService();
  GoogleMapController? _mapController;
  
  List<provider_model.Provider> _providers = [];
  Position? _currentPosition;
  bool _loading = true;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  provider_model.Provider? _selectedProvider;
  double _searchRadius = 50.0; // in kilometers
  bool _showRadiusFilter = false;
  MapType _mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Get current location
      Position? position;
      try {
        position = await _mapService.getCurrentLocation();
        debugPrint('📍 Current location: ${position?.latitude}, ${position?.longitude}');
      } catch (e) {
        debugPrint('⚠️ Location error: $e');
        // Continue without location
      }
      
      // Load providers with location-based search if available
      List<provider_model.Provider> providers = [];
      try {
        if (position != null) {
          // Use location-based search
          final filters = SearchFilters(
            latitude: position.latitude,
            longitude: position.longitude,
            radius: _searchRadius,
            sortBy: 'distance',
          );
          providers = await _searchService.searchProviders(filters);
          debugPrint('✅ Loaded ${providers.length} providers with location');
        } else {
          // Fallback to all providers
          providers = await _serviceService.getProviders();
          debugPrint('✅ Loaded ${providers.length} providers (no location)');
        }
      } catch (e) {
        debugPrint('❌ Error loading providers: $e');
        // Try to load without location
        try {
          providers = await _serviceService.getProviders();
          debugPrint('✅ Loaded ${providers.length} providers (fallback)');
        } catch (e2) {
          debugPrint('❌ Failed to load providers: $e2');
        }
      }
      
      // Use a default location if current location is not available
      // Use London as default (where some test providers are)
      final defaultPosition = Position(
        latitude: 51.5074, // London
        longitude: -0.1278,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      setState(() {
        _currentPosition = position ?? defaultPosition;
        _providers = providers;
        _loading = false;
      });

      debugPrint('🗺️ Map initialized at: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      debugPrint('📍 Providers with location: ${providers.where((p) => (p as provider_model.Provider).latitude != null && (p as provider_model.Provider).longitude != null).length}');

      // Wait a bit for map to initialize, then update markers
      await Future.delayed(const Duration(milliseconds: 1000));
      _updateMarkers();
    } catch (e, stackTrace) {
      debugPrint('❌ Map initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // If location fails, use default location (London)
      final defaultPosition = Position(
        latitude: 51.5074,
        longitude: -0.1278,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      setState(() {
        _currentPosition = defaultPosition;
        _loading = false;
      });
      
      // Load providers even if location fails
      try {
        final providers = await _serviceService.getProviders();
        setState(() {
          _providers = providers;
        });
        debugPrint('✅ Loaded ${providers.length} providers (error fallback)');
      } catch (e) {
        debugPrint('❌ Failed to load providers: $e');
      }
      
      await Future.delayed(const Duration(milliseconds: 1000));
      _updateMarkers();
    }
  }

  Future<BitmapDescriptor> _getProviderMarkerIcon(provider_model.Provider provider) async {
    return await CustomMarker.createMarkerIcon(
      providerName: provider.name,
      rating: provider.rating,
    );
  }

  Future<BitmapDescriptor> _getCurrentLocationIcon() async {
    return await CustomMarker.createCurrentLocationIcon();
  }

  Future<void> _openDirections(provider_model.Provider provider) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    if (provider.latitude == null || provider.longitude == null) return;
    
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${provider.latitude},${provider.longitude}',
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open directions'),
            backgroundColor: colors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _refreshProviders() async {
    if (_currentPosition == null) return;
    
    setState(() {
      _loading = true;
    });

    try {
      final filters = SearchFilters(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: _searchRadius,
        sortBy: 'distance',
      );
      final providers = await _searchService.searchProviders(filters);
      setState(() {
        _providers = providers;
        _loading = false;
      });
      await _updateMarkers();
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  String? _getMapStyle() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.currentTheme == AppThemeMode.darkProfessional ||
        themeProvider.currentTheme == AppThemeMode.darkElegant;
    return isDark ? MapStyles.darkStyle : MapStyles.lightStyle;
  }

  Future<void> _updateMarkers() async {
    final markers = <Marker>{};
    final circles = <Circle>{};

    // Current location marker with custom icon
    if (_currentPosition != null) {
      final currentLocationIcon = await _getCurrentLocationIcon();
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: currentLocationIcon,
          infoWindow: const InfoWindow(title: 'Your Location'),
          anchor: const Offset(0.5, 0.5),
        ),
      );

      // Add search radius circle
      circles.add(
        Circle(
          circleId: const CircleId('search_radius'),
          center: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          radius: _searchRadius * 1000, // Convert km to meters
          fillColor: Colors.blue.withOpacity(0.1),
          strokeColor: Colors.blue.withOpacity(0.5),
          strokeWidth: 2,
        ),
      );
    }

    // Provider markers with custom icons
    int providerMarkerCount = 0;
    for (final provider in _providers) {
      if (provider.latitude != null && provider.longitude != null) {
        final icon = await _getProviderMarkerIcon(provider);
        markers.add(
          Marker(
            markerId: MarkerId(provider.id),
            position: LatLng(
              provider.latitude!,
              provider.longitude!,
            ),
            icon: icon,
            infoWindow: InfoWindow(
              title: provider.name,
              snippet: provider.rating != null
                  ? 'Rating: ${provider.rating!.toStringAsFixed(1)}'
                  : null,
            ),
            anchor: const Offset(0.5, 1.0), // Pin point at bottom
            onTap: () {
              setState(() {
                _selectedProvider = provider;
              });
            },
          ),
        );
        providerMarkerCount++;
      }
    }

    // If no providers have locations, add some demo markers near current location
    if (providerMarkerCount == 0 && _currentPosition != null) {
      // Add a few demo provider markers around the current location
      final demoProviders = [
        {'name': 'Demo Provider 1', 'latOffset': 0.01, 'lngOffset': 0.01, 'rating': 4.5},
        {'name': 'Demo Provider 2', 'latOffset': -0.01, 'lngOffset': 0.01, 'rating': 4.8},
        {'name': 'Demo Provider 3', 'latOffset': 0.015, 'lngOffset': -0.01, 'rating': 4.2},
      ];
      
      for (int i = 0; i < demoProviders.length; i++) {
        final demo = demoProviders[i];
        markers.add(
          Marker(
            markerId: MarkerId('demo_$i'),
            position: LatLng(
              _currentPosition!.latitude + (demo['latOffset'] as double),
              _currentPosition!.longitude + (demo['lngOffset'] as double),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: demo['name'] as String,
              snippet: 'Rating: ${demo['rating']}',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _circles = circles;
    });

    // Move camera to show all markers
    if (_mapController != null) {
      final targetLat = _currentPosition?.latitude ?? 51.5074; // London default
      final targetLng = _currentPosition?.longitude ?? -0.1278;
      
      debugPrint('📷 Moving camera to: $targetLat, $targetLng with ${_markers.length} markers');
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(targetLat, targetLng),
          _currentPosition != null ? 14 : 12,
        ),
      );
    } else {
      debugPrint('⚠️ Map controller not ready yet');
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
        title: Text('Find Providers'),
        actions: [
          // Map type switcher
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _mapType == MapType.satellite
                    ? Icons.map
                    : _mapType == MapType.terrain
                        ? Icons.terrain
                        : Icons.satellite,
                size: 20,
              ),
            ),
            onPressed: () {
              setState(() {
                if (_mapType == MapType.normal) {
                  _mapType = MapType.satellite;
                } else if (_mapType == MapType.satellite) {
                  _mapType = MapType.terrain;
                } else {
                  _mapType = MapType.normal;
                }
              });
            },
            tooltip: 'Map type',
          ),
          // Radius filter
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showRadiusFilter
                    ? colors.primaryColor.withOpacity(0.2)
                    : colors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tune,
                size: 20,
                color: _showRadiusFilter ? colors.primaryColor : null,
              ),
            ),
            onPressed: () {
              setState(() {
                _showRadiusFilter = !_showRadiusFilter;
              });
            },
            tooltip: 'Filter radius',
          ),
          // My location
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.my_location, size: 20),
            ),
            onPressed: () async {
              final position = await _mapService.getCurrentLocation();
              if (position != null && _mapController != null) {
                setState(() {
                  _currentPosition = position;
                  _loading = true;
                });
                
                // Reload providers with new location
                try {
                  final filters = SearchFilters(
                    latitude: position.latitude,
                    longitude: position.longitude,
                    radius: _searchRadius,
                    sortBy: 'distance',
                  );
                  final providers = await _searchService.searchProviders(filters);
                  setState(() {
                    _providers = providers;
                    _loading = false;
                  });
                } catch (e) {
                  setState(() {
                    _loading = false;
                  });
                }
                
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(position.latitude, position.longitude),
                    15,
                  ),
                );
                await _updateMarkers();
              }
            },
            tooltip: 'My location',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Map
          _loading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition?.latitude ?? 51.5074, // London default
                      _currentPosition?.longitude ?? -0.1278,
                    ),
                    zoom: _currentPosition != null ? 14.0 : 12.0,
                  ),
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                  buildingsEnabled: true,
                  trafficEnabled: false,
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: _mapType,
                  zoomControlsEnabled: true,
                  style: _getMapStyle(),
                  onMapCreated: (controller) async {
                    _mapController = controller;
                    debugPrint('🗺️ Map created successfully');
                    // Apply custom styling
                    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                    final isDark = themeProvider.currentTheme == AppThemeMode.darkProfessional ||
                        themeProvider.currentTheme == AppThemeMode.darkElegant;
                    controller.setMapStyle(isDark ? MapStyles.darkStyle : MapStyles.lightStyle);
                    
                    // Wait a moment for map to fully initialize
                    await Future.delayed(const Duration(milliseconds: 1000));
                    await _updateMarkers();
                    
                    // Ensure camera is positioned correctly
                    if (_currentPosition != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          14,
                        ),
                      );
                    }
                  },
                  onCameraMoveStarted: () {
                    debugPrint('📷 Camera move started');
                  },
                  onCameraIdle: () {
                    debugPrint('📷 Camera idle');
                  },
                  onTap: (LatLng position) {
                    // Clear selection when tapping map
                    setState(() {
                      _selectedProvider = null;
                    });
                  },
                ),
          // Radius Filter Card
          if (_showRadiusFilter)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: FadeInWidget(
                child: FloatingCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Search Radius',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_searchRadius.toStringAsFixed(0)} km',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: _searchRadius,
                        min: 5,
                        max: 100,
                        divisions: 19,
                        label: '${_searchRadius.toStringAsFixed(0)} km',
                        activeColor: colors.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _searchRadius = value;
                          });
                        },
                        onChangeEnd: (value) async {
                          await _refreshProviders();
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () async {
                              setState(() {
                                _searchRadius = 10;
                              });
                              await _refreshProviders();
                            },
                            child: Text('10 km'),
                          ),
                          TextButton(
                            onPressed: () async {
                              setState(() {
                                _searchRadius = 25;
                              });
                              await _refreshProviders();
                            },
                            child: Text('25 km'),
                          ),
                          TextButton(
                            onPressed: () async {
                              setState(() {
                                _searchRadius = 50;
                              });
                              await _refreshProviders();
                            },
                            child: Text('50 km'),
                          ),
                          TextButton(
                            onPressed: () async {
                              setState(() {
                                _searchRadius = 100;
                              });
                              await _refreshProviders();
                            },
                            child: Text('100 km'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Selected Provider Card with slide animation
          if (_selectedProvider != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SlideInWidget(
                offset: const Offset(0, 1), // Slide from bottom
                child: FloatingCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookAppointmentScreen(
                          preselectedProviderId: _selectedProvider!.id,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedProvider!.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                if (_selectedProvider!.rating != null) ...[
                                  const SizedBox(height: 8),
                                  RatingWidget(
                                    rating: _selectedProvider!.rating!,
                                    totalRatings: _selectedProvider!.reviewCount ?? 0,
                                    size: 14,
                                  ),
                                ],
                                if (_selectedProvider!.distance != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.navigation,
                                        size: 12,
                                        color: colors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_selectedProvider!.distance!.toStringAsFixed(1)} km away',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: colors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedProvider!.address != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.place,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _selectedProvider!.address!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openDirections(_selectedProvider!),
                              icon: const Icon(Icons.directions, size: 16),
                              label: Text('Directions'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookAppointmentScreen(
                                      preselectedProviderId: _selectedProvider!.id,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.book, size: 16),
                              label: Text('Book'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
