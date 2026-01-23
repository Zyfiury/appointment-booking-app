import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/provider_image.dart';
import '../../services/provider_image_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_in_widget.dart';
import '../../providers/theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProviderGalleryScreen extends StatefulWidget {
  final String providerId;
  final String providerName;

  const ProviderGalleryScreen({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<ProviderGalleryScreen> createState() => _ProviderGalleryScreenState();
}

class _ProviderGalleryScreenState extends State<ProviderGalleryScreen> {
  final ProviderImageService _imageService = ProviderImageService();
  List<ProviderImage> _images = [];
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _loading = true;
    });

    try {
      final images = await _imageService.getProviderImages(widget.providerId);
      setState(() {
        _images = images;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
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
        title: Text('${widget.providerName}\'s Gallery'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No images yet',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Main Image Viewer
                    Expanded(
                      child: PageView.builder(
                        itemCount: _images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final image = _images[index];
                          return FadeInWidget(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CachedNetworkImage(
                                  imageUrl: image.url,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: colors.cardColor,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: colors.primaryColor,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: colors.cardColor,
                                    child: Icon(
                                      Icons.error_outline,
                                      color: colors.errorColor,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Image Info
                    if (_images.isNotEmpty && _images[_selectedIndex].caption != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _images[_selectedIndex].caption!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Thumbnail Grid
                    Container(
                      height: 100,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          final image = _images[index];
                          final isSelected = index == _selectedIndex;
                          return GestureDetector(
                            onTap: () {
                              // Scroll to image
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.primaryColor
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: CachedNetworkImage(
                                  imageUrl: image.url,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: colors.cardColor,
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: colors.cardColor,
                                    child: Icon(
                                      Icons.image,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Page Indicator
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _images.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _selectedIndex
                                  ? colors.primaryColor
                                  : colors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
