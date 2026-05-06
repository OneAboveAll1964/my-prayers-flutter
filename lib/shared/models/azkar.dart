class AzkarCategory {
  AzkarCategory({required this.id, required this.name});
  final int id;
  final String name;
}

class AzkarChapter {
  AzkarChapter({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
  });
  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
}

class AzkarItem {
  AzkarItem({
    required this.id,
    required this.chapterId,
    this.item,
    this.transliteration,
    this.count,
    this.topNote,
    this.bottomNote,
    this.translation,
    required this.reference,
  });
  final int id;
  final int chapterId;
  final String? item;
  final String? transliteration;
  final int? count;
  final String? topNote;
  final String? bottomNote;
  final String? translation;
  final String reference;
}
