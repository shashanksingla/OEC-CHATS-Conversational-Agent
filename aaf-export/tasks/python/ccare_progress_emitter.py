msg = _context.get("progressMessage")
if msg is None:
    write_context("progressMessage", "")
elif "PROVIDER_NAME_PENDING" in msg:
    name = ((_context.get("sessionState") or {}).get("providerName") or ((_context.get("ccare_provider_data_py") or {}).get("providerName")) or "there")
    write_context("progressMessage", msg.replace("PROVIDER_NAME_PENDING", name))
respond("")
