import 'cartabook.dart';

class CartaLibrary {
  String? id;
  String title;
  String owner;
  List<String> members;
  List<CartaBook> books;
  String? description;
  bool isPublic;
  String? credential;
  Map<String, dynamic> info;
  bool? signedUp;

  CartaLibrary({
    this.id,
    required this.title,
    required this.owner,
    required this.members,
    required this.books,
    this.description,
    required this.isPublic,
    this.credential,
    required this.info,
  });

  factory CartaLibrary.fromFirestore(String id, Map<String, dynamic> data) {
    return CartaLibrary(
      id: id,
      title: data['title'],
      owner: data['owner'],
      members: (data['members'] as List).map((e) => e as String).toList(),
      books: (data['books'] as List)
          .map((b) => CartaBook.fromFirestore(b))
          .toList(),
      description: data['description'],
      isPublic: data['isPublic'],
      credential: data['credential'],
      info: data['info'],
    );
  }

  factory CartaLibrary.fromDefault(String userId) {
    return CartaLibrary(
      title: '',
      owner: userId,
      members: <String>[],
      books: <CartaBook>[],
      description: '',
      isPublic: true,
      info: {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'owner': owner,
      'members': members,
      'books': books.map((b) => b.toFirestore()).toList(),
      'description': description,
      'isPublic': isPublic,
      'credential': credential,
      'info': info,
    };
  }

  @override
  String toString() {
    return {
      'id': id,
      'title': title,
      'owner': owner,
      'members': members,
      'books': books.map((b) => b.toString()).toList().toString(),
      'description': description,
      'isPublic': isPublic,
      'credential': credential,
      'info': info,
      'signedUp': signedUp,
    }.toString();
  }
}
