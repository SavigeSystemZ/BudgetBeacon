/**
 * Minimal RFC 4180 CSV parser.
 *
 * Handles:
 *   - quoted fields containing commas, embedded quotes ("" -> "), and newlines
 *   - LF and CRLF line endings
 *   - optional header row
 *
 * Trade-off: assumes UTF-8 input (the file picker returns text via `file.text()`).
 * Does NOT support custom delimiters, comments, or BOM stripping yet — bank CSVs
 * occasionally include a BOM, so we strip a leading `﻿` defensively.
 */

export interface ParsedCsv {
  headers: string[];
  rows: Record<string, string>[];
}

export function parseCsv(input: string): ParsedCsv {
  const text = input.charCodeAt(0) === 0xfeff ? input.slice(1) : input;
  const cells = parseCells(text);
  if (cells.length === 0) return { headers: [], rows: [] };

  const headers = cells[0].map((h) => h.trim());
  const rows: Record<string, string>[] = [];
  for (let i = 1; i < cells.length; i++) {
    const row = cells[i];
    // Skip empty trailing lines.
    if (row.length === 1 && row[0] === "") continue;
    const obj: Record<string, string> = {};
    for (let j = 0; j < headers.length; j++) {
      obj[headers[j]] = (row[j] ?? "").trim();
    }
    rows.push(obj);
  }
  return { headers, rows };
}

function parseCells(text: string): string[][] {
  const out: string[][] = [];
  let row: string[] = [];
  let field = "";
  let inQuotes = false;
  let i = 0;
  const len = text.length;

  while (i < len) {
    const ch = text[i];

    if (inQuotes) {
      if (ch === '"') {
        if (i + 1 < len && text[i + 1] === '"') {
          field += '"';
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field += ch;
      i++;
      continue;
    }

    if (ch === '"') {
      inQuotes = true;
      i++;
      continue;
    }
    if (ch === ",") {
      row.push(field);
      field = "";
      i++;
      continue;
    }
    if (ch === "\r") {
      // Handle CRLF or lone CR.
      row.push(field);
      out.push(row);
      row = [];
      field = "";
      i++;
      if (i < len && text[i] === "\n") i++;
      continue;
    }
    if (ch === "\n") {
      row.push(field);
      out.push(row);
      row = [];
      field = "";
      i++;
      continue;
    }

    field += ch;
    i++;
  }

  // Flush the final field/row if no trailing newline.
  if (field !== "" || row.length > 0) {
    row.push(field);
    out.push(row);
  }
  return out;
}
