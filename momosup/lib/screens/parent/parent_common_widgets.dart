import 'package:flutter/material.dart';

class ParentHubTile extends StatelessWidget {
  const ParentHubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ParentRow(
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF78966A)),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    ),
  );
}

class ParentNoticeCard extends StatelessWidget {
  const ParentNoticeCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFF1D8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF8D6438)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class ParentRow extends StatelessWidget {
  const ParentRow({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 5),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFD0DAB8))),
    ),
    child: child,
  );
}
