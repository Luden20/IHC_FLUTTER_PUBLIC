import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';

class ShinnyButton23 extends StatelessWidget {
  const ShinnyButton23({
    super.key,
    required this.onPressed,
    required this.text,
    this.icons,
    this.isLoading = false,
    this.expand = true,
    this.confetti=false,
    this.width,
    this.height = 44,
    this.padding,
  });

  final FutureOr<void> Function()? onPressed;
  final String text;
  final IconData? icons;
  final bool isLoading;
  final bool expand;
  final bool confetti;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final resolvedPadding =
    (padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14))
        .resolve(Directionality.of(context));

    final textStyle = TextStyle(
      fontSize: 16,
      color: colorScheme.onPrimary,
      fontWeight: FontWeight.w800,
    );

    void handleTap() {
      if (onPressed == null || isLoading) return;
      final result = onPressed!.call();
      if (result is Future<void>) {
        unawaited(result);
      }
    }

    final buttonContent = isLoading
        ? SizedBox(
      width: height / 2,
      height: height / 2,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
      ),
    )
        : Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icons != null) ...[
          Icon(icons, color: colorScheme.onPrimary,size: 20,),
          const SizedBox(width: 8,),
        ],
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: expand ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );
    Widget btn = ElevatedButton(
      onPressed: (onPressed == null || isLoading) ? null : (){
        handleTap();
        if(confetti){
          Confetti.launch(context, options:
          const ConfettiOptions(
              particleCount: 100,
              spread: 70,
              y: 0.6
          ));
        }
      },
      style: ElevatedButton.styleFrom(
        padding: resolvedPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: colorScheme.tertiary,
        elevation: 2,
        minimumSize: Size(0, height),
      ),
      child: buttonContent,
    );

    if (width != null) {
      btn = SizedBox(width: width, child: btn);
    } else if (expand) {
      btn = SizedBox(width: double.infinity, child: btn);
    }

    return AnimatedOpacity(
      opacity: onPressed == null || isLoading ? 0.8 : 1,
      duration: const Duration(milliseconds: 150),
      child: btn,
    );
  }
}
