import { useState } from "react";
import { GlassCard } from "../ui/GlassCard";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../ui/card";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { Users, Copy, Check, ArrowRight, ShieldCheck } from "lucide-react";
import { getSession } from "../../modules/auth/authService";
import { deriveSharedSecret, importPublicKey, wrapKey, unwrapKey } from "../../modules/crypto/crypto";
import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../../db/db";
import { logger } from "../../lib/logger";

export function JointHouseholdPanel() {
  const [mode, setMode] = useState<"idle" | "invite" | "join">("idle");
  const [copied, setCopied] = useState(false);

  // Invite state
  const [inviteeKeyPayload, setInviteeKeyPayload] = useState("");
  const [generatedInvitePayload, setGeneratedInvitePayload] = useState("");

  // Join state
  const [myJoinPayload, setMyJoinPayload] = useState("");
  const [receivedAcceptancePayload, setReceivedAcceptancePayload] = useState("");

  const household = useLiveQuery(() => db.households.toCollection().first());

  const handleCopy = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const generateMyJoinPayload = async () => {
    try {
      const session = getSession();
      if (!session.currentAccount) return;
      setMyJoinPayload(btoa(JSON.stringify({
        publicKey: session.currentAccount.publicKey,
        deviceId: session.currentAccount.id,
      })));
    } catch (err) {
      logger.error("Failed to generate join payload", err);
    }
  };

  const processInviteePayload = async () => {
    try {
      const session = getSession();
      if (!session.currentAccount || !session.currentHouseholdKey || !session.currentSyncKeypair || !household) return;

      const inviteeData = JSON.parse(atob(inviteeKeyPayload));
      const inviteePub = await importPublicKey(inviteeData.publicKey);

      // Derive shared secret
      const sharedSecret = await deriveSharedSecret(session.currentSyncKeypair.privateKey, inviteePub);

      // Wrap household key with shared secret
      const wrappedHouseholdKey = await wrapKey(session.currentHouseholdKey, sharedSecret);

      const acceptancePayload = btoa(JSON.stringify({
        householdId: household.id,
        wrappedHouseholdKey,
        publicKey: session.currentAccount.publicKey,
      }));

      setGeneratedInvitePayload(acceptancePayload);
    } catch (err) {
      logger.error("Failed to process invitee payload", err);
      alert("Invalid invite payload provided.");
    }
  };

  const processAcceptancePayload = async () => {
    try {
      const session = getSession();
      if (!session.currentAccount || !session.currentSyncKeypair) return;

      const acceptData = JSON.parse(atob(receivedAcceptancePayload));
      const inviterPub = await importPublicKey(acceptData.publicKey);

      // Derive shared secret
      const sharedSecret = await deriveSharedSecret(session.currentSyncKeypair.privateKey, inviterPub);

      // Unwrap household key
      const householdKey = await unwrapKey(
        acceptData.wrappedHouseholdKey,
        sharedSecret,
        { name: "AES-GCM", length: 256 },
        ["encrypt", "decrypt"]
      );

      // Update local account with the new household key
      // Wait, we just need to wrap the household key with our local KEK.
      // But we bypassed the passphrase by using autoProvision which has a hardcoded passphrase.
      const { derivePassphraseKey } = await import("../../modules/crypto/crypto");
      const localKek = await derivePassphraseKey("local@device.beacon", "local-device-passphrase-beacon-app");
      const newlyWrappedHouseholdKey = await wrapKey(householdKey, localKek);

      await db.accounts.update(session.currentAccount.id, {
        householdKeyWrapped: newlyWrappedHouseholdKey,
      });

      // Update household ID (this device leaves its old empty household and joins the new one)
      // Since it's a new device, we can just wipe local db and set the new household ID?
      // For now, let's just wipe local db (except accounts) and reload, the sync module will pull.
      // Or simply change the household ID.
      await db.households.clear();
      await db.households.add({
        id: acceptData.householdId,
        name: "Joint Household",
        currency: "USD",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });

      alert("Successfully joined household! The app will now reload.");
      window.location.reload();
    } catch (err) {
      logger.error("Failed to process acceptance payload", err);
      alert("Invalid acceptance payload provided.");
    }
  };

  return (
    <GlassCard className="border-primary/20 bg-primary/5">
      <CardHeader className="border-b border-primary/10 pb-6">
        <CardTitle className="flex items-center gap-2 uppercase italic font-black text-primary">
          <Users className="h-5 w-5" /> Joint Household Pairing
        </CardTitle>
        <CardDescription className="text-[10px] font-bold uppercase tracking-widest text-primary/70">
          Secure offline pairing via ECDH key exchange
        </CardDescription>
      </CardHeader>
      <CardContent className="pt-6 space-y-5">
        {mode === "idle" && (
          <div className="flex flex-col sm:flex-row gap-4">
            <Button onClick={() => setMode("invite")} className="flex-1 bg-primary hover:bg-primary/90 text-primary-foreground gap-2">
              <ShieldCheck className="h-4 w-4" /> Add Device to My Household
            </Button>
            <Button onClick={() => { setMode("join"); generateMyJoinPayload(); }} variant="outline" className="flex-1 border-primary/30 text-primary gap-2">
              <ArrowRight className="h-4 w-4" /> Join Another Household
            </Button>
          </div>
        )}

        {mode === "invite" && (
          <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300">
            {!generatedInvitePayload ? (
              <div className="space-y-4">
                <div className="p-3 bg-muted/30 rounded-xl border border-primary/10">
                  <Label className="text-xs font-bold uppercase text-muted-foreground mb-2 block">Step 1: Ask invitee for their Join Code</Label>
                  <p className="text-[11px] text-muted-foreground leading-relaxed mb-3">
                    The other person must click "Join Another Household" on their device and give you their code.
                  </p>
                  <Input 
                    value={inviteeKeyPayload} 
                    onChange={e => setInviteeKeyPayload(e.target.value)} 
                    placeholder="Paste Invitee's Join Code here..." 
                    className="font-mono text-[10px]"
                  />
                  <Button onClick={processInviteePayload} disabled={!inviteeKeyPayload} className="w-full mt-3 h-8 text-[11px]">
                    Generate Acceptance Code
                  </Button>
                </div>
              </div>
            ) : (
              <div className="space-y-4">
                <div className="p-3 bg-success/10 rounded-xl border border-success/20">
                  <Label className="text-xs font-bold uppercase text-success mb-2 block">Step 2: Give this to the Invitee</Label>
                  <p className="text-[11px] text-success/80 leading-relaxed mb-3">
                    Copy this code and give it to the invitee. It contains the encrypted household key.
                  </p>
                  <div className="flex gap-2">
                    <Input readOnly value={generatedInvitePayload} className="font-mono text-[10px] bg-background/50 border-success/20 text-success" />
                    <Button size="icon" variant="outline" onClick={() => handleCopy(generatedInvitePayload)} className="shrink-0 border-success/20 text-success hover:bg-success/20">
                      {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                    </Button>
                  </div>
                </div>
              </div>
            )}
            <Button variant="ghost" size="sm" onClick={() => { setMode("idle"); setInviteeKeyPayload(""); setGeneratedInvitePayload(""); }} className="w-full text-xs">
              Cancel
            </Button>
          </div>
        )}

        {mode === "join" && (
          <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300">
            <div className="space-y-4">
              <div className="p-3 bg-muted/30 rounded-xl border border-primary/10">
                <Label className="text-xs font-bold uppercase text-muted-foreground mb-2 block">Step 1: Give this Join Code to the Inviter</Label>
                <div className="flex gap-2">
                  <Input readOnly value={myJoinPayload} className="font-mono text-[10px]" />
                  <Button size="icon" variant="outline" onClick={() => handleCopy(myJoinPayload)} className="shrink-0">
                    {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                  </Button>
                </div>
              </div>
              <div className="p-3 bg-muted/30 rounded-xl border border-primary/10">
                <Label className="text-xs font-bold uppercase text-muted-foreground mb-2 block">Step 2: Enter their Acceptance Code</Label>
                <p className="text-[11px] text-muted-foreground leading-relaxed mb-3">
                  Once they accept your Join Code, they will give you an Acceptance Code. Paste it here to complete pairing.
                </p>
                <Input 
                  value={receivedAcceptancePayload} 
                  onChange={e => setReceivedAcceptancePayload(e.target.value)} 
                  placeholder="Paste Acceptance Code here..." 
                  className="font-mono text-[10px]"
                />
                <Button onClick={processAcceptancePayload} disabled={!receivedAcceptancePayload} className="w-full mt-3 h-8 text-[11px] bg-primary text-primary-foreground">
                  Complete Join
                </Button>
              </div>
            </div>
            <Button variant="ghost" size="sm" onClick={() => { setMode("idle"); setReceivedAcceptancePayload(""); }} className="w-full text-xs">
              Cancel
            </Button>
          </div>
        )}
      </CardContent>
    </GlassCard>
  );
}
