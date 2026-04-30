# The Diary of an Entrepreneur — Guest Booking

MVP en Next.js para reservas de invitados del podcast con disponibilidad en viernes, bloqueo en Google Calendar, persistencia en Supabase y confirmaciones por email.

## Setup
1. `npm install`
2. Configura `.env.local` usando `.env.example`
3. Ejecuta `supabase/schema.sql`
4. `npm run dev`

## Arquitectura MVP
- Frontend público: `app/page.tsx`
- API disponibilidad: `GET /api/availability`
- API booking: `POST /api/bookings`
- Admin básico: `app/admin/page.tsx`
- Integración Calendar: `lib/google-calendar.ts`
- Emails: `lib/emails.ts`

## Despliegue
- Conecta repo a Vercel.
- Agrega variables de entorno.
- Define `APP_URL` con tu dominio productivo.
