import 'dart:ui';

import 'package:flutter/material.dart';

class BlockingLoadingOverlay extends StatelessWidget {
  const BlockingLoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
    this.message = 'Please wait...',
  });

  final bool loading;
  final Widget child;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(absorbing: loading, child: child),
        if (loading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: .58),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
