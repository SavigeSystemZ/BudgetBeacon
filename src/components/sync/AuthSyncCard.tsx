import { useEffect, useState } from "react";
import { GlassCard } from "../ui/GlassCard";
import { CardContent, CardHeader, CardTitle, CardDescription } from "../ui/card";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { ShieldCheck, LogIn, UserPlus, LogOut, Loader2 } from "lucide-react";
import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../../db/db";
import { signUp, login, logout, getSession, restoreSessionPromptIfNeeded } from "../../modules/auth/authService";
import { syncService } from "../../modules/sync/syncService";
import { SyncStatusBadge } from "./SyncStatusBadge";

const RELAY_URL_KEY = "beacon_sync_relay_url";

export function AuthSyncCard() {
  const accounts = useLiveQuery(() => db.accounts.toArray(), []);
  const [activeId, setActiveId] = useState<string | null>(() => localStorage.getItem("beacon_active_account"));
  const [mode, setMode] = useState<"signup" | "login">("login");
  const [email, setEmail] = useState("");
  const [passphrase, setPassphrase] = useState("");
  const [relayUrl, setRelayUrl] = useState<string>(() => localStorage.getItem(RELAY_URL_KEY) ?? "");
  const [busy, setBusy] = useState<"idle" | "auth" | "boot">("idle");
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);

  // If accounts exist but none active, default to login. If none exist, default to signup.
  // Derived directly from `accounts` rather than via a setState-in-effect.
  const effectiveMode: "signup" | "login" =
    accounts && accounts.length === 0 ? "signup" : mode;

  // Restore active account row reference (does not unwrap keys).
  useEffect(() => {
    void restoreSessionPromptIfNeeded();
  }, []);

  const session = getSession();
  const activeAccount = accounts?.find(a => a.id === activeId);
  const isAuthed = !!session.currentAccount && session.currentHouseholdKey != null;
  const householdId = useLiveQuery(() => db.households.toCollection().first().then(h => h?.id), []);

  const handleAuth = async () => {
    setError(null);
    setInfo(null);
    if (!email.trim() || !passphrase.trim()) {
      setError("Email and passphrase are both required.");
      return;
    }
    if (effectiveMode === "signup" && passphrase.length < 8) {
      setError("Passphrase must be at least 8 characters.");
      return;
    }
    setBusy("auth");
    try {
      const account = effectiveMode === "signup"
        ? await signUp(email.trim(), passphrase)
        : await login(email.trim(), passphrase);
      setActiveId(account.id);
      setPassphrase("");
      setInfo(effectiveMode === "signup" ? "Account created. Sync key derived locally." : "Signed in. Sync key unwrapped locally.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Authentication failed.");
    } finally {
      setBusy("idle");
    }
  };

  const handleBootstrap = async () => {
    setError(null);
    setInfo(null);
    const sess = getSession();
    if (!sess.currentAccount || !sess.currentHouseholdKey || !householdId) {
      setError("Sign in first.");
      return;
    }
    setBusy("boot");
    try {
      const url = relayUrl.trim();
      if (url) localStorage.setItem(RELAY_URL_KEY, url);
      else localStorage.removeItem(RELAY_URL_KEY);
      await syncService.bootstrap(householdId, sess.currentHouseholdKey, url || null);
      setInfo(url ? "Sync bootstrapped. Connecting to relay…" : "Sync bootstrapped locally (no relay).");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Bootstrap failed.");
    } finally {
      setBusy("idle");
    }
  };

  const handleLogout = () => {
    logout();
    syncService.disconnect();
    setActiveId(null);
    setInfo("Signed out. Local data unaffected.");
  };

  return (
    <GlassCard className="overflow-hidden border-primary/10 bg-card/50 backdrop-blur-xl md:col-span-2">
      <CardHeader className="bg-primary/5">
        <CardTitle className="flex items-center gap-2">
          <ShieldCheck className="h-5 w-5" /> Sync &amp; Account
          <SyncStatusBadge className="ml-auto" />
        </CardTitle>
        <CardDescription>
          E2EE optional. Local-only is the default — sign in only if you want to share with a partner device.
        </CardDescription>
      </CardHeader>
      <CardContent className="pt-6 space-y-4">
        {isAuthed ? (
          <div className="space-y-4">
            <div className="rounded-2xl border border-emerald-500/20 bg-emerald-500/5 p-4 text-sm">
              <div className="font-bold text-emerald-500">Signed in as {activeAccount?.email}</div>
              <div className="text-xs text-muted-foreground mt-1">
                Household key is in memory only. Logging out clears it; local Dexie data is untouched.
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="relay-url">Relay URL (optional)</Label>
              <Input
                id="relay-url"
                type="url"
                placeholder="wss://your-relay.example.com"
                value={relayUrl}
                onChange={(e) => setRelayUrl(e.target.value)}
                autoComplete="off"
              />
              <p className="text-xs text-muted-foreground">
                Leave blank to mirror locally without a network. The relay only sees ciphertext.
              </p>
            </div>

            <div className="flex flex-wrap gap-2">
              <Button onClick={handleBootstrap} disabled={busy !== "idle"}>
                {busy === "boot" ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : <ShieldCheck className="h-4 w-4 mr-2" />}
                Start sync
              </Button>
              <Button variant="ghost" onClick={handleLogout} disabled={busy !== "idle"}>
                <LogOut className="h-4 w-4 mr-2" /> Sign out
              </Button>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="flex gap-2">
              <Button
                type="button"
                variant={effectiveMode === "login" ? "default" : "ghost"}
                onClick={() => setMode("login")}
                disabled={accounts?.length === 0}
              >
                <LogIn className="h-4 w-4 mr-2" /> Sign in
              </Button>
              <Button
                type="button"
                variant={effectiveMode === "signup" ? "default" : "ghost"}
                onClick={() => setMode("signup")}
              >
                <UserPlus className="h-4 w-4 mr-2" /> Create account
              </Button>
            </div>

            <div className="space-y-2">
              <Label htmlFor="auth-email">Email</Label>
              <Input
                id="auth-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="email"
                placeholder="you@example.com"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="auth-pass">Passphrase</Label>
              <Input
                id="auth-pass"
                type="password"
                value={passphrase}
                onChange={(e) => setPassphrase(e.target.value)}
                autoComplete={effectiveMode === "signup" ? "new-password" : "current-password"}
                placeholder="At least 8 characters"
              />
              <p className="text-xs text-muted-foreground">
                {effectiveMode === "signup"
                  ? "Used to derive your household key. Cannot be recovered — store it safely."
                  : "Used locally to unwrap your household key. Never sent over the network."}
              </p>
            </div>

            <Button onClick={handleAuth} disabled={busy !== "idle"} className="w-full">
              {busy === "auth" && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              {effectiveMode === "signup" ? "Create account" : "Sign in"}
            </Button>
          </div>
        )}

        {error && <div role="alert" className="text-xs font-bold text-destructive">{error}</div>}
        {info && <div role="status" className="text-xs font-bold text-emerald-500">{info}</div>}
      </CardContent>
    </GlassCard>
  );
}
