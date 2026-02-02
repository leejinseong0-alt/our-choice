import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const OurChoiceApp());
}

/* -------------------------
   1) 앱 테마 및 스타일
------------------------- */
class OurChoiceApp extends StatelessWidget {
  const OurChoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '갈래 말래?',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B6B)),
        scaffoldBackgroundColor: const Color(0xFFF2F4F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: Color(0xFF191F28), fontSize: 24, fontWeight: FontWeight.w900),
          iconTheme: IconThemeData(color: Color(0xFF191F28)),
        ),
      ),
      home: const FoodSplashPage(),
    );
  }
}

/* -------------------------
   2) 데이터 모델
------------------------- */
class Question {
  final String id;
  String text;
  Question({required this.id, required this.text});
  Map<String, dynamic> toJson() => {'id': id, 'text': text};
  static Question fromJson(Map<String, dynamic> json) => Question(id: json['id'], text: json['text']);
}

class OptionItem {
  final String id;
  String name;
  Map<String, bool?> answers;
  OptionItem({required this.id, required this.name, Map<String, bool?>? answers}) : answers = answers ?? {};
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'answers': answers};
  static OptionItem fromJson(Map<String, dynamic> json) => OptionItem(
    id: json['id'], name: json['name'], answers: Map<String, bool?>.from(json['answers'] ?? {}));
}

class Category {
  final String id;
  String name;
  List<Question> questions;
  List<OptionItem> options;
  Category({required this.id, required this.name, List<Question>? questions, List<OptionItem>? options})
      : questions = questions ?? [], options = options ?? [];
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'questions': questions.map((q) => q.toJson()).toList(),
    'options': options.map((o) => o.toJson()).toList(),
  };
  static Category fromJson(Map<String, dynamic> json) => Category(
    id: json['id'], name: json['name'],
    questions: (json['questions'] as List? ?? []).map((e) => Question.fromJson(e)).toList(),
    options: (json['options'] as List? ?? []).map((e) => OptionItem.fromJson(e)).toList(),
  );
}

/* -------------------------
   3) UI 유틸리티
------------------------- */
Widget prettyCard(BuildContext context, Widget child, {Key? key}) {
  return Container(
    key: key,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}

Future<String?> showEditDialog(BuildContext context, String title, {String initialText = ''}) async {
  final ctrl = TextEditingController(text: initialText);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: '내용을 입력하세요'),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('확인')),
      ],
    ),
  );
}

/* -------------------------
   4) 메인 카테고리 페이지
------------------------- */
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});
  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Category> categories = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('our_choice_v3');
    if (raw != null) {
      setState(() => categories = (jsonDecode(raw) as List).map((e) => Category.fromJson(e)).toList());
    } else {
      // 데이터가 없으면 기본 데이터 생성
      setState(() => categories = [_generateDefaultCategory()]);
      _save();
    }
    setState(() => loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('our_choice_v3', jsonEncode(categories.map((c) => c.toJson()).toList()));
  }

  // ★★★ [수정됨] 메뉴 데이터 160종으로 대폭 추가 ★★★
  Category _generateDefaultCategory() {
    // 1. 질문 정의 (ID 부여)
    final qs = [
      Question(id: 'q_spicy', text: "지금 스트레스 받아? 매운 게 땡겨?"),
      Question(id: 'q_fresh', text: "입안이 텁텁해? 상큼하거나 차가운 게 좋아?"),
      Question(id: 'q_oily', text: "느끼하고 고소한 기름진 음식이 당겨?"),
      Question(id: 'q_salty', text: "입맛이 없어? 짭짤하고 자극적인 게 필요해?"),
      Question(id: 'q_sweet_salty', text: "단짠단짠의 정석을 느끼고 싶어?"),
      Question(id: 'q_rice', text: "무조건 밥이야? 탄수화물(곡물)이 꼭 있어야 해?"),
      Question(id: 'q_noodle', text: "후루룩 소리 내며 먹는 면 요리가 좋아?"),
      Question(id: 'q_meat', text: "오늘 고기 썰거나 뜯고 싶어? (육류 선호)"),
      Question(id: 'q_fried', text: "바삭바삭 소리가 나는 튀긴 음식이 땡겨?"),
      Question(id: 'q_soup', text: "숟가락으로 떠먹는 뜨끈한 국물이 필요해?"),
      Question(id: 'q_seafood', text: "해산물이나 생선 종류를 좋아해?"),
      Question(id: 'q_heavy', text: "지금 배가 너무 고파서 쓰러질 것 같아? (헤비한 음식)"),
      Question(id: 'q_light', text: "다이어트 중이거나 가볍게 먹고 싶어? (라이트한 음식)"),
      Question(id: 'q_hangover', text: "어제 술 마셨어? 해장이 시급해?"),
      Question(id: 'q_clean', text: "손에 묻히지 않고 깔끔하게 먹어야 하는 상황이야?"),
      Question(id: 'q_luxury', text: "오늘 나를 위해 돈 좀 쓰고 싶은 날이야? (고급 메뉴)"),
      Question(id: 'q_korean', text: "역시 한국인은 밥심! 한식이 당겨?"),
      Question(id: 'q_western', text: "치즈나 크림이 들어간 서양 스타일이 좋아?"),
      Question(id: 'q_chinese', text: "이국적이고 화끈한 불맛(중식)이 그리워?"),
      Question(id: 'q_japanese', text: "깔끔하고 정갈한 맛(일식)을 원해?"),
    ];

    OptionItem makeOpt(String name, List<String> trueAttributes) {
      final answers = <String, bool>{};
      for (var id in trueAttributes) { answers[id] = true; }
      return OptionItem(id: DateTime.now().toString() + name, name: name, answers: answers);
    }

    final opts = [
      // ---------------- 🇰🇷 한식 (Korean) 약 50종 ----------------
      // 찌개/탕
      makeOpt("김치찌개", ['q_spicy', 'q_soup', 'q_korean', 'q_heavy', 'q_hangover']),
      makeOpt("된장찌개", ['q_soup', 'q_korean', 'q_salty']),
      makeOpt("순두부찌개", ['q_spicy', 'q_soup', 'q_korean', 'q_soft']),
      makeOpt("부대찌개", ['q_spicy', 'q_soup', 'q_korean', 'q_heavy', 'q_meat', 'q_salty']),
      makeOpt("청국장", ['q_soup', 'q_korean', 'q_salty', 'q_heavy']),
      makeOpt("동태찌개", ['q_soup', 'q_korean', 'q_seafood', 'q_spicy', 'q_hangover']),
      makeOpt("알탕", ['q_soup', 'q_korean', 'q_seafood', 'q_spicy', 'q_hangover']),
      makeOpt("감자탕", ['q_spicy', 'q_soup', 'q_korean', 'q_heavy', 'q_meat', 'q_hangover']),
      makeOpt("갈비탕", ['q_soup', 'q_korean', 'q_meat', 'q_luxury', 'q_hangover']),
      makeOpt("삼계탕", ['q_soup', 'q_korean', 'q_meat', 'q_luxury', 'q_heavy']),
      makeOpt("육개장", ['q_spicy', 'q_soup', 'q_korean', 'q_meat', 'q_hangover']),
      makeOpt("미역국", ['q_soup', 'q_korean', 'q_clean', 'q_light']),
      makeOpt("설렁탕", ['q_soup', 'q_korean', 'q_meat', 'q_clean']),
      makeOpt("곰탕", ['q_soup', 'q_korean', 'q_meat', 'q_clean']),
      makeOpt("추어탕", ['q_soup', 'q_korean', 'q_heavy', 'q_hangover']),
      // 국밥
      makeOpt("순대국밥", ['q_soup', 'q_korean', 'q_meat', 'q_heavy', 'q_hangover']),
      makeOpt("돼지국밥", ['q_soup', 'q_korean', 'q_meat', 'q_heavy']),
      makeOpt("콩나물국밥", ['q_soup', 'q_korean', 'q_light', 'q_hangover']),
      makeOpt("소머리국밥", ['q_soup', 'q_korean', 'q_meat', 'q_heavy']),
      // 찜/볶음
      makeOpt("갈비찜", ['q_meat', 'q_korean', 'q_sweet_salty', 'q_heavy', 'q_luxury']),
      makeOpt("아구찜", ['q_seafood', 'q_korean', 'q_spicy', 'q_heavy', 'q_luxury']),
      makeOpt("해물찜", ['q_seafood', 'q_korean', 'q_spicy', 'q_heavy', 'q_luxury']),
      makeOpt("닭볶음탕", ['q_meat', 'q_korean', 'q_spicy', 'q_soup', 'q_heavy']),
      makeOpt("찜닭", ['q_meat', 'q_korean', 'q_sweet_salty', 'q_heavy', 'q_noodle']),
      makeOpt("제육볶음", ['q_meat', 'q_korean', 'q_spicy', 'q_heavy', 'q_rice']),
      makeOpt("오징어볶음", ['q_seafood', 'q_korean', 'q_spicy', 'q_rice']),
      makeOpt("주꾸미볶음", ['q_seafood', 'q_korean', 'q_spicy', 'q_rice']),
      makeOpt("낙지볶음", ['q_seafood', 'q_korean', 'q_spicy', 'q_luxury']),
      makeOpt("닭갈비", ['q_meat', 'q_korean', 'q_spicy', 'q_heavy']),
      makeOpt("불고기", ['q_meat', 'q_korean', 'q_salty', 'q_rice', 'q_sweet_salty']),
      // 구이/메인
      makeOpt("삼겹살", ['q_meat', 'q_korean', 'q_oily', 'q_heavy', 'q_luxury']),
      makeOpt("돼지갈비", ['q_meat', 'q_korean', 'q_sweet_salty', 'q_heavy']),
      makeOpt("소고기구이", ['q_meat', 'q_korean', 'q_luxury', 'q_oily']),
      makeOpt("곱창/대창", ['q_meat', 'q_korean', 'q_oily', 'q_heavy', 'q_luxury']),
      makeOpt("족발", ['q_meat', 'q_korean', 'q_heavy', 'q_oily', 'q_luxury']),
      makeOpt("보쌈", ['q_meat', 'q_korean', 'q_heavy', 'q_clean']),
      makeOpt("생선구이", ['q_seafood', 'q_korean', 'q_rice', 'q_clean']),
      makeOpt("육회", ['q_meat', 'q_korean', 'q_fresh', 'q_luxury']),
      // 면/밥/분식
      makeOpt("비빔밥", ['q_rice', 'q_korean', 'q_fresh', 'q_light']),
      makeOpt("돌솥비빔밥", ['q_rice', 'q_korean', 'q_heavy', 'q_oily']),
      makeOpt("육회비빔밥", ['q_rice', 'q_korean', 'q_fresh', 'q_luxury', 'q_meat']),
      makeOpt("물냉면", ['q_noodle', 'q_korean', 'q_fresh', 'q_soup', 'q_light', 'q_hangover']),
      makeOpt("비빔냉면", ['q_noodle', 'q_korean', 'q_fresh', 'q_spicy']),
      makeOpt("칼국수", ['q_noodle', 'q_korean', 'q_soup', 'q_heavy']),
      makeOpt("수제비", ['q_noodle', 'q_korean', 'q_soup']),
      makeOpt("잔치국수", ['q_noodle', 'q_korean', 'q_soup', 'q_light']),
      makeOpt("비빔국수", ['q_noodle', 'q_korean', 'q_spicy', 'q_fresh']),
      makeOpt("콩국수", ['q_noodle', 'q_korean', 'q_fresh', 'q_light', 'q_clean']),
      makeOpt("떡만두국", ['q_soup', 'q_korean', 'q_heavy']),
      makeOpt("떡볶이", ['q_spicy', 'q_korean', 'q_salty', 'q_sweet_salty']),
      makeOpt("김밥", ['q_rice', 'q_korean', 'q_light', 'q_clean']),
      makeOpt("순대", ['q_korean', 'q_heavy']),
      makeOpt("파전/빈대떡", ['q_korean', 'q_oily', 'q_fried']),
      makeOpt("간장게장", ['q_seafood', 'q_korean', 'q_salty', 'q_rice', 'q_luxury']),

      // ---------------- 🇨🇳 중식 (Chinese) 약 35종 ----------------
      // 면류
      makeOpt("짜장면", ['q_noodle', 'q_chinese', 'q_oily', 'q_sweet_salty', 'q_heavy']),
      makeOpt("간짜장", ['q_noodle', 'q_chinese', 'q_oily', 'q_salty', 'q_heavy']),
      makeOpt("쟁반짜장", ['q_noodle', 'q_chinese', 'q_oily', 'q_seafood', 'q_heavy']),
      makeOpt("짬뽕", ['q_noodle', 'q_chinese', 'q_spicy', 'q_soup', 'q_seafood', 'q_hangover']),
      makeOpt("백짬뽕", ['q_noodle', 'q_chinese', 'q_soup', 'q_seafood', 'q_hangover', 'q_clean']),
      makeOpt("마라탕", ['q_chinese', 'q_spicy', 'q_soup', 'q_heavy', 'q_salty']),
      makeOpt("우동(중식)", ['q_noodle', 'q_chinese', 'q_soup', 'q_clean']),
      makeOpt("울면", ['q_noodle', 'q_chinese', 'q_soup', 'q_heavy']),
      makeOpt("기스면", ['q_noodle', 'q_chinese', 'q_soup', 'q_light']),
      makeOpt("탄탄면", ['q_noodle', 'q_chinese', 'q_spicy', 'q_oily', 'q_heavy']),
      makeOpt("중국냉면", ['q_noodle', 'q_chinese', 'q_fresh', 'q_soup']),
      // 밥류
      makeOpt("볶음밥", ['q_rice', 'q_chinese', 'q_oily', 'q_heavy']),
      makeOpt("잡채밥", ['q_rice', 'q_chinese', 'q_oily', 'q_noodle', 'q_heavy']),
      makeOpt("마파두부밥", ['q_rice', 'q_chinese', 'q_spicy', 'q_soft']),
      makeOpt("유산슬밥", ['q_rice', 'q_chinese', 'q_seafood', 'q_meat', 'q_soft']),
      makeOpt("고추잡채밥", ['q_rice', 'q_chinese', 'q_spicy', 'q_meat']),
      // 요리류
      makeOpt("탕수육", ['q_meat', 'q_chinese', 'q_fried', 'q_sweet_salty', 'q_heavy']),
      makeOpt("꿔바로우", ['q_meat', 'q_chinese', 'q_fried', 'q_sweet_salty']),
      makeOpt("사천탕수육", ['q_meat', 'q_chinese', 'q_fried', 'q_spicy']),
      makeOpt("깐풍기", ['q_meat', 'q_chinese', 'q_fried', 'q_spicy']),
      makeOpt("유린기", ['q_meat', 'q_chinese', 'q_fried', 'q_fresh', 'q_oily']),
      makeOpt("라조기", ['q_meat', 'q_chinese', 'q_fried', 'q_spicy', 'q_heavy']),
      makeOpt("크림새우", ['q_seafood', 'q_chinese', 'q_fried', 'q_sweet_salty', 'q_oily']),
      makeOpt("칠리새우", ['q_seafood', 'q_chinese', 'q_fried', 'q_spicy', 'q_sweet_salty']),
      makeOpt("깐쇼새우", ['q_seafood', 'q_chinese', 'q_fried', 'q_spicy']),
      makeOpt("멘보샤", ['q_fried', 'q_chinese', 'q_seafood', 'q_oily']),
      makeOpt("양장피", ['q_chinese', 'q_fresh', 'q_seafood', 'q_salty', 'q_luxury']),
      makeOpt("팔보채", ['q_chinese', 'q_seafood', 'q_luxury', 'q_heavy']),
      makeOpt("유산슬", ['q_chinese', 'q_seafood', 'q_meat', 'q_luxury', 'q_soft']),
      makeOpt("전가복", ['q_chinese', 'q_seafood', 'q_luxury', 'q_clean']),
      makeOpt("난자완스", ['q_chinese', 'q_meat', 'q_heavy', 'q_soft']),
      makeOpt("동파육", ['q_chinese', 'q_meat', 'q_heavy', 'q_soft', 'q_luxury']),
      makeOpt("군만두", ['q_fried', 'q_chinese', 'q_oily']),
      makeOpt("딤섬", ['q_chinese', 'q_clean', 'q_meat', 'q_seafood']),
      makeOpt("양꼬치/훠궈", ['q_chinese', 'q_meat', 'q_oily', 'q_spicy', 'q_luxury']),
      makeOpt("마라샹궈", ['q_chinese', 'q_spicy', 'q_oily', 'q_heavy', 'q_meat']),

      // ---------------- 🇯🇵 일식 (Japanese) 약 35종 ----------------
      // 밥/덮밥
      makeOpt("초밥(스시)", ['q_rice', 'q_japanese', 'q_fresh', 'q_seafood', 'q_clean', 'q_luxury']),
      makeOpt("회덮밥", ['q_rice', 'q_japanese', 'q_fresh', 'q_seafood', 'q_spicy', 'q_light']),
      makeOpt("사케동(연어)", ['q_rice', 'q_japanese', 'q_fresh', 'q_seafood', 'q_oily']),
      makeOpt("카이센동", ['q_rice', 'q_japanese', 'q_fresh', 'q_seafood', 'q_luxury']),
      makeOpt("규동", ['q_rice', 'q_japanese', 'q_meat', 'q_sweet_salty']),
      makeOpt("가츠동", ['q_rice', 'q_japanese', 'q_meat', 'q_fried', 'q_heavy']),
      makeOpt("오야코동", ['q_rice', 'q_japanese', 'q_meat', 'q_soft', 'q_light']),
      makeOpt("텐동", ['q_rice', 'q_japanese', 'q_fried', 'q_oily', 'q_seafood']),
      makeOpt("부타동", ['q_rice', 'q_japanese', 'q_meat', 'q_oily', 'q_heavy']),
      makeOpt("장어덮밥", ['q_rice', 'q_japanese', 'q_seafood', 'q_luxury', 'q_heavy']),
      makeOpt("일본식 카레", ['q_rice', 'q_japanese', 'q_heavy', 'q_spicy']),
      makeOpt("하이라이스", ['q_rice', 'q_japanese', 'q_heavy', 'q_sweet_salty']),
      makeOpt("오차즈케", ['q_rice', 'q_japanese', 'q_clean', 'q_light', 'q_soup']),
      // 면류
      makeOpt("라멘(돈코츠)", ['q_noodle', 'q_japanese', 'q_soup', 'q_oily', 'q_heavy', 'q_hangover']),
      makeOpt("라멘(쇼유/시오)", ['q_noodle', 'q_japanese', 'q_soup', 'q_clean']),
      makeOpt("미소라멘", ['q_noodle', 'q_japanese', 'q_soup', 'q_heavy']),
      makeOpt("마제소바", ['q_noodle', 'q_japanese', 'q_oily', 'q_heavy', 'q_spicy']),
      makeOpt("우동", ['q_noodle', 'q_japanese', 'q_soup', 'q_clean', 'q_light']),
      makeOpt("냉모밀(소바)", ['q_noodle', 'q_japanese', 'q_fresh', 'q_clean', 'q_light']),
      makeOpt("야끼소바", ['q_noodle', 'q_japanese', 'q_oily', 'q_sweet_salty']),
      makeOpt("츠케멘", ['q_noodle', 'q_japanese', 'q_heavy', 'q_salty']),
      // 카츠/튀김/기타
      makeOpt("돈카츠(등심)", ['q_meat', 'q_japanese', 'q_fried', 'q_oily', 'q_heavy']),
      makeOpt("돈카츠(안심)", ['q_meat', 'q_japanese', 'q_fried', 'q_oily', 'q_soft']),
      makeOpt("치즈카츠", ['q_meat', 'q_japanese', 'q_fried', 'q_oily', 'q_heavy', 'q_western']),
      makeOpt("고로케", ['q_fried', 'q_japanese', 'q_oily', 'q_soft']),
      makeOpt("새우튀김", ['q_fried', 'q_japanese', 'q_seafood', 'q_oily']),
      makeOpt("가라아게", ['q_fried', 'q_japanese', 'q_meat', 'q_oily']),
      makeOpt("사시미", ['q_japanese', 'q_fresh', 'q_seafood', 'q_light', 'q_luxury', 'q_clean']),
      makeOpt("타코야끼", ['q_japanese', 'q_seafood', 'q_sweet_salty', 'q_heavy']),
      makeOpt("오코노미야끼", ['q_japanese', 'q_seafood', 'q_meat', 'q_heavy', 'q_oily']),
      makeOpt("샤브샤브", ['q_japanese', 'q_meat', 'q_soup', 'q_clean', 'q_luxury', 'q_light']),
      makeOpt("스키야키", ['q_japanese', 'q_meat', 'q_sweet_salty', 'q_luxury']),
      makeOpt("모츠나베", ['q_japanese', 'q_soup', 'q_meat', 'q_oily', 'q_heavy']),
      makeOpt("야키토리", ['q_japanese', 'q_meat', 'q_oily', 'q_clean']),

      // ---------------- 🇮🇹 양식/기타 (Western) 약 40종 ----------------
      // 파스타
      makeOpt("알리오올리오", ['q_noodle', 'q_western', 'q_oily', 'q_clean', 'q_light']),
      makeOpt("까르보나라", ['q_noodle', 'q_western', 'q_oily', 'q_heavy', 'q_salty']),
      makeOpt("토마토 파스타", ['q_noodle', 'q_western', 'q_fresh']),
      makeOpt("로제 파스타", ['q_noodle', 'q_western', 'q_oily', 'q_soft']),
      makeOpt("봉골레", ['q_noodle', 'q_western', 'q_seafood', 'q_oily', 'q_clean']),
      makeOpt("투움바 파스타", ['q_noodle', 'q_western', 'q_spicy', 'q_oily', 'q_heavy']),
      makeOpt("바질페스토 파스타", ['q_noodle', 'q_western', 'q_oily', 'q_fresh']),
      makeOpt("라자냐", ['q_western', 'q_heavy', 'q_oily', 'q_meat', 'q_salty']),
      makeOpt("뇨끼", ['q_western', 'q_heavy', 'q_oily', 'q_soft']),
      // 피자/리조또
      makeOpt("마르게리따 피자", ['q_western', 'q_oily', 'q_clean']),
      makeOpt("페퍼로니 피자", ['q_western', 'q_oily', 'q_heavy', 'q_salty', 'q_meat']),
      makeOpt("고르곤졸라", ['q_western', 'q_oily', 'q_sweet_salty']),
      makeOpt("시카고 피자", ['q_western', 'q_oily', 'q_heavy', 'q_cheese']),
      makeOpt("버섯 크림 리조또", ['q_rice', 'q_western', 'q_oily', 'q_heavy', 'q_luxury']),
      makeOpt("해산물 리조또", ['q_rice', 'q_western', 'q_seafood', 'q_fresh']),
      makeOpt("먹물 리조또", ['q_rice', 'q_western', 'q_seafood', 'q_luxury']),
      // 메인/스테이크
      makeOpt("안심 스테이크", ['q_meat', 'q_western', 'q_heavy', 'q_luxury', 'q_clean']),
      makeOpt("등심 스테이크", ['q_meat', 'q_western', 'q_heavy', 'q_luxury', 'q_oily']),
      makeOpt("티본 스테이크", ['q_meat', 'q_western', 'q_heavy', 'q_luxury', 'q_oily']),
      makeOpt("함박 스테이크", ['q_meat', 'q_western', 'q_heavy', 'q_sweet_salty']),
      makeOpt("바비큐 폭립", ['q_meat', 'q_western', 'q_heavy', 'q_sweet_salty', 'q_luxury']),
      makeOpt("찹스테이크", ['q_meat', 'q_western', 'q_heavy', 'q_sweet_salty']),
      makeOpt("감바스", ['q_seafood', 'q_western', 'q_oily', 'q_salty', 'q_luxury']),
      makeOpt("에그인헬", ['q_western', 'q_spicy', 'q_heavy', 'q_soup']),
      makeOpt("비프 스튜", ['q_western', 'q_meat', 'q_soup', 'q_heavy']),
      // 패스트푸드/브런치/멕시칸
      makeOpt("수제버거", ['q_meat', 'q_western', 'q_heavy', 'q_oily', 'q_salty', 'q_luxury']),
      makeOpt("치즈버거", ['q_meat', 'q_western', 'q_heavy', 'q_oily', 'q_salty']),
      makeOpt("샌드위치", ['q_western', 'q_fresh', 'q_light', 'q_clean']),
      makeOpt("서브웨이", ['q_western', 'q_fresh', 'q_light', 'q_clean']),
      makeOpt("베이글&크림치즈", ['q_western', 'q_light', 'q_clean', 'q_cheese']),
      makeOpt("프렌치토스트", ['q_western', 'q_oily', 'q_sweet_salty', 'q_soft']),
      makeOpt("브런치 플래터", ['q_western', 'q_light', 'q_clean', 'q_luxury']),
      makeOpt("타코", ['q_western', 'q_meat', 'q_fresh', 'q_light', 'q_spicy']),
      makeOpt("부리또", ['q_western', 'q_meat', 'q_heavy', 'q_rice']),
      makeOpt("퀘사디아", ['q_western', 'q_meat', 'q_oily', 'q_cheese']),
      makeOpt("치킨(후라이드)", ['q_meat', 'q_western', 'q_fried', 'q_oily', 'q_heavy']),
      makeOpt("치킨(양념)", ['q_meat', 'q_western', 'q_fried', 'q_sweet_salty', 'q_heavy']),
      makeOpt("시저 샐러드", ['q_western', 'q_fresh', 'q_light', 'q_clean']),
      makeOpt("포케(Poke)", ['q_western', 'q_fresh', 'q_light', 'q_clean', 'q_seafood', 'q_rice']),
    ];

    return Category(id: DateTime.now().toString(), name: "오늘 뭐 먹지? (160종)", questions: qs, options: opts);
  }

  void _resetData() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('데이터 초기화'),
      content: const Text('기본 제공되는 160여가지 음식 데이터로 덮어씌우시겠습니까?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        ElevatedButton(onPressed: () {
          setState(() => categories = [_generateDefaultCategory()]);
          _save();
          Navigator.pop(ctx);
        }, child: const Text('확인')),
      ],
    ));
  }

  void _addOrEdit({Category? category}) async {
    final res = await showEditDialog(context, category == null ? '새 카테고리' : '이름 수정', initialText: category?.name ?? '');
    if (res != null && res.trim().isNotEmpty) {
      setState(() {
        if (category == null) categories.add(Category(id: DateTime.now().toString(), name: res));
        else category.name = res;
      });
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {const SingleActivator(LogicalKeyboardKey.keyN): const ActivateIntent()},
      child: Actions(
        actions: {ActivateIntent: CallbackAction(onInvoke: (_) => _addOrEdit())},
        child: Focus(autofocus: true, child: Scaffold(
          appBar: AppBar(
            title: const Text('갈래 말래?'),
            actions: [
              IconButton(onPressed: _resetData, icon: const Icon(Icons.refresh), tooltip: '기본 데이터 로드'),
            ],
          ),
          body: loading ? const Center(child: CircularProgressIndicator()) : ReorderableListView.builder(
            buildDefaultDragHandles: false, 
            itemCount: categories.length,
            onReorder: (o, n) { setState(() { if (n > o) n -= 1; categories.insert(n, categories.removeAt(o)); }); _save(); },
            itemBuilder: (ctx, i) => Dismissible(
              key: ValueKey(categories[i].id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) { setState(() => categories.removeAt(i)); _save(); },
              background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
              child: prettyCard(ctx, ListTile(
                leading: ReorderableDragStartListener(
                  index: i,
                  child: const Icon(Icons.drag_handle, color: Colors.grey),
                ),
                title: Text(categories[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _addOrEdit(category: categories[i])),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailPage(category: categories[i], onSave: _save))),
              )),
            ),
          ),
          floatingActionButton: FloatingActionButton(onPressed: () => _addOrEdit(), child: const Icon(Icons.add)),
        )),
      ),
    );
  }
}

/* -------------------------
   5) 상세 관리
------------------------- */
class CategoryDetailPage extends StatelessWidget {
  final Category category;
  final Future<void> Function() onSave;
  const CategoryDetailPage({super.key, required this.category, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(category.name),
          actions: [IconButton(icon: const Icon(Icons.play_circle_fill, size: 32, color: Colors.redAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FunnelPage(category: category))))],
          bottom: const TabBar(tabs: [Tab(text: '항목'), Tab(text: '질문')]),
        ),
        body: TabBarView(children: [
          OptionsPage(category: category, onSave: onSave),
          QuestionsPage(category: category, onSave: onSave),
        ]),
      ),
    );
  }
}

// 질문 관리
class QuestionsPage extends StatefulWidget {
  final Category category;
  final Future<void> Function() onSave;
  const QuestionsPage({super.key, required this.category, required this.onSave});
  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  void _addOrEdit({Question? q}) async {
    final res = await showEditDialog(context, q == null ? '질문 추가' : '질문 수정', initialText: q?.text ?? '');
    if (res != null && res.trim().isNotEmpty) {
      setState(() {
        if (q == null) widget.category.questions.add(Question(id: DateTime.now().toString(), text: res));
        else q.text = res;
      });
      widget.onSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {const SingleActivator(LogicalKeyboardKey.keyN): const ActivateIntent()},
      child: Actions(
        actions: {ActivateIntent: CallbackAction(onInvoke: (_) => _addOrEdit())},
        child: Focus(
          autofocus: true, 
          child: Scaffold(
            body: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: widget.category.questions.length,
              onReorder: (o, n) { setState(() { if (n > o) n -= 1; widget.category.questions.insert(n, widget.category.questions.removeAt(o)); }); widget.onSave(); },
              itemBuilder: (ctx, i) {
                final q = widget.category.questions[i];
                return Dismissible(
                  key: ValueKey(q.id),
                  onDismissed: (_) { setState(() => widget.category.questions.removeAt(i)); widget.onSave(); },
                  child: prettyCard(ctx, ListTile(
                    leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle, color: Colors.grey)),
                    title: Text(q.text),
                    trailing: IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _addOrEdit(q: q)),
                  )),
                );
              },
            ),
            floatingActionButton: FloatingActionButton(onPressed: () => _addOrEdit(), child: const Icon(Icons.add)),
          ),
        ),
      ),
    );
  }
}

// 항목 관리
class OptionsPage extends StatefulWidget {
  final Category category;
  final Future<void> Function() onSave;
  const OptionsPage({super.key, required this.category, required this.onSave});
  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  void _addOrEdit({OptionItem? opt}) async {
    final res = await showEditDialog(context, opt == null ? '항목 추가' : '이름 수정', initialText: opt?.name ?? '');
    if (res != null && res.trim().isNotEmpty) {
      setState(() {
        if (opt == null) widget.category.options.add(OptionItem(id: DateTime.now().toString(), name: res));
        else opt.name = res;
      });
      widget.onSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {const SingleActivator(LogicalKeyboardKey.keyN): const ActivateIntent()},
      child: Actions(
        actions: {ActivateIntent: CallbackAction(onInvoke: (_) => _addOrEdit())},
        child: Focus(
          autofocus: true, 
          child: Scaffold(
            body: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: widget.category.options.length,
              onReorder: (o, n) { setState(() { if (n > o) n -= 1; widget.category.options.insert(n, widget.category.options.removeAt(o)); }); widget.onSave(); },
              itemBuilder: (ctx, i) {
                final opt = widget.category.options[i];
                return Dismissible(
                  key: ValueKey(opt.id),
                  onDismissed: (_) { setState(() => widget.category.options.removeAt(i)); widget.onSave(); },
                  child: prettyCard(ctx, ListTile(
                    leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle, color: Colors.grey)),
                    title: Text(opt.name),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _addOrEdit(opt: opt)),
                      IconButton(icon: const Icon(Icons.settings, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OptionAnswerPage(category: widget.category, option: opt, onSave: widget.onSave)))),
                    ]),
                  )),
                );
              },
            ),
            floatingActionButton: FloatingActionButton(onPressed: () => _addOrEdit(), child: const Icon(Icons.add)),
          ),
        ),
      ),
    );
  }
}

/* -------------------------
   6) 기타 페이지
------------------------- */
class FoodSplashPage extends StatefulWidget {
  const FoodSplashPage({super.key});
  @override
  State<FoodSplashPage> createState() => _FoodSplashPageState();
}

class _FoodSplashPageState extends State<FoodSplashPage> with TickerProviderStateMixin {
  final List<String> icons = ['🍕', '🍔', '🍣', '🍜', '🌮', '🍗', '🍱', '🥘', '🍦', '🍩'];
  late List<_Part> parts;
  @override
  void initState() {
    super.initState();
    parts = List.generate(10, (i) => _Part(icons[Random().nextInt(icons.length)], this));
    Timer(const Duration(milliseconds: 2000), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CategoryPage())));
  }
  @override
  void dispose() { for (var p in parts) { p.ctrl.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Stack(children: [
      ...parts.map((p) => AnimatedBuilder(animation: p.ctrl, builder: (_, __) => Positioned(left: p.x + (p.mx * p.ctrl.value), top: p.y + (p.my * p.ctrl.value), child: Opacity(opacity: 0.3, child: Text(p.icon, style: const TextStyle(fontSize: 40)))))),
      const Center(child: Text('갈래 말래?', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900))),
    ]));
  }
}

class _Part {
  final String icon; final AnimationController ctrl; final double x, y, mx, my;
  _Part(this.icon, TickerProvider v) : ctrl = AnimationController(vsync: v, duration: const Duration(seconds: 2))..repeat(reverse: true), x = Random().nextDouble() * 300, y = Random().nextDouble() * 600, mx = (Random().nextDouble()-0.5)*100, my = (Random().nextDouble()-0.5)*100;
}

class OptionAnswerPage extends StatefulWidget {
  final Category category; final OptionItem option; final Future<void> Function() onSave;
  const OptionAnswerPage({super.key, required this.category, required this.option, required this.onSave});
  @override
  State<OptionAnswerPage> createState() => _OptionAnswerPageState();
}

class _OptionAnswerPageState extends State<OptionAnswerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.option.name} 설정')),
      body: ListView.builder(
        itemCount: widget.category.questions.length,
        itemBuilder: (ctx, i) {
          final q = widget.category.questions[i];
          return prettyCard(ctx, ListTile(
            title: Text(q.text),
            trailing: SegmentedButton<bool?>(
              segments: const [ButtonSegment(value: true, label: Text('예')), ButtonSegment(value: false, label: Text('아니오')), ButtonSegment(value: null, label: Text('무시'))],
              selected: {widget.option.answers[q.id]},
              onSelectionChanged: (v) { setState(() => widget.option.answers[q.id] = v.first); widget.onSave(); },
            ),
          ));
        },
      ),
    );
  }
}

/* -------------------------
   ★ 결과 화면 (랜덤 뽑기 기능 유지)
------------------------- */
class FunnelPage extends StatefulWidget {
  final Category category;
  const FunnelPage({super.key, required this.category});
  @override
  State<FunnelPage> createState() => _FunnelPageState();
}

class _FunnelPageState extends State<FunnelPage> {
  int qIdx = 0; 
  List<String> yesIds = [];
  
  // 랜덤 결과를 저장할 변수 (빌드 때마다 바뀌지 않도록)
  OptionItem? _randomWinner;
  
  @override
  Widget build(BuildContext context) {
    final qs = widget.category.questions; 
    final done = qIdx >= qs.length;
    
    // 점수 계산
    final scores = { for (var o in widget.category.options) o.id : 0 };
    for (var o in widget.category.options) {
      int s = 0; 
      for (var y in yesIds) { if (o.answers[y] == true) s++; } 
      scores[o.id] = s;
    }
    
    // 점수 내림차순 정렬
    final sorted = List.of(widget.category.options)..sort((a, b) => scores[b.id]!.compareTo(scores[a.id]!));

    // ★ 동점자 처리 및 랜덤 뽑기 로직
    if (done && _randomWinner == null && sorted.isNotEmpty) {
      final maxScore = scores[sorted.first.id] ?? 0;
      // 최고 점수를 가진 후보들을 모두 추림
      final topCandidates = sorted.where((o) => scores[o.id] == maxScore).toList();
      // 그 중에서 랜덤으로 하나 선택
      _randomWinner = topCandidates[Random().nextInt(topCandidates.length)];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('베스트 추천')), 
      body: Column(
        children: [
          if (!done) 
            prettyCard(context, Padding(padding: const EdgeInsets.all(24), child: Column(children: [
              Text(qs[qIdx].text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ElevatedButton(onPressed: () => setState(() { yesIds.add(qs[qIdx].id); qIdx++; }), child: const Text('예')),
                ElevatedButton(onPressed: () => setState(() => qIdx++), child: const Text('아니오')),
              ])
            ]))) 
          else 
            Padding(
              padding: const EdgeInsets.all(20), 
              child: Column(
                children: [
                  const Text('🎉 오늘의 추천 메뉴 🎉', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(_randomWinner?.name ?? '결과 없음', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFFF6B6B))),
                  const SizedBox(height: 8),
                  if (_randomWinner != null)
                    Text('(최고 점수 ${scores[_randomWinner!.id]}점 후보들 중 랜덤 선택)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            ),
          
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length, 
              itemBuilder: (ctx, i) {
                final item = sorted[i];
                final score = scores[item.id];
                // 1등(랜덤 당첨)인 경우 강조 표시
                final isWinner = (done && item.id == _randomWinner?.id);
                
                return Container(
                  color: isWinner ? const Color(0xFFFFECEC) : null, // 당첨된 항목 배경색 살짝 변경
                  child: ListTile(
                    leading: Text('${i+1}위', style: TextStyle(fontWeight: FontWeight.bold, color: isWinner ? const Color(0xFFFF6B6B) : Colors.black)), 
                    title: Text(item.name, style: TextStyle(fontWeight: isWinner ? FontWeight.bold : FontWeight.normal)), 
                    trailing: Text('$score점'),
                  ),
                );
              }
            )
          )
        ]
      )
    );
  }
}