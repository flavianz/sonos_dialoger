import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sonos_dialoger/providers/firestore_providers/user_providers.dart';

class QrCodePage extends ConsumerWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final userData = ref.watch(userDataProvider);
    if (userData.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Laden...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (userData.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text("Fehler")),
        body: Center(child: Text("Ups, hier hat etwas nicht geklappt")),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text("Twint QR-Code")),
      body: Center(
        child:
            userData.value!.twintQrCode == null
                ? Text("Du hast keinen persönlichen Twint QR-Code")
                : LayoutBuilder(
                  builder: (context, constraints) {
                    return QrImageView(
                      data: userData.value!.twintQrCode!,
                      version: QrVersions.auto,
                      size:
                          min(constraints.maxWidth, constraints.maxHeight) *
                          0.8,
                    );
                  },
                ),
      ),
    );
  }
}
