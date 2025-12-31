import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/pages/admin/admin_schedule_page.dart';
import 'package:sonos_dialoger/pages/admin/admin_settings_page.dart';
import 'package:sonos_dialoger/pages/admin/dialoger_details_page.dart';
import 'package:sonos_dialoger/pages/admin/dialoger_edit_page.dart';
import 'package:sonos_dialoger/pages/admin/dialoger_page.dart';
import 'package:sonos_dialoger/pages/admin/location_details_page.dart';
import 'package:sonos_dialoger/pages/admin/location_edit_page.dart';
import 'package:sonos_dialoger/pages/admin/locations_page.dart';
import 'package:sonos_dialoger/pages/admin/payment_details_page.dart';
import 'package:sonos_dialoger/pages/admin/payments_page.dart';
import 'package:sonos_dialoger/pages/admin/schedule_review_page.dart';
import 'package:sonos_dialoger/pages/coach/coach_schedule_page.dart';
import 'package:sonos_dialoger/pages/coach/coach_schedule_personnel_assignment_page.dart';
import 'package:sonos_dialoger/pages/coach/create_schedule_page.dart';
import 'package:sonos_dialoger/pages/dialoger/dialoger_payments_page.dart';
import 'package:sonos_dialoger/pages/dialoger/dialoger_schedule_page.dart';
import 'package:sonos_dialoger/pages/dialoger/dialoger_stats_page.dart';
import 'package:sonos_dialoger/pages/dialoger/qr_code_page.dart';
import 'package:sonos_dialoger/pages/dialoger/register_payment_page.dart';
import 'package:sonos_dialoger/pages/home_page.dart';
import 'package:sonos_dialoger/utils.dart';

import 'app.dart';

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return App(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => HomePage()),
        GoRoute(
          path: '/admin/dialoger',
          builder: (context, state) => DialogerPage(),
        ),
        GoRoute(
          path: '/admin/dialog/:dialogerId',
          builder: (context, state) {
            final dialogerId = state.pathParameters['dialogerId']!;
            return DialogerDetailsPage(dialogerId: dialogerId);
          },
        ),
        GoRoute(
          path: '/admin/dialog/:dialogerId/edit',
          builder: (context, state) {
            final dialogerId = state.pathParameters['dialogerId']!;
            return DialogerEditPage(userId: dialogerId);
          },
        ),
        GoRoute(
          path: '/admin/dialoger/new',
          builder: (context, state) {
            return DialogerEditPage(
              userId: generateFirestoreKey(),
              creating: true,
            );
          },
        ),
        GoRoute(
          path: '/admin/payments',
          builder: (context, state) => PaymentsPage(),
        ),
        GoRoute(
          path: '/admin/locations',
          builder: (context, state) => LocationsPage(),
        ),
        GoRoute(
          path: '/admin/schedules',
          builder: (context, state) => AdminSchedulePage(),
        ),
        GoRoute(
          path: '/dialoger/payments',
          builder: (context, state) => DialogerPaymentsPage(),
        ),
        GoRoute(
          path: '/dialoger/payments/register',
          builder: (context, state) => RegisterPaymentPage(),
        ),
        GoRoute(
          path: '/coach/schedules/new/:year/:month/:day',
          builder: (context, state) {
            final year =
                int.tryParse(state.pathParameters['year'] ?? "") ??
                DateTime.now().year;
            final month =
                int.tryParse(state.pathParameters['month'] ?? "") ??
                DateTime.now().month;
            final day =
                int.tryParse(state.pathParameters['day'] ?? "") ??
                DateTime.now().day;
            return CreateSchedulePage(date: DateTime(year, month, day));
          },
        ),
        GoRoute(
          path: '/coach/schedules',
          builder: (context, state) => CoachSchedulePage(),
        ),
        GoRoute(
          path: '/dialog/schedules',
          builder: (context, state) => DialogerSchedulePage(),
        ),
        GoRoute(
          path: '/dialoger/payment/:paymentId/edit',
          builder: (context, state) {
            final paymentId = state.pathParameters['paymentId']!;
            return RegisterPaymentPage(editing: true, id: paymentId);
          },
        ),
        GoRoute(
          path: '/admin/payment/:paymentId',
          builder: (context, state) {
            final paymentId = state.pathParameters['paymentId']!;
            return PaymentDetailsPage(paymentId: paymentId);
          },
        ),
        GoRoute(
          path: '/admin/location/:locationId',
          builder: (context, state) {
            final locationId = state.pathParameters['locationId']!;
            return LocationDetailsPage(locationId: locationId);
          },
        ),
        GoRoute(
          path: '/admin/location/:locationId/edit',
          builder: (context, state) {
            final locationId = state.pathParameters['locationId']!;
            return LocationEditPage(locationId: locationId);
          },
        ),
        GoRoute(
          path: '/admin/locations/new',
          builder: (context, state) {
            return LocationEditPage(isCreate: true);
          },
        ),
        GoRoute(
          path: '/admin/schedule-review/:scheduleId',
          builder: (context, state) {
            final scheduleId = state.pathParameters['scheduleId']!;
            return ScheduleReviewPage(scheduleId: scheduleId);
          },
        ),
        GoRoute(
          path: '/coach/schedule/personnel_assignment/:scheduleId',
          builder: (context, state) {
            final scheduleId = state.pathParameters['scheduleId']!;
            return CoachSchedulePersonnelAssignmentPage(scheduleId: scheduleId);
          },
        ),
        GoRoute(
          path: '/admin/settings',
          builder: (context, state) {
            return AdminSettingsPage();
          },
        ),
        GoRoute(
          path: '/dialog/qr',
          builder: (context, state) {
            return QrCodePage();
          },
        ),
        GoRoute(
          path: '/dialoger/stats',
          builder: (context, state) {
            return DialogerStatsPage();
          },
        ),
      ],
    ),
    GoRoute(
      path: "/auth",
      builder: (context, state) {
        return SignInScreen(
          actions: [
            AuthStateChangeAction<SignedIn>((context, state) {
              context.go('/');
            }),
            AuthStateChangeAction<UserCreated>((context, state) {
              context.go('/');
            }),
          ],
        );
      },
    ),
  ],
);
