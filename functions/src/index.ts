import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {setGlobalOptions} from "firebase-functions";
import {getFirestore} from "firebase-admin/firestore";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

initializeApp();
setGlobalOptions({ region: "europe-west3" });
const db = getFirestore();

exports.defineRoleAfterUserCreation = onDocumentCreated("/users/{userId}", async (event) => {
    try {
        const passwordData = await db.doc("/passwords/join").get();
        const accessCode = event.data?.data()["access"];
        let role = "";
        if(passwordData.data()!["admin"] == accessCode) {
            role = "admin";
        } else if(passwordData.data()!["coach"] == accessCode) {
            role = "coach";
        } else if(passwordData.data()!["dialog"] == accessCode) {
            role = "dialog";
        }
        else {
            logger.error("Access key does not match any role's access key; deleting user doc");
            await db.doc(event.document).delete();
            return;
        }
        await db.doc(event.document).update("role", role);
    } catch (e) {
        await db.doc(event.document).delete();
    }
})
