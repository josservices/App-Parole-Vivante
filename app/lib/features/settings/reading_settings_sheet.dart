import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'reading_preferences_controller.dart';

class ReadingSettingsSheet extends StatelessWidget {
  const ReadingSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReadingPreferencesController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Réglages de lecture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('Taille du texte: ${controller.textSize.toStringAsFixed(0)}'),
            Slider(
              min: 14,
              max: 28,
              value: controller.textSize,
              onChanged: (value) => controller.setTextSize(value),
            ),
            Text('Interligne: ${controller.lineHeight.toStringAsFixed(2)}'),
            Slider(
              min: 1.2,
              max: 2.2,
              value: controller.lineHeight,
              onChanged: (value) => controller.setLineHeight(value),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Système'),
                  selected: controller.themeMode == ThemeMode.system,
                  onSelected: (_) => controller.setThemeMode(ThemeMode.system),
                ),
                ChoiceChip(
                  label: const Text('Clair'),
                  selected: controller.themeMode == ThemeMode.light,
                  onSelected: (_) => controller.setThemeMode(ThemeMode.light),
                ),
                ChoiceChip(
                  label: const Text('Sombre'),
                  selected: controller.themeMode == ThemeMode.dark,
                  onSelected: (_) => controller.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
