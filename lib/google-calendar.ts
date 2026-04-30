import { google } from "googleapis";
import { env } from "@/lib/env";

function calendarClient() {
  const auth = new google.auth.OAuth2(env.GOOGLE_CLIENT_ID, env.GOOGLE_CLIENT_SECRET);
  auth.setCredentials({ refresh_token: env.GOOGLE_REFRESH_TOKEN });
  return google.calendar({ version: "v3", auth });
}

export async function getBusySlots(timeMin: string, timeMax: string) {
  const calendar = calendarClient();
  const response = await calendar.freebusy.query({
    requestBody: { timeMin, timeMax, items: [{ id: env.GOOGLE_CALENDAR_ID }] }
  });
  return response.data.calendars?.[env.GOOGLE_CALENDAR_ID]?.busy ?? [];
}

export async function createCalendarEvent(input: { start: string; end: string; summary: string; description: string }) {
  const calendar = calendarClient();
  const response = await calendar.events.insert({
    calendarId: env.GOOGLE_CALENDAR_ID,
    requestBody: {
      summary: input.summary,
      description: input.description,
      start: { dateTime: input.start, timeZone: "America/Mexico_City" },
      end: { dateTime: input.end, timeZone: "America/Mexico_City" }
    }
  });
  return response.data;
}
