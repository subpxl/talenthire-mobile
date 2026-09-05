import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_tab_bar.dart';

class StickyBarDelegate extends SliverPersistentHeaderDelegate {
  StickyBarDelegate({required this.child, required this.extent});

  final Widget child;
  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: AppColors.background,
      elevation: overlapsContent ? 0.6 : 0,
      shadowColor: Colors.black26,
      child: SizedBox(
        height: extent,
        width: double.infinity,
        child: ClipRect(child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickyBarDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}

/// Consistent shell for every main tab screen.
class AppScreenLayout extends StatelessWidget {
  const AppScreenLayout({
    super.key,
    this.title,
    this.tabs,
    this.selectedTabIndex,
    this.onTabChanged,
    this.actions,
    required this.body,
    this.innerTabKey,
    this.showAppBar = true,
  });

  final String? title;
  final List<AppTabItem>? tabs;
  final int? selectedTabIndex;
  final ValueChanged<int>? onTabChanged;
  final List<Widget>? actions;
  final Widget body;
  final Object? innerTabKey;
  final bool showAppBar;

  bool get _hasTabs => tabs != null && tabs!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: showAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: _hasTabs ? 28 : 16,
              title: _hasTabs
                  ? AppTabBar(
                      tabs: tabs!,
                      selectedIndex: selectedTabIndex ?? 0,
                      onChanged: onTabChanged ?? (_) {},
                    )
                  : Text(
                      title ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
              actions: actions,
            )
          : null,
      body: AnimatedSwitcher(
        duration: AppDurations.innerTab,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(innerTabKey ?? title ?? 'body'),
          child: body,
        ),
      ),
    );
  }
}

/// Standard padded scroll body used across tabs.
class AppScrollBody extends StatelessWidget {
  const AppScrollBody({
    super.key,
    required this.child,
    this.padding,
    this.onRefresh,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final resolved = padding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH,
          vertical: AppSpacing.screenV,
        );
    final scrollView = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: resolved.add(
        const EdgeInsets.only(bottom: AppSpacing.scrollBottom),
      ),
      child: child,
    );
    if (onRefresh == null) return scrollView;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh!,
      child: scrollView,
    );
  }
}

/// Paginated job lists: pull-to-refresh, infinite scroll, and a loading footer.
class AppRefreshScrollBody extends StatelessWidget {
  const AppRefreshScrollBody({
    super.key,
    this.leading,
    this.header,
    this.pinnedHeader,
    this.pinnedHeaderExtent = 0,
    required this.itemCount,
    required this.itemBuilder,
    this.onRefresh,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.padding,
    this.empty,
  });

  final List<Widget>? leading;
  final List<Widget>? header;
  final Widget? pinnedHeader;
  final double pinnedHeaderExtent;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;
  final EdgeInsetsGeometry? padding;
  final Widget? empty;

  static const _loadMoreOffset = 420.0;

  @override
  Widget build(BuildContext context) {
    final resolved = padding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH,
          vertical: AppSpacing.screenV,
        );

    Widget list = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (onLoadMore == null || !hasMore || isLoadingMore) return false;
        if (notification is! ScrollUpdateNotification &&
            notification is! OverscrollNotification) {
          return false;
        }
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - _loadMoreOffset) {
          onLoadMore!();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          if (leading != null && leading!.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: leading!,
              ),
            ),
          if (pinnedHeader != null && pinnedHeaderExtent > 0)
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyBarDelegate(
                extent: pinnedHeaderExtent,
                child: pinnedHeader!,
              ),
            ),
          SliverPadding(
            padding: resolved,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...?header,
                if (itemCount == 0 && empty != null) empty!,
              ]),
            ),
          ),
          if (itemCount > 0)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                _horizontal(resolved),
                0,
                _horizontal(resolved),
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  itemBuilder,
                  childCount: itemCount,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.scrollBottom,
              ),
              child: isLoadingMore
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );

    if (onRefresh == null) return list;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh!,
      child: list,
    );
  }

  double _horizontal(EdgeInsetsGeometry padding) {
    if (padding is EdgeInsets) return padding.left;
    return AppSpacing.screenH;
  }
}

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.text, {super.key, this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: context.sectionTitle,
      ),
    );
  }
}

class AppHintBar extends StatelessWidget {
  const AppHintBar(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      color: AppColors.hintBar,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, size: 22),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
            size: 20,
          ),
          onTap: onTap,
        ),
        const Divider(indent: AppSpacing.screenH, endIndent: AppSpacing.screenH),
      ],
    );
  }
}
