import 'package:dfranc/dfranc.dart';
import 'package:test/test.dart';

void main() {
  final franc = Franc();
  test('correctly detects language', () async {
    final String textInRussian1 = "Я пришёл к тебе с приветом,"
        "Рассказать, что солнце встало,"
        "Что оно горячим светом"
        "По листам затрепетало;"
        "Рассказать, что лес проснулся,"
        "Весь проснулся, веткой каждой,"
        "Каждой птицей встрепенулся"
        "И весенней полон жаждой;"
        "Рассказать, что с той же страстью,"
        "Как вчера, пришёл я снова,"
        "Что душа всё так же счастью"
        "И тебе служить готова;"
        "Рассказать, что отовсюду"
        "На меня весельем веет,"
        "Что не знаю сам, что буду"
        "Петь — но только песня зреет.";
    final result1 = await franc.detectLanguages(textInRussian1);
    expect(result1["rus"], 1.0);
    print(result1);

    final String textInRussian2 = "Кот стоит на задних лапах";
    final result2 = await franc.detectLanguages(textInRussian2);
    expect(result2["mkd"], 1.0);
    print(result2);

    final String textInRussian3 = "Слава слава слава";
    final result3 = await franc.detectLanguages(textInRussian3);
    expect(result3["bos"], 1.0);
    print(result3);
  });
}
