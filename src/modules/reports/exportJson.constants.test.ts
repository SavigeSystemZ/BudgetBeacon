import { describe, it, expect } from "vitest";
import {
  BACKUP_FORMAT_VERSION,
  BACKUP_FORMAT_VERSION_LABEL,
  BACKUP_FORMAT_HELP_TEXT,
} from "./exportJson";

describe("backup format UX constants", () => {
  it("keeps version label aligned with numeric version", () => {
    expect(BACKUP_FORMAT_VERSION_LABEL).toBe(`v${BACKUP_FORMAT_VERSION}`);
  });

  it("surfaces version in operator help text so UI stays truthful", () => {
    expect(BACKUP_FORMAT_HELP_TEXT).toContain(BACKUP_FORMAT_VERSION_LABEL);
    expect(BACKUP_FORMAT_HELP_TEXT.toLowerCase()).toContain("v1–v3");
  });
});
