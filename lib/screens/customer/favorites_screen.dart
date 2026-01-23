import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/provider.dart' as provider_model;
import '../../services/favorite_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layered_card.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/rating_widget.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import '../../providers/theme_provider.dart';
import 'book_appointment_screen.dart';
import 'search_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  List<provider_model.Provider> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
    });

    try {
      final favorites = await _favoriteService.getFavorites();
      setState(() {
        _favorites = favorites;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final colors = AppTheme.getColors(themeProvider.currentTheme);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load favorites: $e'),
            backgroundColor: colors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _removeFavorite(provider_model.Provider provider) async {
    try {
      await _favoriteService.removeFavorite(provider.id);
      setState(() {
        _favorites.removeWhere((p) => p.id == provider.id);
      });
      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final colors = AppTheme.getColors(themeProvider.currentTheme);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: colors.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final colors = AppTheme.getColors(themeProvider.currentTheme);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove favorite: $e'),
            backgroundColor: colors.errorColor,
          ),
        );
      }
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
        title: Text('Favorites'),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: colors.backgroundGradient),
        child: _loading
            ? const ShimmerList(itemCount: 5, itemHeight: 150)
            : _favorites.isEmpty
                ? EmptyState(
                    fallbackIcon: Icons.favorite_border,
                    title: 'No Favorites Yet',
                    message: 'Start saving your favorite providers to access them quickly',
                    actionText: 'Browse Providers',
                    onAction: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                    },
                  )
                : RefreshIndicator(
                    onRefresh: _loadFavorites,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final provider = _favorites[index];
                        return FadeInWidget(
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          child: FloatingCard(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: Row(
                              children: [
                                // Provider Avatar
                                Hero(
                                  tag: 'provider_avatar_${provider.id}',
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: colors.primaryGradient,
                                    ),
                                    child: provider.profilePicture != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              provider.profilePicture!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 30,
                                                );
                                              },
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Provider Info
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
                                        const SizedBox(height: 4),
                                        RatingWidget(
                                          rating: provider.rating!,
                                          totalRatings: provider.reviewCount ?? 0,
                                          size: 14,
                                        ),
                                      ],
                                      if (provider.distance != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 12,
                                              color: colors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${provider.distance!.toStringAsFixed(1)} km away',
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
                                // Remove Favorite Button
                                IconButton(
                                  icon: Icon(
                                    Icons.favorite,
                                    color: colors.errorColor,
                                  ),
                                  onPressed: () => _removeFavorite(provider),
                                  tooltip: 'Remove from favorites',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
