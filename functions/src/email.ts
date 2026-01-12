import { Workbook } from "exceljs";
import {
  Attachment,
  EmailParams,
  MailerSend,
  Recipient,
  Sender,
} from "mailersend";

export async function sendEmailWithExcel(
  senderEmail: string,
  senderName: string,
  recipientEmail: string,
  recipientName: string,
  attachmentWorkbook: Workbook,
  attachmentName: string,
  subject: string,
  text: string,
) {
  const mailerSendApiKey = process.env.MAILERSEND_KEY;
  if (!mailerSendApiKey) {
    throw new Error("No API key set for MailerSend");
  }

  const mailerSend = new MailerSend({
    apiKey: mailerSendApiKey,
  });

  const sentFrom = new Sender(senderEmail, senderName);

  const recipients = [new Recipient(recipientEmail, recipientName)];

  const attachments = [
    new Attachment(
      Buffer.from(await attachmentWorkbook.xlsx.writeBuffer()).toString(
        "base64",
      ),
      attachmentName,
      "attachment",
    ),
  ];

  const emailParams = new EmailParams()
    .setFrom(sentFrom)
    .setTo(recipients)
    .setReplyTo(sentFrom)
    .setAttachments(attachments)
    .setSubject(subject)
    .setText(text);

  await mailerSend.email.send(emailParams);
}
