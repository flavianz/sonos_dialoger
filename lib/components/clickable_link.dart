import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClickableLink extends StatelessWidget {
  final String link;
  final String? label;

  const ClickableLink({super.key, required this.link, this.label});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(Icons.open_in_new),
      onPressed: () async {
        if (!await launchUrl(
          Uri.parse(link),
          mode: LaunchMode.externalApplication,
        )) {
          throw Exception('Could not launch link');
        }
      },
      label: Text(label != null ? label! : link),
    );
  }
}
