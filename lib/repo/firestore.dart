import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/cartabook.dart';
import '../model/cartalibrary.dart';
import '../model/cartaserver.dart';

class FirestoreRepo {
  final _db = FirebaseFirestore.instance;
  String? uid;

  //
  // CartaBook
  //
  // Create
  Future<bool> addAudioBook(CartaBook book) async {
    if (uid is String) {
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('books')
            .doc(book.bookId)
            .set(book.toFirestore());
        return true;
      } catch (e) {
        log(e.toString());
      }
    }
    return false;
  }

  // Read
  Future<CartaBook?> getAudioBookByBookId(String bookId) async {
    if (uid is String) {
      try {
        final doc = await _db
            .collection('users')
            .doc(uid)
            .collection('books')
            .doc(bookId)
            .get();
        return CartaBook.fromFirestore(doc.data());
      } catch (e) {
        log(e.toString());
      }
    }
    return null;
  }

  // Read Collection
  Future<List<CartaBook>> getAudioBooks() async {
    if (uid is String) {
      try {
        final query =
            await _db.collection('users').doc(uid).collection('books').get();
        return query.docs
            .map((doc) => CartaBook.fromFirestore(doc.data()))
            .toList();
      } catch (e) {
        log(e.toString());
      }
    }
    return <CartaBook>[];
  }

  // Update
  Future<bool> updateAudioBook(CartaBook book) async {
    return await addAudioBook(book);
  }

  // Update Data
  Future<bool> updateBookData(String bookId, Map<String, Object?> data) async {
    if (uid is String) {
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('books')
            .doc(bookId)
            .update(data);
        return true;
      } catch (e) {
        log(e.toString());
      }
    }
    return false;
  }

  // Delete
  Future<bool> deleteAudioBook(CartaBook book) async {
    if (uid is String) {
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('books')
            .doc(book.bookId)
            .delete();
        return true;
      } catch (e) {
        log(e.toString());
      }
    }
    return false;
  }

  //
  // CartaServer
  //
  // Create
  Future<bool> addBookServer(CartaServer server) async {
    if (uid is String) {
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('servers')
            .doc(server.serverId)
            .set(server.toFirestore());
        return true;
      } catch (e) {
        log(e.toString());
      }
    }
    return false;
  }

  // Read
  Future<CartaServer?> getBookServerById(String serverId) async {
    if (uid is String) {
      try {
        final doc = await _db
            .collection('users')
            .doc(uid)
            .collection('servers')
            .doc(serverId)
            .get();
        return CartaServer.fromFirestore(doc.data());
      } catch (e) {
        log(e.toString());
      }
    }
    return null;
  }

  // Read Collection
  Future<List<CartaServer>> getBookServers() async {
    if (uid is String) {
      final query =
          await _db.collection('users').doc(uid).collection('servers').get();
      return query.docs
          .map((doc) => CartaServer.fromFirestore(doc.data()))
          .toList();
    }
    return <CartaServer>[];
  }

  // Update
  Future<bool> updateBookServer(CartaServer server) async {
    return await addBookServer(server);
  }

  // Delete
  Future<bool> deleteBookServer(CartaServer server) async {
    if (uid is String) {
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('servers')
            .doc(server.serverId)
            .delete();
        return true;
      } catch (e) {
        log(e.toString());
      }
    }
    return false;
  }

  //
  // CartaLibrary
  //
  // Create
  Future<bool> createLibrary(CartaLibrary library) async {
    if (uid is String) {
      try {
        await _db
            .collection('libraries')
            .add(library.toFirestore()..remove('id'));
        return true;
      } catch (e) {
        log(e.toString());
      }
    }
    return false;
  }

  // Read
  Future<List<CartaLibrary>> getAllLibraries() async {
    final res = <CartaLibrary>[];
    if (uid is String) {
      try {
        final query = await _db.collection('libraries').get();
        for (final doc in query.docs) {
          final library = CartaLibrary.fromFirestore(doc.id, doc.data());
          library.signedUp = library.members.contains(uid);
          res.add(library);
        }
      } catch (e) {
        log(e.toString());
      }
    }
    return res;
  }

  // Read: libraries I owned or signed up
  Future<List<CartaLibrary>> getOurLibraries() async {
    if (uid is String) {
      try {
        final query = _db.collection('libraries').where(Filter.or(
            Filter('owner', isEqualTo: uid),
            Filter('members', arrayContains: uid)));
        final snapshot = await query.get();
        return snapshot.docs
            .map((doc) => CartaLibrary.fromFirestore(doc.id,
                doc.data()..addEntries(const [MapEntry('signedUp', true)])))
            .toList();
      } catch (e) {
        log(e.toString());
      }
    }
    return <CartaLibrary>[];
  }

  // Update
  Future<bool> updateLibrary(CartaLibrary library) async {
    if (uid is String && library.id is String) {
      try {
        await _db
            .collection('libraries')
            .doc(library.id)
            .set(library.toFirestore()..remove('id'));
        return true;
      } catch (e) {
        log(e.toString());
      }
    }
    return false;
  }

  // Update Data
  Future<bool> updateLibraryData(
      String libraryId, Map<String, Object?> data) async {
    if (uid is String) {
      try {
        await _db.collection('libraries').doc(libraryId).update(data);
        return true;
      } catch (e) {
        log(e.toString());
      }
    }
    return false;
  }

  // Delete
  Future<bool> deleteLibrary(CartaLibrary library) async {
    if (uid is String && library.id is String) {
      try {
        await _db.collection('libraries').doc(library.id).delete();
        return true;
      } catch (e) {
        log(e.toString());
      }
    }
    return false;
  }
}
