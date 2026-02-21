import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumReportsScreen extends StatelessWidget {
  const PremiumReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Slate
      appBar: AppBar(
        title: Text(
          'BUSINESS INTELLIGENCE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // KPI Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    'Revenue',
                    'R\$ 12.450',
                    '+15%',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    'Profit',
                    'R\$ 8.200',
                    '+8%',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Chart Placeholder
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Overview',
                    style: GoogleFonts.outfit(color: Colors.white70),
                  ),
                  const Expanded(
                    child: Center(
                      child: Icon(
                        Icons.bar_chart,
                        size: 80,
                        color: Colors.white10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Reports Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildReportCard(
                  context,
                  title: 'Monthly Revenue',
                  icon: Icons.monetization_on_outlined,
                  color: const Color(0xFF10B981), // Emerald
                  onTap: () => context.push('/reports/monthly-revenue'),
                ),
                _buildReportCard(
                  context,
                  title: 'Top Services',
                  icon: Icons.star_outline,
                  color: Colors.amber,
                  onTap: () => context.push('/reports/top-services'),
                ),
                _buildReportCard(
                  context,
                  title: 'Recurring Clients',
                  icon: Icons.sync,
                  color: Colors.purple,
                  onTap: () => context.push('/reports/recurring-clients'),
                ),
                _buildReportCard(
                  context,
                  title: 'Month Comparison',
                  icon: Icons.compare_arrows,
                  color: Colors.orange,
                  onTap: () => context.push('/reports/month-comparison'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String label, String value, String change, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              change,
              style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color, // Should be standard Colors, but handled below
    required VoidCallback onTap,
  }) {
    // Custom colors mapping if needed, but passing standard Colors works
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.arrow_forward, color: Colors.white24, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
