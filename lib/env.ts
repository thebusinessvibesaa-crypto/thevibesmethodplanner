import { z } from "zod";

const envSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  GOOGLE_CLIENT_ID: z.string().min(1),
  GOOGLE_CLIENT_SECRET: z.string().min(1),
  GOOGLE_REFRESH_TOKEN: z.string().min(1),
  GOOGLE_CALENDAR_ID: z.string().min(1),
  RESEND_API_KEY: z.string().min(1),
  ADMIN_EMAIL: z.string().email(),
  DEFAULT_ZOOM_LINK: z.string().optional(),
  APP_URL: z.string().url()
});

export const env = envSchema.parse(process.env);
