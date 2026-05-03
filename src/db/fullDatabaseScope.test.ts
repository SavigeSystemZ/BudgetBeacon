import { describe, it, expect } from "vitest";
import { fullDatabaseRwScope } from "./fullDatabaseScope";

describe("fullDatabaseRwScope", () => {
  it("enumerates every Dexie v5 store once (aligned with backup restore wipe)", () => {
    expect(fullDatabaseRwScope()).toHaveLength(19);
  });
});
