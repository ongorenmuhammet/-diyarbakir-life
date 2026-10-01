import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sub_page_pop_scope.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/main_navigation_shell.dart';
import '../../features/home/presentation/welcome_location_screen.dart';
import '../../features/businesses/presentation/businesses_list_screen.dart';
import '../../features/businesses/presentation/business_detail_screen.dart';
import '../../features/halisaha/presentation/hali_saha_screen.dart';
import '../../features/news/presentation/news_list_screen.dart';
import '../../features/news/presentation/news_detail_screen.dart';
import '../../features/pharmacies/presentation/pharmacy_screen.dart';
import '../../features/classifieds/presentation/ads_list_screen.dart';
import '../../features/classifieds/presentation/ad_detail_screen.dart';
import '../../features/jobs/presentation/jobs_screen.dart';
import '../../features/jobs/presentation/job_detail_screen.dart';
import '../../features/weather/presentation/weather_forecast_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/prayer_times/presentation/prayer_times_screen.dart';

import '../../features/home/presentation/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
String initialAppLocation = '/splash';

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: initialAppLocation,
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashLocationScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeLocationScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigationShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/businesses',
              builder: (context, state) => const BusinessesListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/news',
              builder: (context, state) => const NewsListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/classifieds',
              builder: (context, state) => const AdsListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/jobs',
              builder: (context, state) => const JobsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/businesses/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SubPagePopScope(child: BusinessDetailScreen(businessId: id));
      },
    ),
    GoRoute(
      path: '/halisaha',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SubPagePopScope(child: HaliSahaScreen()),
    ),
    GoRoute(
      path: '/news/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SubPagePopScope(child: NewsDetailScreen(newsId: id));
      },
    ),
    GoRoute(
      path: '/classifieds/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SubPagePopScope(child: AdDetailScreen(adId: id));
      },
    ),
    GoRoute(
      path: '/jobs/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SubPagePopScope(child: JobDetailScreen(jobId: id));
      },
    ),
    GoRoute(
      path: '/weather',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SubPagePopScope(child: WeatherForecastScreen()),
    ),
    GoRoute(
      path: '/pharmacies',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SubPagePopScope(child: PharmacyScreen()),
    ),
    GoRoute(
      path: '/prayer-times',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SubPagePopScope(child: PrayerTimesScreen()),
    ),
    GoRoute(
      path: '/admin',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SubPagePopScope(child: AdminDashboardScreen()),
    ),
  ],
);
