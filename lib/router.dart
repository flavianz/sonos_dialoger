import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

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
