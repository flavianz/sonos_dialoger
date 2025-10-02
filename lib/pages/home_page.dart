import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/app.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final data = ref.watch(userDataProvider).value?.data() ?? {};
    return Center(child: Text("${data["first"]} ${data["last"]}"));
  }
}
