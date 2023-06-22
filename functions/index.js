const account = require('./account');
const purchase = require('./purchase');

exports.deleteAuthUser = account.deleteAuthUser;
exports.purgeUserData = account.purgeUserData;

exports.verifyPurchase = purchase.verifyPurchase;
exports.handlePlayStoreServerEvent = purchase.handlePlayStoreServerEvent;

