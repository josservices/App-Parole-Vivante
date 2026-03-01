import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../../legal/legal_guard.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});
  static const String _appVersion = '1.0.0+1';

  Future<void> _showDbDiagnostics(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final diagnostics = await AppDatabase.instance.collectDiagnostics();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Diagnostic DB'),
          content: SingleChildScrollView(
            child: SelectableText(diagnostics.toMultilineText()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final licenseOk = LegalGuard.licenseOk;

    return Scaffold(
      appBar: AppBar(title: const Text('Mentions légales')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Usage strictement privé / offline',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Le texte importé depuis le PDF est destiné à un usage personnel. '
            'Toute publication, duplication ou distribution intégrale nécessite '
            'une autorisation/licence de l’éditeur.',
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('LEGAL_GUARD'),
              subtitle: Text(
                licenseOk
                    ? 'LICENSE_OK=true (déverrouillage manuel actif)'
                    : 'LICENSE_OK=false (blocage distribution actif)',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(kIsWeb ? Icons.cloud_off : Icons.storage),
              title: Text(kIsWeb ? 'Mode Web (JSON offline)' : 'Mode Local (SQLite offline)'),
              subtitle: Text(
                kIsWeb
                    ? 'Source: assets/bible.parolevivante.nt.json'
                    : 'Source: assets/bible.db',
              ),
              trailing: const Chip(
                label: Text('OFFLINE'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Branding',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Image.asset(
                    'assets/branding/wordmark.png',
                    height: 56,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version: $_appVersion',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Restrictions techniques appliquées tant que LICENSE_OK=false :',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text('• Export complet du corpus: BLOQUÉ'),
          const Text('• API publique de diffusion du texte: BLOQUÉE'),
          const Text('• Synchronisation cloud du texte: BLOQUÉE'),
          const SizedBox(height: 12),
          const Text(
            'Partage autorisé dans l’application: extrait court uniquement (un verset / petit extrait).',
          ),
          if (kDebugMode && !kIsWeb) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showDbDiagnostics(context),
              icon: const Icon(Icons.bug_report),
              label: const Text('Diagnostic DB (debug)'),
            ),
          ],
        ],
      ),
    );
  }
}
