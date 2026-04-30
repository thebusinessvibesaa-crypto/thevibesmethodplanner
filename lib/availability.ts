import { addDays, formatISO, setHours, setMinutes } from "date-fns";
import { getBusySlots } from "@/lib/google-calendar";

const TEMPLATE_HOURS = [[8,0,10,0],[10,0,12,0],[14,0,16,0]];

export async function buildAvailableSlots(fromISO: string, toISO: string) {
  const from = new Date(fromISO);
  const to = new Date(toISO);
  const busy = await getBusySlots(formatISO(from), formatISO(to));
  const slots: {start:string;end:string}[] = [];

  for (let d = new Date(from); d <= to; d = addDays(d, 1)) {
    if (d.getDay() !== 5) continue;
    for (const [sh, sm, eh, em] of TEMPLATE_HOURS) {
      const start = setMinutes(setHours(new Date(d), sh), sm);
      const end = setMinutes(setHours(new Date(d), eh), em);
      const isBusy = busy.some((b) => !(new Date(b.end!) <= start || new Date(b.start!) >= end));
      if (!isBusy) slots.push({ start: start.toISOString(), end: end.toISOString() });
    }
  }
  return slots;
}
