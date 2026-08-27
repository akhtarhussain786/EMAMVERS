class ExamCategory {
  final int id;
  final String name;
  final String slug;
  final String type;
  final String? description;

  ExamCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    this.description,
  });

  factory ExamCategory.fromJson(Map<String, dynamic> json) {
    return ExamCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      type: json['type'] ?? 'government',
      description: json['description'],
    );
  }
}

class ExamItem {
  final int id;
  final String title;
  final String slug;
  final String? shortDescription;
  final String? categoryName;
  final String? orgName;

  ExamItem({
    required this.id,
    required this.title,
    required this.slug,
    this.shortDescription,
    this.categoryName,
    this.orgName,
  });

  factory ExamItem.fromJson(Map<String, dynamic> json) {
    return ExamItem(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      shortDescription: json['short_description'],
      categoryName: json['category_name'],
      orgName: json['org_name'],
    );
  }
}

class TestItem {
  final int id;
  final String title;
  final String slug;
  final String testType;
  final bool isPaid;
  final double price;
  final int? totalQuestions;
  final double? totalMarks;
  final int? totalDurationSeconds;

  TestItem({
    required this.id,
    required this.title,
    required this.slug,
    required this.testType,
    required this.isPaid,
    required this.price,
    this.totalQuestions,
    this.totalMarks,
    this.totalDurationSeconds,
  });

  factory TestItem.fromJson(Map<String, dynamic> json) {
    return TestItem(
      id: json['id'],
      title: json['title'],
      slug: json['slug'] ?? '',
      testType: json['test_type'] ?? 'full_mock',
      isPaid: json['is_paid'] == 1 || json['is_paid'] == true,
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      totalQuestions: json['total_questions'],
      totalMarks: json['total_marks'] != null ? double.parse(json['total_marks'].toString()) : null,
      totalDurationSeconds: json['total_duration_seconds'],
    );
  }
}

class QuestionItem {
  final int questionId;
  final int questionOrder;
  final double positiveMarks;
  final double negativeMarks;
  final String? sectionName;
  final String questionType;
  final List<QuestionTranslation> translations;
  final List<QuestionOption> options;
  
  // User attempt state during player
  String? selectedOptionKey;
  String? numericalAnswer;
  bool isMarkedForReview;
  int timeSpentSeconds;

  int get id => questionId;
  String? get selectedOption => selectedOptionKey;
  set selectedOption(String? val) => selectedOptionKey = val;
  bool get isAnswered => (selectedOptionKey != null && selectedOptionKey!.isNotEmpty) || (numericalAnswer != null && numericalAnswer!.isNotEmpty);
  set isAnswered(bool val) {}
  String get questionText {
    if (translations.isNotEmpty) return translations.first.questionText;
    return 'Question';
  }

  QuestionItem({
    required this.questionId,
    required this.questionOrder,
    required this.positiveMarks,
    required this.negativeMarks,
    this.sectionName,
    required this.questionType,
    required this.translations,
    required this.options,
    this.selectedOptionKey,
    this.numericalAnswer,
    this.isMarkedForReview = false,
    this.timeSpentSeconds = 0,
  });

  factory QuestionItem.fromJson(Map<String, dynamic> json) {
    var transList = (json['translations'] as List? ?? []).map((t) => QuestionTranslation.fromJson(t)).toList();
    var optsList = (json['options'] as List? ?? []).map((o) => QuestionOption.fromJson(o)).toList();
    var uState = json['user_state'];

    return QuestionItem(
      questionId: json['question_id'],
      questionOrder: json['question_order'],
      positiveMarks: double.parse(json['positive_marks'].toString()),
      negativeMarks: double.parse(json['negative_marks'].toString()),
      sectionName: json['section_name'],
      questionType: json['question_type'] ?? 'MCQ',
      translations: transList,
      options: optsList,
      selectedOptionKey: uState != null ? uState['selected_option_key'] : null,
      numericalAnswer: uState != null ? uState['numerical_answer'] : null,
      isMarkedForReview: uState != null && (uState['is_marked_for_review'] == 1 || uState['is_marked_for_review'] == true),
      timeSpentSeconds: uState != null ? (uState['time_spent_seconds'] ?? 0) : 0,
    );
  }
}

class QuestionTranslation {
  final String language;
  final String questionText;

  QuestionTranslation({required this.language, required this.questionText});

  factory QuestionTranslation.fromJson(Map<String, dynamic> json) {
    return QuestionTranslation(
      language: json['language'] ?? 'en',
      questionText: json['question_text'] ?? '',
    );
  }
}

class QuestionOption {
  final int id;
  final String optionKey;
  final String language;
  final String optionText;

  QuestionOption({
    required this.id,
    required this.optionKey,
    required this.language,
    required this.optionText,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'],
      optionKey: json['option_key'],
      language: json['language'] ?? 'en',
      optionText: json['option_text'] ?? '',
    );
  }
}
