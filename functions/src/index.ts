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
import { sendEmailWithExcel } from "./email";

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
                "autoexport.sonos@flavianz.ch",
                "Auto-Export Sonos Dialoger",
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
            "export.sonos@flavianz.ch",
            "Export Sonos Dialoger",
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
