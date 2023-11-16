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
  // auth user ID
  String? _uid;

  int sortIndex = 0;
  int filterIndex = 0;
  // bool _hasLibrary = false;

  final _books = <CartaBook>[];
  // download related variables
  final _cancelRequests = <String>{};
  final _isDownloading = <String>{};
  // databases
  final _db = SqliteRepo();
  final _fs = FirebaseFirestore.instance;
  // book server data stored in the local database
  final List<CartaServer> _servers = <CartaServer>[];
  // libraries the user signed up
  final List<CartaLibrary> _libraries = <CartaLibrary>[];

  CartaBloc();

  @override
  dispose() {
    _db.close();
    super.dispose();
  }

  String? get uid => _uid;
  String get currentSort => sortOptions[sortIndex];
  String get currentFilter => filterOptions[filterIndex];
  IconData get sortIcon => sortIcons[sortIndex];
  IconData get filterIcon => filterIcons[filterIndex];

  // set userId
  void setUid(String? uid) {
    _uid = uid;
    // valid user signed in
    if (_uid is String) {
      refreshBookServers();
      refreshBooks();
      refreshLibraries();
    }
  }

  // Return list of books filtered
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

  //
  // BOOK
  //

  // Refresh list of books
  Future<void> refreshBooks() async {
    if (_uid is String) {
      try {
        final query =
            await _fs.collection('users').doc(_uid).collection('books').get();
        _books.clear();
        for (final doc in query.docs) {
          _books.add(CartaBook.fromFirestore(doc.data()));
        }
        _sortBooks();
        notifyListeners();
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  // Create
  Future<bool> addAudioBook(CartaBook book) async {
    if (_uid is String) {
      if (_books.length > maxBooksToCreate) {
        debugPrint('exceed limit');
      } else {
        try {
          // add book to database
          await _fs
              .collection('users')
              .doc(_uid)
              .collection('books')
              .doc(book.bookId)
              .set(book.toFirestore());
          refreshBooks();
          return true;
        } catch (e) {
          debugPrint(e.toString());
        }
      }
    }
    return false;
  }

  // Read by Id
  Future<CartaBook?> getAudioBookByBookId(String bookId) async {
    if (_uid is String) {
      try {
        final doc = await _fs
            .collection('users')
            .doc(_uid)
            .collection('books')
            .doc(bookId)
            .get();
        return CartaBook.fromFirestore(doc.data());
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  // Delete
  Future deleteAudioBook(CartaBook book) async {
    if (_uid is String) {
      try {
        // remove database entry: do not omit await
        await _fs
            .collection('users')
            .doc(_uid)
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
  }

  //
  // Update only certain fields of the book
  // It is the callers responsibility to do the conversion of the field
  //
  Future<bool> updateBookData(String bookId, Map<String, Object?> data) async {
    if (_uid is String) {
      try {
        await _fs
            .collection('users')
            .doc(_uid)
            .collection('books')
            .doc(bookId)
            .update(data);
        refreshBooks();
        return true;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false;
  }

  // Book filter
  void rotateFilterBy() {
    filterIndex = (filterIndex + 1) % filterOptions.length;
    notifyListeners();
  }

  // Book sort
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

      // otherwise go ahead
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

  // Delete audio data
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
  // Get Sample Cards
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

  // Get Book from the card
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

  // Refresh server list
  Future refreshBookServers() async {
    _servers.clear();
    _servers.addAll(await _db.getBookServers());
    notifyListeners();
  }

  // Create
  Future addBookServer(CartaServer server) async {
    await _db.addBookServer(server);
    refreshBookServers();
  }

  // Update
  Future updateBookServer(CartaServer server) async {
    await _db.updateBookServer(server);
    refreshBookServers();
  }

  // Delete
  Future deleteBookServer(CartaServer server) async {
    await _db.deleteBookServer(server);
    refreshBookServers();
  }

  //
  // Library
  //
  // bool get hasLibrary => _hasLibrary;
  List<CartaLibrary> get libraries => _libraries;

  // Refresh list of libraries which I own or signed up
  Future refreshLibraries() async {
    if (_uid is String) {
      try {
        // library I own or I signed up
        final query = _fs.collection('libraries').where(Filter.or(
            Filter('owner', isEqualTo: _uid),
            Filter('members', arrayContains: _uid)));
        final snapshot = await query.get();
        _libraries.clear();
        debugPrint('refreshLibraries: ${snapshot.docs}');
        for (final doc in snapshot.docs) {
          _libraries.add(CartaLibrary.fromFirestore(doc.id, doc.data()));
        }
        // _hasLibrary = _libraries.any((l) => l.ownerId == userId);
        notifyListeners();
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  // Create
  Future<void> createLibrary(CartaLibrary library) async {
    // how many libraries owns already
    if (_uid is String) {
      int count = 0;
      for (final library in _libraries) {
        if (library.owner == _uid) {
          count = count + 1;
        }
      }
      if (count < maxLibrariesToCreate) {
        await _fs
            .collection('libraries')
            .add(library.toFirestore()..remove('id'));
        refreshLibraries();
      }
    }
  }

  // Update
  Future<bool> updateLibrary(CartaLibrary library) async {
    // debugPrint('updateLibrary: ${library.toString()}');
    if (_uid is String && library.id != null) {
      try {
        await _fs
            .collection('libraries')
            .doc(library.id)
            .set(library.toFirestore()..remove('id'));
        refreshLibraries();
        return true;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false;
  }

  // Update Data
  // It is the callers responsibility to do the conversion of the field
  Future<bool> updateLibraryData(
      String libraryId, Map<String, Object?> data) async {
    // debugPrint('updateLibrary: ${library.toString()}');
    if (_uid is String) {
      try {
        await _fs.collection('libraries').doc(libraryId).update(data);
        refreshLibraries();
        return true;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false;
  }

  // Delete
  Future<bool> deleteLibrary(String? libraryId) async {
    if (libraryId is String) {
      try {
        await _fs.collection('libraries').doc(libraryId).delete();
        refreshLibraries();
        return true;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false;
  }

  // Get my library from the list
  CartaLibrary? getMyLibrary() {
    // ASSUME that one can own only one library
    final index = _libraries.indexWhere((l) => l.owner == _uid);
    return index == -1 ? null : _libraries[index];
  }

  // Get all public libraries available
  Future<List<CartaLibrary>> getPublicLibraries() async {
    final libraries = <CartaLibrary>[];
    if (_uid is String) {
      try {
        final snapshot = await _fs.collection('libraries').get();
        for (final doc in snapshot.docs) {
          // debugPrint('getLibraryList.doc: ${doc.data()}');
          final library = CartaLibrary.fromFirestore(doc.id, doc.data());
          // exclude my library from the result
          if (library.owner != _uid) {
            // signed up for the library already so appeared in _libraries?
            if (_libraries.any((l) => l.id == library.id)) {
              // mark as signed up
              library.signedUp = true;
            } else {
              library.signedUp = false;
            }
            libraries.add(library);
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return libraries;
  }

  // Sign Up
  Future<bool> signupLibrary(CartaLibrary library, {String? credential}) async {
    if (_uid is String) {
      try {
        await _fs
            .collection('libraries')
            .doc(library.id)
            .update({'members': library.members..add(_uid!)});
        refreshLibraries();
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false;
  }

  // Cancel
  Future cancelLibrary(CartaLibrary library, {String? credential}) async {
    if (_uid is String) {
      try {
        await _fs
            .collection('libraries')
            .doc(library.id)
            .update({'members': library.members..remove(_uid!)});
        refreshLibraries();
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return false;
  }
}
