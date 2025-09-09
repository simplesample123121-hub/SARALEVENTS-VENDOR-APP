"use client";
import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase";
import Link from "next/link";

type Invitation = {
  id: string;
  title: string;
  description: string | null;
  event_date: string | null;
  event_time: string | null;
  venue_name: string | null;
  address: string | null;
  cover_image_url: string | null;
  slug: string;
};

export default function InvitePage({ params }: { params: { slug: string } }) {
  const [loading, setLoading] = useState(true);
  const [inv, setInv] = useState<Invitation | null>(null);

  useEffect(() => {
    const supabase = createClient();
    supabase
      .from("invitations")
      .select("*")
      .eq("slug", params.slug)
      .maybeSingle()
      .then(({ data }) => {
        setInv((data as Invitation) ?? null);
        setLoading(false);
      });
  }, [params.slug]);

  if (loading) return <div className="p-6">Loading…</div>;
  if (!inv) return <div className="p-6">Invitation not found</div>;

  return (
    <div className="max-w-2xl mx-auto p-6">
      <div className="rounded-xl overflow-hidden border">
        {inv.cover_image_url && (
          <img src={inv.cover_image_url} alt={inv.title} className="w-full h-64 object-cover" />
        )}
        <div className="p-5">
          <h1 className="text-2xl font-bold mb-2">{inv.title}</h1>
          {inv.description && <p className="text-gray-700 mb-3">{inv.description}</p>}
          <div className="text-sm text-gray-600 space-y-1">
            <div>
              <span className="font-medium">When:</span> {[inv.event_date, inv.event_time].filter(Boolean).join(" • ")}
            </div>
            {(inv.venue_name || inv.address) && (
              <div>
                <span className="font-medium">Where:</span> {[inv.venue_name, inv.address].filter(Boolean).join(", ")}
              </div>
            )}
          </div>
          <div className="mt-5 space-x-3">
            <Link className="inline-flex items-center px-4 py-2 rounded-md bg-black text-white" href={`/invite/${inv.slug}`}>
              Open in app
            </Link>
            <Link
              className="inline-flex items-center px-4 py-2 rounded-md bg-gray-900/80 text-white"
              href={`https://saral-events.com/invite/${inv.slug}`}
              target="_blank"
            >
              View in browser
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}


