import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/pages/admin/admin_shift_schedule_page.dart';
import 'package:sonos_dialoger/pages/admin/dialoger_edit_page.dart';
import 'package:sonos_dialoger/pages/admin/dialoger_page.dart';
import 'package:sonos_dialoger/pages/admin/location_details_page.dart';
import 'package:sonos_dialoger/pages/admin/locations_page.dart';
import 'package:sonos_dialoger/pages/admin/payments_page.dart';
import 'package:sonos_dialoger/pages/dialoger/dialoger_payments_page.dart';
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
          path: '/admin/shift-schedules',
          builder: (context, state) => AdminShiftSchedulePage(),
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
          path: '/dialoger/payment/:paymentId/edit',
          builder: (context, state) {
            final paymentId = state.pathParameters['paymentId']!;
            return RegisterPaymentPage(editing: true, id: paymentId);
          },
        ),
        GoRoute(
          path: '/admin/location/:locationId',
          builder: (context, state) {
            final locationId = state.pathParameters['locationId']!;
            return LocationDetailsPage(locationId: locationId);
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
