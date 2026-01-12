import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/providers/firestore_providers/user_providers.dart';
import 'package:flutter/scheduler.dart';

import '../core/user.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final data = ref.watch(userDataProvider);
    if (data.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (data.hasError) {
      return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
    }
    final userData = data.value;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (userData == null) {
        context.go("/auth");
      } else if (userData.role == UserRole.admin) {
        context.go("/admin/payments");
      } else if (userData.role == UserRole.coach ||
          userData.role == UserRole.dialog) {
        context.go("/dialoger/payments");
      } else {
        // should never be the case
        context.go("/auth");
      }
    });
    return Center(child: CircularProgressIndicator());
  }
}
