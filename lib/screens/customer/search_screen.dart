import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/provider.dart' as provider_model;
import 'package:provider/provider.dart';
import '../../models/service.dart';
import '../../services/search_service.dart';
import '../../services/service_service.dart';
import '../../services/map_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/rating_widget.dart';
import '../../widgets/favorite_button.dart';
import '../../utils/service_categories.dart';
import 'book_appointment_screen.dart';
import '../../providers/theme_provider.dart';

class SearchScreen extends StatefulWidget {
  final String? preselectedCategory;
  
  const SearchScreen({super.key, this.preselectedCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final SearchService _searchService = SearchService();
  final ServiceService _serviceService = ServiceService();
  final MapService _mapService = MapService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<provider_model.Provider> _providers = [];
  List<Service> _services = [];
  List<provider_model.Provider> _serviceProviders = []; // Providers for services
  bool _loading = false;
  int _selectedTab = 0; // 0 = Services, 1 = Providers
  
  String? _selectedCategory;
  String? _selectedSubcategory;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  String _sortBy = 'rating';
  bool _nearMe = false;
  Position? _currentLocation;
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
    _selectedCategory = widget.preselectedCategory;
    _requestLocation();
    if (_selectedCategory != null) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateActiveFilters() {
    setState(() {
      _hasActiveFilters = _selectedCategory != null ||
          _selectedSubcategory != null ||
          _minPrice != null ||
          _maxPrice != null ||
          _minRating != null ||
          _nearMe ||
          _sortBy != 'rating';
    });
  }

  Future<void> _requestLocation() async {
    try {
      final position = await _mapService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = position;
      });
    } catch (e) {
      // Location permission denied or error - continue without location
      if (!mounted) return;
      debugPrint('Location error: $e');
    }
  }

  Future<void> _performSearch() async {
    if (!mounted) return;
    
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
        radius: _nearMe ? 10.0 : null,
        sortBy: _sortBy,
      );

      // Search both services and providers
      final servicesFuture = _searchService.searchServices(filters);
      final providersFuture = _searchService.searchProviders(filters);

      final results = await Future.wait([servicesFuture, providersFuture]);

      // Check if still mounted before continuing
      if (!mounted) return;

      // Get providers for services
      final serviceProviderIds = (results[0] as List<Service>)
          .map((s) => s.providerId)
          .toSet();
      final allProviders = await _serviceService.getProviders();
      
      // Check mounted again after async operation
      if (!mounted) return;
      
      final serviceProvidersList = allProviders
          .where((p) => serviceProviderIds.contains(p.id))
          .toList();

      // Final mounted check before setState
      if (!mounted) return;
      
      setState(() {
        _services = results[0] as List<Service>;
        _serviceProviders = serviceProvidersList;
        _providers = results[1] as List<provider_model.Provider>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _loading = false;
      });
      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final colors = AppTheme.getColors(themeProvider.currentTheme);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: colors.errorColor,
          ),
        );
      }
    }
  }

  void _showFiltersSheet() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                        _selectedSubcategory = null;
                        _minPrice = null;
                        _maxPrice = null;
                        _minRating = null;
                        _sortBy = 'rating';
                        _nearMe = false;
                      });
                      _updateActiveFilters();
                      Navigator.pop(context);
                      _performSearch();
                    },
                    child: Text('Clear All'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ServiceCategories.getAllCategoryNames()
                          .where((c) => c != 'Other')
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        final cat = ServiceCategories.getCategory(category);
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 200 + (index * 30)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: child,
                              ),
                            );
                          },
                          child: FilterChip(
                            avatar: Icon(cat.icon, size: 18, color: _selectedCategory == category ? cat.color : colors.textSecondary),
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : null;
                                _selectedSubcategory = null;
                              });
                              if (selected) {
                                _performSearch();
                              }
                            },
                            selectedColor: cat.color.withOpacity(0.3),
                            checkmarkColor: cat.color,
                            labelStyle: TextStyle(
                              fontWeight: _selectedCategory == category ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Subcategory (if category selected)
                    if (_selectedCategory != null) ...[
                      Text(
                        'Subcategory',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ServiceCategories.getSubcategories(_selectedCategory!)
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final subcat = entry.value;
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 150 + (index * 20)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(-10 * (1 - value), 0),
                                  child: child,
                                ),
                              );
                            },
                            child: FilterChip(
                              label: Text(subcat),
                              selected: _selectedSubcategory == subcat,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSubcategory = selected ? subcat : null;
                                });
                                if (selected) {
                                  _performSearch();
                                }
                              },
                              selectedColor: ServiceCategories.getCategory(_selectedCategory!).color.withOpacity(0.2),
                              checkmarkColor: ServiceCategories.getCategory(_selectedCategory!).color,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Price Range
                    Text(
                      'Price Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Min Price',
                              hintText: '\$0',
                              prefixText: '\$',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _minPrice = value.isEmpty ? null : double.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Max Price',
                              hintText: '\$1000',
                              prefixText: '\$',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _maxPrice = value.isEmpty ? null : double.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Rating
                    Text(
                      'Minimum Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [1, 2, 3, 4, 5].map((rating) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _minRating = _minRating == rating.toDouble() ? null : rating.toDouble();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: (_minRating != null && _minRating! >= rating)
                                    ? colors.primaryColor
                                    : colors.surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: (_minRating != null && _minRating! >= rating)
                                        ? Colors.white
                                        : colors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$rating+',
                                    style: TextStyle(
                                      color: (_minRating != null && _minRating! >= rating)
                                          ? Colors.white
                                          : colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Sort By
                    Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...['rating', 'price', 'distance', 'name'].map((sort) {
                      return RadioListTile<String>(
                        title: Text(sort == 'rating' ? 'Rating' : 
                                   sort == 'price' ? 'Price' :
                                   sort == 'distance' ? 'Distance' : 'Name'),
                        value: sort,
                        groupValue: _sortBy,
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    // Near Me
                    SwitchListTile(
                      title: Text('Near Me'),
                      subtitle: Text('Show only nearby results'),
                      value: _nearMe,
                      onChanged: (value) {
                        setState(() {
                          _nearMe = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _updateActiveFilters();
                    Navigator.pop(context);
                    _performSearch();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        title: Text(
          'What do you want to book?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
              indicator: BoxDecoration(
                gradient: colors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: colors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.room_service, size: 20),
                  text: 'Services',
                ),
                Tab(
                  icon: Icon(Icons.person, size: 20),
                  text: 'Providers',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.backgroundGradient,
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
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search services or providers...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: colors.primaryColor,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_hasActiveFilters)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colors.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.filter_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: colors.textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch();
                                },
                              ),
                          ],
                        ),
                        filled: true,
                        fillColor: colors.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _performSearch(),
                      onChanged: (_) => _performSearch(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showFiltersSheet,
                            icon: Icon(
                              Icons.tune,
                              color: _hasActiveFilters ? colors.primaryColor : colors.textSecondary,
                            ),
                            label: Text(
                              'Filters',
                              style: TextStyle(
                                color: _hasActiveFilters ? colors.primaryColor : colors.textSecondary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _hasActiveFilters ? colors.primaryColor : colors.textSecondary.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_nearMe && _currentLocation != null)
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _nearMe = false;
                              });
                              _updateActiveFilters();
                              _performSearch();
                            },
                            icon: Icon(Icons.location_on, color: colors.primaryColor),
                            label: Text('Near Me', style: TextStyle(color: colors.primaryColor)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.primaryColor),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Results
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Services Tab
                        _services.isEmpty
                            ? _buildEmptyState('No services found', 'Try adjusting your search or filters', colors)
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _services.length,
                                itemBuilder: (context, index) {
                                  final service = _services[index];
                                  final provider = _serviceProviders.firstWhere(
                                    (p) => p.id == service.providerId,
                                    orElse: () => provider_model.Provider(
                                      id: service.providerId,
                                      name: 'Unknown',
                                      email: '',
                                    ),
                                  );
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: Duration(milliseconds: 300 + (index * 50)),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _ServiceCard(
                                      service: service,
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
                                    ),
                                  );
                                },
                              ),
                        // Providers Tab
                        _providers.isEmpty
                            ? _buildEmptyState('No providers found', 'Try adjusting your search or filters', colors)
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _providers.length,
                                itemBuilder: (context, index) {
                                  final provider = _providers[index];
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: Duration(milliseconds: 300 + (index * 50)),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _ProviderCard(
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
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final Service service;
  final provider_model.Provider provider;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.provider,
    required this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    final cat = ServiceCategories.getCategory(widget.service.category);

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: FloatingCard(
        margin: const EdgeInsets.only(bottom: 12),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: cat.color != null 
                        ? LinearGradient(
                            colors: [cat.color, cat.color.withOpacity(0.7)],
                          )
                        : colors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    cat.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (widget.service.subcategory != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.service.subcategory!,
                            style: TextStyle(
                              fontSize: 12,
                              color: cat.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: colors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '\$${widget.service.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surfaceColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.service.duration} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.provider.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.provider.rating != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          widget.provider.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final provider_model.Provider provider;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    
    return FloatingCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'provider_avatar_${provider.id}',
                child: Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: colors.primaryGradient,
                  ),
                  child: provider.profilePicture != null
                      ? ClipOval(
                          child: Image.network(
                            provider.profilePicture!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            provider.name.isNotEmpty ? provider.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (provider.rating != null) ...[
                      const SizedBox(height: 6),
                      RatingWidget(
                        rating: provider.rating!,
                        totalRatings: provider.reviewCount ?? 0,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
              FavoriteButton(providerId: provider.id, size: 24),
            ],
          ),
          if (provider.address != null) ...[
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
                    provider.address!,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (provider.distance != null) ...[
                  Text(
                    '${provider.distance!.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
