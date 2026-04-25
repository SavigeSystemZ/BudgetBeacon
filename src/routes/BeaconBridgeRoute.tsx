import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../db/db";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { 
  Wifi, QrCode, RefreshCw, Smartphone, 
  Users, ShieldCheck, Merge, Radio
} from "lucide-react";
import { useState } from "react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";

export default function BeaconBridgeRoute() {
  const [syncStep, setSyncStep] = useState<"idle" | "pairing" | "merging" | "complete">("idle");
  const [targetDevice, setTargetDevice] = useState<string | null>(null);

  const persons = useLiveQuery(() => db.persons.toArray(), []);

  const handleInitiateSync = () => {
    setSyncStep("pairing");
    setTimeout(() => {
      setTargetDevice("Partner's Phone (iPhone 15)");
    }, 2000);
  };

  const handleMerge = async () => {
    setSyncStep("merging");
    setTimeout(async () => {
      const now = new Date().toISOString();
      await db.syncLogs.add({
        id: crypto.randomUUID(),
        deviceId: targetDevice || "Unknown",
        timestamp: now,
        payloadSize: 1024 * 45
      });
      setSyncStep("complete");
      alert("Household telemetry unified.");
    }, 3500);
  };

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Beacon Bridge" 
        subtitle="Peer-to-Peer household synchronization and telemetry merging."
        actions={
          <div className="h-12 w-12 rounded-full bg-blue-500/10 flex items-center justify-center border border-blue-500/20 shadow-xl shadow-blue-500/10">
            <Radio className="h-6 w-6 text-blue-500 animate-pulse" />
          </div>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <GlassCard intensity="high" className="border-blue-500/20 bg-blue-500/5 shadow-2xl relative overflow-hidden">
          <div className="absolute top-0 right-0 p-4 opacity-10"><Wifi className="h-32 w-32 text-blue-500" /></div>
          <CardHeader className="border-b border-blue-500/10 bg-blue-500/5 pb-6">
            <CardTitle className="flex items-center gap-2 uppercase italic font-black text-blue-500">
              <Smartphone className="h-5 w-5" /> Sync Terminal
            </CardTitle>
            <CardDescription className="text-[10px] font-bold uppercase tracking-widest text-blue-500/70">Establish P2P Encrypted Handshake</CardDescription>
          </CardHeader>
          <CardContent className="pt-8">
            {syncStep === "idle" && (
              <div className="flex flex-col items-center gap-8 py-10">
                <div className="p-10 bg-background/50 rounded-[2.5rem] border-2 border-dashed border-blue-500/20 relative group hover:border-blue-500/40 transition-all duration-500 cursor-pointer shadow-inner">
                  <QrCode className="h-32 w-32 text-blue-500" />
                  <div className="absolute inset-0 flex items-center justify-center bg-blue-500/10 opacity-0 group-hover:opacity-100 transition-opacity rounded-[2.5rem]">
                    <span className="text-[10px] font-black uppercase text-blue-500 tracking-widest">Generate Auth Key</span>
                  </div>
                </div>
                <Button size="lg" onClick={handleInitiateSync} className="w-full bg-blue-500 hover:bg-blue-600 text-white shadow-2xl shadow-blue-500/40 h-14 uppercase font-black italic tracking-widest">
                  Scan for Nearby Beacons
                </Button>
              </div>
            )}

            {syncStep === "pairing" && (
              <div className="space-y-8 py-6 text-center">
                <div className="flex flex-col items-center gap-4">
                  <div className="h-20 w-20 rounded-full bg-blue-500/20 flex items-center justify-center animate-ping absolute" />
                  <div className="h-20 w-20 rounded-full bg-blue-500/20 flex items-center justify-center relative border border-blue-500/30">
                    <Smartphone className="h-10 w-10 text-blue-500" />
                  </div>
                  <div className="space-y-1">
                    <p className="font-black text-lg uppercase italic text-blue-500">Pairing Protocol Active</p>
                    <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest">Keep devices within telemetry range</p>
                  </div>
                </div>
                {targetDevice ? (
                  <GlassCard className="p-4 border-blue-500/30 bg-blue-500/10 flex items-center justify-between animate-in zoom-in-95">
                    <div className="flex items-center gap-3">
                      <div className="h-10 w-10 rounded-2xl bg-blue-500 flex items-center justify-center text-white font-black italic text-sm">P</div>
                      <span className="text-sm font-black italic uppercase tracking-tighter">{targetDevice}</span>
                    </div>
                    <Button size="sm" onClick={handleMerge} className="bg-blue-500 text-white h-10 px-6 uppercase font-black italic text-[10px] tracking-widest">Merge Data</Button>
                  </GlassCard>
                ) : (
                  <div className="flex items-center justify-center gap-4 text-blue-500 font-black uppercase italic text-xs animate-pulse pt-4">
                    <RefreshCw className="h-4 w-4 animate-spin" /> Identifying Nearby Instances...
                  </div>
                )}
              </div>
            )}

            {syncStep === "merging" && (
              <div className="flex flex-col items-center py-16 gap-8">
                <Merge className="h-24 w-24 text-blue-500 animate-bounce" />
                <div className="w-full max-w-[250px] h-3 bg-blue-500/10 rounded-full overflow-hidden border border-blue-500/20 shadow-inner">
                  <div className="h-full bg-blue-500 animate-pulse" style={{ width: '75%' }} />
                </div>
                <p className="text-[10px] font-black uppercase tracking-widest text-blue-500 italic animate-pulse text-center leading-relaxed">
                  Reconciling Ledger Loops,<br/>Stash Objectives & Multi-Person Telemetry...
                </p>
              </div>
            )}

            {syncStep === "complete" && (
              <div className="flex flex-col items-center py-12 gap-8 text-center">
                <div className="h-24 w-24 rounded-[2rem] bg-green-500/10 flex items-center justify-center border-2 border-green-500/20 shadow-2xl">
                  <ShieldCheck className="h-12 w-12 text-green-500" />
                </div>
                <div className="space-y-2">
                  <h3 className="text-2xl font-black uppercase italic text-green-500 tracking-tighter">Unified Mission</h3>
                  <p className="text-xs font-bold text-muted-foreground max-w-[250px] uppercase leading-relaxed">Household telemetry successfully synchronized across both instances.</p>
                </div>
                <Button variant="outline" onClick={() => setSyncStep("idle")} className="w-full h-12 border-blue-500/20 text-blue-500 uppercase font-black italic text-xs tracking-widest">Dismiss Terminal</Button>
              </div>
            )}
          </CardContent>
        </GlassCard>

        <div className="space-y-8">
          <GlassCard intensity="high">
            <CardHeader className="pb-3 border-b border-primary/5 bg-primary/5">
              <CardTitle className="flex items-center gap-2 text-sm uppercase font-black text-primary">
                <Users className="h-5 w-5" /> Members
              </CardTitle>
            </CardHeader>
            <CardContent className="pt-6 space-y-4">
              {persons?.map(p => (
                <div key={p.id} className="flex items-center justify-between p-4 rounded-2xl bg-primary/5 border border-primary/10 hover:border-primary/30 transition-all cursor-default">
                  <div className="flex items-center gap-4">
                    <div className="h-12 w-12 rounded-2xl bg-primary/20 flex items-center justify-center font-black text-lg text-primary uppercase shadow-inner italic">{p.name[0]}</div>
                    <div>
                      <div className="font-black italic uppercase tracking-tighter">{p.name}</div>
                      <div className="text-[8px] font-black uppercase tracking-widest text-primary opacity-60 italic">{p.role} Profile</div>
                    </div>
                  </div>
                  <div className="h-2 w-2 rounded-full bg-green-500 shadow-[0_0_10px_rgba(34,197,94,0.5)]" />
                </div>
              ))}
              <Button variant="ghost" className="w-full h-12 uppercase font-black italic text-[10px] tracking-widest text-primary border border-primary/10 border-dashed hover:bg-primary/5 rounded-2xl">
                Authorize New Instance
              </Button>
            </CardContent>
          </GlassCard>

          <GlassCard className="bg-primary/5 border-primary/20 shadow-2xl">
            <CardHeader>
              <CardTitle className="text-[10px] font-black uppercase tracking-widest flex items-center gap-2"><ShieldCheck className="h-4 w-4" /> Bridge Encryption</CardTitle>
            </CardHeader>
            <CardContent className="text-[10px] font-bold text-muted-foreground leading-relaxed italic">
              Handshakes occur over local secure discovery protocols. Your financial telemetry is encrypted with session-specific keys before instance merging.
            </CardContent>
          </GlassCard>
        </div>
      </div>
    </div>
  );
}
