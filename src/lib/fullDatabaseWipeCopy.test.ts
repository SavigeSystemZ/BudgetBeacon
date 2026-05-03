import { describe, expect, it } from "vitest";
import {
  CANNOT_UNDONE_SHORT,
  DEMO_RESET_DESCRIPTION,
  DEMO_RESET_MODAL_TITLE,
  FULL_WIPE_EXPORT_HINT,
  FULL_WIPE_MODAL_TITLE,
  FULL_WIPE_SCOPE_DESCRIPTION,
} from "./fullDatabaseWipeCopy";

describe("fullDatabaseWipeCopy", () => {
  it("defines non-empty gated destructive copy aligned with IndexedDB wipe scope hints", () => {
    expect(FULL_WIPE_MODAL_TITLE.trim().length).toBeGreaterThan(8);
    expect(FULL_WIPE_SCOPE_DESCRIPTION.toLowerCase()).toContain("dexie");
    expect(FULL_WIPE_SCOPE_DESCRIPTION.toLowerCase()).toContain("household");
    expect(FULL_WIPE_EXPORT_HINT.length).toBeGreaterThan(20);
    expect(CANNOT_UNDONE_SHORT.length).toBeGreaterThan(5);
    expect(DEMO_RESET_MODAL_TITLE.trim().length).toBeGreaterThan(8);
    expect(DEMO_RESET_DESCRIPTION.toLowerCase()).toContain("demo");
    expect(DEMO_RESET_DESCRIPTION.toLowerCase()).toContain("wipe");
  });
});
