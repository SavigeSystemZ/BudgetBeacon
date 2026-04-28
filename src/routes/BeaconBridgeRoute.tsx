import { Link as RouterLink } from "react-router-dom";
import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../db/db";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Smartphone, Users, ShieldCheck, Download, Upload, Radio, Settings as SettingsIcon } from "lucide-react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { DemoBadge } from "../components/ui/DemoBadge";
import { featureFlags } from "../lib/flags/featureFlags";

/**
 * Beacon Bridge — household sync.
 *
 * Today's path is manual: export from Settings, transfer the file to the other
 * device, import on that device. Real cross-device sync (login from anywhere,
 * automatic merge) lands in M10; joint households with two linked accounts
 * lands in M11. See docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md.
 *
 * No fake P2P handshake, no fabricated `syncLogs` rows.
 */
export default function BeaconBridgeRoute() {
  const persons = useLiveQuery(() => db.persons.toArray(), []);
  const recentSyncs = useLiveQuery(() => db.syncLogs.orderBy("timestamp").reverse().limit(5).toArray(), []);

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader
        title="Beacon Bridge"
        subtitle="Move household data between devices."
        actions={
          <div className="h-12 w-12 rounded-full bg-blue-500/10 flex items-center justify-center border border-blue-500/20 shadow-xl shadow-blue-500/10">
            <Radio className="h-6 w-6 text-blue-500" />
          </div>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <GlassCard intensity="high" className="border-blue-500/20 bg-blue-500/5">
          <CardHeader className="border-b border-blue-500/10 bg-blue-500/5 pb-6">
            <CardTitle className="flex items-center gap-2 uppercase italic font-black text-blue-500">
              <Smartphone className="h-5 w-5" /> Today: Manual Bundle
            </CardTitle>
            <CardDescription className="text-[10px] font-bold uppercase tracking-widest text-blue-500/70">
              Export → transfer → import
            </CardDescription>
          </CardHeader>
          <CardContent className="pt-6 space-y-5">
            <ol className="space-y-3 text-sm text-muted-foreground list-decimal list-inside">
              <li>
                On <strong className="text-foreground">this</strong> device, open{" "}
                <RouterLink to="/settings" className="text-primary underline">Settings</RouterLink>{" "}
                and choose <strong>Export Backup</strong>.
              </li>
              <li>Send the JSON file to your other device (AirDrop, USB, email-to-self, encrypted messenger).</li>
              <li>
                On the other device, open Settings → <strong>Restore from JSON</strong> and pick the file.
              </li>
            </ol>
            <div className="grid grid-cols-2 gap-3">
              <RouterLink to="/settings">
                <Button className="w-full gap-2 h-12 bg-blue-500 hover:bg-blue-600 text-white uppercase font-black italic text-[11px] tracking-widest">
                  <Download className="h-4 w-4" /> Open Export
                </Button>
              </RouterLink>
              <RouterLink to="/settings">
                <Button variant="outline" className="w-full gap-2 h-12 border-blue-500/30 text-blue-500 uppercase font-black italic text-[11px] tracking-widest">
                  <Upload className="h-4 w-4" /> Open Import
                </Button>
              </RouterLink>
            </div>
            <p className="text-[10px] text-muted-foreground leading-relaxed pt-2 border-t border-blue-500/10">
              Backup format v3 covers all household data including uploaded documents (base64-encoded). On import, the receiving device <strong>replaces</strong> its data with the bundle.
            </p>
          </CardContent>
        </GlassCard>

        <div className="space-y-6">
          {!featureFlags.syncBundleExport && (
            <GlassCard className="border-amber-400/20 bg-amber-400/5">
              <CardHeader className="pb-3 flex flex-row items-center gap-2">
                <Radio className="h-5 w-5 text-amber-400" />
                <CardTitle className="text-[10px] font-black uppercase tracking-widest">Cross-device sync — coming in M10</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <DemoBadge milestone="M10">
                  Account login + automatic sync across phone ↔ web.
                </DemoBadge>
                <p className="text-[10px] text-muted-foreground leading-relaxed">
                  M10 ships an end-to-end-encrypted CRDT (Yjs) over a thin relay so the same login can sync data across all your devices — the server only ever sees ciphertext. M11 adds joint households so two accounts can share one budget with auto-merge. See <code>docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md</code> in the repo. No P2P handshake exists yet; no fake "Scan / Merge" buttons.
                </p>
              </CardContent>
            </GlassCard>
          )}

          <GlassCard intensity="high">
            <CardHeader className="pb-3 border-b border-primary/5 bg-primary/5">
              <CardTitle className="flex items-center gap-2 text-sm uppercase font-black text-primary">
                <Users className="h-5 w-5" /> Members
              </CardTitle>
            </CardHeader>
            <CardContent className="pt-6 space-y-3">
              {persons && persons.length > 0 ? persons.map(p => (
                <div key={p.id} className="flex items-center gap-4 p-3 rounded-2xl bg-primary/5 border border-primary/10">
                  <div className="h-10 w-10 rounded-2xl bg-primary/20 flex items-center justify-center font-black text-base text-primary uppercase shadow-inner italic">{p.name[0]}</div>
                  <div>
                    <div className="font-black italic uppercase tracking-tighter text-sm">{p.name}</div>
                    <div className="text-[8px] font-black uppercase tracking-widest text-primary opacity-60 italic">{p.role} profile</div>
                  </div>
                </div>
              )) : (
                <p className="text-xs text-muted-foreground">No members yet — add one in the Income or Pay Path setup flow.</p>
              )}
            </CardContent>
          </GlassCard>

          <GlassCard className="bg-primary/5 border-primary/20">
            <CardHeader className="pb-3 flex flex-row items-center gap-2">
              <ShieldCheck className="h-4 w-4 text-primary" />
              <CardTitle className="text-[10px] font-black uppercase tracking-widest">Recent transfers</CardTitle>
            </CardHeader>
            <CardContent className="text-[11px] text-muted-foreground space-y-2">
              {recentSyncs && recentSyncs.length > 0 ? (
                recentSyncs.map(log => (
                  <div key={log.id} className="flex justify-between items-center py-1 border-b border-primary/5 last:border-0">
                    <span className="font-mono text-[10px] truncate max-w-[150px]">{log.deviceId}</span>
                    <span className="text-[9px] opacity-60">{new Date(log.timestamp).toLocaleString()}</span>
                  </div>
                ))
              ) : (
                <div className="flex items-center gap-2">
                  <SettingsIcon className="h-3 w-3 opacity-40" />
                  <span>No transfers logged yet.</span>
                </div>
              )}
            </CardContent>
          </GlassCard>
        </div>
      </div>
    </div>
  );
}
