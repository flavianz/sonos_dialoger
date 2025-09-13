import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {setGlobalOptions} from "firebase-functions";
import {getFirestore} from "firebase-admin/firestore";
import {onCall} from "firebase-functions/https";

initializeApp();
setGlobalOptions({ region: "europe-west3" });
const db = getFirestore();

exports.assignUser = onCall(async (request) => {
    const accessCode = request.data["access"];
    if(!accessCode && accessCode === "" || !request.auth) {
        return {"result": false};
    }
    const userDoc = (await db.doc(`/users/${accessCode}`).get());
    if(!userDoc.exists || !userDoc.data()) {
        return {"result": false};
    }

    const userData  = userDoc.data()!;
    if(userData["linked"] !== false) {
        return {"result": false};
    }

    const batch = db.batch();
    batch.create(db.doc(`/users/${request.auth.uid}`), {
        ...userData,
        "linked": true
    });
    batch.delete(db.doc(`/users/${accessCode}`));
    await batch.commit();

    logger.log(`Assigned ${request.auth.uid} to user`);

    return {"result": true};
});