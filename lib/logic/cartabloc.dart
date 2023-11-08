import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../model/cartabook.dart';
import '../model/cartacard.dart';
import '../model/cartaserver.dart';
import '../repo/sqlite.dart';
import '../service/webpage.dart';
import '../shared/settings.dart';
import 'authprovider.dart';

class CartaBloc extends ChangeNotifier {
  // User? user;
  AuthProvider auth;
  late final StreamSubscription<QuerySnapshot> _booksListener;
  late final StreamSubscription<DocumentSnapshot> _plusSubListener;

  bool hasPlus = false;
  final _books = <CartaBook>[];
  final _cancelRequests = <String>{};
  final _isDownloading = <String>{};

  final _db = SqliteRepo();
  // NOTE: book server data stored in the local database
  List<CartaServer> _servers = <CartaServer>[];

  CartaBloc({required this.auth}) {
    // update book server list when start
    refreshBookServers();

    // listen to the books change
    final colRef = FirebaseFirestore.instance
        .collection('users')
        .doc(auth.getUid())
        .collection('books');
    _booksListener = colRef.snapshots().listen((event) {
      // clear existing list
      _books.clear();
      // fill the list with new book data
      for (final doc in event.docs) {
        _books.add(CartaBook.fromFirestore(doc));
      }
      notifyListeners();
    });

    // listen to the subscription change
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(auth.getUid());
    _plusSubListener = docRef.snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          // subscription change
          final plusSubData = snapshot.get(productPlusSub);
          // debugPrint('subscription data: ${data['expired']}');
          hasPlus = plusSubData['expired'] == false ? true : false;
          // debugPrint('hasPlus: $hasPlus');
          notifyListeners();
        }
      },
      onError: (e) => debugPrint(e.toString()),
    );
  }

  @override
  dispose() {
    _db.close();
    _booksListener.cancel();
    _plusSubListener.cancel();
    super.dispose();
  }

  List<CartaBook> get books {
    return _books;
  }

  Future<bool> addAudioBook(CartaBook book) async {
    if (auth.getUid() == null) {
      debugPrint('invalid user');
      return false;
    }

    // download cover image: no longer necessary
    // await book.downloadCoverImage();

    // add book to database
    FirebaseFirestore.instance
        .collection('users')
        // .doc(user!.uid)
        .doc(auth.getUid())
        .collection('books')
        .doc(book.bookId)
        .set(book.toFirestore());
    return true;
  }

  Future<CartaBook?> getAudioBookByBookId(String bookId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        // .doc(user?.uid)
        .doc(auth.getUid())
        .collection('books')
        .doc(bookId)
        .get();
    return CartaBook.fromFirestore(doc);
  }

  Future deleteAudioBook(CartaBook book) async {
    // remove database entry: do not omit await
    await FirebaseFirestore.instance
        .collection('users')
        // .doc(user?.uid)
        .doc(auth.getUid())
        .collection('books')
        .doc(book.bookId)
        .delete();

    // remove stored data regardless of book.source
    await book.deleteBookDirectory();
  }

  // update fields of the book
  //
  // it is the callers responsibility to do the conversion depending on the
  // field and the database
  //
  Future updateBookData(String bookId, Map<String, Object?> data) async {
    await FirebaseFirestore.instance
        .collection('users')
        // .doc(user?.uid)
        .doc(auth.getUid())
        .collection('books')
        .doc(bookId)
        .update(data);
  }

  //
  // Handling Download
  //
  bool isDownloading(String bookId) {
    return _isDownloading.contains(bookId);
    // return _downloadState.isDownloading && _downloadState.bookId == bookId
    //     ? true
    //     : false;
  }

  void cancelDownload(String bookId) {
    _cancelRequests.add(bookId);
  }

  // Download media files
  //
  // All the download tasks are handled here in one place in order to
  // get rid of the need of CartaBook being a ChangeNotifier
  //
  Future downloadMediaData(CartaBook book) async {
    // book must have sections
    if (book.sections == null || _isDownloading.contains(book.bookId)) {
      return;
    }

    // reset cancel flag first
    _cancelRequests.remove(book.bookId);

    // get book directory
    final bookDir = book.getBookDirectory();
    // if not exists, create one
    if (!bookDir.existsSync()) {
      await bookDir.create();
    }

    // download cover image: no longer necessary
    // book.downloadCoverImage();

    _isDownloading.add(book.bookId);
    // download each section data
    for (final section in book.sections!) {
      // debugPrint('downloading:${section.index}');
      notifyListeners();

      // break if cancelled
      if (_cancelRequests.contains(book.bookId)) {
        debugPrint('download canceled: ${book.title}');
        break;
      }

      // otherwise go head
      final res = await http.get(
        Uri.parse(section.uri),
        headers: book.getAuthHeaders(),
      );

      if (res.statusCode == 200) {
        final file = File('${bookDir.path}/${section.uri.split('/').last}');
        // store audio data
        await file.writeAsBytes(res.bodyBytes);
      }
    }

    if (_cancelRequests.contains(book.bookId)) {
      // delete media data in the directory
      deleteMediaData(book);
      _cancelRequests.remove(book.bookId);
    }
    // notify the end of download
    _isDownloading.remove(book.bookId);
    debugPrint('download done: ${book.title}');
    notifyListeners();
  }

  // delete audio data
  Future deleteMediaData(CartaBook book) async {
    final bookDir = book.getBookDirectory();
    for (final entry in bookDir.listSync()) {
      if (entry is File &&
          lookupMimeType(entry.path)?.contains('audio') == true) {
        entry.deleteSync();
      }
    }
    // debugPrint('deleteMediaData.notifyListeners');
    notifyListeners();
  }

  //
  // CartaCard
  //
  Future<List<CartaCard>> getSampleBookCards() async {
    final cards = <CartaCard>[];
    final res = await http.get(Uri.parse(urlSelectedBooksJson));
    if (res.statusCode == 200) {
      final jsonDoc = jsonDecode(res.body) as Map<String, dynamic>;
      if (jsonDoc.containsKey('data') && jsonDoc['data'] is List) {
        for (final item in jsonDoc['data']) {
          cards.add(CartaCard.fromJsonDoc(item));
          // debugPrint('card: ${CartaCard.fromJsonDoc(item)}');
        }
      }
    }
    return cards;
  }

  Future<CartaBook?> getAudioBookFromCard(CartaCard card) async {
    CartaBook? book;
    if (card.source == CartaSource.carta) {
      book = CartaBook.fromCartaCard(card);
    } else if (card.source == CartaSource.librivox ||
        card.source == CartaSource.archive) {
      book = await WebPageParser.getBookFromUrl(card.data['siteUrl']);
    }
    return book;
  }

  //
  //  Book Server
  //
  List<CartaServer> get servers => _servers;

  Future refreshBookServers() async {
    _servers = await _db.getBookServers();
    notifyListeners();
  }

  Future addBookServer(CartaServer server) async {
    await _db.addBookServer(server);
    refreshBookServers();
  }

  Future updateBookServer(CartaServer server) async {
    await _db.updateBookServer(server);
    refreshBookServers();
  }

  Future deleteBookServer(CartaServer server) async {
    await _db.deleteBookServer(server);
    refreshBookServers();
  }
}
