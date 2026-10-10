import 'package:intl/intl.dart';

String formatDate(DateTime d) => DateFormat('d MMM y').format(d);

/// Whole calendar days from [from] to [to] (negative if [to] is earlier).
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}