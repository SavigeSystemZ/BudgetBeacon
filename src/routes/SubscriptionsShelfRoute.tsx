import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { NativeSelect } from "../components/ui/native-select";
import { 
  Library, Trash2, Mail, Edit2,
  ShieldAlert, Sparkles, MessageSquare, AlertCircle, Plus 
} from "lucide-react";
import { useState, useMemo } from "react";
import { cn } from "../lib/utils";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { EmptyState } from "../components/ui/EmptyState";
import { BeaconModal } from "../components/ui/BeaconModal";

const subscriptionSchema = z.object({
  label: z.string().min(1, "Name is required"),
  amount: z.number().min(0),
  frequency: z.enum(["monthly", "annual", "quarterly"]),
  category: z.enum(["entertainment", "software", "utility", "health", "other"]),
  nextRenewal: z.string().optional(),
  supportEmail: z.string().email().optional().or(z.literal("")),
  personId: z.string().optional()
});

type FormData = z.infer<typeof subscriptionSchema>;

interface Subscription {
  id: string;
  label: string;
  amount: number;
  frequency: "monthly" | "annual" | "quarterly";
  category: "entertainment" | "software" | "utility" | "health" | "other";
  supportEmail?: string;
  personId: string;
}

export default function SubscriptionsShelfRoute() {
  const subscriptions = useLiveQuery(() => db.subscriptions.toArray(), []) as Subscription[] | undefined;
  const households = useLiveQuery(() => db.households.toArray(), []);
  const persons = useLiveQuery(() => db.persons.toArray(), []);
  const householdId = households?.[0]?.id;
  const defaultPersonId = persons?.[0]?.id || "default-person";

  const [editingId, setEditingId] = useState<string | null>(null);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [activeTemplate, setActiveTemplate] = useState<{ type: string; sub: Subscription; content: string } | null>(null);

  const form = useForm<FormData>({
    resolver: zodResolver(subscriptionSchema),
    defaultValues: { label: "", amount: 0, frequency: "monthly", category: "entertainment", supportEmail: "", personId: defaultPersonId },
  });

  const totalMonthly = useMemo(() => {
    if (!subscriptions) return 0;
    return subscriptions.reduce((acc, s) => {
      if (s.frequency === "annual") return acc + (s.amount / 12);
      if (s.frequency === "quarterly") return acc + (s.amount / 3);
      return acc + s.amount;
    }, 0);
  }, [subscriptions]);

  const onSubmit = async (data: FormData) => {
    if (!householdId) return;
    if (editingId) {
      await db.subscriptions.update(editingId, { ...data });
      setEditingId(null);
    } else {
      await db.subscriptions.add({ ...data, id: createId(), householdId, personId: data.personId || defaultPersonId });
    }
    form.reset();
    setIsAddModalOpen(false);
  };

  const handleEdit = (sub: Subscription) => {
    setEditingId(sub.id);
    form.reset({
      label: sub.label,
      amount: sub.amount,
      frequency: sub.frequency,
      category: sub.category,
      supportEmail: sub.supportEmail || "",
      personId: sub.personId
    });
    setIsAddModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm("Remove this subscription from your shelf?")) await db.subscriptions.delete(id);
  };

  const generateTemplate = (type: "cancel" | "dispute", sub: Subscription) => {
    const templates = {
      cancel: `Subject: Cancellation Request - ${sub.label}\n\nTo the Support Team,\n\nI am writing to formally request the cancellation of my ${sub.label} subscription effective immediately. Please confirm once this is processed.\n\nThank you,\n[My Name]`,
      dispute: `Subject: Billing Dispute - ${sub.label}\n\nTo the Billing Department,\n\nI am disputing a recent charge of $${sub.amount} for ${sub.label}. I would like to request a formal review.\n\nBest regards,\n[My Name]`
    };
    setActiveTemplate({ type, sub, content: templates[type] });
  };

  if (!subscriptions) return <div className="p-4 text-muted-foreground animate-pulse">Dusting the Shelf...</div>;

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Subscriptions Shelf" 
        subtitle="Manage recurring burns and agentic protocols."
        actions={
          <div className="flex items-center gap-4 bg-primary/10 px-6 py-2.5 rounded-2xl border border-primary/20 shadow-2xl">
            <div className="text-right">
              <div className="text-[10px] font-black uppercase text-muted-foreground tracking-widest">Monthly Burn</div>
              <div className="text-xl font-black text-primary italic tracking-tighter">${totalMonthly.toFixed(2)}</div>
            </div>
            <Button size="icon" onClick={() => { setEditingId(null); form.reset(); setIsAddModalOpen(true); }} className="rounded-full shadow-lg shadow-primary/20 h-10 w-10">
              <Plus className="h-5 w-5" />
            </Button>
          </div>
        }
      />

      {subscriptions.length === 0 ? (
        <EmptyState 
          icon={Library}
          title="The Shelf is Empty"
          description="Stock your shelf with recurring services to track your cumulative burn rate."
          action={<Button onClick={() => setIsAddModalOpen(true)} className="gap-2 px-8 uppercase font-black italic text-xs tracking-widest"><Plus className="h-4 w-4" /> Add Subscription</Button>}
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {subscriptions.map((sub) => (
            <GlassCard hoverable key={sub.id} className={cn("overflow-hidden group", editingId === sub.id && "border-primary ring-1 ring-primary shadow-[0_0_30px_rgba(var(--primary),0.2)]")}>
              <CardHeader className="pb-3 border-b border-primary/5 bg-primary/5">
                <div className="flex justify-between items-start">
                  <div>
                    <CardTitle className="text-xl font-black italic tracking-tight">{sub.label}</CardTitle>
                    <CardDescription className="uppercase text-[10px] font-black tracking-widest text-primary opacity-70">{sub.category}</CardDescription>
                  </div>
                  <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all duration-300">
                    <Button variant="ghost" size="icon" onClick={() => handleEdit(sub)} className="h-8 w-8 rounded-full hover:bg-primary/10 text-primary"><Edit2 className="h-4 w-4" /></Button>
                    <Button variant="ghost" size="icon" onClick={() => handleDelete(sub.id)} className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"><Trash2 className="h-4 w-4" /></Button>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="pt-6 space-y-6">
                <div className="flex justify-between items-end">
                   <div>
                     <div className="text-[10px] uppercase font-black text-muted-foreground opacity-50 mb-1">Service Value</div>
                     <div className="text-3xl font-black italic tracking-tighter">${sub.amount.toFixed(2)}</div>
                   </div>
                   <div className="text-right">
                     <div className="text-[10px] uppercase font-black text-primary mb-1">Frequency</div>
                     <div className="text-xs font-black uppercase tracking-widest">{sub.frequency}</div>
                   </div>
                </div>

                <div className="flex gap-2">
                  <Button variant="outline" size="sm" className="flex-1 gap-2 text-[10px] font-black uppercase tracking-widest h-10 border-primary/20 hover:bg-destructive/5 hover:text-destructive hover:border-destructive/30" onClick={() => generateTemplate("cancel", sub)}>
                    <ShieldAlert className="h-3.5 w-3.5" /> Cancel Protocol
                  </Button>
                  <Button variant="outline" size="sm" className="flex-1 gap-2 text-[10px] font-black uppercase tracking-widest h-10 border-primary/20" onClick={() => generateTemplate("dispute", sub)}>
                    <AlertCircle className="h-3.5 w-3.5" /> Dispute
                  </Button>
                </div>

                <div className="pt-4 border-t border-primary/5 flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="h-5 w-5 rounded-full bg-primary/10 flex items-center justify-center text-[10px] font-black text-primary">{persons?.find(p => p.id === sub.personId)?.name?.[0]}</div>
                    <span className="text-[10px] font-bold uppercase text-muted-foreground tracking-widest">{persons?.find(p => p.id === sub.personId)?.name}</span>
                  </div>
                  <span className="text-[9px] font-mono text-muted-foreground/60">{sub.supportEmail || "No Support Email"}</span>
                </div>
              </CardContent>
            </GlassCard>
          ))}
        </div>
      )}

      {/* Add/Edit Modal */}
      <BeaconModal 
        isOpen={isAddModalOpen} 
        onClose={() => { setIsAddModalOpen(false); setEditingId(null); }} 
        title={editingId ? "Edit Subscription" : "Add to Shelf"}
      >
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Service Name</Label>
              <Input {...form.register("label")} placeholder="e.g. Netflix" className="bg-primary/5 border-none font-bold h-12" />
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Monthly/Total Cost</Label>
              <Input type="number" step="0.01" {...form.register("amount", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" />
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Billing Loop</Label>
              <NativeSelect {...form.register("frequency")} className="bg-primary/5 border-none font-bold h-12">
                <option value="monthly">Monthly</option>
                <option value="quarterly">Quarterly</option>
                <option value="annual">Annual</option>
              </NativeSelect>
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Telemetry Owner</Label>
              <NativeSelect {...form.register("personId")} className="bg-primary/5 border-none font-bold h-12">
                {persons?.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
              </NativeSelect>
            </div>
            <div className="space-y-2 md:col-span-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Support Contact (Email)</Label>
              <Input {...form.register("supportEmail")} placeholder="support@service.com" className="bg-primary/5 border-none font-bold h-12" />
            </div>
          </div>
          <div className="flex gap-3 pt-4">
            <Button type="button" variant="outline" onClick={() => { setIsAddModalOpen(false); setEditingId(null); }} className="flex-1 h-12 uppercase font-black italic tracking-widest border-primary/20">Cancel</Button>
            <Button type="submit" className="flex-[2] h-12 uppercase font-black italic tracking-widest shadow-xl shadow-primary/20">
              {editingId ? "Update Asset" : "Commit to Shelf"}
            </Button>
          </div>
        </form>
      </BeaconModal>

      {/* Protocol Modal */}
      <BeaconModal 
        isOpen={!!activeTemplate} 
        onClose={() => setActiveTemplate(null)} 
        title={`Beacon Protocol: ${activeTemplate?.type === "cancel" ? "Cancellation" : "Dispute"}`}
        footer={
          <>
            <Button variant="outline" className="gap-2 h-12 px-6 uppercase font-black italic text-xs tracking-widest border-primary/20" onClick={() => { void navigator.clipboard.writeText(activeTemplate?.content || ""); }}>
              <MessageSquare className="h-4 w-4" /> Copy Protocol
            </Button>
            <Button className="gap-2 h-12 px-6 uppercase font-black italic text-xs tracking-widest shadow-xl shadow-primary/20" onClick={() => window.location.href = `mailto:${activeTemplate?.sub.supportEmail || ''}?subject=Beacon Request&body=${encodeURIComponent(activeTemplate?.content || "")}`}>
              <Mail className="h-4 w-4" /> Execute Email
            </Button>
          </>
        }
      >
        <div className="space-y-4">
          <div className="p-6 bg-background/50 rounded-3xl text-sm font-mono whitespace-pre-wrap border border-primary/10 leading-relaxed italic shadow-inner">
            {activeTemplate?.content}
          </div>
          <div className="flex items-center gap-3 p-4 rounded-2xl bg-primary/5 border border-primary/10">
            <Sparkles className="h-5 w-5 text-primary shrink-0" />
            <p className="text-[10px] font-bold uppercase tracking-widest opacity-70 leading-tight">
              Agentic Note: This protocol was generated by mapping your {activeTemplate?.sub.label} subscription telemetry to optimal dispute language.
            </p>
          </div>
        </div>
      </BeaconModal>
    </div>
  );
}
