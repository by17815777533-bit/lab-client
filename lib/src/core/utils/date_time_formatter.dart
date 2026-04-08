import 'package:intl/intl.dart';

class DateTimeFormatter {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  static String date(DateTime? value) {
    if (value == null) {
      return '-';
    }
    return _dateFormat.format(value.toLocal());
  }

  static String dateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }
    return _dateTimeFormat.format(value.toLocal());
  }

  static DateTime? tryParse(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
