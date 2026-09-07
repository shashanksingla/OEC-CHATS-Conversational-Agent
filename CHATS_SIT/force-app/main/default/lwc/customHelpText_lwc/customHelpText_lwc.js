import { LightningElement, api, track } from "lwc";

export default class CustomHelpText_lwc extends LightningElement {
  /**
   * @property {string} - Text to display (equivalent to Aura 'text' attribute)
   */
  @api content = "";
  /**
   * @property {boolean} - Tracks visibility state of tooltip
   */
  @track isVisible = false;

  /** @private - debounce timer for hiding the tooltip */
  _hideTimer = null;

  /**
   * @type {string} - Returns the CSS classes for the tooltip container
   * Matches Aura: slds-popover slds-popover_tooltip slds-nubbin_left-top ms-help-popup-in-header slds-hide
   */
  get tooltipClasses() {
    const baseClasses = [
      "slds-popover",
      "slds-popover_tooltip",
      "slds-nubbin_left-top",
      "ms-help-popup-in-header"
    ];
    if (!this.isVisible || !this.content) {
      baseClasses.push("slds-hide");
    }
    return baseClasses.join(" ");
  }

  /**
   * @type {Array} - Returns the content split into lines for rendering
   * Each line is an object with key and text properties
   */
  get formattedLines() {
    if (!this.content) {
      return [];
    }
    // Split by both literal newlines and escaped \n characters
    const lines = this.content
      .replace(/\\n/g, "\n")
      .replace(/\\t/g, "\t")
      .split("\n");
    
    return lines.map((text, index) => ({
      key: `line-${index}`,
      text: text
    }));
  }

  /**
   * Handler for mouse enter - cancels any pending hide and shows the tooltip.
   * Cancelling the timer prevents the glitch caused by mouseleave/mouseenter
   * firing rapidly as the pointer moves between the icon and the tooltip popup.
   */
  handleMouseEnter() {
    if (this._hideTimer) {
      clearTimeout(this._hideTimer);
      this._hideTimer = null;
    }
    this.isVisible = true;
  }

  /**
   * Handler for mouse leave - schedules tooltip hide after a short delay.
   * The delay window allows a mouseenter on a sibling element (e.g. the tooltip
   * popup) to cancel the hide before it fires, preventing the glitch loop.
   * relatedTarget is NOT used here because LWC Shadow DOM makes cross-boundary
   * contains() checks unreliable.
   */
  handleMouseLeave() {
    this._hideTimer = setTimeout(() => {
      this.isVisible = false;
      this._hideTimer = null;
    }, 100);
  }

  /**
   * Handler for click - toggles tooltip
   * Equivalent to Aura handleOnClick
   */
  handleClick() {
    this.isVisible = !this.isVisible;
  }
}