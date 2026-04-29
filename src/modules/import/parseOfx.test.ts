import { describe, it, expect } from "vitest";
import { parseOfx, parseOfxDate, stripHeader, tagValue, extractBlocks } from "./parseOfx";

const SAMPLE_OFX_1X = `OFXHEADER:100
DATA:OFXSGML
VERSION:102
SECURITY:NONE
ENCODING:USASCII
CHARSET:1252
COMPRESSION:NONE
OLDFILEUID:NONE
NEWFILEUID:NONE

<OFX>
<BANKMSGSRSV1>
<STMTTRNRS>
<TRNUID>1
<STATUS><CODE>0<SEVERITY>INFO</STATUS>
<STMTRS>
<CURDEF>USD
<BANKACCTFROM>
<BANKID>123456789
<ACCTID>987654321
<ACCTTYPE>CHECKING
</BANKACCTFROM>
<BANKTRANLIST>
<DTSTART>20260301
<DTEND>20260331
<STMTTRN>
<TRNTYPE>DEBIT
<DTPOSTED>20260315120000
<TRNAMT>-42.99
<FITID>1001
<NAME>Amazon.com
<MEMO>Order #123
</STMTTRN>
<STMTTRN>
<TRNTYPE>CREDIT
<DTPOSTED>20260301
<TRNAMT>1450.00
<FITID>1002
<NAME>SSDI Deposit
</STMTTRN>
</BANKTRANLIST>
</STMTRS>
</STMTTRNRS>
</BANKMSGSRSV1>
</OFX>
`;

const SAMPLE_QFX_CC = `OFXHEADER:100
DATA:OFXSGML
VERSION:102

<OFX>
<CREDITCARDMSGSRSV1>
<CCSTMTTRNRS>
<CCSTMTRS>
<CURDEF>USD
<CCACCTFROM>
<ACCTID>4111111111111111
</CCACCTFROM>
<BANKTRANLIST>
<CCSTMTTRN>
<TRNTYPE>DEBIT
<DTPOSTED>20260205
<TRNAMT>-25.00
<FITID>cc-1
<NAME>Starbucks
</CCSTMTTRN>
</BANKTRANLIST>
</CCSTMTRS>
</CCSTMTTRNRS>
</CREDITCARDMSGSRSV1>
</OFX>
`;

describe("M5 carry-over — OFX/QFX parser", () => {
  describe("parseOfxDate", () => {
    it("parses YYYYMMDD", () => {
      expect(parseOfxDate("20260315")).toBe("2026-03-15");
    });
    it("parses YYYYMMDDHHMMSS", () => {
      expect(parseOfxDate("20260315120000")).toBe("2026-03-15");
    });
    it("rejects nonsense", () => {
      expect(parseOfxDate("not-a-date")).toBeNull();
    });
    it("rejects out-of-range months", () => {
      expect(parseOfxDate("20261315")).toBeNull();
    });
  });

  describe("stripHeader", () => {
    it("removes OFX 1.x header", () => {
      const body = stripHeader(SAMPLE_OFX_1X);
      expect(body.startsWith("<OFX>")).toBe(true);
    });
  });

  describe("tagValue", () => {
    it("reads a top-level tag", () => {
      const body = stripHeader(SAMPLE_OFX_1X);
      expect(tagValue(body, "CURDEF")).toBe("USD");
    });
    it("walks nested path", () => {
      const body = stripHeader(SAMPLE_OFX_1X);
      expect(tagValue(body, "BANKACCTFROM/ACCTID")).toBe("987654321");
    });
  });

  describe("extractBlocks", () => {
    it("returns one inner block per STMTTRN", () => {
      const body = stripHeader(SAMPLE_OFX_1X);
      expect(extractBlocks(body, "STMTTRN")).toHaveLength(2);
    });
  });

  describe("parseOfx full bank file", () => {
    it("returns two drafts with correct sign convention", () => {
      const r = parseOfx(SAMPLE_OFX_1X);
      expect(r.drafts).toHaveLength(2);
      expect(r.skipped).toHaveLength(0);

      const expense = r.drafts.find((d) => d.payee === "Amazon.com")!;
      const income = r.drafts.find((d) => d.payee === "SSDI Deposit")!;

      expect(expense.type).toBe("expense");
      expect(expense.amount).toBe(42.99);
      expect(expense.date).toBe("2026-03-15");

      expect(income.type).toBe("income");
      expect(income.amount).toBe(1450);
      expect(income.date).toBe("2026-03-01");
    });

    it("captures account metadata", () => {
      const r = parseOfx(SAMPLE_OFX_1X);
      expect(r.meta.currency).toBe("USD");
      expect(r.meta.accountId).toBe("987654321");
      expect(r.meta.accountType).toBe("CHECKING");
    });

    it("dedupeKey is set on every draft", () => {
      const r = parseOfx(SAMPLE_OFX_1X);
      for (const d of r.drafts) expect(d.dedupeKey).toBeTruthy();
    });
  });

  describe("parseOfx credit-card file", () => {
    it("parses CCSTMTTRN blocks just like STMTTRN", () => {
      const r = parseOfx(SAMPLE_QFX_CC);
      expect(r.drafts).toHaveLength(1);
      expect(r.drafts[0].payee).toBe("Starbucks");
      expect(r.drafts[0].type).toBe("expense");
      expect(r.drafts[0].amount).toBe(25);
    });
  });

  describe("parseOfx skipping", () => {
    it("skips blocks missing DTPOSTED", () => {
      const broken = `<OFX><STMTTRN><TRNAMT>-1.00<NAME>X</STMTTRN></OFX>`;
      const r = parseOfx(broken);
      expect(r.drafts).toHaveLength(0);
      expect(r.skipped[0].reason).toMatch(/DTPOSTED/);
    });

    it("skips blocks missing TRNAMT", () => {
      const broken = `<OFX><STMTTRN><DTPOSTED>20260315<NAME>X</STMTTRN></OFX>`;
      const r = parseOfx(broken);
      expect(r.drafts).toHaveLength(0);
      expect(r.skipped[0].reason).toMatch(/TRNAMT/);
    });
  });

  describe("entity decoding", () => {
    it("decodes & in payee names", () => {
      const xml = `<OFX><STMTTRN><DTPOSTED>20260315<TRNAMT>-1.00<NAME>Joe &amp; Co</STMTTRN></OFX>`;
      const r = parseOfx(xml);
      expect(r.drafts[0].payee).toBe("Joe & Co");
    });
  });
});
