const functions = require("firebase-functions");
const settings = require('./settings');
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const db = getFirestore();

// how to create service account credentials
// https://codelabs.developers.google.com/codelabs/flutter-in-app-purchases#8
const credentials = require('./assets/service-account.json');

// code reference (warning: may be outdated)
// https://github.com/flutter/codelabs/blob/main/in_app_purchases/complete/firebase-backend/functions/src/google-play.purchase-handler.ts
const { GoogleAuth } = require('google-auth-library');    // package: google-auth-library
const { google } = require('googleapis');                 // package: googleapis
const { service } = require("firebase-functions/v1/analytics"); 

async function handlePlayStoreSubscription(userId, productId, token) {
    // console.log(`userId: ${userId}`);
    // console.log(`productId: ${productId}`);
    // console.log(`token: ${token}`);

    // productId is required
    if(!productId) {
        console.error('productId is required');
        return false;
    }
    // token is required
    if(!token) {
        console.error('token is required');
        return false;
    }

    try {
        // get api
        // https://googleapis.dev/nodejs/googleapis/latest/androidpublisher/index.html#using-api-keys 
        const androidPublisher = google.androidpublisher({
            version: 'v3',
            auth: new GoogleAuth({
                credentials,
                scopes: ["https://www.googleapis.com/auth/androidpublisher"],
            }),
        });

        // call subscriptions.get method
        // https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions/get
        const response = await androidPublisher.purchases.subscriptions.get({
            packageName: settings.packageName,
            subscriptionId: productId,
            token: token,
        });
        // console.log(JSON.stringify(response));
        
        // make sure an order id exists
        if(!response.data.orderId) {
            console.error("Could not handle purchase without order id");
            return false;
        }
        // https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions#SubscriptionPurchase
        // "data": {
        //     "startTimeMillis": "1663013494274",
        //     "expiryTimeMillis": "1663013796330",
        //     "autoRenewing": false,
        //     "priceCurrencyCode": "CAD",
        //     "priceAmountMicros": "1000000",
        //     "countryCode": "CA",
        //     "developerPayload": "",
        //     "cancelReason": 1,
        //     "orderId": "GPA.3300-0361-7398-64954..0",
        //     "purchaseType": 0,
        //     "acknowledgementState": 0,
        //     "kind": "androidpublisher#subscriptionPurchase"
        // }
        const purchaseData = {...response.data};
        
        // if a subscription suffix is present (..#) extract the orderId.
        let orderId = response.data.orderId;
        const orderIdMatch = /^(.+)?[.]{2}[0-9]+$/g.exec(orderId);
        if (orderIdMatch) {
            orderId = orderIdMatch[1];
        }
        // console.log({
        //     rawOrderId: response.data.orderId,
        //     newOrderId: orderId,
        // });

        // orderId should be the same for all renewals
        purchaseData.orderId = orderId;

        // augment response.data
        purchaseData.store = settings.stores.playStore;
        purchaseData.productId = productId;
        purchaseData.startDate = Timestamp.fromMillis(parseInt(response.data.startTimeMillis ?? "0", 10));
        purchaseData.expiryDate = Timestamp.fromMillis(parseInt(response.data.expiryTimeMillis ?? "0", 10));
        // console.log(`purchaseData: ${JSON.stringify(purchaseData)}`);

        // save data
        try {
            const docId = `${purchaseData.store}_${purchaseData.orderId}`;
            let docRef = db.collection('purchases').doc(docId);
            // console.log(`docId: ${docId}`);
            // console.log(`userId: ${userId}`);
            if(userId) {
                // data came from the purchase process => create
                purchaseData.userId = userId;
                await docRef.set(purchaseData);
            } else {
                // data came from the pub/sub => update
                await docRef.update(purchaseData);
                // read the data back
                const all = await docRef.get();
                // retrieve userId
                userId = all.data().userId;
            }
            // console.log(`userId: ${userId}`);

            // update user data with subscription state
            const subscriptionState = {};
            subscriptionState[productId] = {
                store: purchaseData.store,
                orderId: purchaseData.orderId,
                expiryDate: purchaseData.expiryDate,
                expired: Timestamp.now() > purchaseData.expiryDate,
            };

            docRef = db.collection('users').doc(userId);
            await docRef.set(subscriptionState);

        } catch (e) {
            console.log("Could not create or update purchase", {orderId, productId: productId});
            return false;
        }
        return true;
    } catch(e) {
        console.error(e);
        return false;
    }
}

async function handleAppStoreSubscription(userId, productId, token) {
    // console.log(`handleAppStoreSubscription.userId: ${userId}`);
    // console.log(`handleAppStoreSubscription.productId: ${productId}`);
    // console.log(`handleAppStoreSubscription.token: ${token}`);

    return false;
}

exports.verifyPurchase = functions.https.onCall(async (data, context) => {
    if(!context.auth) {
        throw new functions.https.HttpsError('failed-precondition', 
            'The function must be called while authenticated');
    }
    // context
    //  .auth.uid
    // data
    //  .source
    //  .productId (subscriptionId)
    //  .verificationData
    if(data.source == settings.stores.playStore) {
        return handlePlayStoreSubscription(
            context.auth.uid,
            data.productId,
            data.verificationData,
        );
    } else if(data.source == settings.stores.appStore) {
        return handleAppStoreSubscription(
            context.auth.uid,
            data.productId,
            data.verificationData,
        );
    }
});

// Handle Google Play Billing Event from Pub/Sub
//
// NOTE: this only handles subscription messages
// for consumables, check the reference source
//
// References:
// https://firebase.google.com/docs/functions/pubsub-events
// https://github.com/flutter/codelabs/blob/main/in_app_purchases/complete/firebase-backend/functions/src/google-play.purchase-handler.ts
exports.handlePlayStoreServerEvent  = functions.pubsub
    .topic(settings.googlePlayPubSubTopic).onPublish(async (message) => {
        // console.log(`pubsub message:${JSON.stringify(message)}`);
        // https://developer.android.com/google/play/billing/rtdn-reference

        // message format
        // {
        //     "message": {
        //       "data": "eyAidmVyc2lvbiI6IHN0cmluZywgInBhY2thZ2VOYW1lI...,
        //       "attributes": {}
        //     },
        // }
        //
        // data field (base64 encoded)
        // {
        //      "version":"1.0",
        //      "packageName":"com.innomatic.cartaplus",
        //      "eventTimeMillis":"1663096802193",
        //      "subscriptionNotification":{
        //          "version":"1.0",
        //          "notificationType":2,
        //          "purchaseToken": "debekoijnhpbnhfbngggpaod...",
        //          "subscriptionId":"plus_subscription"
        //      },
        //     "oneTimeProductNotification": OneTimeProductNotification, (optional)
        //     "testNotification": TestNotification (optional)
        // }"

        // parse the event data
        try {
            // decode the PubSub Message body (data field)
            const event = message.data ? JSON.parse(Buffer.from(message.data, 'base64').toString('ascii')) : null;
            // console.log(`event: ${JSON.stringify(event)}`);
            // const packageName = event.packageName;
            const subscriptionId = event.subscriptionNotification.subscriptionId;
            const purchaseToken = event.subscriptionNotification.purchaseToken;
            // console.log(`subscriptionId: ${subscriptionId}`);
            // console.log(`purchaseToken: ${purchaseToken}`);

            // verify token and store the result to the firestore
            handlePlayStoreSubscription(null, subscriptionId, purchaseToken);

        } catch (e) {
            console.error("Could not parse Google Play billing event", e);
          return;
        }

});