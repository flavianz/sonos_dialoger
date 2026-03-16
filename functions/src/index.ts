import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions";
import { getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/https";
import { getAuth } from "firebase-admin/auth";
import { exportDate } from "./exports";
import { Workbook } from "exceljs";
import "dotenv/config";
import { onSchedule } from "firebase-functions/scheduler";
import { sendEmail, sendEmailWithExcel } from "./email";
import {
    onDocumentCreatedWithAuthContext,
    onDocumentDeleted,
    onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import { parseDateFromDoc } from "./utils";

initializeApp();
setGlobalOptions({ region: "europe-west3" });
export const db = getFirestore();
const auth = getAuth();

exports.assignUser = onCall(async (request) => {
    const accessCode = request.data["access"];
    if ((!accessCode && accessCode === "") || !request.auth) {
        return { result: false };
    }
    const userDoc = await db.doc(`/users/${accessCode}`).get();
    if (!userDoc.exists || !userDoc.data()) {
        return { result: false };
    }

    const userData = userDoc.data()!;
    const role = userData["role"];

    if (userData["linked"] !== false || !role) {
        return { result: false };
    }

    const batch = db.batch();
    batch.create(db.doc(`/users/${request.auth.uid}`), {
        ...userData,
        linked: true,
    });
    batch.delete(db.doc(`/users/${accessCode}`));
    await batch.commit();

    await auth.setCustomUserClaims(request.auth.uid, { role });

    logger.log(`Assigned ${request.auth.uid} to user`);

    return { result: true };
});

exports.scheduleRequested = onDocumentCreatedWithAuthContext("/schedules/{scheduleId}", async (change) => {
    if(!change.data) {
        logger.log("No data in created schedule");
        return;
    }
    const scheduleData = change.data.data();

    let emailAddress: string | undefined;
    try {
        emailAddress = await getEmailAddress();
    } catch (e) {
        logger.error("Failed to get email for export");
        logger.error(e);
        return;
    }

    if (!scheduleData["group_id"]) {
        // single day schedule
        const scheduleDate = parseDateFromDoc(scheduleData["date"]);
        try {
            await sendEmail(
                "sonos@flavianz.ch",
                "Sonos Dialoger",
                emailAddress!,
                "Sonos-Admin",
                `Neue Standplatz-Anfrage`,
                `Hallo Hannes\n\nEs wurde eine neue Standplatz-Anfrage am ${scheduleDate.getDay()}. ${scheduleDate.getMonth()}. ${scheduleDate.getFullYear()} eingereicht.\n\nSonos Dialoger-App`,
            );
        } catch (e) {
            logger.error("Failed to send single schedule creation email");
            logger.error(e);
            return;
        }
    } else {
        // group schedule
        const groupId: string = scheduleData["group_id"];

        const firstScheduleGroupMemberQuery = await db.collection("schedules").where("group_id", "==", groupId).orderBy("date", "asc").limit(1).get();
        if(firstScheduleGroupMemberQuery.empty) {
            logger.error("No group schedule member found");
            return;
        }

        const firstScheduleGroupMember = firstScheduleGroupMemberQuery.docs[0];
        const firstScheduleGroupMemberData = firstScheduleGroupMember.data();
        if(firstScheduleGroupMember.id != change.data.id) {
            // only the first schedule of a group schedule sends the email,
            // because else there would be one email per day of the group schedule
            return;
        }

        const lastScheduleGroupMemberQuery = await db
            .collection("schedules")
            .where("group_id", "==", groupId)
            .orderBy("date", "desc")
            .limit(1)
            .get();
        const lastScheduleGroupMemberData = lastScheduleGroupMemberQuery.docs[0].data();

        const startDate = parseDateFromDoc(firstScheduleGroupMemberData["date"]);
        const endDate = parseDateFromDoc(lastScheduleGroupMemberData["date"]);

        try {
            await sendEmail(
                "sonos@flavianz.ch",
                "Sonos Dialoger",
                emailAddress!,
                "Sonos-Admin",
                `Neue Standplatz-Anfrage`,
                `Hallo Hannes\n\nEs wurde eine neue Standplatz-Anfrage vom ${startDate.getDay()}. ${startDate.getMonth()}. ${startDate.getFullYear()} bis zum ${endDate.getDay()}. ${endDate.getMonth()}. ${endDate.getFullYear()} eingereicht.\n\nSonos Dialoger-App`,
            );
        } catch (e) {
            logger.error("Failed to send group schedule creation email");
            logger.error(e);
            return;
        }
    }
})

exports.updateRole = onDocumentUpdated("/users/{userId}", async (change) => {
    const userId = change.params.userId;
    if (
        change.data?.after.data()["role"] &&
        change.data?.before.data()["role"] === change.data?.after.data()["role"]
    ) {
        return;
    }
    if (change.data?.after.data()["linked"] !== true) {
        return;
    }

    try {
        await auth.setCustomUserClaims(userId, {
            role: change.data?.after.data()["role"],
        });
    } catch (e) {
        logger.log(
            `User doc ${userId} was updated but no user with this uid exist.`,
        );
        return;
    }

    logger.log(
        `Updated role of user ${userId} to ${change.data?.after.data()["role"]}`,
    );
});

exports.deleteRole = onDocumentDeleted("/users/{userId}", async (change) => {
    if (change.data?.data()["linked"] !== true) {
        return;
    }
    const userId = change.params.userId;
    try {
        await auth.setCustomUserClaims(userId, { role: undefined });
    } catch (e) {
        logger.log(
            `User doc ${userId} was deleted but no user with this uid exist.`,
        );
        return;
    }
    logger.log(`Deleted role of user ${userId}`);
});

exports.autoExportEmail = onSchedule(
    { schedule: "0 11 * * *", timeZone: "Europe/Zurich" },
    async (_) => {
        let workbook: Workbook | undefined;
        const today = new Date();
        try {
            workbook = await exportDate(
                new Date(
                    today.getFullYear(),
                    today.getMonth(),
                    today.getDate() - 1,
                ),
                new Date(
                    today.getFullYear(),
                    today.getMonth(),
                    today.getDate(),
                ),
            );
        } catch (e) {
            logger.error("Failed to export data");
            logger.error(e);
            return;
        }

        let emailAddress: string | undefined;
        try {
            emailAddress = await getEmailAddress();
        } catch (e) {
            logger.error("Failed to get email for auto export");
            logger.error(e);
            return;
        }

        const dateOfExport = new Date(
            today.getFullYear(),
            today.getMonth(),
            today.getDate() - 1,
            12,
        );

        try {
            await sendEmailWithExcel(
                "sonos@flavianz.ch",
                "Sonos Dialoger",
                emailAddress!,
                "Sonos-Admin",
                workbook,
                `export-${getDateString(dateOfExport)}.xlsx`,
                `Auto-Export vom ${getDateString(dateOfExport)}`,
                `Hallo Hannes\n\nAnbei der Auto-Export der Leistungen deiner DialogerInnen.\nDatum: ${getDateString(dateOfExport)}\n\nSonos Dialoger-App`,
            );
        } catch (e) {
            logger.error("Failed to send auto export email");
            logger.error(e);
            return;
        }
        logger.log("Sent auto export email");
        return;
    },
);

exports.exportPayments = onCall(async (request, _) => {
    if (request.auth?.token["role"] !== "admin") {
        return false;
    }
    let startDate: Date;
    let endDate: Date;
    try {
        const parsedStartDate = new Date(request.data["start"] as string);
        const parsedEndDate = new Date(request.data["end"] as string);
        startDate = new Date(
            parsedStartDate.getFullYear(),
            parsedStartDate.getMonth(),
            parsedStartDate.getDate(),
        );
        endDate = new Date(
            parsedEndDate.getFullYear(),
            parsedEndDate.getMonth(),
            parsedEndDate.getDate() + 1,
        );
    } catch (e) {
        logger.error("Failed to parse export dates");
        logger.error(e);
        return false;
    }

    let workbook: Workbook | undefined;
    try {
        workbook = await exportDate(startDate, endDate);
    } catch (e) {
        logger.error("Failed to export data");
        logger.error(e);
        return false;
    }

    let emailAddress: string | undefined;
    try {
        emailAddress = await getEmailAddress();
    } catch (e) {
        logger.error("Failed to get email for export");
        logger.error(e);
        return false;
    }

    const displayStartDate = new Date(
        startDate.getTime() + 1000 * 60 * 60 * 12,
    );
    const displayEndDate = new Date(endDate.getTime() - 1000 * 60 * 60 * 12);

    try {
        await sendEmailWithExcel(
            "sonos@flavianz.ch",
            "Sonos Dialoger",
            emailAddress!,
            "Sonos-Admin",
            workbook,
            `export-${getDateString(displayStartDate)}-${getDateString(displayEndDate)}.xlsx`,
            `Export von ${getDateString(displayStartDate)} - ${getDateString(displayEndDate)}`,
            `Hallo Hannes\n\nAnbei der Export der Leistungen deiner DialogerInnen.\nZeitraum: ${getDateString(displayStartDate)} - ${getDateString(displayEndDate)}\n\nSonos Dialoger-App`,
        );
    } catch (e) {
        logger.error("Failed to send export email");
        logger.error(e);
        return false;
    }
    logger.log("Sent export email");
    return true;
});

async function getEmailAddress(): Promise<string> {
    const emailConfig = await db.collection("config").doc("autoexport").get();
    if (!emailConfig.exists) {
        throw new Error("No auto export config found");
    }
    const data = emailConfig.data()!;
    if (!data["email"]) {
        throw new Error("No email set in config");
    }
    return data["email"]!;
}

function getDateString(date: Date): string {
    return `${date.getDate()}.${date.getMonth() + 1}.${date.getFullYear()}`;
}
