import Event from '../models/Event.js';

const events = [
  // Muharram (month 1)
  {
    month: 'Muharram', monthNumber: 1, day: 1,
    title: { en: 'Islamic New Year', ur: 'اسلامی نیا سال' },
    type: 'celebration',
    description: { en: 'First day of the Islamic calendar year. Marks the Hijra of Prophet Muhammad from Mecca to Medina.', ur: 'اسلامی کیلنڈر کے سال کا پہلا دن۔ نبی کریم صلی اللہ علیہ وسلم کی مکہ سے مدینہ ہجرت کی یاد دلاتا ہے۔' },
    amal: ['Nafil fasting on this day', 'Recite Durood Shareef', 'Ask for forgiveness'],
    duas: [{ arabic: 'اللَّهُمَّ أَنْتَ الْأَبَدِيُّ الْقَدِيمُ', urdu: 'اے اللہ تو ہی ازلی اور قدیم ہے', transliteration: 'Allahumma antal abadiyyul qadeem' }],
  },
  {
    month: 'Muharram', monthNumber: 1, day: 7,
    title: { en: 'Access to Water Cut Off at Karbala', ur: 'کربلا میں پانی بند' },
    type: 'mourning',
    description: { en: 'The forces of Yazid cut off access to water for Imam Hussain and his family.', ur: 'یزید کی فوجوں نے امام حسین اور ان کے اہل خانہ کے لیے پانی بند کر دیا۔' },
    amal: ['Recite Ziyarat Ashura', 'Give water in charity', 'Recite Surah Al-Kahf'],
    duas: [{ arabic: 'اللَّهُمَّ الْعَنْ قَتَلَةَ الْحُسَيْنِ', urdu: 'اے اللہ! حسین کے قاتلوں پر لعنت فرما', transliteration: 'Allahummal an qatalatal Husain' }],
  },
  {
    month: 'Muharram', monthNumber: 1, day: 10,
    title: { en: 'Ashura', ur: 'عاشورہ' },
    type: 'major_mourning',
    description: { en: 'Day of Ashura - Martyrdom of Imam Hussain at Karbala. Also the day Allah saved Prophet Musa from Pharaoh.', ur: 'یوم عاشورہ - کربلا میں امام حسین کی شہادت۔ اسی دن اللہ نے موسیٰ علیہ السلام کو فرعون سے نجات دی۔' },
    amal: ['Fast on Ashura', 'Recite Surah Al-Ikhlas 1000 times', 'Give charity', 'Visit the Masjid'],
    duas: [{ arabic: 'يَا قَاضِيَ الْحَاجَاتِ', urdu: 'اے حاجتوں کو پورا کرنے والے', transliteration: 'Ya Qadiyal Hajat' }],
  },
  // Safar (month 2)
  {
    month: 'Safar', monthNumber: 2, day: 20,
    title: { en: 'Arbaeen / Chehlum', ur: 'اربعین / چہلم' },
    type: 'major_mourning',
    description: { en: '40th day after the martyrdom of Imam Hussain at Karbala.', ur: 'کربلا میں امام حسین کی شہادت کے 40 ویں دن کی یاد' },
    amal: ['Recite Ziyarat Arbaeen', 'Give food in charity', 'Recite Surah Yaseen'],
    duas: [{ arabic: 'السَّلَامُ عَلَيْكَ يَا أَبَا عَبْدِ اللَّهِ', urdu: 'آپ پر سلام ہو اے ابا عبداللہ', transliteration: 'Assalamu alayka ya aba Abdillah' }],
  },
  // Rabi ul Awwal (month 3)
  {
    month: 'Rabi ul Awwal', monthNumber: 3, day: 12,
    title: { en: 'Eid Milad un Nabi', ur: 'عید میلاد النبی ﷺ' },
    type: 'major_celebration',
    description: { en: 'Birth of Prophet Muhammad (peace be upon him).', ur: 'نبی کریم صلی اللہ علیہ وسلم کی ولادت باسعادت' },
    amal: ['Recite Durood Shareef abundantly', 'Give charity', 'Feed the poor', 'Naat and Dhikr'],
    duas: [{ arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ', urdu: 'اے اللہ! محمد اور آل محمد پر رحمت نازل فرما', transliteration: 'Allahumma salli ala Muhammadin wa ala aali Muhammad' }],
  },
  // Rajab (month 7)
  {
    month: 'Rajab', monthNumber: 7, day: 27,
    title: { en: 'Shab-e-Meraj', ur: 'شب معراج' },
    type: 'major_celebration',
    description: { en: 'The night of Isra and Miraj - Prophet Muhammad ascended to the heavens.', ur: 'اسراء و معراج کی رات - نبی کریم صلی اللہ علیہ وسلم کا آسمانوں کا سفر' },
    amal: ['Nafil prayers', 'Fast during the day', 'Recite Surah Al-Isra', 'Give charity'],
    duas: [{ arabic: 'سُبْحَانَ الَّذِي أَسْرَىٰ بِعَبْدِهِ لَيْلًا', urdu: 'پاک ہے وہ جو اپنے بندے کو راتوں رات لے گیا', transliteration: 'Subhanallazi asra bi abdihi laylan' }],
  },
  // Shaban (month 8)
  {
    month: 'Shaban', monthNumber: 8, day: 15,
    title: { en: 'Shab-e-Barat', ur: 'شب برات' },
    type: 'major_celebration',
    description: { en: 'Night of forgiveness - Allah forgives sins and determines destinies for the year.', ur: 'بخشش کی رات - اللہ تعالیٰ گناہ معاف کرتے ہیں اور سال بھر کے مقررات طے ہوتے ہیں' },
    amal: ['Nafil prayers all night', 'Recite Surah Yaseen', 'Fast on 15th Shaban', 'Visit graveyard for dua'],
    duas: [{ arabic: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي', urdu: 'اے اللہ تو معاف کرنے والا ہے، معاف کرنا پسند کرتا ہے، مجھے معاف فرما', transliteration: 'Allahumma innaka afuwwun tuhibbul afwa fa\'fu anni' }],
  },
  // Ramadan (month 9)
  {
    month: 'Ramadan', monthNumber: 9, day: 1,
    title: { en: 'First Day of Ramadan', ur: 'رمضان المبارک کا پہلا دن' },
    type: 'major_celebration',
    description: { en: 'The holy month of fasting begins. The month in which the Quran was revealed.', ur: 'روزوں کا مقدس مہینہ شروع ہوتا ہے۔ وہ مہینہ جس میں قرآن نازل ہوا۔' },
    amal: ['Keep fast', 'Taraweeh prayers', 'Recite Quran daily', 'Give charity'],
    duas: [{ arabic: 'اللَّهُمَّ بَارِكْ لَنَا فِي رَجَبَ وَشَعْبَانَ وَبَلِّغْنَا رَمَضَانَ', urdu: 'اے اللہ! ہمارے لیے رجب اور شعبان میں برکت عطا فرما اور ہمیں رمضان تک پہنچا', transliteration: 'Allahumma barik lana fi Rajaba wa Shabana wa ballighna Ramadan' }],
  },
  {
    month: 'Ramadan', monthNumber: 9, day: 21,
    title: { en: 'Laylatul Qadr (Possible Night 1)', ur: 'شب قدر (ممکنہ رات 1)' },
    type: 'major_celebration',
    description: { en: 'One of the odd nights of the last 10 days of Ramadan - the Night of Power.', ur: 'رمضان کے آخری عشرے کی طاق راتوں میں سے ایک - شب قدر' },
    amal: ['Itikaf', 'Nafil prayers all night', 'Recite Quran', 'Dua and Istighfar'],
    duas: [{ arabic: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي', urdu: 'اے اللہ! تو معاف کرنے والا ہے، معاف کرنا پسند کرتا ہے، مجھے معاف فرما', transliteration: 'Allahumma innaka afuwwun tuhibbul afwa fa\'fu anni' }],
  },
  {
    month: 'Ramadan', monthNumber: 9, day: 23,
    title: { en: 'Laylatul Qadr (Possible Night 2)', ur: 'شب قدر (ممکنہ رات 2)' },
    type: 'major_celebration',
    description: { en: 'The Night of Power - worship on this night is better than 1000 months.', ur: 'شب قدر - اس رات کی عبادت ہزار مہینوں سے بہتر ہے۔' },
    amal: ['Nafil prayers', 'Recite Durood', 'Give sadaqah', 'Make sincere dua'],
    duas: [{ arabic: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي', urdu: 'اے اللہ! تو معاف کرنے والا ہے، مجھے معاف فرما', transliteration: 'Allahumma innaka afuwwun tuhibbul afwa fa\'fu anni' }],
  },
  {
    month: 'Ramadan', monthNumber: 9, day: 25,
    title: { en: 'Laylatul Qadr (Possible Night 3)', ur: 'شب قدر (ممکنہ رات 3)' },
    type: 'major_celebration',
    description: { en: 'Seek Laylatul Qadr in the odd nights of the last ten days of Ramadan.', ur: 'رمضان کے آخری عشرے کی طاق راتوں میں شب قدر تلاش کریں۔' },
    amal: ['Worship throughout the night', 'Recite Surah Al-Qadr', 'Give charity'],
    duas: [{ arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ', urdu: 'اے ہمارے رب! ہمیں دنیا میں بھی بھلائی دے اور آخرت میں بھی بھلائی دے', transliteration: 'Rabbana atina fid dunya hasanah wa fil aakhirati hasanah wa qina azaban naar' }],
  },
  {
    month: 'Ramadan', monthNumber: 9, day: 27,
    title: { en: 'Laylatul Qadr (Possible Night 4)', ur: 'شب قدر (ممکنہ رات 4)' },
    type: 'major_celebration',
    description: { en: 'Most likely night for Laylatul Qadr - the night the Quran was revealed.', ur: 'شب قدر کا سب سے زیادہ امکان - وہ رات جس میں قرآن نازل ہوا۔' },
    amal: ['Itikaf', 'Complete Quran recitation', 'Nafil prayers', 'Sincere repentance'],
    duas: [{ arabic: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي', urdu: 'اے اللہ! تو معاف کرنے والا ہے، مجھے معاف فرما', transliteration: 'Allahumma innaka afuwwun tuhibbul afwa fa\'fu anni' }],
  },
  {
    month: 'Ramadan', monthNumber: 9, day: 29,
    title: { en: 'Laylatul Qadr (Possible Night 5)', ur: 'شب قدر (ممکنہ رات 5)' },
    type: 'major_celebration',
    description: { en: 'Last possible odd night for Laylatul Qadr in Ramadan.', ur: 'رمضان میں شب قدر کے لیے آخری ممکنہ طاق رات۔' },
    amal: ['Increase worship', 'Pay Zakat', 'Recite Istighfar', 'Last chance for Itikaf'],
    duas: [{ arabic: 'اللَّهُمَّ اجْعَلْنَا مِنَ الْمُفْلِحِينَ', urdu: 'اے اللہ! ہمیں کامیاب لوگوں میں شامل فرما', transliteration: 'Allahummaj\'alna minal mufliheen' }],
  },
  // Shawwal (month 10)
  {
    month: 'Shawwal', monthNumber: 10, day: 1,
    title: { en: 'Eid ul Fitr', ur: 'عید الفطر' },
    type: 'major_celebration',
    description: { en: 'Festival of breaking the fast - marks the end of Ramadan.', ur: 'روزوں کے اختتام کی خوشی - عید الفطر' },
    amal: ['Eid prayer', 'Give Zakat al-Fitr', 'Wear new clothes', 'Visit family', 'Eat dates before prayer'],
    duas: [{ arabic: 'اللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ لَا إِلَٰهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ وَلِلَّهِ الْحَمْدُ', urdu: 'اللہ سب سے بڑا ہے، اللہ کے سوا کوئی معبود نہیں', transliteration: 'Allahu Akbar Allahu Akbar la ilaha illallahu wallahu Akbar' }],
  },
  // Dhul Hijjah (month 12)
  {
    month: 'Dhul Hijjah', monthNumber: 12, day: 9,
    title: { en: 'Day of Arafah', ur: 'یوم عرفہ' },
    type: 'major_celebration',
    description: { en: 'The most important day of Hajj. Pilgrims stand at Mount Arafat. Allah forgives sins on this day.', ur: 'حج کا سب سے اہم دن۔ حجاج میدان عرفات میں کھڑے ہوتے ہیں۔ اللہ اس دن گناہ معاف کرتا ہے۔' },
    amal: ['Fast on Arafah (for non-pilgrims)', 'Recite Talbiyah', 'Make abundant dua', 'Recite Surah Al-Ikhlas'],
    duas: [{ arabic: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ', urdu: 'اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں', transliteration: 'La ilaha illallahu wahdahu la sharika lah' }],
  },
  {
    month: 'Dhul Hijjah', monthNumber: 12, day: 10,
    title: { en: 'Eid ul Adha', ur: 'عید الاضحی' },
    type: 'major_celebration',
    description: { en: 'Festival of sacrifice - commemorates Prophet Ibrahim willingness to sacrifice his son.', ur: 'قربانی کا تہوار - حضرت ابراہیم علیہ السلام کی قربانی کی یاد' },
    amal: ['Eid prayer', 'Sacrifice animal', 'Distribute meat', 'Takbeerat', 'Give charity'],
    duas: [{ arabic: 'بِسْمِ اللَّهِ وَاللَّهُ أَكْبَرُ اللَّهُمَّ تَقَبَّلْ مِنِّي', urdu: 'اللہ کے نام سے، اللہ سب سے بڑا ہے، اے اللہ مجھ سے قبول فرما', transliteration: 'Bismillahi wallahu Akbar Allahumma taqabbal minni' }],
  },
  {
    month: 'Dhul Hijjah', monthNumber: 12, day: 11,
    title: { en: 'Ayyam-e-Tashreeq (Day 1)', ur: 'ایام تشریق (پہلا دن)' },
    type: 'major_celebration',
    description: { en: 'Days of eating and drinking - pilgrims stone the pillars at Mina.', ur: 'کھانے پینے کے دن - حاجی منیٰ میں جمرات کو کنکر مارتے ہیں۔' },
    amal: ['Recite Takbeerat', 'Eat and drink', 'Continue good deeds'],
    duas: [{ arabic: 'اللَّهُ أَكْبَرُ كَبِيرًا وَالْحَمْدُ لِلَّهِ كَثِيرًا', urdu: 'اللہ سب سے بڑا ہے، بہت بڑائی والا', transliteration: 'Allahu akbaru kabeeran walhamdu lillahi katheera' }],
  },
  {
    month: 'Dhul Hijjah', monthNumber: 12, day: 12,
    title: { en: 'Ayyam-e-Tashreeq (Day 2)', ur: 'ایام تشریق (دوسرا دن)' },
    type: 'major_celebration',
    description: { en: 'Second day of Tashreeq - Hajj continues at Mina.', ur: 'تشریق کا دوسرا دن - حج منیٰ میں جاری رہتا ہے۔' },
    amal: ['Takbeerat after prayers', 'Charity', 'Family gathering'],
    duas: [{ arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً', urdu: 'اے ہمارے رب! ہمیں دنیا اور آخرت میں بھلائی عطا فرما', transliteration: 'Rabbana atina fid dunya hasanah' }],
  },
  {
    month: 'Dhul Hijjah', monthNumber: 12, day: 13,
    title: { en: 'Ayyam-e-Tashreeq (Day 3)', ur: 'ایام تشریق (تیسرا دن)' },
    type: 'major_celebration',
    description: { en: 'Final day of Tashreeq - last day of Hajj.', ur: 'تشریق کا آخری دن - حج کا آخری دن۔' },
    amal: ['Final Takbeerat', 'Farewell Tawaf', 'Continue good deeds'],
    duas: [{ arabic: 'الْحَمْدُ لِلَّهِ الَّذِي هَدَانَا لِهَٰذَا', urdu: 'اللہ کا شکر ہے جس نے ہمیں اس کی ہدایت دی', transliteration: 'Alhamdu lillahil lazi hadana lihaza' }],
  },
];

const seedEvents = async () => {
  try {
    await Event.deleteMany({});
    await Event.insertMany(events);
    console.log(`${events.length} Islamic events seeded successfully`);
  } catch (error) {
    console.error('Error seeding events:', error.message);
    throw error;
  }
};

export default seedEvents;
