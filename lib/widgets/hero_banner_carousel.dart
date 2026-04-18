import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/banner_model.dart';
import '../config/theme.dart';
import 'app_image.dart';
import 'dart:async';

class HeroBannerCarousel extends ConsumerStatefulWidget {
  final List<BannerModel> banners;
  final Function(String?)? onBannerTap;
  final double height;
  final bool showTag;

  const HeroBannerCarousel({
    super.key,
    required this.banners,
    this.onBannerTap,
    this.height = 450, // Slightly increased for more impact
    this.showTag = true,
  });

  @override
  ConsumerState<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends ConsumerState<HeroBannerCarousel> {
  late final PageController _controller;
  int _currentPage = 0;
  Timer? _timer;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    // Start at a high multiple of the banners length for infinite-like looping
    final initialPage = widget.banners.length > 1 ? (5000 ~/ widget.banners.length) * widget.banners.length : 0;
    _currentPage = initialPage;
    _controller = PageController(
      viewportFraction: widget.banners.length > 1 ? 0.85 : 1.0,
      initialPage: initialPage,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 7), (_) {
        if (!mounted || _isHovered) return;
        _controller.nextPage(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.fastOutSlowIn,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: SizedBox(
            height: widget.height,
            child: RepaintBoundary(
              child: PageView.builder(
                controller: _controller,
                clipBehavior: Clip.none, // Allow shadows to bleed out slightly to fix 5px overflow
                itemCount: widget.banners.length > 1 ? 10000 : 1, // Large number for looping
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                _startTimer();
              },
              itemBuilder: (context, index) {
                final bannerIndex = index % widget.banners.length;
                final banner = widget.banners[bannerIndex];
                
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double pageOffset = 0;
                    if (_controller.position.haveDimensions) {
                      pageOffset = _controller.page! - index;
                    } else {
                      pageOffset = (_currentPage - index).toDouble();
                    }
                    
                    // Clamping offset for visuals to prevent extreme values during jumps
                    final double parallaxOffset = pageOffset * 150.0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: GestureDetector(
                        onTap: () => widget.onBannerTap?.call(banner.linkUrl),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background image with parallax and scaling
                              if (banner.imagePath != null)
                                Transform.translate(
                                  offset: Offset(parallaxOffset, 0),
                                  child: Transform.scale(
                                    scale: 1.1 + (pageOffset.abs() * -0.1), // Subtle scale-in effect
                                    child: AppImage(
                                      path: banner.imagePath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              
                              // Sophisticated Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.85),
                                      Colors.black.withValues(alpha: 0.4),
                                      Colors.black.withValues(alpha: 0.1),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.4, 0.7, 1.0],
                                  ),
                                ),
                              ),

                              // Content overlay
                              Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, boxConstraints) {
                                    final contentWidth = boxConstraints.maxWidth;
                                    final isSmallContent = contentWidth < 350;
                                    
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: isSmallContent ? 60 : 100,
                                          right: 4,
                                        ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: RepaintBoundary(
                                          child: _BannerContent(
                                            banner: banner,
                                            showTag: widget.showTag,
                                            pageOffset: pageOffset,
                                            onTap: () => widget.onBannerTap?.call(banner.linkUrl),
                                            maxWidth: contentWidth,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Decorative floating leaf (Top Right)
                              _FloatingDecoration(
                                pageOffset: pageOffset,
                                top: 40,
                                right: 40,
                                icon: Icons.eco_rounded,
                                size: 80,
                                opacity: 0.15,
                                rotation: 0.5,
                              ),

                              // Decorative floating leaf (Bottom Right)
                              _FloatingDecoration(
                                pageOffset: pageOffset,
                                bottom: 60,
                                right: 100,
                                icon: Icons.filter_vintage_rounded,
                                size: 100,
                                opacity: 0.1,
                                rotation: -0.3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
        
        // Premium Indicators
        if (widget.banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.banners.length,
                (i) => _Indicator(
                  isActive: (_currentPage % widget.banners.length) == i,
                  onTap: () {
                    // Find the nearest page for this index to animate to
                    final currentBase = (_currentPage ~/ widget.banners.length) * widget.banners.length;
                    _controller.animateToPage(
                      currentBase + i,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.fastOutSlowIn,
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerContent extends StatelessWidget {
  final BannerModel banner;
  final bool showTag;
  final double pageOffset;

  final VoidCallback? onTap;
  
  final double maxWidth;
  
  const _BannerContent({
    required this.banner,
    required this.showTag,
    required this.pageOffset,
    required this.maxWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = maxWidth < 350;
    final isTiny = maxWidth < 280;
    
    // Smoother fade logic: keep it fully visible until 0.5 offset, then fade out
    final double opacity = (1.0 - (pageOffset.abs() - 0.3).clamp(0.0, 1.0) * 1.5).clamp(0.0, 1.0);
    final double xTranslation = pageOffset * (isSmall ? 30.0 : 60.0);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(-xTranslation, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showTag)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 10 : 16, 
                  vertical: isSmall ? 4 : 8
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'PREMIUM QUALITY',
                  style: GoogleFonts.outfit(
                    fontSize: isSmall ? 8 : 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: isSmall ? 1.5 : 3.0,
                  ),
                ),
              ),
            SizedBox(height: isSmall ? 12 : 24),
            Text(
              banner.title ?? 'Fresh Harvest',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.philosopher(
                fontSize: isTiny ? 32 : (isSmall ? 40 : 56),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1, // Increased from 1.0 to prevent descender cutting
                letterSpacing: -1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 10),
                    blurRadius: 30,
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmall ? 8 : 16),
            if (banner.subtitle != null)
              Container(
                constraints: BoxConstraints(maxWidth: isSmall ? 250 : 450),
                child: Text(
                  banner.subtitle!,
                  maxLines: isSmall ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: isSmall ? 14 : 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ),
            SizedBox(height: isSmall ? 20 : 40),
            _CTAButton(
              onTap: onTap ?? () {},
              isSmall: isSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CTAButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isSmall;
  const _CTAButton({required this.onTap, this.isSmall = false});

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: Colors.transparent,
          child: AnimatedScale(
            scale: _isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: widget.isSmall ? 24 : 40, 
                vertical: widget.isSmall ? 12 : 20
              ),
              decoration: BoxDecoration(
                gradient: _isHovered 
                  ? LinearGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0.9)])
                  : null,
                color: _isHovered ? null : Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isHovered ? 0.3 : 0.15),
                    blurRadius: _isHovered ? 30 : 20,
                    offset: Offset(0, _isHovered ? 15 : 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'DISCOVER NOW',
                        style: GoogleFonts.outfit(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: widget.isSmall ? 11 : 14,
                          letterSpacing: widget.isSmall ? 1.0 : 2.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: widget.isSmall ? 8 : 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(_isHovered ? 8 : 0, 0, 0),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingDecoration extends StatelessWidget {
  final double pageOffset;
  final double? top, bottom, right;
  final IconData icon;
  final double size;
  final double opacity;
  final double rotation;

  const _FloatingDecoration({
    required this.pageOffset,
    this.top,
    this.bottom,
    this.right,
    required this.icon,
    required this.size,
    required this.opacity,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      right: right,
      child: Transform.rotate(
        angle: rotation + (pageOffset * 0.5),
        child: Transform.translate(
          offset: Offset(pageOffset * 50, pageOffset * -30),
          child: Icon(
            icon,
            size: size,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _Indicator({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: isActive ? 40 : 10,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.outline,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
      ),
    );
  }
}

