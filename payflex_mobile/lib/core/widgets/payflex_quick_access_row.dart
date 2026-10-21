import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../design/pf_components.dart';

class PayflexQuickAccessRow extends StatelessWidget {
  const PayflexQuickAccessRow({
    super.key,
    required this.onReportTap,
    required this.onOpportunitiesTap,
  });

  final VoidCallback onReportTap;
  final VoidCallback onOpportunitiesTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAccessButton(
            icon: Icons.campaign_outlined,
            label: 'Signaler',
            subtitle: 'Un problème',
            color: const Color(0xFFE53E3E),
            onTap: onReportTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAccessButton(
            icon: Icons.work_outline_rounded,
            label: 'Opportunités',
            subtitle: 'Offres d\'emploi',
            color: AppColors.secondary,
            onTap: onOpportunitiesTap,
          ),
        ),
      ],
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  const _QuickAccessButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PfCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: Pf.br(Pf.rSm)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: Pf.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Pf.label(size: 13)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Pf.body(size: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
