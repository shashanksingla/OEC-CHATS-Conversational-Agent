# CCCAP Provider API MCP Server

This local stdio MCP server gives CarePay Advisor seven read-only tools backed by `CccapPortalApiV1` in the Salesforce target org.

## Authentication and Scope

The server reuses the existing Salesforce CLI authorization for `SF_TARGET_ORG`. At startup it resolves that authenticated Salesforce username to its `User.Id`; VS Code does not prompt for a user ID, and the model cannot view or override it.

`cccap_initialize_provider` calls `getProviderData`, captures the provider IDs and active county agreements mapped to that user, and establishes the in-process authorization scope. Every provider-specific downstream call injects those provider IDs. County filters outside that scope are rejected before Salesforce is called.

For production, prefer per-user Salesforce OAuth and derive identity in Apex with `UserInfo.getUserId()` rather than accepting `userId` in the request body. The local input approach is for VS Code development.

## Commands

From this directory:

```powershell
npm install
npm test
npm run typecheck
npm run build
```

VS Code starts `node dist/index.js` from `.vscode/mcp.json` and uses the existing `CHATS_SIT` Salesforce CLI session. Ensure the authenticated Salesforce user has a matching `Provider_Persona_MD__mdt` record.

After changing tool code, rebuild and run **MCP: Reset Cached Tools**, then restart `cccapprovider` from **MCP: List Servers**.

## Tool Order

1. Call `cccap_initialize_provider` with the date scope for the provider request.
2. Retrieve cases, authorizations, county rate plans, schedules, service periods, and holidays only as needed.
3. Normalize the returned records and pass calculation inputs to CarePay Advisor's Python calculator.
4. Stop and report the source error when a required tool or field is unavailable.

## Payment Readiness

Attendance responses include a deterministic payment-readiness result. It is currently `BLOCKED_MISSING_REQUIRED_INPUTS`: live MCP responses do not yet provide complete normalized fiscal rates, attendance transactions, parent confirmations and absence approvals, existing sub-payments, slot contracts, parent fees, holiday-payment eligibility, rate-unit mapping, ART-fee history, or Care Not Offered status. CarePay Advisor must not calculate or estimate a live payment amount until those authorized source mappings exist. The canonical evaluator is `scripts/provider_risk_payment_engine.py` and requires rule version `provider-risk-payment-v1`.

The generic `Salesforce DX` MCP server cannot invoke custom Apex REST resources; it remains useful for development operations such as SOQL, metadata, and tests.