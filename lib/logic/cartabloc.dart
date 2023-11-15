import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../model/cartabook.dart';
import '../model/cartacard.dart';
import '../model/cartaserver.dart';
import '../model/cartalibrary.dart';
import '../repo/sqlite.dart';
import '../service/webpage.dart';
import '../shared/settings.dart';
import 'cartaauth.dart';

const sortOptions = ['title', 'authors'];
const filterOptions = ['all', 'librivox', 'archive', 'cloud'];
const sortIcons = [Icons.album_rounded, Icons.account_circle_rounded];
const filterIcons = [
  Icons.import_contacts_rounded,
  Icons.local_library_rounded,
  Icons.account_balance_rounded,
  Icons.cloud_rounded,
];

class CartaBloc extends ChangeNotifier {
  // User? user;
  CartaAuth auth;

  int sortIndex = 0;
  int filterIndex = 0;
  // bool _hasLibrary = false;

  final _books = <CartaBook>[];
  final _cancelRequests = <String>{};
  final _isDownloading = <String>{};

  final _db = SqliteRepo();
  // NOTE: book server data stored in the local database
  final List<CartaServer> _servers = <CartaServer>[];
  // community book shelf
  final List<CartaLibrary> _libraries = <CartaLibrary>[];

  CartaBloc({required this.auth}) {
    // update book server list when start
    refreshBookServers();
    refreshBooks();
    refreshLibraries();
  }

  @override
  dispose() {
    _db.close();
    super.dispose();
  }

  String get currentSort => sortOptions[sortIndex];
  String get currentFilter => filterOptions[filterIndex];
  IconData get sortIcon => sortIcons[sortIndex];
  IconData get filterIcon => filterIcons[filterIndex];

  List<CartaBook> get books {
    final filterOption = filterOptions[filterIndex];
    // debugPrint('filterOption: $filterOption');
    if (filterOption == 'librivox') {
      return _books
          .where((b) =>
              b.source == CartaSource.librivox ||
              b.source == CartaSource.legamus)
          .toList();
    } else if (filterOption == 'archive') {
      return _books.where((b) => b.source == CartaSource.archive).toList();
    } else if (filterOption == 'cloud') {
      return _books.where((b) => b.source == CartaSource.cloud).toList();
    } else {
      return _books;
    }
  }

  Future<bool> addAudioBook(CartaBook book) async {
    if (auth.uid == null) {
      debugPrint('invalid user');
    } else if (_books.length > maxBooksToCreate) {
      debugPrint('exceed limit');
    } else {
      try {
        // add book to database
        await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.uid)
            .collection('books')
            .doc(book.bookId)
            .set(book.toFirestore());
        refreshBooks();
        return true;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false;
  }

  Future<CartaBook?> getAudioBookByBookId(String bookId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          // .doc(user?.uid)
          .doc(auth.uid)
          .collection('books')
          .doc(bookId)
          .get();
      return CartaBook.fromFirestore(doc);
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future deleteAudioBook(CartaBook book) async {
    try {
      // remove database entry: do not omit await
      await FirebaseFirestore.instance
          .collection('users')
          // .doc(user?.uid)
          .doc(auth.uid)
          .collection('books')
          .doc(book.bookId)
          .delete();
      // remove stored data regardless of book.source
      await book.deleteBookDirectory();
      refreshBooks();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // update fields of the book
  //
  // it is the callers responsibility to do the conversion depending on the
  // field and the database
  //
  Future<bool> updateBookData(String bookId, Map<String, Object?> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.uid)
          .collection('books')
          .doc(bookId)
          .update(data);
      refreshBooks();
      return true;
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
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

  void rotateFilterBy() {
    filterIndex = (filterIndex + 1) % filterOptions.length;
    notifyListeners();
  }

  void rotateSortBy() {
    sortIndex = (sortIndex + 1) % sortOptions.length;
    _sortBooks();
    notifyListeners();
  }

  _sortBooks() {
    final sortOption = sortOptions[sortIndex];
    // debugPrint('sortOption: $sortOption');
    if (sortOption == 'title') {
      _books.sort((a, b) => a.title.compareTo(b.title));
    } else if (sortOption == 'authors') {
      _books.sort((a, b) => (a.authors ?? '').compareTo(b.authors ?? ''));
    }
  }

  Future<void> refreshBooks() async {
    final db = FirebaseFirestore.instance;
    try {
      final query =
          await db.collection('users').doc(auth.uid).collection('books').get();
      _books.clear();
      for (final doc in query.docs) {
        _books.add(CartaBook.fromFirestore(doc));
      }
      _sortBooks();
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
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
    _servers.clear();
    _servers.addAll(await _db.getBookServers());
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

  //
  // Library
  //
  // bool get hasLibrary => _hasLibrary;
  List<CartaLibrary> get libraries => _libraries;

  Future refreshLibraries() async {
    final db = FirebaseFirestore.instance;
    final userId = auth.uid;
    try {
      final query =
          db.collection('libraries').where('owner', isEqualTo: userId);
      debugPrint('refreshLibraries: $query');
      final snapshot = await query.get();
      _libraries.clear();
      for (final doc in snapshot.docs) {
        _libraries.add(CartaLibrary.fromFirestore(doc.id, doc.data()));
      }
      // _hasLibrary = _libraries.any((l) => l.ownerId == userId);
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<List<CartaLibrary>> getLibraryList() async {
    final libraries = <CartaLibrary>[];
    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('libraries').get();
    final userId = auth.uid;

    for (final doc in snapshot.docs) {
      debugPrint('getLibraryList.doc: ${doc.data()}');
      // TODO: check this
      final library = CartaLibrary.fromFirestore(doc.id, doc.data());
      if (library.owner != userId) {
        if (_libraries.any((l) => l.id == library.id)) {
          library.signedUp = true;
        } else {
          library.signedUp = false;
        }
        libraries.add(library);
      }
    }
    return libraries;
  }

  Future<void> createLibrary(CartaLibrary library) async {
    // how many libraries owns already
    String? userId = auth.uid;
    if (userId is String) {
      int count = 0;
      for (final library in _libraries) {
        if (library.owner == userId) {
          count = count + 1;
        }
      }
      if (count < maxLibrariesToCreate) {
        final db = FirebaseFirestore.instance;
        await db
            .collection('libraries')
            .add(library.toFirestore()..remove('id'));
        refreshLibraries();
      }
    }
  }

  Future<void> updateLibrary(CartaLibrary library) async {
    // debugPrint('updateLibrary: ${library.toString()}');
    String? userId = auth.uid;
    if (userId is String && library.id != null) {
      final db = FirebaseFirestore.instance;
      await db
          .collection('libraries')
          .doc(library.id)
          .set(library.toFirestore()..remove('id'));
      refreshLibraries();
    }
  }

  Future<void> deleteLibrary(String? libraryId) async {
    if (libraryId is String) {
      final db = FirebaseFirestore.instance;
      await db.collection('libraries').doc(libraryId).delete();
      refreshLibraries();
    }
  }

  Future signupLibrary(String? libraryId, {String? credential}) async {}
  Future cancelLibrary(String? libraryId, {String? credential}) async {}

  Future<List<CartaLibrary>> listLibraries() async {
    final libraries = <CartaLibrary>[];
    return libraries;
  }

  CartaLibrary? getMyLibrary() {
    final index = _libraries.indexWhere((l) => l.owner == auth.uid);
    return index == -1 ? null : _libraries[index];
  }
}
