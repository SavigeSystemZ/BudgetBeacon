/**
 * Minimal CSV writer (RFC 4180 subset).
 *
 * Avoids a dependency for what is essentially three lines of escape logic.
 * Used by `src/modules/reports/exportCsv.ts` to produce per-entity CSV files
 * suitable for opening in Excel / Numbers / Google Sheets.
 */

export type CsvCell = string | number | boolean | null | undefined;

export function escapeCsvCell(value: CsvCell): string {
  if (value === null || value === undefined) return "";
  const str = String(value);
  // Quote if the cell contains comma, double-quote, CR, or LF.
  if (/[",\r\n]/.test(str)) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

export function rowsToCsv(headers: string[], rows: CsvCell[][]): string {
  const lines: string[] = [];
  lines.push(headers.map(escapeCsvCell).join(","));
  for (const row of rows) {
    lines.push(row.map(escapeCsvCell).join(","));
  }
  // Trailing newline so editors don't complain about missing final newline.
  return lines.join("\r\n") + "\r\n";
}

/**
 * Triggers a browser download of `content` as `filename`. Wraps the
 * blob/URL/anchor pattern used by the JSON exporter.
 */
export function downloadTextFile(filename: string, content: string, mimeType = "text/csv;charset=utf-8"): void {
  const blob = new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
