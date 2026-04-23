import React, { useEffect, useState } from "react";
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
import { LayoutDashboard, ReceiptText, CreditCard, PiggyBank, Menu, X } from "lucide-react";

const AppShell = ({ children }: { children: React.ReactNode }) => {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const closeMenu = () => setIsMobileMenuOpen(false);

  return (
    <div className="flex min-h-[100dvh] w-full bg-transparent text-foreground transition-colors duration-500 md:pb-0" style={{ paddingBottom: 'calc(env(safe-area-inset-bottom, 0px) + 4rem)' }}>
      {/* Desktop Sidebar */}
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

      {/* Mobile Full-Screen Hamburger Menu Overlay */}
      {isMobileMenuOpen && (
        <div className="md:hidden fixed inset-0 z-[100] bg-background/95 backdrop-blur-3xl p-6 flex flex-col">
          <div className="flex justify-between items-center mb-8">
            <span className="font-bold text-2xl">Menu</span>
            <button onClick={closeMenu} className="p-2 bg-secondary/50 rounded-full text-foreground hover:bg-secondary transition-colors">
              <X className="h-6 w-6" />
            </button>
          </div>
          <div className="flex flex-col space-y-4 text-lg font-medium">
            <NavLink to="/" onClick={closeMenu} className={({ isActive }) => `p-4 rounded-xl border ${isActive ? 'bg-primary text-primary-foreground border-primary' : 'bg-card/50 border-white/10'}`}>Dashboard</NavLink>
            <NavLink to="/ledger" onClick={closeMenu} className={({ isActive }) => `p-4 rounded-xl border ${isActive ? 'bg-primary text-primary-foreground border-primary' : 'bg-card/50 border-white/10'}`}>Ledger</NavLink>
            <NavLink to="/income" onClick={closeMenu} className={({ isActive }) => `p-4 rounded-xl border ${isActive ? 'bg-primary text-primary-foreground border-primary' : 'bg-card/50 border-white/10'}`}>Income</NavLink>
            <NavLink to="/pay-path" onClick={closeMenu} className={({ isActive }) => `p-4 rounded-xl border ${isActive ? 'bg-primary text-primary-foreground border-primary' : 'bg-card/50 border-white/10'}`}>Pay Path (Bills)</NavLink>
            <NavLink to="/stash-map" onClick={closeMenu} className={({ isActive }) => `p-4 rounded-xl border ${isActive ? 'bg-primary text-primary-foreground border-primary' : 'bg-card/50 border-white/10'}`}>Stash Map (Savings)</NavLink>
            <NavLink to="/credit" onClick={closeMenu} className={({ isActive }) => `p-4 rounded-xl border ${isActive ? 'bg-primary text-primary-foreground border-primary' : 'bg-card/50 border-white/10'}`}>Credit Snapshot</NavLink>
            <NavLink to="/reports" onClick={closeMenu} className={({ isActive }) => `p-4 rounded-xl border ${isActive ? 'bg-primary text-primary-foreground border-primary' : 'bg-card/50 border-white/10'}`}>Reports</NavLink>
            <NavLink to="/settings" onClick={closeMenu} className={({ isActive }) => `p-4 rounded-xl border ${isActive ? 'bg-primary text-primary-foreground border-primary' : 'bg-card/50 border-white/10'}`}>Settings</NavLink>
          </div>
        </div>
      )}

      {/* Mobile Bottom Navigation */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 z-50 border-t border-white/10 dark:border-white/5 bg-card/80 dark:bg-card/60 backdrop-blur-3xl shadow-[0_-10px_30px_rgba(0,0,0,0.1)]" style={{ paddingBottom: 'env(safe-area-inset-bottom, 16px)' }}>
        <div className="flex items-center justify-around px-2 py-2">
          <NavLink to="/" className={({ isActive }) => `flex flex-col items-center p-2 rounded-lg transition-all duration-300 ${isActive ? 'text-primary' : 'text-muted-foreground hover:text-primary'}`}>
            <LayoutDashboard className="h-6 w-6" />
            <span className="text-[10px] mt-1 font-bold">Dash</span>
          </NavLink>
          <NavLink to="/ledger" className={({ isActive }) => `flex flex-col items-center p-2 rounded-lg transition-all duration-300 ${isActive ? 'text-primary' : 'text-muted-foreground hover:text-primary'}`}>
            <ReceiptText className="h-6 w-6" />
            <span className="text-[10px] mt-1 font-bold">Ledger</span>
          </NavLink>
          <NavLink to="/pay-path" className={({ isActive }) => `flex flex-col items-center p-2 rounded-lg transition-all duration-300 ${isActive ? 'text-primary' : 'text-muted-foreground hover:text-primary'}`}>
            <CreditCard className="h-6 w-6" />
            <span className="text-[10px] mt-1 font-bold">Bills</span>
          </NavLink>
          <NavLink to="/stash-map" className={({ isActive }) => `flex flex-col items-center p-2 rounded-lg transition-all duration-300 ${isActive ? 'text-primary' : 'text-muted-foreground hover:text-primary'}`}>
            <PiggyBank className="h-6 w-6" />
            <span className="text-[10px] mt-1 font-bold">Savings</span>
          </NavLink>
          <button onClick={() => setIsMobileMenuOpen(true)} className="flex flex-col items-center p-2 rounded-lg transition-all duration-300 text-muted-foreground hover:text-primary">
            <Menu className="h-6 w-6" />
            <span className="text-[10px] mt-1 font-bold">Menu</span>
          </button>
        </div>
      </div>

      <main className="flex-1 p-4 md:p-6 overflow-y-auto">
        {/* Mobile Header */}
        <div className="md:hidden flex justify-between items-center mb-6 pt-2">
          <span className="font-bold text-2xl tracking-tight text-primary">Beacon</span>
          <div className="flex items-center gap-3">
            <ModeToggle />
            <button onClick={() => setIsMobileMenuOpen(true)} className="p-2 bg-secondary/30 rounded-full text-foreground hover:bg-secondary transition-colors">
              <Menu className="h-5 w-5" />
            </button>
          </div>
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
