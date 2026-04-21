import React, { useEffect } from "react";
import { BrowserRouter, Routes, Route, NavLink } from "react-router-dom";
import "./index.css";
import DashboardRoute from "./routes/DashboardRoute";
import IncomeRoute from "./routes/IncomeRoute";
import PayPathRoute from "./routes/PayPathRoute";
import StashMapRoute from "./routes/StashMapRoute";
import CreditRoute from "./routes/CreditRoute";
import ReportsRoute from "./routes/ReportsRoute";
import SettingsRoute from "./routes/SettingsRoute";
import { seedDemoData } from "./db/seedDemoData";
import { ThemeProvider } from "./components/theme-provider";
import { ModeToggle } from "./components/mode-toggle";

const AppShell = ({ children }: { children: React.ReactNode }) => (
  <div className="flex min-h-screen w-full bg-background text-foreground transition-colors duration-300">
    <nav className="w-64 border-r bg-card p-4 space-y-2 flex flex-col justify-between hidden md:flex shrink-0">
      <div>
        <div className="mb-8 px-2 font-semibold text-lg tracking-tight flex items-center justify-between">
          <span>Budget Beacon</span>
          <ModeToggle />
        </div>
        <div className="space-y-1">
          <NavLink to="/" className={({ isActive }) => `block px-2 py-1.5 rounded-md text-sm ${isActive ? 'bg-primary text-primary-foreground' : 'hover:bg-muted'}`}>Dashboard</NavLink>
          <NavLink to="/income" className={({ isActive }) => `block px-2 py-1.5 rounded-md text-sm ${isActive ? 'bg-primary text-primary-foreground' : 'hover:bg-muted'}`}>Income</NavLink>
          <NavLink to="/pay-path" className={({ isActive }) => `block px-2 py-1.5 rounded-md text-sm ${isActive ? 'bg-primary text-primary-foreground' : 'hover:bg-muted'}`}>Pay Path</NavLink>
          <NavLink to="/stash-map" className={({ isActive }) => `block px-2 py-1.5 rounded-md text-sm ${isActive ? 'bg-primary text-primary-foreground' : 'hover:bg-muted'}`}>Stash Map</NavLink>
          <NavLink to="/credit" className={({ isActive }) => `block px-2 py-1.5 rounded-md text-sm ${isActive ? 'bg-primary text-primary-foreground' : 'hover:bg-muted'}`}>Credit Snapshot</NavLink>
          <NavLink to="/reports" className={({ isActive }) => `block px-2 py-1.5 rounded-md text-sm ${isActive ? 'bg-primary text-primary-foreground' : 'hover:bg-muted'}`}>Reports</NavLink>
          <NavLink to="/settings" className={({ isActive }) => `block px-2 py-1.5 rounded-md text-sm ${isActive ? 'bg-primary text-primary-foreground' : 'hover:bg-muted'}`}>Settings</NavLink>
        </div>
      </div>
    </nav>
    <main className="flex-1 p-6 overflow-y-auto">
      <div className="md:hidden flex justify-between items-center mb-6">
        <span className="font-semibold text-lg">Budget Beacon</span>
        <ModeToggle />
      </div>
      {children}
    </main>
  </div>
);

function App() {
  useEffect(() => {
    seedDemoData().catch(console.error);
  }, []);

  return (
    <ThemeProvider defaultTheme="system" storageKey="budget-beacon-theme">
      <BrowserRouter>
        <AppShell>
          <Routes>
            <Route path="/" element={<DashboardRoute />} />
            <Route path="/income" element={<IncomeRoute />} />
            <Route path="/pay-path" element={<PayPathRoute />} />
            <Route path="/stash-map" element={<StashMapRoute />} />
            <Route path="/credit" element={<CreditRoute />} />
            <Route path="/reports" element={<ReportsRoute />} />
            <Route path="/settings" element={<SettingsRoute />} />
          </Routes>
        </AppShell>
      </BrowserRouter>
    </ThemeProvider>
  );
}

export default App;
