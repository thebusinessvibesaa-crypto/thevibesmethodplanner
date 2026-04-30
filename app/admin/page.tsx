async function getBookings() {
  const res = await fetch(`${process.env.APP_URL}/api/admin/bookings`, { cache: "no-store" });
  if (!res.ok) return [];
  const data = await res.json();
  return data.bookings as Array<any>;
}

export default async function AdminPage() {
  const bookings = await getBookings();
  return (
    <main className="mx-auto max-w-6xl px-6 py-10">
      <h1 className="mb-6 font-[var(--font-title)] text-3xl">Panel de reservas</h1>
      <div className="overflow-x-auto rounded-2xl bg-white p-4">
        <table className="w-full text-left text-sm">
          <thead><tr><th>Invitado</th><th>Fecha</th><th>Estado</th><th>Calendar</th></tr></thead>
          <tbody>
            {bookings.map((b) => (
              <tr key={b.id} className="border-t"><td>{b.podcast_guests?.full_name}</td><td>{new Date(b.start_time).toLocaleString()}</td><td>{b.status}</td><td><a className="text-terracotta" href={b.google_calendar_event_link}>Ver</a></td></tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  );
}
