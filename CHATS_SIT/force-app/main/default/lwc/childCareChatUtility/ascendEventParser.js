const NON_TEXT_EVENT_TYPES = new Set([
  'awaiting_human',
  'heartbeat',
  'note_updated',
  'progress_appended',
  'run_completed',
  'run_failed',
  'skill_completed',
  'skill_started',
  'tool_call',
  'tool_result'
]);

function firstText(...values) {
  return values.find((value) => typeof value === 'string' && value.length > 0) ?? '';
}

function summarizeError(value) {
  return firstText(value).split(/\r?\n/, 1)[0].trim();
}

function eventType(event) {
  const dataType = event?.data && typeof event.data === 'object'
    ? event.data.type ?? event.data.event
    : '';
  return String(dataType || event?.event || '').toLowerCase();
}

export function eventText(event) {
  const data = event?.data;
  if (typeof data === 'string') return data === '[DONE]' ? '' : data;
  if (!data || typeof data !== 'object') return '';

  const type = eventType(event);
  if (type === 'skill_token') {
    return firstText(data.delta, data.text, data.content);
  }
  if (NON_TEXT_EVENT_TYPES.has(type)) return '';

  return firstText(
    data.delta,
    data.text,
    data.content,
    data.token,
    data.response,
    data.final_response,
    data.output,
    data.message,
    data.data?.delta,
    data.data?.text,
    data.data?.content,
    data.data?.response
  );
}

export function eventError(event) {
  if (!['error', 'run_failed'].includes(eventType(event))) return '';
  const data = event?.data;
  if (!data || typeof data !== 'object') return '';
  return summarizeError(data.error ?? data.message ?? data.detail ?? data.data?.error);
}

export function parseSseEvents(stream) {
  return String(stream ?? '')
    .split(/\r?\n\r?\n/)
    .map((block) => {
      const lines = block.split(/\r?\n/);
      const dataLines = lines
        .filter((line) => line.startsWith('data:'))
        .map((line) => line.slice(5).replace(/^ /, ''));

      if (dataLines.length === 0) return null;

      const raw = dataLines.join('\n');
      let data = raw;
      try {
        data = JSON.parse(raw);
      } catch {
      }

      return {
        event: lines.find((line) => line.startsWith('event:'))?.slice(6).trim() || 'message',
        data
      };
    })
    .filter(Boolean);
}

export function runError(run) {
  const error = summarizeError(run?.error);
  if (error) return error;

  const status = String(run?.status ?? '').toLowerCase();
  if (['failed', 'error', 'cancelled', 'canceled'].includes(status)) {
    return `Ascend run ${status}.`;
  }
  return '';
}

export function isTerminalRun(run) {
  return [
    'completed',
    'failed',
    'error',
    'cancelled',
    'canceled',
    'escalated'
  ].includes(String(run?.status ?? '').toLowerCase());
}

export function canContinueRun(run) {
  return Boolean(run) && !isTerminalRun(run) && !runFinalText(run);
}

export function runFinalText(run) {
  return firstText(run?.final_response, run?.output?.response);
}