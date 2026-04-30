import { NextRequest, NextResponse } from "next/server";
import { buildAvailableSlots } from "@/lib/availability";

export async function GET(req: NextRequest) {
  const from = req.nextUrl.searchParams.get("from");
  const to = req.nextUrl.searchParams.get("to");
  if (!from || !to) return NextResponse.json({ error: "Missing date range" }, { status: 400 });
  const slots = await buildAvailableSlots(from, to);
  return NextResponse.json({ slots });
}
