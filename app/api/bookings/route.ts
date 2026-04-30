import { NextRequest, NextResponse } from "next/server";
import { bookingFormSchema } from "@/lib/schemas";
import { buildAvailableSlots } from "@/lib/availability";
import { supabaseAdmin } from "@/lib/supabase";
import { createCalendarEvent } from "@/lib/google-calendar";
import { sendBookingEmails } from "@/lib/emails";

export async function POST(req: NextRequest) {
  const body = await req.json();
  const parsed = bookingFormSchema.safeParse(body);
  if (!parsed.success) return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 });

  const { start, end, fullName, email } = parsed.data;
  const slots = await buildAvailableSlots(start, end);
  if (!slots.find((slot) => slot.start === start && slot.end === end)) {
    return NextResponse.json({ error: "Este horario ya no está disponible. Elige otro, por favor." }, { status: 409 });
  }

  const guest = await supabaseAdmin.from("podcast_guests").insert({
    full_name: parsed.data.fullName, email: parsed.data.email, phone: parsed.data.phone,
    country: parsed.data.country, timezone: parsed.data.timezone, instagram: parsed.data.instagram,
    short_bio: parsed.data.shortBio, preferred_intro: parsed.data.preferredIntro,
    topic_proposal: parsed.data.topicProposal, what_to_promote: parsed.data.whatToPromote,
    consent_recording: true, consent_content_reuse: true
  }).select("id").single();

  const event = await createCalendarEvent({
    start, end,
    summary: `Grabación Podcast — The Diary of an Entrepreneur con ${fullName}`,
    description: `Invitado: ${fullName}\nEmail: ${email}`
  });

  const booking = await supabaseAdmin.from("podcast_bookings").insert({
    guest_id: guest.data?.id, start_time: start, end_time: end,
    timezone: parsed.data.timezone, google_calendar_event_id: event.id,
    google_calendar_event_link: event.htmlLink, status: "Confirmado"
  }).select("id").single();

  await sendBookingEmails({
    guestName: fullName, guestEmail: email, start, end, topic: parsed.data.topicProposal,
    internalHtml: `<p>Nuevo booking de ${fullName}</p><p>Evento: <a href="${event.htmlLink}">Google Calendar</a></p>`
  });

  return NextResponse.json({ bookingId: booking.data?.id, eventLink: event.htmlLink });
}
