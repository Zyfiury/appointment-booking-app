import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/provider.dart';
import '../../models/service.dart';
import '../../services/search_service.dart';
import '../../services/map_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/rating_widget.dart';
import 'book_appointment_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchService _searchService = SearchService();
  final MapService _mapService = MapService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Provider> _providers = [];
  List<String> _categories = [];
  bool _loading = false;
  bool _loadingCategories = true;
  
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  String _sortBy = 'rating';
  bool _nearMe = false;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _requestLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _searchService.getCategories();
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _loadingCategories = false;
      });
    }
  }

  Future<void> _requestLocation() async {
    final position = await _mapService.getCurrentLocation();
    setState(() {
      _currentLocation = position;
    });
  }

  Future<void> _performSearch() async {
    setState(() {
      _loading = true;
    });

    try {
      final filters = SearchFilters(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        category: _selectedCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        latitude: _nearMe && _currentLocation != null
            ? _currentLocation!.latitude
            : null,
        longitude: _nearMe && _currentLocation != null
            ? _currentLocation!.longitude
            : null,
        radius: _nearMe ? 10.0 : null, // 10km radius
        sortBy: _sortBy,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Search Providers'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: FloatingCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search providers or services...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                    const SizedBox(height: 12),
                    // Quick Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Near Me',
                            selected: _nearMe,
                            icon: Icons.location_on,
                            onSelected: (value) {
                              setState(() {
                                _nearMe = value;
                              });
                              _performSearch();
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Top Rated',
                            selected: _minRating == 4.0,
                            icon: Icons.star,
                            onSelected: (value) {
                              setState(() {
                                _minRating = value ? 4.0 : null;
                              });
                              _performSearch();
                            },
                          ),
                          if (_categories.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            ..._categories.take(3).map((category) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildFilterChip(
                                    label: category,
                                    selected: _selectedCategory == category,
                                    onSelected: (value) {
                                      setState(() {
                                        _selectedCategory = value ? category : null;
                                      });
                                      _performSearch();
                                    },
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Results
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _providers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No providers found',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters',
                                style: TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _providers.length,
                          itemBuilder: (context, index) {
                            final provider = _providers[index];
                            return _ProviderCard(
                              provider: provider,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookAppointmentScreen(
                                      preselectedProviderId: provider.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    IconData? icon,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.primaryColor),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppTheme.primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.textPrimary,
        fontSize: 13,
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final Provider provider;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
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
                      provider.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (provider.rating != null) ...[
                      const SizedBox(height: 8),
                      RatingWidget(
                        rating: provider.rating!,
                        totalRatings: provider.reviewCount ?? 0,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
              if (provider.latitude != null && provider.longitude != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
            ],
          ),
          if (provider.address != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.place,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    provider.address!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
