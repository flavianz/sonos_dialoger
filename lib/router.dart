import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/pages/dialoger/dialoger_payments_page.dart';
import 'package:sonos_dialoger/pages/dialoger_edit_page.dart';
import 'package:sonos_dialoger/pages/dialoger_page.dart';
import 'package:sonos_dialoger/pages/payments_page.dart';
import 'package:sonos_dialoger/utils.dart';

import 'app.dart';

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return App(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Center(child: Text("home")),
        ),
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
          path: '/dialoger/payments',
          builder: (context, state) => DialogerPaymentsPage(),
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
