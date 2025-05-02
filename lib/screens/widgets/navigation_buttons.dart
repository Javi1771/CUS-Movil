// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool enabled;

  const NavigationButtons({
    super.key,
    required this.onNext,
    required this.onBack,
    this.enabled = false,
  });

  @override
  Widget build(BuildContext context) {
    const govBlue = Color(0xFF0B3B60);
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Anterior'),
          style: OutlinedButton.styleFrom(
            foregroundColor: govBlue,
            side: const BorderSide(color: govBlue),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: enabled ? onNext : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Siguiente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: govBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: govBlue.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
        ),
      ],
    );
  }
}
