import 'dart:math';
import 'package:home_widget/home_widget.dart';
import '../../features/home_widget/short_texts.dart';

class WidgetDataService {
  WidgetDataService._();
  static final WidgetDataService instance = WidgetDataService._();

  static const _appGroupId = 'group.com.shkomaghdid.myprayers';
  static const _iosName = 'MyPrayersWidget';
  static const _androidName = 'PrayersAppWidgetProvider';

  Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  Future<void> push({
    required ShortPiece piece,
    required String langCode,
    required String fontFamily,
  }) async {
    await HomeWidget.saveWidgetData<String>('arabic', piece.arabic);
    await HomeWidget.saveWidgetData<String>(
      'translation',
      piece.translationFor(langCode),
    );
    await HomeWidget.saveWidgetData<String>('reference', piece.reference);
    await HomeWidget.saveWidgetData<String>('lang', langCode);
    await HomeWidget.saveWidgetData<String>('font', fontFamily);
    await HomeWidget.saveWidgetData<int>(
        'updatedAt', DateTime.now().millisecondsSinceEpoch);
    await HomeWidget.updateWidget(name: _androidName, iOSName: _iosName);
  }

  Future<void> randomizeAndPush({
    required String type,
    required String langCode,
    required String fontFamily,
  }) async {
    final list = type == 'azkar'
        ? shortAzkars
        : (type == 'ayah' ? shortAyahs : [...shortAzkars, ...shortAyahs]);
    final pick = list[Random().nextInt(list.length)];
    await push(piece: pick, langCode: langCode, fontFamily: fontFamily);
  }
}
