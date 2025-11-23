
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget ButtonWrap(double buttonWidth, List<Widget> buttons) {
  if (buttons.isEmpty) {
    return const SizedBox.shrink();
  }
  return Align(
    alignment: Alignment.center,
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: buttons
          .map((btn) => SizedBox(width: buttonWidth, child: btn))
          .toList(growable: false),
    ),
  );
}
