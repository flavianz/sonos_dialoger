import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions";
import { getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/https";
import { getAuth } from "firebase-admin/auth";
import { exportDate } from "./exports";
import { Workbook } from "exceljs";
import "dotenv/config";
import {
  Attachment,
  EmailParams,
  MailerSend,
  Recipient,
  Sender,
} from "mailersend";
import { onSchedule } from "firebase-functions/scheduler";

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
  { schedule: "0 10 * * *", timeZone: "Europe/Zurich" },
  async (_) => {
    let workbook: Workbook | undefined;
    const today = new Date();
    const dateToExport = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate() - 1,
    );
    try {
      workbook = await exportDate(dateToExport);
    } catch (e) {
      logger.error("Failed to export data");
      logger.error(e);
      return;
    }

    const exportContent = await workbook.xlsx.writeBuffer();

    let emailAddress: string | undefined;
    try {
      const emailConfig = await db.collection("config").doc("autoexport").get();
      if (!emailConfig.exists) {
        throw new Error("No auto export config found");
      }
      const data = emailConfig.data()!;
      if (!data["email"]) {
        throw new Error("No email set in config");
      }
      emailAddress = data["email"]!;
    } catch (e) {
      logger.error("Failed to get email for auto export");
      logger.error(e);
      return;
    }

    const mailerSendApiKey = process.env.MAILERSEND_KEY;
    if (!mailerSendApiKey) {
      logger.error("No API key set for MailerSend");
      return;
    }

    try {
      const mailerSend = new MailerSend({
        apiKey: mailerSendApiKey,
      });

      const sentFrom = new Sender(
        "autoexport.sonos@flavianz.ch",
        "Auto-Export Sonos Dialoger",
      );

      const recipients = [new Recipient(emailAddress!, "Sonos Admin")];

      const attachments = [
        new Attachment(
          Buffer.from(exportContent).toString("base64"),
          `export-${dateToExport.getDate()}-${dateToExport.getMonth() + 1}-${dateToExport.getFullYear()}.xlsx`,
          "attachment",
        ),
      ];

      const dateString = new Date().toLocaleDateString();

      const emailParams = new EmailParams()
        .setFrom(sentFrom)
        .setTo(recipients)
        .setReplyTo(sentFrom)
        .setAttachments(attachments)
        .setSubject(`Auto-Export vom ${dateString}`)
        .setText(
          "Hallo Hannes\n\nAnbei der Auto-Export der Leistungen deiner DialogerInnen.\n\nSonos Dialoger-App",
        );

      await mailerSend.email.send(emailParams);
    } catch (e) {
      logger.error("Failed to send auto export email");
      logger.error(e);
      return;
    }
    logger.log("Sent auto export email");
    return;
  },
);
