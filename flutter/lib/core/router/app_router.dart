// lib/core/router/app_router.dart
//
// GoRouter configuration for Log-O-Logu.
//
// Route guard logic (redirect callback):
//   • If AuthStatus.initializing → stay on splash (null = no redirect)
//   • If unauthenticated → redirect to /login
//   • If authenticated on /login → redirect to role home
//   • If authenticated on wrong role route → redirect to correct role home
//   • If unknown role → redirect to /error

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:log_o_logu/features/auth/domain/auth_service.dart';
import 'package:log_o_logu/features/auth/domain/user_model.dart';
import 'package:log_o_logu/features/auth/presentation/login_screen.dart';
import 'package:log_o_logu/features/auth/presentation/oauth_details_screen.dart';
import 'package:log_o_logu/features/home/presentation/resident_home_screen.dart';
import 'package:log_o_logu/features/home/presentation/guard/guard_shell.dart';
import 'package:log_o_logu/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:log_o_logu/features/invite/presentation/create_invite_screen.dart';
import 'package:log_o_logu/features/invite/presentation/visitor_history_screen.dart';
import 'package:log_o_logu/core/presentation/error_screen.dart';
import 'package:log_o_logu/features/auth/presentation/waiting_approval_screen.dart';
import 'package:log_o_logu/features/auth/presentation/profile_completion_screen.dart';
import 'package:log_o_logu/features/admin/presentation/admin_approval_screen.dart';

// ─── Route name constants ────────────────────────────────────────────────────

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const oauthDetails = '/oauth-details';
  static const resident = '/resident';
  static const guard = '/guard';
  static const admin = '/admin';
  static const createInvite = '/create-invite';
  static const visitorHistory = '/history';
  static const waitingApproval = '/waiting-approval';
  static const completeProfile = '/complete-profile';
  static const adminApprovals = '/admin-approvals';
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
      final isOnAuthPage = loc == AppRoutes.login;

      // ── 2. Unauthenticated → always send to login ────────────────────────
      if (!isAuthenticated) {
        return isOnAuthPage ? null : AppRoutes.login;
      }

      if (user?.isOnboardingPending == true) {
        return loc == AppRoutes.oauthDetails ? null : AppRoutes.oauthDetails;
      }

      // ── 3. Authenticated on auth pages → redirect to role home ───────────
      if (isOnAuthPage || loc == AppRoutes.splash) {
        if (user == null) return AppRoutes.error;
        if (user.requiresProfileCompletion) {
          return AppRoutes.completeProfile;
        }
        if (user.role != UserRole.admin && !user.isApproved) {
          return AppRoutes.waitingApproval;
        }
        return AppRoutes.homeFor(user.role);
      }

      // ── 4. Authenticated but accessing wrong role's route ────────────────
      if (user == null) return AppRoutes.login;

      final correctHome = AppRoutes.homeFor(user.role);

      if (user.requiresProfileCompletion) {
        return loc == AppRoutes.completeProfile
            ? null
            : AppRoutes.completeProfile;
      }

      if (loc == AppRoutes.completeProfile) {
        if (user.role != UserRole.admin && !user.isApproved) {
          return AppRoutes.waitingApproval;
        }
        return correctHome;
      }

      if (user.role != UserRole.admin && !user.isApproved) {
        return loc == AppRoutes.waitingApproval
            ? null
            : AppRoutes.waitingApproval;
      }

      if (loc == AppRoutes.waitingApproval) {
        return correctHome;
      }

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
        path: AppRoutes.oauthDetails,
        builder: (context, state) => const OAuthDetailsScreen(),
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
      GoRoute(
        path: AppRoutes.waitingApproval,
        builder: (context, state) => const WaitingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminApprovals,
        builder: (context, state) => const AdminApprovalScreen(),
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
