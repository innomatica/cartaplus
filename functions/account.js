const functions = require("firebase-functions");
const { initializeApp} = require('firebase-admin/app');
const { getFirestore} = require('firebase-admin/firestore');
const { log, info, debug, warn, error} = require('firebase-functions/logger');

initializeApp();
const db = getFirestore();

// https://firebase.google.com/docs/firestore/manage-data/delete-data#collections
exports.triggerUserDelete = functions.auth.user().onDelete(async (user) => {
    const userId = user.uid;
    const colRef = db.collection('users').doc(userId).collection('books');
    const query = colRef.orderBy('__name__').limit(30);
    try{
        // delete books subcollection
        await deleteQueryBatch(db, query);
        // delete user data
        await db.collection('users').doc(userId).delete();
    } catch(e) {
        error(e);
    }
});

async function deleteQueryBatch(db, query, resolve) {
    const snapshot = await query.get();
  
    const batchSize = snapshot.size;
    if (batchSize === 0) {
      // When there are no documents left, we are done
      if(resolve) resolve();
      return;
    }
  
    // Delete documents in a batch
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
  
    // Recurse on the next process tick, to avoid exploding the stack.
    process.nextTick(() => {
      deleteQueryBatch(db, query, resolve);
    });
  }

