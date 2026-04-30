"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { bookingFormSchema, BookingFormPayload } from "@/lib/schemas";
import { useState } from "react";

export function BookingForm() {
  const [result, setResult] = useState<string>("");
  const form = useForm<BookingFormPayload>({ resolver: zodResolver(bookingFormSchema) });

  const onSubmit = form.handleSubmit(async (values) => {
    const response = await fetch("/api/bookings", { method: "POST", body: JSON.stringify(values) });
    const data = await response.json();
    if (!response.ok) return setResult(data.error || "Error al agendar.");
    setResult("¡Listo! Tu entrevista quedó confirmada.");
  });

  return (
    <form onSubmit={onSubmit} className="grid gap-4 rounded-2xl bg-white p-6 shadow-sm">
      <input placeholder="Nombre completo" {...form.register("fullName")} className="rounded-xl border p-3" />
      <input placeholder="Email" {...form.register("email")} className="rounded-xl border p-3" />
      <input placeholder="WhatsApp" {...form.register("phone")} className="rounded-xl border p-3" />
      <input placeholder="País" {...form.register("country")} className="rounded-xl border p-3" />
      <input placeholder="Zona horaria" {...form.register("timezone")} className="rounded-xl border p-3" />
      <input placeholder="Instagram" {...form.register("instagram")} className="rounded-xl border p-3" />
      <textarea placeholder="Bio corta" {...form.register("shortBio")} className="rounded-xl border p-3" />
      <textarea placeholder="Cómo quieres ser presentado/a" {...form.register("preferredIntro")} className="rounded-xl border p-3" />
      <textarea placeholder="Tema principal" {...form.register("topicProposal")} className="rounded-xl border p-3" />
      <textarea placeholder="Qué quieres promover" {...form.register("whatToPromote")} className="rounded-xl border p-3" />
      <input type="datetime-local" {...form.register("start")} className="rounded-xl border p-3" />
      <input type="datetime-local" {...form.register("end")} className="rounded-xl border p-3" />
      <label><input type="checkbox" {...form.register("consentRecording")} /> Acepto grabar en video.</label>
      <label><input type="checkbox" {...form.register("consentContentReuse")} /> Autorizo uso de contenido para difusión.</label>
      <button className="rounded-xl bg-terracotta px-4 py-3 text-white">Confirmar entrevista</button>
      {result && <p>{result}</p>}
    </form>
  );
}
