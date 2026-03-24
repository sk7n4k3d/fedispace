import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fedispace/core/image_filters.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Photo filter selection screen.
/// Shows filter preview thumbnails and manual adjustment controls.
class PhotoFiltersPage extends StatefulWidget {
  final String imagePath;

  const PhotoFiltersPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<PhotoFiltersPage> createState() => _PhotoFiltersPageState();
}

class _PhotoFiltersPageState extends State<PhotoFiltersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilterIndex = 0;
  double _filterIntensity = 1.0;
  final ImageAdjustments _adjustments = ImageAdjustments();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filterIntensity = photoFilters[0].defaultIntensity;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ColorFilter? get _combinedFilter {
    final filterCf = photoFilters[_selectedFilterIndex].getColorFilter(_filterIntensity);
    final adjustCf = _adjustments.toColorFilter();

    // If only one is active, return it
    if (filterCf == null && adjustCf == null) return null;
    if (filterCf == null) return adjustCf;
    if (adjustCf == null) return filterCf;

    // Both active — we return the filter one (adjustments applied separately)
    // For simplicity, we return the filter; both are applied as stacked widgets
    return filterCf;
  }

  void _applyAndReturn() {
    Navigator.pop(context, PhotoFilterResult(
      filterIndex: _selectedFilterIndex,
      filterIntensity: _filterIntensity,
      adjustments: _adjustments,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.imagePath);

    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [CyberpunkTheme.neonCyan, CyberpunkTheme.neonPink],
          ).createShader(bounds),
          child: Text(
            'FILTERS',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _applyAndReturn,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CyberpunkTheme.neonCyan, Color(0xFF0077CC)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main image preview
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildFilteredImage(file, fullSize: true),
                ),
              ),
            ),
          ),

          // Intensity slider (only if a filter is selected)
          if (_selectedFilterIndex > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: CyberpunkTheme.textTertiary, size: 16),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: CyberpunkTheme.neonCyan,
                        inactiveTrackColor: CyberpunkTheme.borderDark,
                        thumbColor: CyberpunkTheme.neonCyan,
                        overlayColor: CyberpunkTheme.neonCyan.withOpacity(0.15),
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _filterIntensity,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (v) => setState(() => _filterIntensity = v),
                      ),
                    ),
                  ),
                  Text(
                    '${(_filterIntensity * 100).round()}%',
                    style: const TextStyle(
                      color: CyberpunkTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tab bar for Filters / Adjust
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: CyberpunkTheme.borderDark, width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: CyberpunkTheme.neonCyan,
              indicatorWeight: 2,
              labelColor: CyberpunkTheme.neonCyan,
              unselectedLabelColor: CyberpunkTheme.textTertiary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Filters'),
                Tab(text: 'Adjust'),
              ],
            ),
          ),

          // Tab content
          SizedBox(
            height: 120,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFiltersTab(file),
                _buildAdjustTab(),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildFilteredImage(File file, {bool fullSize = false}) {
    Widget image = Image.file(
      file,
      fit: BoxFit.contain,
      width: fullSize ? double.infinity : null,
    );

    // Apply filter
    final filterCf = photoFilters[_selectedFilterIndex].getColorFilter(_filterIntensity);
    if (filterCf != null) {
      image = ColorFiltered(colorFilter: filterCf, child: image);
    }

    // Apply adjustments
    final adjustCf = _adjustments.toColorFilter();
    if (adjustCf != null) {
      image = ColorFiltered(colorFilter: adjustCf, child: image);
    }

    return image;
  }

  Widget _buildFiltersTab(File file) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: photoFilters.length,
      itemBuilder: (context, index) {
        final filter = photoFilters[index];
        final isSelected = index == _selectedFilterIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFilterIndex = index;
              _filterIntensity = filter.defaultIntensity;
            });
          },
          child: Container(
            width: 76,
            margin: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                // Thumbnail
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (filter.isCyberpunk
                              ? CyberpunkTheme.neonPink
                              : CyberpunkTheme.neonCyan)
                          : CyberpunkTheme.borderDark,
                      width: isSelected ? 2 : 0.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (filter.isCyberpunk
                                      ? CyberpunkTheme.neonPink
                                      : CyberpunkTheme.neonCyan)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildThumbFiltered(file, filter),
                  ),
                ),
                const SizedBox(height: 6),
                // Name
                Text(
                  filter.name,
                  style: TextStyle(
                    color: isSelected
                        ? (filter.isCyberpunk
                            ? CyberpunkTheme.neonPink
                            : CyberpunkTheme.neonCyan)
                        : CyberpunkTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbFiltered(File file, ImageFilterPreset filter) {
    Widget thumb = Image.file(file, fit: BoxFit.cover, width: 64, height: 64);
    final cf = filter.getColorFilter(filter.defaultIntensity);
    if (cf != null) {
      thumb = ColorFiltered(colorFilter: cf, child: thumb);
    }
    return thumb;
  }

  Widget _buildAdjustTab() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildAdjustSlider(
            icon: Icons.brightness_6_rounded,
            label: 'Brightness',
            value: _adjustments.brightness,
            onChanged: (v) => setState(() => _adjustments.brightness = v),
          ),
          const SizedBox(width: 20),
          _buildAdjustSlider(
            icon: Icons.contrast_rounded,
            label: 'Contrast',
            value: _adjustments.contrast,
            onChanged: (v) => setState(() => _adjustments.contrast = v),
          ),
          const SizedBox(width: 20),
          _buildAdjustSlider(
            icon: Icons.palette_rounded,
            label: 'Saturation',
            value: _adjustments.saturation,
            onChanged: (v) => setState(() => _adjustments.saturation = v),
          ),
          const SizedBox(width: 20),
          _buildAdjustSlider(
            icon: Icons.wb_sunny_rounded,
            label: 'Warmth',
            value: _adjustments.warmth,
            onChanged: (v) => setState(() => _adjustments.warmth = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustSlider({
    required IconData icon,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: CyberpunkTheme.textSecondary, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: CyberpunkTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: CyberpunkTheme.neonCyan,
              inactiveTrackColor: CyberpunkTheme.borderDark,
              thumbColor: CyberpunkTheme.neonCyan,
              overlayColor: CyberpunkTheme.neonCyan.withOpacity(0.15),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: value,
              min: -100,
              max: 100,
              onChanged: onChanged,
            ),
          ),
          Text(
            '${value.round()}',
            style: const TextStyle(
              color: CyberpunkTheme.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Result returned from the photo filters page.
class PhotoFilterResult {
  final int filterIndex;
  final double filterIntensity;
  final ImageAdjustments adjustments;

  const PhotoFilterResult({
    required this.filterIndex,
    required this.filterIntensity,
    required this.adjustments,
  });

  /// Get combined ColorFilter for rendering.
  ColorFilter? get filterColorFilter =>
      photoFilters[filterIndex].getColorFilter(filterIntensity);

  /// Get adjustments ColorFilter.
  ColorFilter? get adjustmentsColorFilter => adjustments.toColorFilter();

  /// Check if any filter/adjustment is applied.
  bool get hasChanges => filterIndex > 0 || adjustments.hasChanges;
}
