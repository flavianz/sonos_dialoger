import 'package:flutter/material.dart';

class DialogOrBottomSheet extends StatefulWidget {
  final Widget widget;

  const DialogOrBottomSheet({super.key, required this.widget});

  @override
  DialogOrBottomSheetState createState() => DialogOrBottomSheetState();
}

class DialogOrBottomSheetState extends State<DialogOrBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 800),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: widget,
      ),
    );
  }
}

void openDialogOrBottomSheet(context, Widget child) async {
  final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;
  if (isScreenWide) {
    await showDialog<String>(
      context: context,
      builder:
          (BuildContext context) =>
              Dialog(child: DialogOrBottomSheet(widget: child)),
    );
  } else {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Allows modal to expand beyond default limits
      builder:
          (context) => FractionallySizedBox(
            heightFactor: 0.7, // 90% of screen height
            child: DialogOrBottomSheet(widget: child),
          ),
    );
  }
}
