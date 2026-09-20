import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_shell.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/notifications_screen.dart';
import '../../features/gifts/presentation/screens/gifts_screen.dart';
import '../../features/gifts/presentation/screens/gift_configurator_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/events/presentation/screens/event_form_screen.dart';
import '../../features/events/presentation/screens/b2c_event_form_screen.dart';
import '../../features/projects/presentation/screens/projects_screen.dart';
import '../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/terms/presentation/screens/terms_screen.dart';
import '../../features/admin/presentation/screens/admin_requests_screen.dart';
import '../../features/admin/presentation/screens/admin_request_detail_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/phone_verification_screen.dart';
import '../services/auth_service.dart';
import '../services/shared_prefs_service.dart';
import '../models/app_user.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final loading = authState.isLoading;
      if (loading) return null;

      final user = authState.valueOrNull;
      final isAuth = user != null;
      final loc = state.matchedLocation;

      final publicRoutes = [
        '/splash',
        '/onboarding',
        '/login',
        '/register',
      ];

      // Always resolve splash explicitly so we don't leave unauthenticated
      // users parked on the loading screen forever.
      if (loc == '/splash') {
        final prefs = ref.read(sharedPreferencesProvider);
        final onboardingDone = prefs.getBool('onboarding_done') ?? false;

        if (!onboardingDone) return '/onboarding';
        if (!isAuth) return '/login';

        if (user.role == UserRole.customer) {
          final isEmailVerified =
              ref.read(authServiceProvider).isEmailVerified();
          if (!isEmailVerified) return '/verify-email';
        }

        return user.role == UserRole.admin ? '/admin' : '/home';
      }

      // 1. If not authenticated, force redirect to login unless already on a public route
      if (!isAuth) {
        return publicRoutes.contains(loc) ? null : '/login';
      }

      // 2. If authenticated, check email verification (customers only)
      if (user.role == UserRole.customer) {
        final isEmailVerified = ref.read(authServiceProvider).isEmailVerified();
        if (!isEmailVerified) {
          // If not verified, only allow /verify-email
          return loc == '/verify-email' ? null : '/verify-email';
        }
        // If verified, don't allow staying on /verify-email
        if (loc == '/verify-email') return '/home';
      }

      // 3. Prevent authenticated users from accessing public routes (except splash)
      if (publicRoutes.contains(loc) &&
          loc != '/splash' &&
          loc != '/verify-email') {
        return user.role == UserRole.admin ? '/admin' : '/home';
      }

      // 4. B2B Restricted Routes
      if (loc.startsWith('/gifts') && user.clientType.isB2C) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/verify-email',
          builder: (_, __) => const EmailVerificationScreen()),
      GoRoute(
        path: '/verify-phone',
        builder: (_, state) => PhoneVerificationScreen(
            phoneNumber: state.uri.queryParameters['phone'] ?? ''),
      ),

      // Admin
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminRequestsScreen(),
        routes: [
          GoRoute(
            path: 'request/:id',
            builder: (_, s) =>
                AdminRequestDetailScreen(requestId: s.pathParameters['id']!),
          ),
        ],
      ),

      // Customer shell with bottom nav
      ShellRoute(
        builder: (_, __, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(
            path: '/gifts',
            builder: (_, __) => const GiftsScreen(),
            routes: [
              GoRoute(
                path: ':category',
                builder: (_, s) => GiftConfiguratorScreen(
                    category: s.pathParameters['category']!),
              ),
            ],
          ),
          GoRoute(
            path: '/events',
            builder: (_, __) => const EventsScreen(),
            routes: [
              GoRoute(
                path: 'b2c',
                builder: (_, s) => B2cEventFormScreen(
                  initialCategory: s.uri.queryParameters['category'],
                ),
              ),
              GoRoute(
                path: ':type',
                builder: (_, s) =>
                    EventFormScreen(eventType: s.pathParameters['type']!),
              ),
            ],
          ),
          GoRoute(
            path: '/projects',
            builder: (_, s) {
              return const ProjectsScreen(initialTab: 0);
            },
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    ProjectDetailScreen(requestId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFEF5350)),
            const SizedBox(height: 16),
            const Text('Page introuvable',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(state.error?.message ?? '',
                style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/home'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
});
