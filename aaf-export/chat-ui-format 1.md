# React Chat Rich UI Format

This document defines the small response format that an AAF agent can emit when the React chat should render a structured UI element. It is intentionally text-based so it works through the existing AAF text stream, Salesforce Apex/LWC adapters, WebSocket fallback, polling, and browser history.

## Contract Summary

An assistant response is normal Markdown by default. Rich controls are opt-in fenced JSON blocks:

````markdown
```chat-ui
{"version":1,"type":"buttons","items":[{"label":"Yes","value":"Yes"}]}
```
````

The renderer:

- Parses rich blocks only after the assistant turn is complete.
- Renders ordinary Markdown before, between, and after rich blocks.
- Treats malformed, unknown, unsupported, oversized, or incomplete blocks as ordinary Markdown/code.
- Never executes HTML, JavaScript, URLs as code, or agent-provided callbacks.
- Persists the original assistant text, so rich messages render again after history reload.

The `version` field is required and must be `1`.

## Supported Markdown

Use Markdown for prose and text formatting. The chat controls the typeface consistently; agents must not offer or emit font-family selectors, font controls, CSS styles, or inline style attributes.

- Headings (`#` through `######`, rendered as H1-H6), paragraphs, bold, italic, strikethrough, inline code, code blocks, lists, blockquotes, horizontal rules, and simple keyboard/highlight formatting.
- GFM links.
- GFM tables for simple tabular content.

Raw `<p>` and other common semantic text tags are accepted only through the renderer's fixed sanitizer allowlist. Do not use raw HTML as a way to add styling or behavior.

Use the structured `table` block below when the table should be responsive and predictable across hosts.

Do not emit raw HTML. Do not use HTML buttons, `<script>`, event attributes, custom elements, CSS, or embedded iframes.

### Copy-Paste Markdown Example for Agents

When the response only needs text formatting, send normal Markdown like this. Do not wrap it in a `chat-ui` block:

~~~~markdown
# H1: Provider status

## H2: Summary

This is a paragraph. Use *italic text*, **bold text**, ***bold italic text***,
~~strikethrough text~~, `inline code`, and a [descriptive link](https://example.com).

### H3: Key points

- Unordered list item
- Another item with **emphasis**
  - Nested list item

1. Ordered list item
2. Another ordered item

> This is a blockquote for an important note.

#### H4: Code example

```javascript
const status = 'Active';
console.log(status);
```

##### H5: Simple table

| Provider | Status | Open cases |
| --- | --- | ---: |
| Provider A | Active | 3 |
| Provider B | Review | 1 |

###### H6: Closing note

---

The response is complete.
~~~~

The Markdown paragraph above is rendered as a semantic `<p>` element by React. Agents should send the paragraph text, not a literal `<p>` tag. Use normal Markdown for headings and text; use a `chat-ui` block only when an interactive button, responsive structured table, or expandable section is needed.

## Buttons

Buttons are suggested replies. Clicking one sends its `value` as a normal user message through the existing chat continuation path.

````markdown
```chat-ui
{
  "version": 1,
  "type": "buttons",
  "items": [
    {"label": "Show this month's status", "value": "Show this month's status", "variant": "primary"},
    {"label": "Explain the result", "value": "Explain the result"}
  ]
}
```
````

Rules:

- `items` is required and contains 1-8 buttons.
- `label` is required and is the visible accessible name.
- `value` is optional; it defaults to `label`.
- `variant` is optional: `primary` or `secondary`.
- A button is a convenience for sending text. It does not grant access, choose a persona, choose a provider, or bypass server authorization.
- Do not place secrets, bearer values, Salesforce IDs, or authorization claims in button values.

## Structured Tables

Use a structured table when the result has known columns and rows. Cell values are plain text, numbers, booleans, or null. Markdown is not interpreted inside cells.

````markdown
```chat-ui
{
  "version": 1,
  "type": "table",
  "caption": "Provider status",
  "columns": [
    {"key": "provider", "label": "Provider"},
    {"key": "status", "label": "Status"},
    {"key": "openCases", "label": "Open cases", "align": "right"}
  ],
  "rows": [
    {"provider": "Provider A", "status": "Active", "openCases": 3},
    {"provider": "Provider B", "status": "Review", "openCases": 1}
  ]
}
```
````

Rules:

- `columns` is required and contains 1-12 columns.
- Each column has a unique `key` beginning with a letter, a visible `label`, and optional `align`: `left`, `center`, or `right`.
- `rows` is required and contains at most 100 rows.
- Missing or null cells render as empty text.
- Empty rows render a safe `No results` state.
- Return only fields approved for the operation. A table is presentation, not an authorization boundary.

## Expandable Sections

Use an accordion when detail should be available without making the main answer long. The `content` value is Markdown text and is sanitized by the same renderer as the main answer.

````markdown
```chat-ui
{
  "version": 1,
  "type": "accordion",
  "items": [
    {
      "title": "Why this result was returned",
      "content": "The current assignment is active.\n\nOnly the records in the user's approved scope are included."
    },
    {
      "title": "Source details",
      "content": "This section may contain a short **human-readable** explanation.",
      "open": true
    }
  ]
}
```
````

Rules:

- `items` is required and contains 1-8 sections.
- Each item has a `title` and Markdown `content`.
- `open` is optional and defaults to closed.
- Do not nest `chat-ui` blocks inside accordion content. Use Markdown inside the section only.
- The renderer uses native `<details>` and `<summary>` semantics for keyboard and assistive-technology support.

## Combining Content

An answer can combine normal Markdown and several blocks:

````markdown
## Current status

The providers below are in your approved scope.

```chat-ui
{"version":1,"type":"table","columns":[{"key":"provider","label":"Provider"},{"key":"status","label":"Status"}],"rows":[{"provider":"Provider A","status":"Active"}]}
```

What would you like to do next?

```chat-ui
{"version":1,"type":"buttons","items":[{"label":"Show details","value":"Show details","variant":"primary"},{"label":"Ask another question","value":"Ask another question"}]}
```
````

## AAF Authoring Rule

Add the following instruction to an AAF agent or task that uses this renderer:

````text
## React chat response format

Use normal Markdown for the answer. The React chat also supports a small allowlisted UI format.
Only emit a rich UI block when it makes the answer easier to use.

Rich UI syntax:
- Use a fenced code block whose language is exactly `chat-ui`.
- Put exactly one valid JSON object in each block.
- Include `"version": 1`.
- Supported types are `buttons`, `table`, and `accordion`.
- Never emit raw HTML, JavaScript, CSS, event handlers, custom elements, iframes, or arbitrary component names.
- Use Markdown headings, paragraphs, emphasis, lists, links, blockquotes, and code for text formatting. Do not emit font-family controls, CSS, inline styles, or font tags.
- Never put credentials, session IDs, bearer tokens, authorization claims, or unapproved sensitive data in a UI block.
- Keep user-facing explanation in normal Markdown outside the JSON block.
- A button `value` is sent as a normal user message when clicked; it is not an authorization instruction.
- If the UI block is not necessary, answer with normal Markdown only.
- If a block cannot be represented as valid JSON, do not emit it.

Button example:
```chat-ui
{"version":1,"type":"buttons","items":[{"label":"Show details","value":"Show details","variant":"primary"}]}
```

Table example:
```chat-ui
{"version":1,"type":"table","columns":[{"key":"name","label":"Name"},{"key":"status","label":"Status"}],"rows":[{"name":"Provider A","status":"Active"}]}
```

Accordion example:
```chat-ui
{"version":1,"type":"accordion","items":[{"title":"More information","content":"Short Markdown explanation."}]}
```
````

The instruction is guidance for generation, not a security control. Salesforce, the host gateway, and the approved backend remain responsible for identity, authorization, data scope, and action validation.

## Compatibility and Safety

This format is deliberately independent of AAF event names. The existing adapters continue to forward text chunks. A rich block may be split across many stream chunks and is reconstructed from the final assistant text before parsing.

Links are limited to HTTP(S), same-origin/relative links, fragments, and query links. Use descriptive link text. Do not use a link as a fake button; use a `buttons` block for a suggested reply.

The renderer applies bounded sizes to prevent accidental or hostile oversized UI payloads. A block that fails validation remains visible as Markdown/code, which gives the agent author a useful debugging signal without breaking the rest of the answer.

## Design References

- [GitHub Flavored Markdown specification](https://github.github.com/gfm/)
- [Marked advanced usage](https://marked.js.org/using_advanced)
- [DOMPurify configuration and security notes](https://github.com/cure53/DOMPurify)
- [MDN details element](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/details)
- [WAI-ARIA accordion pattern](https://www.w3.org/WAI/ARIA/apg/patterns/accordion/)
- [A2UI protocol](https://a2ui.org/specification/v1.0-a2ui/), reviewed as a future interoperability reference rather than a dependency for this small v1 renderer
