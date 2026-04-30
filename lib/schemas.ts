import { z } from "zod";

export const bookingStatuses = [
  "Nuevo","Confirmado","Pendiente de revisión","Guía en preparación","Guía enviada","Grabado","En edición","Publicado","Cancelado","Reprogramado"
] as const;

export const bookingFormSchema = z.object({
  fullName: z.string().min(2),
  email: z.string().email(),
  phone: z.string().min(7),
  country: z.string().min(2),
  timezone: z.string().min(2),
  instagram: z.string().min(2),
  shortBio: z.string().min(20),
  preferredIntro: z.string().min(10),
  topicProposal: z.string().min(10),
  whatToPromote: z.string().min(5),
  consentRecording: z.literal(true),
  consentContentReuse: z.literal(true),
  start: z.string().datetime(),
  end: z.string().datetime()
});

export type BookingFormPayload = z.infer<typeof bookingFormSchema>;
