class Item {
  final String id;
  final String category;
  final String text;
  final String filePath;

  Item({required this.id, required this.category, required this.text, required this.filePath});

  Item copyWith({String? category, String? text, String? filePath}) {
    return Item(
      id: this.id,
      category: category ?? this.category,
      text: text ?? this.text,
      filePath: filePath ?? this.filePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'text': text,
      'file_path': filePath,
    };
  }

  static Item fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'].toString(),
      category: map['category'],
      text: map['text'],
      filePath: map['file_path'],
    );
  }
}

