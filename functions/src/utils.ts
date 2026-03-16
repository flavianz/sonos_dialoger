import { firestore } from "firebase-admin";
import Timestamp = firestore.Timestamp;

export function parseDateFromDoc(date: any) {
    return new Date(
        (date as Timestamp).toDate().toLocaleString("en-US", { timeZone: "Europe/Zurich" }),
    );
}