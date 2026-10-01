class FinanceExtraItem {
  final String label;
  final double price;
  final double change;

  const FinanceExtraItem({
    required this.label,
    required this.price,
    required this.change,
  });
}

class FinanceModel {
  final double usd;
  final double usdChange;
  final double eur;
  final double eurChange;
  final double gold;
  final double goldChange;
  final double silver;
  final double silverChange;
  final List<FinanceExtraItem> extras;

  const FinanceModel({
    required this.usd,
    required this.usdChange,
    required this.eur,
    required this.eurChange,
    required this.gold,
    required this.goldChange,
    required this.silver,
    required this.silverChange,
    this.extras = const [],
  });
}
