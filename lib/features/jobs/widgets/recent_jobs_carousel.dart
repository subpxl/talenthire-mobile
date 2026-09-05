import 'dart:math';

import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/features/jobs/data/job_discovery_presets.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecentJobsCarousel extends StatefulWidget {
  const RecentJobsCarousel({super.key});

  @override
  State<RecentJobsCarousel> createState() => _RecentJobsCarouselState();
}

class _RecentJobsCarouselState extends State<RecentJobsCarousel> {
  static const _loopBasePage = 10000;

  late final PageController _pageController;
  List<_CarouselSlide>? _slides;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.82,
      initialPage: _loopBasePage,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _slides ??= _buildSlides();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_CarouselSlide> _buildSlides() {
    final jobs = context.read<AppState>().jobs;
    final listings = jobs.isEmpty
        ? jobListings.take(5).toList()
        : [
            for (var i = 0; i < jobs.length; i++)
              JobListing.fromJob(jobs[i], i),
          ];
    final shuffled = [...listings]..shuffle(Random());
    return [
      for (var i = 0; i < jobDiscoveryPresets.length; i++)
        _CarouselSlide(
          preset: jobDiscoveryPresets[i],
          listing: shuffled[i % shuffled.length],
        ),
    ];
  }

  void _openJobsWithPreset(JobDiscoveryPreset preset) {
    context.read<AppState>().openJobsTabWithFilter(preset.toFilter());
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    if (slides == null || slides.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('Recent jobs'),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 196,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index % slides.length);
            },
            itemBuilder: (context, index) {
              final slide = slides[index % slides.length];
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _CarouselCard(
                  slide: slide,
                  onTap: () => _openJobsWithPreset(slide.preset),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: AppDurations.innerTab,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CarouselSlide {
  const _CarouselSlide({required this.preset, required this.listing});

  final JobDiscoveryPreset preset;
  final JobListing listing;
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.slide, required this.onTap});

  final _CarouselSlide slide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlaceholderProfileImage(
              fill: true,
              imageIndex: slide.listing.imageIndex,
              imageUrl: slide.listing.imageUrl,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    slide.listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    slide.listing.location,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
