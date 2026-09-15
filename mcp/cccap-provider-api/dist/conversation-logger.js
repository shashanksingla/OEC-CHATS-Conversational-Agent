import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
// _______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________
const SALESFORCE_ID_PATTERN = /[a-zA-Z0-9]{15,18}/g;
// Resolved relative to THIS module's own file location (mcp/cccap-provider-api/
// src or dist -> ../.logs), never the process's current working directory.
// The real MCP server is launched by .vscode/mcp.json with an explicit
// `cwd` override (CHATS_SIT/), so a bare relative ".logs" default silently
// resolved against that cwd and wrote every real conversation log to
// CHATS_SIT/.logs instead of this package's .logs - a different, easy-to-
// miss location. Resolving against the module's own directory makes the
// log location invariant to whatever cwd a given launcher happens to use.
const DEFAULT_LOG_DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", ".logs");
export class ConversationLogger {
    logDir;
    sessionId = "";
    turn = 0;
    constructor(logDir) {
        this.logDir = logDir ?? process.env.CCCAP_CONVERSATION_LOG_DIR ?? DEFAULT_LOG_DIR;
    }
    startSession(providerKey) {
        this.sessionId = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
        this.turn = 0;
        const now = new Date();
        const started = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}:${String(now.getSeconds()).padStart(2, "0")}`;
        this.append(`## Conversation session ${this.sessionId} - ${this.redact(providerKey)} - started ${started}\n\n`);
    }
    logToolCall(entry) {
        this.turn += 1;
        // redactObject() (not the plain string redact()) - applying the plain
        // string redactor to the whole JSON.stringify'd input previously
        // matched field NAMES too (e.g. "providerUtterance" is exactly 17
        // alphanumeric characters, within the 15-18 Salesforce-ID length
        // range), garbling the key itself into "[redacted-id]" and making the
        // log unreadable. redactObject() only ever touches string VALUES,
        // never object keys, and redacts a known credential field
        // (actionToken) as a whole rather than any partial substring match.
        const input = JSON.stringify(this.redactObject(entry.input));
        const response = entry.providerResponseText === undefined
            ? "(no provider text)"
            : this.truncate(this.redact(entry.providerResponseText));
        const error = entry.error
            ? `Error: ${this.redact(entry.error.code)} - ${this.redact(entry.error.message)}\n${entry.error.diagnostic ? `Diagnostic: ${this.redact(entry.error.diagnostic)}\n` : ""}`
            : "";
        const providerSaidLine = entry.providerUtterance
            ? `Provider said: "${this.redact(entry.providerUtterance)}"\n\n`
            : "";
        const content = `### Turn ${this.turn} - ${this.redact(entry.tool)} - ${entry.status} (${entry.durationMs}ms)\n\n${providerSaidLine}Input: \`${input}\`\n\nResponse:\n${response}\n\n${error}---\n\n`;
        this.append(content);
    }
    append(content) {
        fs.mkdirSync(this.logDir, { recursive: true });
        const now = new Date();
        const date = `${String(now.getDate()).padStart(2, "0")}_${String(now.getMonth() + 1).padStart(2, "0")}_${String(now.getFullYear()).slice(-2)}`;
        // One file per conversation session, not one shared file per day: the
        // sessionId minted in startSession() is folded into the filename so
        // concurrent/sequential sessions never interleave into the same file -
        // a reviewer can open exactly one file per session instead of scanning
        // a day-long file for the right "## Conversation session" heading.
        const filePath = path.join(this.logDir, `Assist_log_${date}_${this.sessionId || "no-session"}.md`);
        fs.appendFileSync(filePath, content, "utf8");
    }
    redact(value) {
        return value.replace(SALESFORCE_ID_PATTERN, "[redacted-id]");
    }
    // Recursively redacts string VALUES only - never object/array keys, so a
    // field name that happens to be 15-18 alphanumeric characters (e.g.
    // "providerUtterance") is never mistaken for a Salesforce ID. A known
    // credential-bearing key (actionToken) is redacted as a whole value
    // rather than via the length-based pattern, avoiding the partial-match
    // garbling a token containing hyphens/underscores previously produced.
    redactObject(value, key) {
        if (typeof value === "string") {
            return key === "actionToken" ? "[redacted-token]" : this.redact(value);
        }
        if (Array.isArray(value)) {
            return value.map((item) => this.redactObject(item));
        }
        if (value && typeof value === "object") {
            return Object.fromEntries(Object.entries(value).map(([entryKey, entryValue]) => [
                entryKey,
                this.redactObject(entryValue, entryKey),
            ]));
        }
        return value;
    }
    truncate(value) {
        return value.length > 4000 ? `${value.slice(0, 4000)}\n[...truncated]` : value;
    }
}
export const conversationLogger = new ConversationLogger();
// __________________________GenAI: Generated code ends here______________________________
