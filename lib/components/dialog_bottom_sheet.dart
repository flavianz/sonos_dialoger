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

Future<T?> openDialogOrBottomSheet<T>(context, Widget child) async {
  final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;
  if (isScreenWide) {
    return showDialog<T>(
      context: context,
      builder:
          (BuildContext context) => Dialog(
            child: DialogOrBottomSheet(widget: Center(child: Text("asdas"))),
          ),
    );
  } else {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => FractionallySizedBox(
            heightFactor: 0.7,
            child: DialogOrBottomSheet(widget: child),
          ),
    );
  }
}
