import json
import re


_KEY_PATTERN = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")
_RICH_TYPES = {"table", "buttons", "accordion"}


def _scalar(value):
    return value is None or isinstance(value, (str, int, float, bool))


def _valid_table(block):
    columns = block.get("columns")
    rows = block.get("rows")
    if not isinstance(columns, list) or not 1 <= len(columns) <= 12:
        return False
    if not isinstance(rows, list) or len(rows) > 100:
        return False
    keys = []
    for column in columns:
        if not isinstance(column, dict):
            return False
        key = column.get("key")
        if not isinstance(key, str) or not _KEY_PATTERN.fullmatch(key) or key in keys:
            return False
        if not isinstance(column.get("label"), str):
            return False
        if column.get("align") not in (None, "left", "center", "right"):
            return False
        keys.append(key)
    for row in rows:
        if not isinstance(row, dict) or set(row) - set(keys):
            return False
        if not all(_scalar(row.get(key)) for key in keys):
            return False
    return True


def _valid_buttons(block):
    items = block.get("items")
    if not isinstance(items, list) or not 1 <= len(items) <= 8:
        return False
    for item in items:
        if not isinstance(item, dict) or not isinstance(item.get("label"), str):
            return False
        if "value" in item and not isinstance(item["value"], str):
            return False
        if item.get("variant") not in (None, "primary", "secondary"):
            return False
    return True


def _valid_accordion(block):
    items = block.get("items")
    if not isinstance(items, list) or not 1 <= len(items) <= 8:
        return False
    for item in items:
        if not isinstance(item, dict):
            return False
        if not isinstance(item.get("title"), str) or not isinstance(item.get("content"), str):
            return False
        if "```chat-ui" in item["content"]:
            return False
        if "open" in item and not isinstance(item["open"], bool):
            return False
    return True


def _valid_block(block):
    if not isinstance(block, dict) or block.get("version") != 1:
        return False
    block_type = block.get("type")
    if block_type == "text":
        return isinstance(block.get("content"), str) and (
            "italic" not in block or isinstance(block.get("italic"), bool)
        )
    if block_type not in _RICH_TYPES:
        return False
    if block_type == "table":
        return _valid_table(block)
    if block_type == "buttons":
        return _valid_buttons(block)
    return _valid_accordion(block)

blocks = read_context("formattedBlocks") or []
if not blocks:
    respond(
        "I could not load today's provider snapshot. Please try again later or contact your system administrator.",
        confidence=1.0,
    )
else:
    parts = []
    for block in blocks:
        if not _valid_block(block):
            continue
        if block.get("type") == "text":
            content = block.get("content", "")
            parts.append(f"*{content}*" if block.get("italic") else content)
        else:
            parts.append(
                "```chat-ui\n"
                + json.dumps(block, ensure_ascii=False, separators=(",", ":"))
                + "\n```"
            )
    if parts:
        respond("\n\n".join(parts), confidence=1.0)
    else:
        respond(
            "I could not load today's provider snapshot. Please try again later or contact your system administrator.",
            confidence=1.0,
        )
