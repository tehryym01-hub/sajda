import 'package:flutter_test/flutter_test.dart';
import 'package:sajda_dataplus/utils/time_format.dart';

void main() {
  test('formatTime12 converts 24h to azan-style 12h', () {
    expect(formatTime12('00:15'), '12:15 AM');
    expect(formatTime12('05:03'), '5:03 AM');
    expect(formatTime12('11:59'), '11:59 AM');
    expect(formatTime12('12:00'), '12:00 PM');
    expect(formatTime12('12:30'), '12:30 PM');
    expect(formatTime12('13:00'), '1:00 PM');
    expect(formatTime12('16:45'), '4:45 PM');
    expect(formatTime12('23:59'), '11:59 PM');
  });

  test('formatTime12 pads minutes', () {
    expect(formatTime12('09:05'), '9:05 AM');
    expect(formatTime12('21:07'), '9:07 PM');
  });

  test('formatTime12 is defensive on garbage input', () {
    expect(formatTime12(''), '');
    expect(formatTime12(null), '');
    expect(formatTime12('sunrise'), 'sunrise');
    expect(formatTime12('25:99'), '25:99'); // out of range → unchanged
    expect(formatTime12('16'), '16'); // no minutes → unchanged
  });
}
