import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class AllahName {
  final String arabic;
  final String urdu;
  const AllahName(this.arabic, this.urdu);
}

const List<AllahName> kAllahNames = [
  AllahName('الرَّحْمَنُ', 'رحمن'),
  AllahName('الرَّحِيمُ', 'رحیم'),
  AllahName('الْمَلِكُ', 'بادشاہ'),
  AllahName('الْقُدُّوسُ', 'پاک'),
  AllahName('السَّلَامُ', 'سلامتی دینے والا'),
  AllahName('الْمُؤْمِنُ', 'امان دینے والا'),
  AllahName('الْمُهَيْمِنُ', 'نگہبان'),
  AllahName('الْعَزِيزُ', 'غالب'),
  AllahName('الْجَبَّارُ', 'زبردست'),
  AllahName('الْمُتَكَبِّرُ', 'بڑائی والا'),
  AllahName('الْخَالِقُ', 'پیدا کرنے والا'),
  AllahName('الْبَارِئُ', 'پیدا کرنے والا'),
  AllahName('الْمُصَوِّرُ', 'صورت بنانے والا'),
  AllahName('الْغَفَّارُ', 'بخشش کرنے والا'),
  AllahName('الْقَهَّارُ', 'غلبہ والا'),
  AllahName('الْوَهَّابُ', 'بہت دینے والا'),
  AllahName('الرَّزَّاقُ', 'رزق دینے والا'),
  AllahName('الْفَتَّاحُ', 'کھولنے والا'),
  AllahName('الْعَلِيمُ', 'جاننے والا'),
  AllahName('الْقَابِضُ', 'قبض کرنے والا'),
  AllahName('الْبَاسِطُ', 'کشادگی دینے والا'),
  AllahName('الْخَافِضُ', 'پست کرنے والا'),
  AllahName('الرَّافِعُ', 'بلند کرنے والا'),
  AllahName('الْمُعِزُّ', 'عزت دینے والا'),
  AllahName('الْمُذِلُّ', 'ذلیل کرنے والا'),
  AllahName('السَّمِيعُ', 'سننے والا'),
  AllahName('الْبَصِيرُ', 'دیکھنے والا'),
  AllahName('الْحَكَمُ', 'فیصلہ کرنے والا'),
  AllahName('الْعَدْلُ', 'انصاف کرنے والا'),
  AllahName('اللَّطِيفُ', 'باریک بین'),
  AllahName('الْخَبِيرُ', 'خبر رکھنے والا'),
  AllahName('الْحَلِيمُ', 'بردبار'),
  AllahName('الْعَظِيمُ', 'بہت بڑا'),
  AllahName('الْغَفُورُ', 'بخشنے والا'),
  AllahName('الشَّكُورُ', 'قدر کرنے والا'),
  AllahName('الْعَلِيُّ', 'بلند'),
  AllahName('الْكَبِيرُ', 'بڑا'),
  AllahName('الْحَفِيظُ', 'حفاظت کرنے والا'),
  AllahName('الْمُقِيتُ', 'خوراک دینے والا'),
  AllahName('الْحَسِيبُ', 'حساب لینے والا'),
  AllahName('الْجَلِيلُ', 'عظمت والا'),
  AllahName('الْكَرِيمُ', 'سخی'),
  AllahName('الرَّقِيبُ', 'نگران'),
  AllahName('الْمُجِيبُ', 'دعا قبول کرنے والا'),
  AllahName('الْوَاسِعُ', 'وسیع'),
  AllahName('الْحَكِيمُ', 'حکمت والا'),
  AllahName('الْوَدُودُ', 'محبت کرنے والا'),
  AllahName('الْمَجِيدُ', 'بزرگی والا'),
  AllahName('الْبَاعِثُ', 'اٹھانے والا'),
  AllahName('الشَّهِيدُ', 'گواہ'),
  AllahName('الْحَقُّ', 'سچا'),
  AllahName('الْوَكِيلُ', 'کارساز'),
  AllahName('الْقَوِيُّ', 'طاقتور'),
  AllahName('الْمَتِينُ', 'مضبوط'),
  AllahName('الْوَلِيُّ', 'دوست'),
  AllahName('الْحَمِيدُ', 'تعریف والا'),
  AllahName('الْمُحْصِي', 'گننے والا'),
  AllahName('الْمُبْدِئُ', 'پہلی بار پیدا کرنے والا'),
  AllahName('الْمُعِيدُ', 'دوبارہ پیدا کرنے والا'),
  AllahName('الْمُحْيِي', 'زندہ کرنے والا'),
  AllahName('الْمُمِيتُ', 'موت دینے والا'),
  AllahName('الْحَيُّ', 'زندہ'),
  AllahName('الْقَيُّومُ', 'قائم رکھنے والا'),
  AllahName('الْوَاجِدُ', 'پانے والا'),
  AllahName('الْمَاجِدُ', 'عزت والا'),
  AllahName('الْوَاحِدُ', 'ایک'),
  AllahName('الْأَحَدُ', 'ایک'),
  AllahName('الصَّمَدُ', 'بے نیاز'),
  AllahName('الْقَادِرُ', 'قدرت والا'),
  AllahName('الْمُقْتَدِرُ', 'مکمل قدرت والا'),
  AllahName('الْمُقَدِّمُ', 'آگے کرنے والا'),
  AllahName('الْمُؤَخِّرُ', 'پیچھے کرنے والا'),
  AllahName('الْأَوَّلُ', 'پہلا'),
  AllahName('الْآخِرُ', 'آخری'),
  AllahName('الظَّاهِرُ', 'ظاہر'),
  AllahName('الْبَاطِنُ', 'پوشیدہ'),
  AllahName('الْوَالِي', 'مالک'),
  AllahName('الْمُتَعَالِي', 'بلند مرتبہ'),
  AllahName('الْبَرُّ', 'نیکی کرنے والا'),
  AllahName('التَّوَّابُ', 'توبہ قبول کرنے والا'),
  AllahName('الْمُنْتَقِمُ', 'بدلہ لینے والا'),
  AllahName('الْعَفُوُّ', 'معاف کرنے والا'),
  AllahName('الرَّءُوفُ', 'مہربان'),
  AllahName('مَالِكُ الْمُلْكِ', 'بادشاہی کا مالک'),
  AllahName('ذُو الْجَلَالِ وَالْإِكْرَامِ', 'عظمت و عزت والا'),
  AllahName('الْمُقْسِطُ', 'انصاف کرنے والا'),
  AllahName('الْجَامِعُ', 'جمع کرنے والا'),
  AllahName('الْغَنِيُّ', 'بے نیاز'),
  AllahName('الْمُغْنِي', 'غنی کرنے والا'),
  AllahName('الْمَانِعُ', 'روکنے والا'),
  AllahName('الضَّارُ', 'نقصان دینے والا'),
  AllahName('النَّافِعُ', 'نفع دینے والا'),
  AllahName('النُّورُ', 'روشنی'),
  AllahName('الْهَادِي', 'ہدایت دینے والا'),
  AllahName('الْبَدِيعُ', 'ناقابل مثال بنانے والا'),
  AllahName('الْبَاقِي', 'ہمیشہ رہنے والا'),
  AllahName('الْوَارِثُ', 'وارث'),
  AllahName('الرَّشِيدُ', 'راستہ دکھانے والا'),
  AllahName('الصَّبُورُ', 'صبر کرنے والا'),
];

class AllahNames {
  static const _kPrefKey = 'sajda_allah_name_index';

  /// Picks a random Asma-ul-Husna, avoiding the one shown on the previous
  /// app launch. Runs once per app open (call from initState).
  static Future<int> pickFreshIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kPrefKey) ?? -1;
    var idx = Random().nextInt(kAllahNames.length);
    if (kAllahNames.length > 1 && idx == last) {
      idx = (idx + 1) % kAllahNames.length;
    }
    await prefs.setInt(_kPrefKey, idx);
    return idx;
  }
}
