import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _short = DateFormat('dd/MM/yyyy', 'fr');
  static final _long = DateFormat('d MMMM yyyy', 'fr');
  static final _time = DateFormat('HH:mm', 'fr');
  static final _dateTime = DateFormat('dd/MM/yy • HH:mm', 'fr');

  static String short(DateTime d) => _short.format(d);
  static String long(DateTime d) => _long.format(d);
  static String time(DateTime d) => _time.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);

  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return short(d);
  }
}
