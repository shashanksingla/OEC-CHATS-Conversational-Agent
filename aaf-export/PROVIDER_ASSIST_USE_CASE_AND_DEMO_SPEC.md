# Provider Assist Use Case and Demo Spec

## 1. Product Promise

Provider Assist is a daily payout-readiness companion for Colorado CDEC child care providers.

It answers four questions without requiring the provider to navigate multiple screens:

1. What attendance or authorization issue could reduce my next payout?
2. How much money could be affected?
3. How much time is left to resolve it?
4. What should I do next?

The agent is read-only for the current demo. It identifies issues, explains the rule and estimated impact, and gives the provider a follow-up action. It does not claim to update attendance, obtain parent confirmation, submit a claim, or guarantee the final payment.

## 2. Provider Context

- A service week runs Monday through Sunday.
- Attendance may remain unconfirmed by the parent or may not yet be entered by the provider.
- The provider has a 9-day resolution window for these records.
- An unresolved record may be excluded from the payment processed approximately two weeks after the service week.
- County policy defines monthly absence limits by child and applicable county tier.
- A child approaching the limit is a warning; days beyond the limit are not payable by the state.
- Vacant-slot payment may contribute to a payout forecast, but it is not an attendance-risk category.
- If a missed item is discovered after payout release, the provider may need to raise a manual claim that can take up to 60 days to settle after verification.

## 3. Daily Snapshot

The first response should be a compact decision surface, not a data dump.

### Recommended opening

> **Good morning. Here is your payout-readiness snapshot.**
>
> **Upcoming payout estimate:** $X,XXX  
> Includes $XXX from vacant-slot payment.  
> **Estimated amount at risk:** $XXX  
> **Needs attention:** N items before the next processing date.

The snapshot ranks issues using both dimensions:

1. Urgency first: past window, due today, 1-3 days remaining, more than 3 days remaining.
2. Estimated dollar impact second: higher potential loss first within the same urgency band.

### Snapshot categories

| Category | Meaning | Primary action |
| --- | --- | --- |
| Attendance confirmation | Parent confirmation or provider attendance entry is missing | Follow up outside the system and/or complete the provider entry in the source system |
| Incomplete attendance | A record is missing required attendance detail | Review and correct the source record |
| Absence-limit risk | A child is near or beyond the county monthly limit | Verify the absence record and understand the payout impact |
| Payment forecast | Current period, upcoming payout, or month-to-date estimate | Inspect the service period breakdown |
| Vacant-slot amount | A positive component included in the forecast | Mention within the payout forecast, not as a separate risk |

### Suggested snapshot actions

- Review the most urgent attendance item
- See estimated payout impact
- Review absence-limit risk
- Check upcoming payout
- See this week's forecast
- See this month's payouts by service period

Do not show every possible action at once. Show at most three primary recommendations, with the first unresolved urgent risk first.

## 4. Drill-Down Contracts

### 4.1 Attendance confirmation detail

Show:

- Child
- Authorization
- Service date
- Service week
- Current status: provider entry missing or parent confirmation pending
- Days remaining in the 9-day window
- Estimated amount affected
- Next processing or payout context when available

Recommended explanation:

> This day is not yet confirmed. If it remains unresolved after the 9-day window, it may not be included when the service week is processed for payment.

Recommended action:

> Follow up with the parent outside the system, then verify the attendance record in the source system.

The agent must not imply that sending a message, changing attendance, or obtaining confirmation happened inside the agent.

### 4.2 Absence-limit detail

Show:

- Child
- County
- Service month
- Absence days used
- County monthly limit
- Remaining days before the limit
- Confirmed and probable absence dates
- Whether the limit is approaching or crossed
- Estimated payout impact

Recommended explanation:

> This child has used N of M county-allowed absence days this month. Additional days may be non-payable, and dates beyond the limit are currently treated as at risk.

Recommended action:

> Verify that the absence dates and attendance classification are accurate before the next payment processing cycle.

### 4.3 Payout-impact detail

Show:

- Affected child or service period
- Affected dates
- Risk category
- Estimated amount at risk
- Calculation basis in plain language
- What is already calculated versus still estimated
- The relevant next action

Always include the estimate disclaimer:

> This is an estimate based on current attendance records, authorizations, and rates on file. The county determines the final amount during payment processing.

### 4.4 Service-period payout detail

Show:

- Service week start and end
- Processing or payout date when available
- Estimated attended-care amount
- Vacant-slot amount as a supporting line
- At-risk amount
- Blockers and affected dates
- Full daily breakdown on request

## 5. Recommended Conversation Flow

This is the presenter script for the primary demo. The bracketed notes are presenter cues and are not spoken by the agent.

### Step 1: Establish the session

**Presenter says:**

> Hi, I want to see what needs attention today.

**Agent response:**

> One moment - I am verifying your account details and preparing your attendance and payment overview.

[Pause briefly to establish that the agent is scoped to the authenticated provider.]

### Step 2: Show the daily snapshot

**Agent response:**

> **Today's payout-readiness snapshot**
>
> Upcoming payout estimate: **$2,450**  
> Vacant-slot amount included: **$320**  
> Estimated amount at risk: **$185**  
> Needs attention: **3 items**
>
> 1. **Urgent - $120 at risk:** parent confirmation pending for Jordan Lee; 2 days remain.
> 2. **Review - $65 at risk:** Maya has used 4 of 5 county absence days this month.
> 3. **Review:** one attendance record is incomplete for the current service week.
>
> Recommended actions:
> - Review the urgent confirmation item
> - See estimated payout impact
> - Review absence-limit risk

[Point out that the provider gets a decision summary before seeing individual records.]

### Step 3: Open the most urgent item

**Presenter says:**

> Review the urgent confirmation item.

**Agent response:**

> **Attendance confirmation needed**
>
> Jordan Lee - Tuesday, September 29  
> Service week: September 28 - October 4  
> Status: parent confirmation pending  
> Resolution window: **2 days remaining**  
> Estimated amount affected: **$120**
>
> If this remains unresolved after the 9-day window, the day may be excluded from the payment processed for this service week.
>
> Recommended action: follow up with the parent outside the system, then verify the attendance record in the source system.

[Emphasize that the agent provides the next action but does not pretend to perform it.]

### Step 4: Explain the risk in plain language

**Presenter says:**

> Why is this at risk?

**Agent response:**

> The attendance record is still unresolved within the confirmation window. The payment calculation can use only records that are confirmed or otherwise eligible under the applicable rules. This is currently an estimate, and the county determines the final amount during payment processing.

### Step 5: Show absence-limit risk

**Presenter says:**

> Review absence-limit risk.

**Agent response:**

> **Absence-limit risk**
>
> Maya has used **4 of 5** county-allowed absence days for October.  
> Remaining allowance: **1 day**  
> Status: **approaching limit**  
> Estimated amount at risk: **$65**
>
> The next absence may exceed the monthly limit. Dates beyond the limit are currently treated as non-payable under the applicable county policy.
>
> Recommended action: verify the absence dates and attendance classification before the next payment processing cycle.

### Step 6: Connect risk to money

**Presenter says:**

> Show me the payout impact of these attendance risks.

**Agent response:**

> **Estimated payout impact**
>
> - Jordan Lee: $120 associated with an unresolved confirmation
> - Maya: $65 associated with absence-limit exposure
> - Total estimated amount at risk: **$185**
>
> The estimate is based on current attendance records, authorizations, and rates on file. The county determines the final amount during payment processing.

### Step 7: Show the service-week forecast

**Presenter says:**

> Show this week's forecast.

**Agent response:**

> **Current service-week forecast: September 28 - October 4**
>
> Estimated attended-care payment: **$2,130**  
> Vacant-slot payment included: **$320**  
> Estimated amount at risk: **$185**  
> Forecast total before risk: **$2,450**
>
> The $185 risk is tied to the unresolved confirmation and the absence-limit exposure shown above.

### Step 8: Close with provider value

**Presenter says:**

> What should I do first?

**Agent response:**

> Follow up on Jordan Lee's pending confirmation first because it has the shortest resolution window. Then verify Maya's absence dates and review the incomplete attendance record before the next processing cycle.

[Close by returning to the operational value: earlier visibility, fewer payout surprises, and less reliance on delayed manual claims.]

## 6. Supported Provider Questions

The demo should support natural variations of these requests:

- What needs attention today?
- Show my current month risk.
- What is my upcoming payout?
- What is my forecast for this week?
- Which attendance items are still pending?
- Which children are approaching their absence limit?
- How will this affect my payout?
- Show the full breakdown.
- Why is this day at risk?
- How is this payment calculated?
- Show my payouts by service period.
- Show the highest-impact child.

## 7. Implementation Scope

### Must have for the demo

- A starter response that combines payout estimate, vacant-slot supporting amount, amount at risk, and top risks.
- Consistent urgency plus estimated-dollar ranking.
- Separate language for confirmation risk and absence-limit risk.
- Attendance detail with the 9-day window and next external follow-up action.
- Absence-limit detail with used, limit, remaining, dates, and payout impact.
- Payout-impact drill-down that names the affected child, dates, category, and estimate disclaimer.
- Current service-week forecast with vacant-slot payment shown as a supporting line.
- No claim that the agent changed records or contacted parents.
- Buttons or suggested actions limited to three high-value options.

### Should have next

- Explicit labels for `Due today`, `N days remaining`, and `Past resolution window`.
- A copyable parent follow-up message generated from the pending record without exposing internal IDs.
- A past-cutoff state explaining that a manual claim may be required and can take up to 60 days after verification.
- A full daily breakdown for a selected service period.
- A clear distinction between calculated, estimated, blocked, and unavailable amounts.
- A compact monthly trend showing whether risk is increasing or decreasing.

### Could have later

- Provider reminders or notifications.
- A claim preparation checklist.
- Exportable payout-risk summary.
- Historical comparison of forecast versus released payout.
- What-if analysis for a possible additional absence, clearly labeled as a scenario rather than a prediction.

### Won't claim in this demo

- Directly editing attendance.
- Sending parent messages.
- Submitting or adjudicating manual claims.
- Guaranteeing final county payment.
- Treating a provider-entered child name or authorization number as an authorization boundary.

## 8. Acceptance Criteria

1. A provider can start with a broad request and receive a concise snapshot without knowing internal filters.
2. The snapshot distinguishes confirmation risk, incomplete attendance, absence-limit risk, and payout forecast.
3. The provider can move from a summary to a child, date, service week, rule, and estimated amount.
4. The first recommended action is the most urgent unresolved item, with dollar impact used as a tie-breaker.
5. Vacant-slot payment appears only as a supporting forecast component.
6. Every estimate includes the county-final-payment disclaimer.
7. Every external follow-up action is described honestly as outside the agent or in the source system.
8. A provider can ask for a full breakdown after seeing a summary without restarting the conversation.
9. Responses use the existing `chat-ui` buttons, tables, and accordions only when they improve scanability.
10. The provider session and data remain scoped to the authenticated provider; user-provided names and numbers are filters, not authorization boundaries.

## 9. Demo Success Statement

The demo succeeds when a provider can say:

> I know what could reduce my next payout, why it is at risk, how much time I have, how much money is involved, and what I need to do today.
