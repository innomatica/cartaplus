class Category {
  String id;
  String title;
  Category({
    required this.id,
    required this.title,
  });

  factory Category.fromFirestore() {
    return Category(id: 'tag id', title: 'Tag Title');
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': 'tag id',
      'title': 'tag title',
    };
  }

  @override
  String toString() {
    return toFirestore().toString();
  }
}
