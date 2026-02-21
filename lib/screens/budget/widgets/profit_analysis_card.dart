import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatters.dart';

class ProfitAnalysisCard extends StatelessWidget {
  final double revenue;
  final double cost;

  const ProfitAnalysisCard({
    super.key,
    required this.revenue,
    required this.cost,
  });

  @override
  Widget build(BuildContext context) {
    final profit = revenue - cost;
    final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;

    // Determine color based on margin health
    Color marginColor;
    if (margin > 50) {
      marginColor = Colors.greenAccent;
    } else if (margin > 20) {
      marginColor = Colors.orangeAccent;
    } else {
      marginColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), // Glass background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: marginColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: marginColor.withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANÁLISE DE LUCRO',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),

          // Margin Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Margem', style: GoogleFonts.outfit(color: Colors.white60)),
              Text(
                '${margin.toStringAsFixed(1)}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: marginColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: margin / 100,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(marginColor),
              minHeight: 6,
            ),
          ),

          const Divider(color: Colors.white10, height: 32),

          // Details
          _buildRow('Receita Total', revenue, Colors.white),
          const SizedBox(height: 12),
          _buildRow('Custo Estimado', cost, Colors.redAccent.withOpacity(0.8)),
          const SizedBox(height: 12),
          _buildRow('Lucro Projetado', profit, marginColor, isBold: true),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    double value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
        ),
        Text(
          Formatters.formatCurrency(value),
          style: isBold
              ? GoogleFonts.jetBrainsMono(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )
              : GoogleFonts.jetBrainsMono(color: color, fontSize: 14),
        ),
      ],
    );
  }
}
