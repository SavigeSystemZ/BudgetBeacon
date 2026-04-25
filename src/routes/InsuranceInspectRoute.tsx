import { CardHeader, CardTitle, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { 
  ShieldCheck, Search, Zap, ArrowRight, 
  Globe, Sparkles, Plus
} from "lucide-react";
import { useState } from "react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { EmptyState } from "../components/ui/EmptyState";

export default function InsuranceInspectRoute() {
  const [isScraping, setIsScraping] = useState(false);
  const [quotes, setQuotes] = useState<{ provider: string; type: string; quote: number; saving: number; link: string }[]>([]);

  const handleInspect = () => {
    setIsScraping(true);
    setTimeout(() => {
      setQuotes([
        { provider: "Progressive", type: "Auto", quote: 85.00, saving: 12.50, link: "https://progressive.com" },
        { provider: "Geico", type: "Auto", quote: 79.00, saving: 18.50, link: "https://geico.com" },
        { provider: "State Farm", type: "Home", quote: 110.00, saving: 5.00, link: "https://statefarm.com" }
      ]);
      setIsScraping(false);
    }, 2500);
  };

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Insurance Inspect" 
        subtitle="Agentic coverage analysis and market quote inspection."
        actions={
          <Button 
            size="lg" 
            onClick={handleInspect} 
            disabled={isScraping}
            className="gap-3 shadow-xl shadow-primary/20 animate-pulse hover:animate-none h-12 uppercase font-black italic text-xs tracking-widest"
          >
            {isScraping ? <Zap className="h-4 w-4 animate-spin" /> : <Search className="h-4 w-4" />}
            {isScraping ? "Inspecting Market..." : "Execute Inspection"}
          </Button>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        <div className="lg:col-span-1 space-y-6">
          <GlassCard intensity="high" className="border-primary/20 bg-primary/5">
            <CardHeader className="pb-3 border-b border-primary/5">
              <CardTitle className="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest text-primary">
                <ShieldCheck className="h-4 w-4" /> Active Shield
              </CardTitle>
            </CardHeader>
            <CardContent className="pt-6 space-y-6">
              <div className="p-4 rounded-2xl bg-primary/10 border border-primary/20 shadow-inner">
                <div className="text-[9px] font-black uppercase text-muted-foreground mb-1">Monthly Premium Burn</div>
                <div className="text-3xl font-black italic tracking-tighter text-primary">$245.00</div>
              </div>
              <div className="space-y-3">
                <div className="flex justify-between items-center p-2 rounded-xl bg-background/40 border border-primary/5">
                  <span className="text-[10px] font-black uppercase opacity-70">Auto Policy</span>
                  <span className="text-[8px] font-black uppercase px-2 py-1 bg-green-500/10 text-green-500 rounded-full border border-green-500/20">Active</span>
                </div>
                <div className="flex justify-between items-center p-2 rounded-xl bg-background/40 border border-primary/5">
                  <span className="text-[10px] font-black uppercase opacity-70">Home Policy</span>
                  <span className="text-[8px] font-black uppercase px-2 py-1 bg-green-500/10 text-green-500 rounded-full border border-green-500/20">Active</span>
                </div>
              </div>
              <Button variant="outline" className="w-full h-10 uppercase font-black italic text-[9px] tracking-widest border-primary/20">
                <Plus className="h-3 w-3 mr-2" /> Register Policy
              </Button>
            </CardContent>
          </GlassCard>

          <GlassCard className="bg-primary/5 border-primary/20">
            <CardHeader>
              <CardTitle className="text-[10px] font-black uppercase tracking-widest">Analysis Note</CardTitle>
            </CardHeader>
            <CardContent className="text-[10px] font-bold text-muted-foreground leading-relaxed italic">
              Insurance Inspect uses your household telemetry to sweep public actuarial tables. Binding requires direct carrier verification.
            </CardContent>
          </GlassCard>
        </div>

        <div className="lg:col-span-3 space-y-6">
          <h2 className="text-xl font-black uppercase italic text-primary flex items-center gap-2 px-2">
            <Sparkles className="h-5 w-5" /> Market Intelligence
          </h2>
          
          {quotes.length === 0 ? (
            <EmptyState 
              icon={Globe}
              title="Intelligence Gap"
              description="Initiate a market sweep to discover potential savings based on your active household telemetry."
              action={<Button onClick={handleInspect} className="gap-2 px-8 uppercase font-black italic text-xs tracking-widest h-12"><Search className="h-4 w-4" /> Run Inspection</Button>}
            />
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {quotes.map((q, i) => (
                <GlassCard hoverable key={i} className="group overflow-hidden">
                  <div className="flex flex-col md:flex-row items-center justify-between p-6 gap-6">
                    <div className="flex items-center gap-6 w-full md:w-auto">
                      <div className="h-16 w-16 rounded-3xl bg-primary/10 flex items-center justify-center font-black text-2xl text-primary italic border border-primary/20 shadow-inner group-hover:scale-110 transition-transform duration-500">
                        {q.provider[0]}
                      </div>
                      <div>
                        <div className="font-black text-xl uppercase italic tracking-tight">{q.provider}</div>
                        <div className="text-[10px] font-black text-primary uppercase tracking-widest bg-primary/10 px-2 py-0.5 rounded-full inline-block mt-1">{q.type} Coverage</div>
                      </div>
                    </div>
                    <div className="flex items-center gap-8 w-full md:w-auto justify-between border-t md:border-t-0 border-primary/5 pt-6 md:pt-0">
                      <div className="text-right">
                        <div className="text-3xl font-black italic tracking-tighter text-foreground">${q.quote.toFixed(2)}<span className="text-[10px] text-muted-foreground not-italic">/mo</span></div>
                        <div className="text-[10px] font-black text-green-500 uppercase italic tracking-tighter">Save ${q.saving.toFixed(2)} / Monthly propulsion</div>
                      </div>
                      <Button size="icon" variant="ghost" className="h-12 w-12 rounded-full border border-primary/10 group-hover:bg-primary group-hover:text-primary-foreground group-hover:border-primary transition-all duration-500 shadow-2xl">
                        <ArrowRight className="h-6 w-6" />
                      </Button>
                    </div>
                  </div>
                </GlassCard>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
