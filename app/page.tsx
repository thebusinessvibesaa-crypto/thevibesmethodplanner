import { BookingForm } from "@/components/booking-form";

export default function HomePage() {
  return (
    <main className="mx-auto max-w-5xl space-y-16 px-6 py-12">
      <section className="space-y-4 text-center">
        <h1 className="font-[var(--font-title)] text-4xl">Sé invitado/a en The Diary of an Entrepreneur</h1>
        <p className="text-lg">Una conversación profunda sobre identidad, sistemas, legado y el proceso real de construir un negocio digital.</p>
      </section>
      <section className="grid gap-6 md:grid-cols-2">
        <article className="space-y-4 rounded-2xl bg-white p-6">
          <h2 className="font-[var(--font-title)] text-2xl">Sobre la entrevista</h2>
          <p>Esta no es una entrevista superficial. Cada conversación convierte experiencia real en una herramienta útil para quienes emprenden.</p>
          <ul className="list-disc pl-5">
            <li>Tema de valor</li><li>Historia del invitado</li><li>Herramienta concreta para la audiencia</li>
          </ul>
        </article>
        <BookingForm />
      </section>
    </main>
  );
}
