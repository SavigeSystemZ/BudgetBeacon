import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.aiaast.budgetbeacon',
  appName: 'BudgetBeacon',
  webDir: 'dist',
  plugins: {
    StatusBar: {
      overlaysWebView: true,
    }
  }
};

export default config;
