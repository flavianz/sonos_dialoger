import { db } from "./index";
import ExcelJS from "exceljs";
import { firestore } from "firebase-admin";
import Timestamp = firestore.Timestamp;

export async function exportDate(startDate: Date, endDate: Date) {
    const payments = await db
        .collection("payments")
        .where("timestamp", ">=", Timestamp.fromDate(startDate))
        .where("timestamp", "<", Timestamp.fromDate(endDate))
        .get();

    const dialogers: { [key: string]: string } = {};
    const dialogerDocs = await db
        .collection("users")
        .where("role", "!=", "admin")
        .get();

    dialogerDocs.forEach((user) => {
        dialogers[user.id] =
            (user.data()["first"] ?? "") + " " + (user.data()["last"] ?? "");
    });

    const locations: { [key: string]: string } = {};
    const locationDocs = await db.collection("locations").get();
    locationDocs.forEach((location) => {
        locations[location.id] =
            (location.data()["name"] ?? "") +
            ", " +
            (location.data()["address"]["town"] ?? "");
    });

    const workbook = new ExcelJS.Workbook();

    const sheet = workbook.addWorksheet("Alle Leistungen");
    buildSheet(payments.docs, sheet, dialogers, locations);

    dialogerDocs.forEach((user) => {
        const dialogerSheet = workbook.addWorksheet(dialogers[user.id]);
        buildSheet(
            payments.docs.filter(
                (payment) => payment.data()["dialoger"] === user.id,
            ),
            dialogerSheet,
            dialogers,
            locations,
        );
    });

    return workbook;
}

function buildSheet(
    docs: firestore.QueryDocumentSnapshot<
        firestore.DocumentData,
        firestore.DocumentData
    >[],
    sheet: ExcelJS.Worksheet,
    dialogers: { [key: string]: string },
    locations: { [key: string]: string },
) {
    sheet.columns = [
        { header: "Datum", key: "date", width: 11 },
        { header: "Dialoger", key: "dialoger", width: 20 },
        { header: "Standplatz", key: "location", width: 30 },
        {
            header: "Betrag",
            key: "amount",
            width: 10,
            style: { alignment: { wrapText: true } },
        },
        { header: "Dialoger-Anteil", key: "dialoger_share", width: 15 },
        { header: "Zahlungsmethode", key: "payment_method", width: 22 },
        { header: "Zahlungsstatus", key: "payment_status", width: 17 },
        { header: "Zahlungsintervall", key: "payment_interval", width: 19 },
        { header: "Gönner Name", key: "donor_last_name", width: 20 },
        { header: "Gönner Vorname", key: "donor_first_name", width: 20 },
    ];

    let onceSum = 0;
    let lsvMitSum = 0;
    let lsvOhneSum = 0;

    docs.forEach((doc) => {
        const data = doc.data();

        const amount = data["amount"];
        let paymentMethod;
        if (data["type"] === "repeating") {
            if (data["has_first_payment"] == true) {
                if (data["method"] === "twint") {
                    paymentMethod = "LSV + Twint";
                } else {
                    paymentMethod = "LSV + SumUp";
                }
                lsvMitSum += amount;
            } else {
                lsvOhneSum += amount;
                paymentMethod = "LSV ohne Erstzahlung";
            }
        } else {
            onceSum += amount;
            if (data["method"] === "twint") {
                paymentMethod = "Twint";
            } else {
                paymentMethod = "SumUp";
            }
        }

        let paymentStatus;
        if (data["payment_status"] === "paid") {
            paymentStatus = "Bezahlt";
        } else if (data["payment_status"] === "pending") {
            paymentStatus = "Ausstehend";
        } else if (data["payment_status"] === "cancelled") {
            paymentStatus = "Zurückgenommen";
        } else {
            paymentStatus = "Bezahlt";
        }

        let paymentInterval;
        if (data["type"] === "repeating") {
            if (data["interval"] === "monthly") {
                paymentInterval = "Monatlich";
            } else if (data["interval"] === "quarterly") {
                paymentInterval = "Quartalsweise";
            } else if (data["interval"] === "semester") {
                paymentInterval = "Semesterweise";
            } else if (data["interval"] === "yearly") {
                paymentInterval = "Jährlich";
            } else {
                paymentInterval = "Unbekannt";
            }
        } else {
            paymentInterval = "Einmalig";
        }
        const date = data["timestamp"].toDate();
        sheet.addRow({
            date: `${date.getDate()}.${date.getMonth() + 1}.${date.getFullYear()}`,
            dialoger: dialogers[data["dialoger"]] ?? "Unbekannt",
            location: locations[data["location"]] ?? "Unbekannt",
            amount: amount,
            dialoger_share:
                Math.round(data["dialoger_share"] * data["amount"] * 100) / 100,
            payment_method: paymentMethod,
            payment_status: paymentStatus,
            payment_interval: paymentInterval,
            donor_last_name: data["last"] ?? "",
            donor_first_name: data["first"] ?? "",
        });
    });

    sheet.addConditionalFormatting({
        ref: `D2:D${docs.length + 1}`,
        rules: [
            {
                priority: 1,
                type: "expression",
                formulae: ['F2="SumUp"'],
                style: {
                    fill: {
                        type: "pattern",
                        pattern: "solid",
                        bgColor: { argb: "92D050" },
                    },
                },
            },
            {
                priority: 1,
                type: "expression",
                formulae: ['F2="Twint"'],
                style: {
                    fill: {
                        type: "pattern",
                        pattern: "solid",
                        bgColor: { argb: "92D050" },
                    },
                },
            },
            {
                priority: 1,
                type: "expression",
                formulae: ['F2="LSV + SumUp"'],
                style: {
                    fill: {
                        type: "pattern",
                        pattern: "solid",
                        bgColor: { argb: "95B3D7" },
                    },
                },
            },
            {
                priority: 1,
                type: "expression",
                formulae: ['F2="LSV + Twint"'],
                style: {
                    fill: {
                        type: "pattern",
                        pattern: "solid",
                        bgColor: { argb: "95B3D7" },
                    },
                },
            },
            {
                priority: 1,
                type: "expression",
                formulae: ['F2="LSV ohne Erstzahlung"'],
                style: {
                    fill: {
                        type: "pattern",
                        pattern: "solid",
                        bgColor: { argb: "B7DEE8" },
                    },
                },
            },
        ],
    });

    const abschlussCell = sheet.getCell(`B${docs.length + 5}`);
    abschlussCell.value = "Abschluss:";
    const zahlungmethodeCell = sheet.getCell(`B${docs.length + 9}`);
    zahlungmethodeCell.value = "Zahlungsmethode:";

    const einmalzahlungsCell = sheet.getCell(`C${docs.length + 5}`);
    einmalzahlungsCell.value = "Einmalzahlung";
    einmalzahlungsCell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "92D050" },
    };

    const einmalzahlungsValueCell = sheet.getCell(`D${docs.length + 5}`);
    einmalzahlungsValueCell.value = onceSum;
    einmalzahlungsValueCell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "92D050" },
    };

    const lsvMitCell = sheet.getCell(`C${docs.length + 6}`);
    lsvMitCell.value = "LSV mit EZ";
    lsvMitCell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "95B3D7" },
    };

    const lsvMitValueCell = sheet.getCell(`D${docs.length + 6}`);
    lsvMitValueCell.value = lsvMitSum;
    lsvMitValueCell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "95B3D7" },
    };

    const lsvOhneCell = sheet.getCell(`C${docs.length + 7}`);
    lsvOhneCell.value = "LSV ohne EZ";
    lsvOhneCell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "B7DEE8" },
    };

    const lsvOhneValueCell = sheet.getCell(`D${docs.length + 7}`);
    lsvOhneValueCell.value = lsvOhneSum;
    lsvOhneValueCell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "B7DEE8" },
    };
}
