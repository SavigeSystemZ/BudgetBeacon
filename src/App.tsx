import React, { useState, type ReactNode, lazy, Suspense } from "react";
import { HashRouter, Routes, Route, NavLink, useLocation } from "react-router-dom";
import "./index.css";

// Each route is code-split via React.lazy so the initial bundle stays small.
// Recharts, Tesseract.js wrappers, etc. only load when the user navigates
// to a route that needs them.
const DashboardRoute = lazy(() => import("./routes/DashboardRoute"));
const BudgetMissionControlRoute = lazy(() => import("./routes/BudgetMissionControlRoute"));
const IncomeRoute = lazy(() => import("./routes/IncomeRoute"));
const PayPathRoute = lazy(() => import("./routes/PayPathRoute"));
const LedgerRoute = lazy(() => import("./routes/LedgerRoute"));
const StashMapRoute = lazy(() => import("./routes/StashMapRoute"));
const CreditRoute = lazy(() => import("./routes/CreditRoute"));
const DebtCenterRoute = lazy(() => import("./routes/DebtCenterRoute"));
const TaxTaxiRoute = lazy(() => import("./routes/TaxTaxiRoute"));
const DocumentStoreRoute = lazy(() => import("./routes/DocumentStoreRoute"));
const SubscriptionsShelfRoute = lazy(() => import("./routes/SubscriptionsShelfRoute"));
const InsuranceInspectRoute = lazy(() => import("./routes/InsuranceInspectRoute"));
const BeaconBridgeRoute = lazy(() => import("./routes/BeaconBridgeRoute"));
const ReportsRoute = lazy(() => import("./routes/ReportsRoute"));
const SettingsRoute = lazy(() => import("./routes/SettingsRoute"));
import { db } from "./db/db";
import { useLiveQuery } from "dexie-react-hooks";
import { OnboardingWizard } from "./components/setup/OnboardingWizard";
import { ThemeProvider } from "./components/theme-provider";
import { ModeToggle } from "./components/mode-toggle";
import { BeaconChatbot } from "./components/BeaconChatbot";
import { DeleteConfirmProvider } from "./context/DeleteConfirmContext";
import { ErrorBoundary } from "./components/ErrorBoundary";

import { DexieErrorToastBridge } from "./components/db/DexieErrorToastBridge";
import { ToastProvider } from "./components/ui/Toast";
import { CardSkeleton } from "./components/ui/Skeleton";
import { StatusBarController } from "./components/native/StatusBarController";
import { 
  LayoutDashboard, ReceiptText, CreditCard, PiggyBank, Menu, X, 
  FolderLock, Compass, Library, ShieldCheck, Share2, Wallet, 
  Zap, FileText, Settings, ShieldAlert, Sparkles 
} from "lucide-react";
import { cn } from "./lib/utils";

const AppShell = ({ children }: { children: React.ReactNode }) => {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const location = useLocation();

  const closeMenu = () => setIsMobileMenuOpen(false);

  const navItems = [
    { to: "/", label: "Dashboard Cockpit", icon: LayoutDashboard },
    { to: "/mission-control", label: "Mission Control", icon: Compass },
    { to: "/ledger", label: "Ledger Loops", icon: ReceiptText },
    { to: "/income", label: "Income Pool", icon: Wallet },
    { to: "/pay-path", label: "Pay Path", icon: CreditCard },
    { to: "/stash-map", label: "Stash Map", icon: PiggyBank },
    { to: "/debt-center", label: "Debt Center", icon: ShieldAlert, variant: "destructive" },
    { to: "/tax-taxi", label: "Tax Taxi", icon: Zap },
    { to: "/documents", label: "The Vault", icon: FolderLock },
    { to: "/subscriptions", label: "Subscriptions Shelf", icon: Library },
    { to: "/insurance", label: "Insurance Inspect", icon: ShieldCheck },
    { to: "/bridge", label: "Beacon Bridge", icon: Share2, color: "text-info" },
    { to: "/credit", label: "Credit Snapshot", icon: FileText },
    { to: "/reports", label: "Reports Arena", icon: Sparkles },
    { to: "/settings", label: "System Settings", icon: Settings },
  ];

  return (
    <div className="flex min-h-[100dvh] w-full bg-transparent text-foreground transition-all duration-700 md:pb-0 font-sans selection:bg-primary/30" style={{ paddingBottom: 'calc(env(safe-area-inset-bottom, 0px) + 5rem)' }}>
      {/* Desktop Sidebar */}
      <nav className="w-72 border-r border-white/10 dark:border-white/5 bg-card/20 dark:bg-card/10 backdrop-blur-3xl p-6 pt-[calc(env(safe-area-inset-top,0px)+1.5rem)] space-y-4 flex-col justify-between hidden md:flex shrink-0 shadow-[40px_0_100px_rgba(0,0,0,0.1)] relative z-50 transition-all duration-500 overflow-y-auto scrollbar-none">
        <div>
          <div className="mb-12 px-2 flex items-center justify-between">
            <div className="flex flex-col">
              <span className="font-black text-3xl tracking-tighter italic uppercase text-primary drop-shadow-[0_0_15px_rgba(var(--primary),0.3)]">Beacon</span>
              <span className="text-[8px] font-black uppercase tracking-[0.3em] opacity-40 -mt-1 pl-1">Tactical Engine</span>
            </div>
            <ModeToggle />
          </div>
          <div className="space-y-1">
            {navItems.map((item) => (
              <NavLink 
                key={item.to} 
                to={item.to} 
                className={({ isActive }) => cn(
                  "flex items-center gap-4 px-4 py-3 rounded-2xl text-[11px] font-black uppercase tracking-widest transition-all duration-500 group relative overflow-hidden",
                  isActive 
                    ? "bg-primary text-primary-foreground shadow-2xl shadow-primary/40 scale-105 italic z-10" 
                    : "hover:bg-primary/5 hover:backdrop-blur-md opacity-60 hover:opacity-100 border border-transparent hover:border-primary/10",
                  item.variant === "destructive" && !location.pathname.startsWith(item.to) && "text-destructive opacity-80",
                  item.color && !location.pathname.startsWith(item.to) && item.color
                )}
              >
                <item.icon className={cn("h-4 w-4 shrink-0 transition-transform duration-500 group-hover:scale-110", location.pathname === item.to && "rotate-3")} />
                <span>{item.label}</span>
                {location.pathname === item.to && (
                  <div className="absolute right-2 h-1.5 w-1.5 rounded-full bg-primary-foreground animate-pulse shadow-lg" />
                )}
              </NavLink>
            ))}
          </div>
        </div>
        <div className="pt-8 border-t border-primary/5">
          <div className="p-4 rounded-3xl bg-primary/5 border border-primary/10 text-[9px] font-black text-muted-foreground uppercase tracking-[0.2em] text-center italic shadow-inner space-y-2">
            <div>Engine v2.4.0 • Secured</div>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main id="beacon-main-content" tabIndex={-1} className="flex-1 relative z-0 md:px-12 px-6 pt-0 md:pt-10 overflow-x-hidden w-full">
        {/* Mobile Header */}
        <div className="md:hidden flex items-center justify-between mb-8 sticky top-0 z-40 bg-background/80 backdrop-blur-xl pt-[calc(env(safe-area-inset-top,0px)+1rem)] pb-4 -mx-6 px-6 border-b border-white/5">
          <div className="flex items-center gap-2">
            <span className="font-black text-2xl tracking-tighter italic uppercase text-primary">Beacon</span>
          </div>
          <button
            type="button"
            aria-label="Open navigation menu"
            onClick={() => setIsMobileMenuOpen(true)}
            className="p-3 bg-primary/10 rounded-2xl border border-primary/10 text-primary shadow-xl"
          >
            <Menu className="h-6 w-6" aria-hidden />
          </button>
        </div>
        {children}
      </main>

      {/* Mobile Full-Screen Overlay */}
      {isMobileMenuOpen && (
        <div className="md:hidden fixed inset-0 z-[100] bg-background/95 backdrop-blur-3xl px-6 pb-6 pt-[calc(env(safe-area-inset-top,0px)+1.5rem)] flex flex-col animate-in fade-in duration-500 overflow-y-auto">
          <div className="flex justify-between items-center mb-10">
            <span className="font-black text-3xl tracking-tighter italic uppercase text-primary">Mission Menu</span>
            <button type="button" aria-label="Close navigation menu" onClick={closeMenu} className="p-3 bg-destructive/10 rounded-2xl text-destructive border border-destructive/10">
              <X className="h-6 w-6" aria-hidden />
            </button>
          </div>
          <div className="flex flex-col space-y-3 pb-20">
            {navItems.map((item) => (
              <NavLink 
                key={item.to} 
                to={item.to} 
                onClick={closeMenu}
                className={({ isActive }) => cn(
                  "p-5 rounded-[2rem] border-2 transition-all duration-300 flex items-center gap-5 uppercase font-black italic tracking-widest text-xs shadow-2xl",
                  isActive 
                    ? "bg-primary text-primary-foreground border-primary shadow-primary/30" 
                    : "bg-card/40 border-white/5 text-foreground opacity-70"
                )}
              >
                <item.icon className="h-6 w-6" />
                {item.label}
              </NavLink>
            ))}
          </div>
        </div>
      )}

      {/* Mobile Bottom Navigation (Quick Tactics) */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 z-50 border-t border-white/10 bg-card/60 backdrop-blur-3xl px-6 pt-3 pb-[calc(env(safe-area-inset-bottom,0px)+1rem)] shadow-[0_-10px_40px_rgba(0,0,0,0.2)]">
        <div className="flex justify-between items-center max-w-md mx-auto">
          <NavLink to="/" className={({ isActive }) => cn("flex flex-col items-center p-3 rounded-2xl transition-all duration-500", isActive ? "text-primary scale-110 bg-primary/5" : "text-muted-foreground")}>
            <LayoutDashboard className="h-6 w-6" />
            <span className="text-[9px] mt-1 font-black uppercase tracking-tighter italic">Cockpit</span>
          </NavLink>
          <NavLink to="/ledger" className={({ isActive }) => cn("flex flex-col items-center p-3 rounded-2xl transition-all duration-500", isActive ? "text-primary scale-110 bg-primary/5" : "text-muted-foreground")}>
            <ReceiptText className="h-6 w-6" />
            <span className="text-[9px] mt-1 font-black uppercase tracking-tighter italic">Loops</span>
          </NavLink>
          <NavLink to="/mission-control" className={({ isActive }) => cn("flex flex-col items-center p-3 rounded-2xl transition-all duration-500", isActive ? "text-primary scale-110 bg-primary/5" : "text-muted-foreground")}>
            <Compass className="h-6 w-6" />
            <span className="text-[9px] mt-1 font-black uppercase tracking-tighter italic">Mission</span>
          </NavLink>
          <button
            type="button"
            aria-label="Open full navigation menu"
            onClick={() => setIsMobileMenuOpen(true)}
            className="flex flex-col items-center p-3 text-muted-foreground"
          >
            <Menu className="h-6 w-6" aria-hidden />
            <span className="text-[9px] mt-1 font-black uppercase tracking-tighter italic">Terminal</span>
          </button>
        </div>
      </div>
      <BeaconChatbot />
    </div>
  );
};

function App() {
  const households = useLiveQuery(() => db.households.toArray(), []);
  const showOnboarding = households !== undefined && households.length === 0;

  const wrap = (scope: string, node: ReactNode) => (
    <ErrorBoundary scope={scope}>
      <Suspense
        fallback={
          <div className="space-y-4 p-4 sm:p-6" role="status" aria-label={`Loading ${scope}`}>
            <CardSkeleton rows={2} />
            <div className="grid gap-4 sm:grid-cols-2">
              <CardSkeleton rows={3} />
              <CardSkeleton rows={3} />
            </div>
          </div>
        }
      >
        {node}
      </Suspense>
    </ErrorBoundary>
  );

  React.useEffect(() => {
    async function init() {
      const { restoreSessionPromptIfNeeded, autoProvision, getSession } = await import("./modules/auth/authService");
      const { syncService } = await import("./modules/sync/syncService");
      
      let account = await restoreSessionPromptIfNeeded();
      
      // If we bypassed onboarding or don't have an account, generate one now if there are households
      if (!account && !showOnboarding) {
        account = await autoProvision();
      }

      if (account) {
        const session = getSession();
        if (session.currentHouseholdKey && households?.[0]?.id) {
          await syncService.bootstrap(households[0].id, session.currentHouseholdKey);
        }
      }
    }
    init();
  }, [showOnboarding, households]);


  // Show onboarding wizard if no household exists
  if (showOnboarding) {
    return (
      <ThemeProvider defaultTheme="glass" storageKey="budget-beacon-theme">
        <StatusBarController />
        <ToastProvider>
          <OnboardingWizard onComplete={() => {}} />
        </ToastProvider>
      </ThemeProvider>
    );
  }

  return (
    <ErrorBoundary scope="root">
      <ThemeProvider defaultTheme="glass" storageKey="budget-beacon-theme">
        <StatusBarController />
        <ToastProvider>

        <DexieErrorToastBridge />
        <HashRouter>
          <DeleteConfirmProvider>
          <a
            href="#beacon-main-content"
            className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[400] focus:rounded-md focus:bg-primary focus:px-4 focus:py-2 focus:text-primary-foreground focus:shadow-lg focus:outline-none focus:ring-2 focus:ring-ring"
          >
            Skip to main content
          </a>
          <AppShell>
            <Routes>
              <Route path="/" element={wrap("Dashboard", <DashboardRoute />)} />
              <Route path="/mission-control" element={wrap("Mission Control", <BudgetMissionControlRoute />)} />
              <Route path="/ledger" element={wrap("Ledger", <LedgerRoute />)} />
              <Route path="/income" element={wrap("Income", <IncomeRoute />)} />
              <Route path="/pay-path" element={wrap("Pay Path", <PayPathRoute />)} />
              <Route path="/stash-map" element={wrap("Stash Map", <StashMapRoute />)} />
              <Route path="/debt-center" element={wrap("Debt Center", <DebtCenterRoute />)} />
              <Route path="/tax-taxi" element={wrap("Tax Taxi", <TaxTaxiRoute />)} />
              <Route path="/documents" element={wrap("Vault", <DocumentStoreRoute />)} />
              <Route path="/subscriptions" element={wrap("Subscriptions", <SubscriptionsShelfRoute />)} />
              <Route path="/insurance" element={wrap("Insurance", <InsuranceInspectRoute />)} />
              <Route path="/bridge" element={wrap("Beacon Bridge", <BeaconBridgeRoute />)} />
              <Route path="/credit" element={wrap("Credit", <CreditRoute />)} />
              <Route path="/reports" element={wrap("Reports", <ReportsRoute />)} />
              <Route path="/settings" element={wrap("Settings", <SettingsRoute />)} />
            </Routes>
          </AppShell>
          </DeleteConfirmProvider>
        </HashRouter>
        </ToastProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}

export default App;
