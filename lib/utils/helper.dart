import 'package:intl/intl.dart';

String formatDateTime(String rawDateTime) {
  try {
    final dateTime = DateTime.parse(rawDateTime);
    final formattedDate = DateFormat("dd MMM yy").format(dateTime);
    final formattedTime = DateFormat("h:mm a").format(dateTime);
    return "$formattedDate · $formattedTime";
  } catch (e) {
    return rawDateTime; // fallback in case of parse error
  }
}

String formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
}
