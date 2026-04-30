import "./globals.css";
import { DM_Sans, Playfair_Display } from "next/font/google";
import type { Metadata } from "next";

const dmSans = DM_Sans({ subsets: ["latin"], variable: "--font-body" });
const playfair = Playfair_Display({ subsets: ["latin"], variable: "--font-title" });

export const metadata: Metadata = {
  title: "The Diary of an Entrepreneur — Guest Booking",
  description: "Reserva de entrevistas para invitados del podcast de Anngi Ávila"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body className={`${dmSans.variable} ${playfair.variable} font-sans`}>{children}</body>
    </html>
  );
}
