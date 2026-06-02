import { useState } from "react";
import { BeaconModal } from "../ui/BeaconModal";
import { Button } from "../ui/button";
import { KeyRound, Copy, Download, Check, ShieldAlert } from "lucide-react";

interface RecoveryCodesSheetProps {
  isOpen: boolean;
  onClose: () => void;
  email: string;
  codes: string[];
}

function buildText(email: string, codes: string[]): string {
  return [
    "Budget Beacon — Account Recovery Codes",
    `Account: ${email}`,
    `Generated: ${new Date().toISOString()}`,
    "",
    "Each code can be used ONCE to recover access if you lose your passphrase.",
    "Store these somewhere safe and offline. They are shown only once.",
    "",
    ...codes.map((c, i) => `${String(i + 1).padStart(2, "0")}.  ${c}`),
    "",
  ].join("\n");
}

/**
 * One-time display of newly generated recovery codes. The user must copy or
 * download them and explicitly confirm before the sheet can close — they are
 * never retrievable again (only their hashes are stored).
 */
export function RecoveryCodesSheet({ isOpen, onClose, email, codes }: RecoveryCodesSheetProps) {
  const [copied, setCopied] = useState(false);
  const [saved, setSaved] = useState(false);
  const [confirmed, setConfirmed] = useState(false);

  const handleCopy = async () => {
    const text = buildText(email, codes);
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      // Fallback for older WebViews without the async clipboard API.
      const ta = document.createElement("textarea");
      ta.value = text;
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.select();
      try { document.execCommand("copy"); } catch { /* ignore */ }
      document.body.removeChild(ta);
    }
    setCopied(true);
    setSaved(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleDownload = () => {
    const blob = new Blob([buildText(email, codes)], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "budget-beacon-recovery-codes.txt";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    setSaved(true);
  };

  return (
    <BeaconModal
      isOpen={isOpen}
      onClose={() => { if (confirmed) onClose(); }}
      title="Your recovery codes"
      maxWidth="max-w-xl"
      footer={
        <div className="flex flex-col gap-3 w-full">
          <label className="flex items-start gap-3 text-xs text-muted-foreground cursor-pointer select-none">
            <input
              type="checkbox"
              checked={confirmed}
              onChange={(e) => setConfirmed(e.target.checked)}
              className="mt-0.5 h-4 w-4 accent-primary"
            />
            <span>I have saved these codes somewhere safe. I understand they will not be shown again.</span>
          </label>
          <Button onClick={onClose} disabled={!confirmed} className="w-full">
            Done
          </Button>
        </div>
      }
    >
      <div className="space-y-5">
        <div className="flex items-start gap-3 rounded-2xl border border-warning/30 bg-warning/5 p-4 text-xs">
          <ShieldAlert className="h-5 w-5 shrink-0 text-warning" aria-hidden />
          <p className="text-muted-foreground">
            Each code works <strong>once</strong> to restore access if you lose your passphrase.
            They are stored only as hashes — Budget Beacon cannot show them again. Keep them offline
            and private.
          </p>
        </div>

        <ul className="grid grid-cols-1 sm:grid-cols-2 gap-2" aria-label="Recovery codes">
          {codes.map((code, i) => (
            <li
              key={code}
              className="flex items-center gap-3 rounded-xl border border-primary/10 bg-primary/5 px-3 py-2 font-mono text-sm tracking-wide"
            >
              <span className="text-[10px] font-bold text-muted-foreground w-5 shrink-0">
                {String(i + 1).padStart(2, "0")}
              </span>
              <span className="select-all">{code}</span>
            </li>
          ))}
        </ul>

        <div className="flex flex-wrap gap-2">
          <Button type="button" variant="outline" onClick={handleCopy} className="gap-2">
            {copied ? <Check className="h-4 w-4 text-success" /> : <Copy className="h-4 w-4" />}
            {copied ? "Copied" : "Copy all"}
          </Button>
          <Button type="button" variant="outline" onClick={handleDownload} className="gap-2">
            <Download className="h-4 w-4" /> Download .txt
          </Button>
          <span className="flex items-center gap-1 text-[11px] text-muted-foreground ml-auto">
            <KeyRound className="h-3.5 w-3.5" />
            {saved ? "Saved — confirm below" : "Copy or download first"}
          </span>
        </div>
      </div>
    </BeaconModal>
  );
}
