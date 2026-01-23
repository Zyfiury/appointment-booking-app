import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/favorite_service.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class FavoriteButton extends StatefulWidget {
  final String providerId;
  final double size;
  final Color? color;

  const FavoriteButton({
    super.key,
    required this.providerId,
    this.size = 24,
    this.color,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final FavoriteService _favoriteService = FavoriteService();
  bool _isFavorite = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final isFavorite = await _favoriteService.isFavorite(widget.providerId);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      HapticFeedback.lightImpact();
      await _favoriteService.toggleFavorite(widget.providerId, _isFavorite);
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final colors = AppTheme.getColors(themeProvider.currentTheme);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
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

    if (_loading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.primaryColor,
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleFavorite,
      child: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        size: widget.size,
        color: _isFavorite
            ? (widget.color ?? colors.errorColor)
            : (widget.color ?? colors.textSecondary),
      ),
    );
  }
}
