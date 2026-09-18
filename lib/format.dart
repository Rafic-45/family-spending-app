import 'config.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "$45.00" — currency symbol + two decimals.
String formatAmount(double amount) =>
    '${AppConfig.currencySymbol}${amount.toStringAsFixed(2)}';

/// "Sep 18" — short month + day.
String formatDate(DateTime date) => '${_months[date.month - 1]} ${date.day}';

/// "Sep 18, 2026" — short month + day + year.
String formatDateFull(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}, ${date.year}';
