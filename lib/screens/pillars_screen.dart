import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class Pillar {
  final String nameEn;
  final String nameAr;
  final String nameUr;
  final String description;
  const Pillar({
    required this.nameEn,
    required this.nameAr,
    required this.nameUr,
    required this.description,
  });
}

const List<Pillar> pillars = [
  Pillar(
    nameEn: 'Shahada',
    nameAr: 'الشهادتان',
    nameUr: 'کلمہ شہادت',
    description:
        'الشهادتان هما الإعلان عن الإيمان من دون شك، وتصريح بأن ليس هناك إله في الوجود إلا الله، وأن محمداً رسول مرسل للناس من الله. نص الشهادة هي: أشهد أن لا إله إلا الله وأشهد أن محمداً رسول الله. وهذا النص يُقال يومياً في صلاة المسلمين، وهو أيضاً المفتاح الرئيسي لدخول شخص غير مسلم في الإسلام.',
  ),
  Pillar(
    nameEn: 'Salah (Prayer)',
    nameAr: 'الصلاة',
    nameUr: 'نماز',
    description:
        'الصلاة هي الركن الثاني من أركان الإسلام، لقول النبي محمد ﷺ: «بني الإسلام على خمس: شهادة أن لا إله إلا الله وأن محمداً رسول الله، وإقام الصلاة، وإيتاء الزكاة، وصوم رمضان، وحج البيت من استطاع إليه سبيلاً». وقوله أيضاً: «رأس الأمر الإسلام، وعموده الصلاة، وذروة سنامه الجهاد في سبيل الله». والصلاة واجبة على كل مسلم بالغ عاقل. قد فرضت الصلاة في مكة قبل هجرة النبي محمد ﷺ إلى يثرب أثناء رحلة الإسراء والمعراج.',
  ),
  Pillar(
    nameEn: 'Zakat (Charity)',
    nameAr: 'الزكاة',
    nameUr: 'زکوٰۃ',
    description:
        'وإيتاء الزكاة هو عبادة مالية فرضها الله على عباده، طهرة لنفوسهم من البخل، ولصحائفهم من الخطايا، وقد ذكر الله في كتابه: ﴿خُذْ مِنْ أَمْوَالِهِمْ صَدَقَةً تُطَهِّرُهُمْ وَتُزَكِّيهِمْ بِهَا﴾ [التوبة:103]. وقد فرض الله على المسلمين زكاتين: زكاة الفطر وزكاة المال. وتُدفع الزكاة في مصارفها الثمانية للفقراء والمساكين.',
  ),
  Pillar(
    nameEn: 'Sawm (Fasting)',
    nameAr: 'الصيام',
    nameUr: 'روزہ',
    description:
        'أما الصيام المفروض فهو صيام شهر رمضان. ويعتبر رمضان موسماً عظيماً تكثر فيه الطاعات وهو شهر مبارك تتنزل فيه الرحمة ويجدد فيه العبد عهده مع الله. وقد تكفل الله لمن صامه إيماناً واحتساباً بغفران ما مضى من ذنوبه.',
  ),
  Pillar(
    nameEn: 'Hajj (Pilgrimage)',
    nameAr: 'الحج',
    nameUr: 'حج',
    description:
        'الحج هو زيارة المسجد الحرام في مكة المكرمة وأداء فريضة الحج. فرض الله هذا الفرض على كل مسلم بالغ قادر. في القرآن: ﴿وَلِلَّهِ عَلَى النَّاسِ حِجُّ الْبَيْتِ مَنِ اسْتَطَاعَ إِلَيْهِ سَبِيلًا﴾ [آل عمران:97]. وقد فرض الله الحج تزكيةً للنفوس وتربيةً لها على معاني العبودية والطاعة والصبر، فضلاً عن أنه فرصة عظيمة لتكفير الذنوب.',
  ),
];

class PillarsScreen extends StatefulWidget {
  const PillarsScreen({super.key});

  @override
  State<PillarsScreen> createState() => _PillarsScreenState();
}

class _PillarsScreenState extends State<PillarsScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(state.t('Pillars of Islam', 'ارکان اسلام'))),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: pillars.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) {
              final p = pillars[i];
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDeep],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                     Text(
                       p.nameAr,
                       style: TextStyle(
                         fontSize: 26,
                         fontWeight: FontWeight.w800,
                         fontFamily: 'serif',
                         color: Theme.of(context).colorScheme.primary,
                       ),
                     ),
                    const SizedBox(height: 8),
                    Text(
                      '${i + 1}. ${p.nameUr} • ${p.nameEn}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: GlassCard(
                          padding: const EdgeInsets.all(20),
                           child: Text(
                             p.description,
                             textAlign: TextAlign.right,
                             style: TextStyle(
                               fontSize: 16.5,
                               height: 1.9,
                               fontFamily: 'serif',
                               color: Theme.of(context).colorScheme.onSurface,
                             ),
                           ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pillars.length,
                        (d) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: d == _current ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: d == _current ? AppColors.primary : AppColors.textMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}