const functions = require("firebase-functions");
const firebase_tools = require("firebase-tools");
const admin = require('firebase-admin');
admin.initializeApp();

//
// Delete firebase data recursively
//
// TO USE THIS FUNCTION
//
// 1. install `firebase-tools` packge
// 2. get token : firebase login:ci
// 3. set config: firebase functions:config:set fb.token="YOUR_TOKEN_HERE"
// 4. deply functions: firebase deploy --only functions
//
// https://github.com/firebase/snippets-node/tree/master/firestore/solution-deletes
// https://firebase.google.com/docs/firestore/solutions/delete-collections
//
// There is a bug of course
//
// https://stackoverflow.com/questions/70932654/firebase-functions-firebaseerror-missing-required-options-force-while-runni
async function deleteUserDataRecursive(uid) {
    const path = `users/${uid}`;
    console.log(`deleteUserDataRecursive: deleting ${uid}`);
    await firebase_tools.firestore.delete(path, {
        project: process.env.GCLOUD_PROJECT,
        recursive: true,
        yes: true,
        token: functions.config().fb.token,
        force:true
    });
}

// Delete user data on Firestore when user is deleted on Auth
//
exports.purgeUserData = functions.auth.user().onDelete(async (user) => {
    deleteUserDataRecursive(user.uid);
});

//
// Delete user on Auth when the user's email is yet verified
// This allows user to delete its account without reauthentication
//
exports.deleteAuthUser = functions.https.onCall(async (data, context) => {
    if(!context.auth) {
        throw new functions.https.HttpsError('failed-precondition', 
            'The function must be called while authenticated');
    }

    const uid = context.auth.uid;
    try {
        const userRecord = await admin.auth().getUser(uid);
        if(userRecord.emailVerified) {
            console.log('user has valid email');
            return {result: false, text: 'user has valid email'};
        } else {
            await admin.auth().deleteUser(uid);
            console.log('user deleted');
            return {result: true, text: 'user deleted'}; 
        }
    } catch (error) {
        console.log('exception: ${error}');
        return {result: false, text: 'internal error'}; 
    }
});