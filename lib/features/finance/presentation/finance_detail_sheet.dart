import 'package:flutter/material.dart';
import '../domain/finance_model.dart';

class FinanceDetailSheet extends StatelessWidget {
  final FinanceModel finance;

  const FinanceDetailSheet({super.key, required this.finance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<FinanceExtraItem> allItems = [
      FinanceExtraItem(label: 'Dolar (USD)', price: finance.usd, change: finance.usdChange),
      FinanceExtraItem(label: 'Euro (EUR)', price: finance.eur, change: finance.eurChange),
      FinanceExtraItem(label: 'Gram Altın', price: finance.gold, change: finance.goldChange),
      FinanceExtraItem(label: 'Gümüş', price: finance.silver, change: finance.silverChange),
      ...finance.extras,
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.query_stats, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tüm Piyasalar',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: allItems.length,
              separatorBuilder: (context, index) => Divider(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final item = allItems[index];
                final isPositive = item.change >= 0;
                final changeColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
                final changeSign = isPositive ? '+' : '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.price.toStringAsFixed(2),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$changeSign${item.change.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: changeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
