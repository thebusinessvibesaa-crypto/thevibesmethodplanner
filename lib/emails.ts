import { Resend } from "resend";
import { env } from "@/lib/env";

const resend = new Resend(env.RESEND_API_KEY);

export async function sendBookingEmails(input: { guestName: string; guestEmail: string; start: string; end: string; topic: string; internalHtml: string }) {
  await resend.emails.send({
    from: "Podcast Booking <booking@thevibesmethod.com>",
    to: [input.guestEmail],
    subject: "Confirmación de entrevista — The Diary of an Entrepreneur",
    html: `<p>Hola ${input.guestName},</p><p>Tu entrevista quedó confirmada para ${input.start} - ${input.end} (America/Mexico_City).</p><p>Gracias por ser parte de The Diary of an Entrepreneur.</p>`
  });

  await resend.emails.send({
    from: "Podcast Booking <booking@thevibesmethod.com>",
    to: [env.ADMIN_EMAIL],
    subject: `Nueva entrevista agendada — ${input.guestName}`,
    html: input.internalHtml
  });
}
