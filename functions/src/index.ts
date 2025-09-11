import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {setGlobalOptions} from "firebase-functions";
import {getFirestore} from "firebase-admin/firestore";
import {onCall} from "firebase-functions/https";

initializeApp();
setGlobalOptions({ region: "europe-west3" });
const db = getFirestore();

exports.createUser = onCall(async (request) => {
    const accessCode = request.data["access"];
    if(!accessCode && accessCode == "" || !request.auth || (typeof request.data["first"]) != "string" || (typeof request.data["last"]) != "string") {
        return {"result": false};
    }
    const passwordDoc = (await db.doc("/passwords/join").get());
    if(!passwordDoc.exists || !passwordDoc.data()) {
        logger.error("no join passwords doc available");
        return {"result": false};
    }
    const passwordData = passwordDoc.data()!;
    let role = "";
    if(passwordData["admin"] == accessCode) {
        role = "admin";
    } else if(passwordData["coach"] == accessCode) {
        role = "coach";
    } else if(passwordData["dialog"] == accessCode) {
        role = "dialog";
    }
    else {
        return {"result": false};
    }
    await db.doc(`/users/${request.auth.uid}`).create({
        first: request.data["first"],
        last: request.data["last"],
        role
    })
    return {"result": true};
});