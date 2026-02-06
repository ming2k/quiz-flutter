import 'package:flutter/material.dart';

class BottomSheetHandle extends StatelessWidget {
  final double width;
  final double height;
  final double verticalMargin;
  final Color? color;

  const BottomSheetHandle({
    super.key,
    this.width = 40.0,
    this.height = 4.0,
    this.verticalMargin = 10.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('bottom_sheet_handle'),
      margin: EdgeInsets.symmetric(vertical: verticalMargin),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade300,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
