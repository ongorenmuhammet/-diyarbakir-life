import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'finance_provider.dart';
import '../domain/finance_model.dart';
import 'finance_detail_sheet.dart';

class FinanceCard extends ConsumerWidget {
  const FinanceCard({super.key});

  Widget _buildFinanceItem(
    BuildContext context, {
    required String label,
    required double price,
    required double change,
    required IconData icon,
    required Color iconColor,
    bool isInt = false,
  }) {
    final theme = Theme.of(context);
    final isPositive = change >= 0;
    final changeSign = isPositive ? '+' : '';
    final changeColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isInt ? price.toStringAsFixed(0) : price.toStringAsFixed(2),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$changeSign${change.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeAsync = ref.watch(financeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final containerDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [theme.colorScheme.surface, theme.colorScheme.surface.withOpacity(0.85)]
            : [theme.colorScheme.primary.withOpacity(0.08), theme.colorScheme.primary.withOpacity(0.02)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? Colors.grey.shade800 : theme.colorScheme.primary.withOpacity(0.12),
        width: 1,
      ),
    );

    return Container(
      decoration: containerDecoration,
      child: financeAsync.when(
        data: (finance) => Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FinanceDetailSheet(finance: finance),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  _buildFinanceItem(
                    context,
                    label: 'Dolar',
                    price: finance.usd,
                    change: finance.usdChange,
                    icon: Icons.attach_money,
                    iconColor: Colors.green.shade500,
                  ),
                  _buildDivider(isDark),
                  _buildFinanceItem(
                    context,
                    label: 'Euro',
                    price: finance.eur,
                    change: finance.eurChange,
                    icon: Icons.euro,
                    iconColor: Colors.blue.shade500,
                  ),
                  _buildDivider(isDark),
                  _buildFinanceItem(
                    context,
                    label: 'Altın',
                    price: finance.gold,
                    change: finance.goldChange,
                    icon: Icons.monetization_on,
                    iconColor: Colors.amber.shade600,
                    isInt: true,
                  ),
                  _buildDivider(isDark),
                  _buildFinanceItem(
                    context,
                    label: 'Gümüş',
                    price: finance.silver,
                    change: finance.silverChange,
                    icon: Icons.monetization_on_outlined,
                    iconColor: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Veriler yüklenemedi',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 28,
      width: 1,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
    );
  }
}
