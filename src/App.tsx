import React, { useEffect } from "react";
import { HashRouter, Routes, Route, NavLink } from "react-router-dom";
import "./index.css";
import DashboardRoute from "./routes/DashboardRoute";
import IncomeRoute from "./routes/IncomeRoute";
import PayPathRoute from "./routes/PayPathRoute";
import LedgerRoute from "./routes/LedgerRoute";
import StashMapRoute from "./routes/StashMapRoute";
import CreditRoute from "./routes/CreditRoute";
import ReportsRoute from "./routes/ReportsRoute";
import SettingsRoute from "./routes/SettingsRoute";
import { seedDemoData } from "./db/seedDemoData";
import { ThemeProvider } from "./components/theme-provider";
import { ModeToggle } from "./components/mode-toggle";
import { LayoutDashboard, ReceiptText, Wallet, CreditCard, PiggyBank, Settings } from "lucide-react";

const AppShell = ({ children }: { children: React.ReactNode }) => {
  return (
    <div className="flex min-h-[100dvh] w-full bg-transparent text-foreground transition-colors duration-500 pb-[calc(4rem+env(safe-area-inset-bottom))] md:pb-0">
      <nav className="w-64 border-r border-white/10 dark:border-white/5 bg-card/40 dark:bg-card/20 backdrop-blur-2xl p-4 space-y-2 flex-col justify-between hidden md:flex shrink-0 shadow-2xl relative z-10">
        <div>
          <div className="mb-8 px-2 font-semibold text-lg tracking-tight flex items-center justify-between">
            <span>Budget Beacon</span>
            <ModeToggle />
          </div>
          <div className="space-y-1">
            <NavLink to="/" className={({ isActive }) => `block px-3 py-2 rounded-lg text-sm font-medium transition-all duration-300 ${isActive ? 'bg-primary/10 dark:bg-primary/20 border border-primary/20 text-foreground shadow-[0_0_15px_rgba(0,0,0,0.1)] dark:shadow-[0_0_15px_rgba(255,255,255,0.1)]' : 'border border-transparent hover:bg-muted/50 hover:backdrop-blur-md'}`}>Dashboard</NavLink>
            <NavLink to="/ledger" className={({ isActive }) => `block px-3 py-2 rounded-lg text-sm font-medium transition-all duration-300 ${isActive ? 'bg-primary/10 dark:bg-primary/20 border border-primary/20 text-foreground shadow-[0_0_15px_rgba(0,0,0,0.1)] dark:shadow-[0_0_15px_rgba(255,255,255,0.1)]' : 'border border-transparent hover:bg-muted/50 hover:backdrop-blur-md'}`}>Ledger</NavLink>
            <NavLink to="/income" className={({ isActive }) => `block px-3 py-2 rounded-lg text-sm font-medium transition-all duration-300 ${isActive ? 'bg-primary/10 dark:bg-primary/20 border border-primary/20 text-foreground shadow-[0_0_15px_rgba(0,0,0,0.1)] dark:shadow-[0_0_15px_rgba(255,255,255,0.1)]' : 'border border-transparent hover:bg-muted/50 hover:backdrop-blur-md'}`}>Income</NavLink>
            <NavLink to="/pay-path" className={({ isActive }) => `block px-3 py-2 rounded-lg text-sm font-medium transition-all duration-300 ${isActive ? 'bg-primary/10 dark:bg-primary/20 border border-primary/20 text-foreground shadow-[0_0_15px_rgba(0,0,0,0.1)] dark:shadow-[0_0_15px_rgba(255,255,255,0.1)]' : 'border border-transparent hover:bg-muted/50 hover:backdrop-blur-md'}`}>Pay Path</NavLink>
            <NavLink to="/stash-map" className={({ isActive }) => `block px-3 py-2 rounded-lg text-sm font-medium transition-all duration-300 ${isActive ? 'bg-primary/10 dark:bg-primary/20 border border-primary/20 text-foreground shadow-[0_0_15px_rgba(0,0,0,0.1)] dark:shadow-[0_0_15px_rgba(255,255,255,0.1)]' : 'border border-transparent hover:bg-muted/50 hover:backdrop-blur-md'}`}>Stash Map</NavLink>
            <NavLink to="/credit" className={({ isActive }) => `block px-3 py-2 rounded-lg text-sm font-medium transition-all duration-300 ${isActive ? 'bg-primary/10 dark:bg-primary/20 border border-primary/20 text-foreground shadow-[0_0_15px_rgba(0,0,0,0.1)] dark:shadow-[0_0_15px_rgba(255,255,255,0.1)]' : 'border border-transparent hover:bg-muted/50 hover:backdrop-blur-md'}`}>Credit Snapshot</NavLink>
            <NavLink to="/reports" className={({ isActive }) => `block px-3 py-2 rounded-lg text-sm font-medium transition-all duration-300 ${isActive ? 'bg-primary/10 dark:bg-primary/20 border border-primary/20 text-foreground shadow-[0_0_15px_rgba(0,0,0,0.1)] dark:shadow-[0_0_15px_rgba(255,255,255,0.1)]' : 'border border-transparent hover:bg-muted/50 hover:backdrop-blur-md'}`}>Reports</NavLink>
            <NavLink to="/settings" className={({ isActive }) => `block px-3 py-2 rounded-lg text-sm font-medium transition-all duration-300 ${isActive ? 'bg-primary/10 dark:bg-primary/20 border border-primary/20 text-foreground shadow-[0_0_15px_rgba(0,0,0,0.1)] dark:shadow-[0_0_15px_rgba(255,255,255,0.1)]' : 'border border-transparent hover:bg-muted/50 hover:backdrop-blur-md'}`}>Settings</NavLink>
          </div>
        </div>
      </nav>

      {/* Mobile Bottom Navigation */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 z-50 border-t border-white/10 dark:border-white/5 bg-card/60 dark:bg-card/40 backdrop-blur-2xl pb-[env(safe-area-inset-bottom)]">
        <div className="flex items-center justify-around px-2 py-2">
          <NavLink to="/" className={({ isActive }) => `flex flex-col items-center p-2 rounded-lg transition-all duration-300 ${isActive ? 'text-primary' : 'text-muted-foreground hover:text-primary'}`}>
            <LayoutDashboard className="h-5 w-5" />
            <span className="text-[10px] mt-1 font-medium">Dash</span>
          </NavLink>
          <NavLink to="/ledger" className={({ isActive }) => `flex flex-col items-center p-2 rounded-lg transition-all duration-300 ${isActive ? 'text-primary' : 'text-muted-foreground hover:text-primary'}`}>
            <ReceiptText className="h-5 w-5" />
            <span className="text-[10px] mt-1 font-medium">Ledger</span>
          </NavLink>
          <NavLink to="/income" className={({ isActive }) => `flex flex-col items-center p-2 rounded-lg transition-all duration-300 ${isActive ? 'text-primary' : 'text-muted-foreground hover:text-primary'}`}>
            <Wallet className="h-5 w-5" />
            <span className="text-[10px] mt-1 font-medium">Income</span>
          </NavLink>
          <NavLink to="/pay-path" className={({ isActive }) => `flex flex-col items-center p-2 rounded-lg transition-all duration-300 ${isActive ? 'text-primary' : 'text-muted-foreground hover:text-primary'}`}>
            <CreditCard className="h-5 w-5" />
            <span className="text-[10px] mt-1 font-medium">Bills</span>
          </NavLink>
          <NavLink to="/stash-map" className={({ isActive }) => `flex flex-col items-center p-2 rounded-lg transition-all duration-300 ${isActive ? 'text-primary' : 'text-muted-foreground hover:text-primary'}`}>
            <PiggyBank className="h-5 w-5" />
            <span className="text-[10px] mt-1 font-medium">Savings</span>
          </NavLink>
          <NavLink to="/settings" className={({ isActive }) => `flex flex-col items-center p-2 rounded-lg transition-all duration-300 ${isActive ? 'text-primary' : 'text-muted-foreground hover:text-primary'}`}>
            <Settings className="h-5 w-5" />
            <span className="text-[10px] mt-1 font-medium">More</span>
          </NavLink>
        </div>
      </div>

      <main className="flex-1 p-4 md:p-6 overflow-y-auto">
        <div className="md:hidden flex justify-between items-center mb-6 pt-2">
          <span className="font-semibold text-xl tracking-tight">Budget Beacon</span>
          <ModeToggle />
        </div>
        {children}
      </main>
    </div>
  );
};

function App() {
  useEffect(() => {
    seedDemoData().catch(console.error);
  }, []);

  return (
    <ThemeProvider defaultTheme="system" storageKey="budget-beacon-theme">
      <HashRouter>
        <AppShell>
          <Routes>
            <Route path="/" element={<DashboardRoute />} />
            <Route path="/ledger" element={<LedgerRoute />} />
            <Route path="/income" element={<IncomeRoute />} />
            <Route path="/pay-path" element={<PayPathRoute />} />
            <Route path="/stash-map" element={<StashMapRoute />} />
            <Route path="/credit" element={<CreditRoute />} />
            <Route path="/reports" element={<ReportsRoute />} />
            <Route path="/settings" element={<SettingsRoute />} />
          </Routes>
        </AppShell>
      </HashRouter>
    </ThemeProvider>
  );
}

export default App;
