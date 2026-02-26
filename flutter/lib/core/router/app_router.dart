// lib/core/router/app_router.dart
//
// GoRouter configuration for Log-O-Logu.
//
// Route guard logic (redirect callback):
//   • If AuthStatus.initializing → stay on splash (null = no redirect)
//   • If unauthenticated → redirect to /login
//   • If authenticated on /login or /register → redirect to role home
//   • If authenticated on wrong role route → redirect to correct role home
//   • If unknown role → redirect to /error

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/auth/domain/user_model.dart';
import 'package:log_o_logu/features/auth/presentation/login_screen.dart';
import 'package:log_o_logu/features/auth/presentation/register_screen.dart';
import 'package:log_o_logu/features/home/presentation/resident_home_screen.dart';
import 'package:log_o_logu/features/home/presentation/guard/guard_shell.dart';
import 'package:log_o_logu/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:log_o_logu/features/invite/presentation/create_invite_screen.dart';
import 'package:log_o_logu/features/invite/presentation/visitor_history_screen.dart';
import 'package:log_o_logu/core/presentation/error_screen.dart';

// ─── Route name constants ────────────────────────────────────────────────────

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const resident = '/resident';
  static const guard = '/guard';
  static const admin = '/admin';
  static const createInvite = '/create-invite';
  static const visitorHistory = '/history';
  static const error = '/error';

  /// Returns the home path for a given [UserRole].
  static String homeFor(UserRole role) {
    switch (role) {
      case UserRole.resident:
        return resident;
      case UserRole.guard:
        return guard;
      case UserRole.admin:
        return admin;
    }
  }
}

// ─── Router factory ──────────────────────────────────────────────────────────

GoRouter createAppRouter(AuthService authService) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authService,
    redirect: (BuildContext context, GoRouterState state) {
      final status = authService.status;
      final user = authService.currentUser;
      final loc = state.matchedLocation;

      // ── 1. Still initializing — show splash, no redirect yet ─────────────
      if (status == AuthStatus.initializing) return null;

      final isAuthenticated = status == AuthStatus.authenticated;
      final isOnAuthPage = loc == AppRoutes.login || loc == AppRoutes.register;

      // ── 2. Unauthenticated → always send to login ────────────────────────
      if (!isAuthenticated) {
        return isOnAuthPage ? null : AppRoutes.login;
      }

      // ── 3. Authenticated on auth pages → redirect to role home ───────────
      if (isOnAuthPage || loc == AppRoutes.splash) {
        if (user == null) return AppRoutes.error;
        return AppRoutes.homeFor(user.role);
      }

      // ── 4. Authenticated but accessing wrong role's route ────────────────
      if (user == null) return AppRoutes.login;

      final correctHome = AppRoutes.homeFor(user.role);

      // Guard only allowed on /guard, resident on /resident, admin on /admin
      final protectedRoutes = {
        AppRoutes.resident,
        AppRoutes.guard,
        AppRoutes.admin,
      };

      if (protectedRoutes.contains(loc) && loc != correctHome) {
        return correctHome;
      }

      // ── 5. All good — no redirect ─────────────────────────────────────────
      return null;
    },
    routes: [
      // Splash — shown briefly while auth resolves
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashPage(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Role-specific home routes
      GoRoute(
        path: AppRoutes.resident,
        builder: (context, state) => const ResidentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.guard,
        builder: (context, state) => const GuardShell(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.createInvite,
        builder: (context, state) => const CreateInviteScreen(),
      ),
      GoRoute(
        path: AppRoutes.visitorHistory,
        builder: (context, state) => const VisitorHistoryScreen(),
      ),

      // Error fallback
      GoRoute(
        path: AppRoutes.error,
        builder: (context, state) => ErrorScreen(
          message: state.uri.queryParameters['message'],
        ),
      ),
    ],

    // GoRouter-level error page
    errorBuilder: (context, state) => ErrorScreen(
      message: state.error?.toString(),
    ),
  );
}

// ─── Internal splash page (only shown during AuthStatus.initializing) ────────

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.domain_verification_rounded,
              size: 100,
              color: Colors.black,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.black),
          ],
        ),
      ),
    );
  }
}
