import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DialogerPage extends ConsumerWidget {
  const DialogerPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(
        horizontal: isScreenWide ? 24 : 8,
        vertical: 12,
      ),
      child: Scaffold(appBar: AppBar(title: Text("Dialoger")), body: Center()),
    );
  }
}
