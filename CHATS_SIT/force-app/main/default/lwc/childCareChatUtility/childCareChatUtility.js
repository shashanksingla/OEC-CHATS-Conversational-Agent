import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import chatEmbed from '@salesforce/resourceUrl/childCareChatEmbed';
import chatStyles from '@salesforce/resourceUrl/childCareChatStyles';
import createRunCallout from '@salesforce/apex/ChildCareChatProxy.createRun';
import getRunCallout from '@salesforce/apex/ChildCareChatProxy.getRun';
import submitRunDecisionCallout from '@salesforce/apex/ChildCareChatProxy.submitRunDecision';
import {
	canContinueRun,
	isTerminalRun,
	runError,
	runFinalText
} from './ascendEventParser.js';

function parseJson(value, message) {
  try {
	return JSON.parse(value);
  } catch {
	throw new Error(message);
  }
}

function requiresHumanReview(run) {
  return String(run?.status ?? '').toLowerCase() === 'awaiting_human'
	|| String(run?.pending_task?.mode ?? '').toLowerCase() === 'review';
}

const RUN_POLL_ATTEMPTS = 90;
const RUN_POLL_DELAY_MS = 1000;

function createSalesforceTransport(getConfig) {
  return {
	async stream({ payload = {}, onChunk, signal, context, onRunCreated }) {
	  if (signal?.aborted) return;

	  const config = getConfig();
	  const input = payload.input_text ?? payload.input ?? '';
	  let run;
	  let existingRun = null;
	  if (context?.ascendRunId) {
		try {
		  existingRun = parseJson(
			await getRunCallout({ runId: context.ascendRunId }),
			'Ascend returned an invalid existing run response.'
		  );
		} catch {
		  existingRun = null;
		}
	  }

	  if (context?.ascendRunId && canContinueRun(existingRun)) {
		run = parseJson(
		  await submitRunDecisionCallout({
			runId: context.ascendRunId,
			input
		  }),
		  'Ascend returned an invalid continued run response.'
		);
	  } else {
		run = parseJson(
		  await createRunCallout({
			processRef: config.processRef,
			personaRef: config.personaRef,
			input,
			runLabel: config.runLabel
		  }),
		  'Ascend returned an invalid process run response.'
		);
	  }
	  if (signal?.aborted) return;
	  if (run?.id) await onRunCreated?.(run.id);
	  if (!run?.id) {
		throw new Error('Ascend did not return a process run id.');
	  }

	  let currentRun = run;
	  for (let attempt = 0; attempt < RUN_POLL_ATTEMPTS; attempt += 1) {
		if (signal?.aborted) return;
		if (attempt > 0) {
		  await new Promise((resolve) => setTimeout(resolve, RUN_POLL_DELAY_MS));
		}
		try {
		  currentRun = parseJson(
			await getRunCallout({ runId: run.id }),
			'Ascend returned an invalid current run response.'
		  );
		} catch {
		  break;
		}
		if (requiresHumanReview(currentRun)
		  || isTerminalRun(currentRun)
		  || runFinalText(currentRun)) break;
	  }
	  if (requiresHumanReview(currentRun)) {
		onChunk?.('This question requires human review before an answer can be provided.');
		return;
	  }
	  const currentRunError = runError(currentRun);
	  if (currentRunError) throw new Error(currentRunError);
	  if (!isTerminalRun(currentRun) && !runFinalText(currentRun)) {
		throw new Error('Ascend run did not complete within the allowed wait time.');
	  }

	  const finalText = runFinalText(currentRun);
	  if (finalText) onChunk?.(finalText);
	}
  };
}

export default class ChildCareChatUtility extends LightningElement {
  @api label = 'Child Care Chat';
  @api ascendBaseUrl = '';
  @api personaRef = '';
  @api processRef = '';
  @api runLabel = '';

  errorMessage = '';
  loadPromise;
  widget;

  renderedCallback() {
	if (this.loadPromise) {
	  return;
	}

	this.loadPromise = Promise.all([
	  loadScript(this, chatEmbed),
	  loadStyle(this, chatStyles)
	])
	  .then(() => {
		const sdk = self.ChatSdk ?? globalThis.ChatSdk ?? window.ChatSdk;
		const host = this.template.querySelector('.chat-host');

		if (!sdk?.mountChatWidget || !host) {
		  throw new Error('Chat embed did not load.');
		}

		this.widget = sdk.mountChatWidget(host, this.chatConfig);
	  })
	  .catch(() => {
		this.errorMessage = 'Chat is unavailable right now.';
	  });
  }

  disconnectedCallback() {
	this.widget?.unmount();
	this.widget = undefined;
	this.loadPromise = undefined;
  }

  get chatConfig() {
	return {
	  transport: createSalesforceTransport(() => ({
		personaRef: this.personaRef,
		processRef: this.processRef,
		runLabel: this.runLabel
	  }))
	};
  }
}