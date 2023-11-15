class CartaLibrary {
  String? id;
  String title;
  String owner;
  List<String> members;
  String? description;
  bool isPublic;
  int count;
  String? credential;
  Map<String, dynamic> info;
  bool? signedUp;

  CartaLibrary({
    this.id,
    required this.title,
    required this.owner,
    required this.members,
    this.description,
    required this.isPublic,
    required this.count,
    this.credential,
    required this.info,
  });

  factory CartaLibrary.fromFirestore(String id, Map<String, dynamic> data) {
    return CartaLibrary(
      id: id,
      title: data['title'],
      owner: data['owner'],
      members: (data['members'] as List).map((e) => e as String).toList(),
      description: data['description'],
      isPublic: data['isPublic'],
      count: data['count'],
      credential: data['credential'],
      info: data['info'],
    );
  }

  factory CartaLibrary.fromDefault(String userId) {
    return CartaLibrary(
      title: '',
      owner: userId,
      members: <String>[],
      description: '',
      isPublic: true,
      count: 0,
      info: {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'owner': owner,
      'members': members,
      'description': description,
      'isPublic': isPublic,
      'count': count,
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
      'description': description,
      'isPublic': isPublic,
      'count': count,
      'credential': credential,
      'info': info,
      'signedUp': signedUp,
    }.toString();
  }
}
