import { LightningElement, api, track } from 'lwc';

export default class NavigationComponent_lwc extends LightningElement {
    // ═══════════════════════════════════════════════════════════════════════════
    // @track backing fields for @api properties that need reactivity
    // Defaults match Aura component defaults
    // ═══════════════════════════════════════════════════════════════════════════
    @track _showCancel = true;          // Aura default: true
    @track _showPrevious = true;        // Aura default: true
    @track _showNext = true;            // Aura default: true
    @track _showFinish = false;         // Aura default: false
    @track _doNextEnabled = true;       // Aura default: true
    @track _currentTabNumber = 1;
    @track _totalTabs = 1;
    @track isHighZoom = false;          // Tracks zoom state for responsive menu

    // Flag to track if initial render has occurred
    _hasRendered = false;
    _zoomHandler = null;
    _resizeTimeout = null;

    // ═══════════════════════════════════════════════════════════════════════════
    // Simple @api properties (primitives that don't need getter/setter)
    // ═══════════════════════════════════════════════════════════════════════════
    @api showPreviousAlways = false;
    @api hideFinish = false;
    @api nextLabel = 'Next';
    @api finishLabel = 'Complete';
    @api cancelLabel = 'Cancel';
    @api previousLabel = 'Previous';
    @api finishVariant = 'brand';
    @api showNextPeakFlow = false;
    @api disableCustomButton = false;
    @api disableFinishButton = false;
    @api showCustomButton = false;
    @api showCustomButtonHelp = false;
    @api customButtonHelpText;
    @api customButtonLabel = 'New Button';
    @api customButtonVariant = 'brand';
    @api previousVariant = 'neutral';
    @api customButtonLabelColor;
    @api buttonSpace;
    @api showCustomButton2 = false;
    @api customButtonLabel2 = 'New Button';
    @api customButtonVariant2 = 'brand';
    @api customButtonLabelColor2;
    @api showFinishBtnForExmptProvider = false;

    // ═══════════════════════════════════════════════════════════════════════════
    // @api getter/setter pairs for properties that need reactivity
    // These allow parent to explicitly set values and have them reflect properly
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * totalTabs - Total number of tabs/steps in the flow
     * Default: 1
     * Triggers handleCurrentTabNumberChange when updated
     */
    @api
    get totalTabs() {
        return this._totalTabs;
    }
    set totalTabs(value) {
        this._totalTabs = value;
        // Only recalculate if component has rendered (all props are set)
        if (this._hasRendered) {
            this.handleCurrentTabNumberChange();
        }
    }

    /**
     * showCancel - Controls visibility of Cancel button
     * Default: true (matches Aura)
     * Parent can set show-cancel={false} to hide
     */
    @api
    get showCancel() {
        return this._showCancel;
    }
    set showCancel(value) {
        // Handle string 'false' from HTML attributes and boolean false
        this._showCancel = value !== false && value !== 'false';
    }

    /**
     * showPrevious - Controls visibility of Previous button
     * Default: true (matches Aura)
     * Parent can set show-previous={false} to hide
     * Note: Also controlled by handleCurrentTabNumberChange based on currentTabNumber
     */
    @api
    get showPrevious() {
        return this._showPrevious;
    }
    set showPrevious(value) {
        this._showPrevious = value !== false && value !== 'false';
    }

    /**
     * showNext - Controls visibility of Next button
     * Default: true (matches Aura)
     * Parent can set show-next={false} to hide
     * Note: Also controlled by handleCurrentTabNumberChange based on currentTabNumber
     */
    @api
    get showNext() {
        return this._showNext;
    }
    set showNext(value) {
        this._showNext = value !== false && value !== 'false';
    }

    /**
     * showFinish - Controls visibility of Finish button
     * Default: false (matches Aura)
     * Parent can set show-finish={true} to show
     * Note: Also controlled by handleCurrentTabNumberChange based on currentTabNumber
     */
    @api
    get showFinish() {
        return this._showFinish;
    }
    set showFinish(value) {
        this._showFinish = value === true || value === 'true';
    }

    /**
     * doNextEnabled - Controls whether Next button is enabled
     * Default: true (matches Aura)
     * Parent can set do-next-enabled={false} to disable
     */
    @api
    get doNextEnabled() {
        return this._doNextEnabled;
    }
    set doNextEnabled(value) {
        this._doNextEnabled = value !== false && value !== 'false';
    }

    /**
     * currentTabNumber - Current tab/step number
     * Default: 1
     * Triggers handleCurrentTabNumberChange when updated
     */
    @api
    get currentTabNumber() {
        return this._currentTabNumber;
    }
    set currentTabNumber(value) {
        this._currentTabNumber = value;
        // Only recalculate if component has rendered (all props are set)
        if (this._hasRendered) {
            this.handleCurrentTabNumberChange();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Computed getters for dynamic button rendering
    // ═══════════════════════════════════════════════════════════════════════════

    get nextDisabled() {
        return !this._doNextEnabled;
    }

    get showFinishButton() {
        return this._showFinish && !this.hideFinish;
    }

    /**
     * Returns array of visible button configurations for dynamic rendering
     * Order: Cancel → Previous → Custom1 → Custom2 → Next → Finish
     */
    get visibleButtons() {
        const buttons = [];

        if (this._showCancel) {
            buttons.push({
                key: 'cancel',
                label: this.cancelLabel,
                variant: 'neutral',
                disabled: false,
                cssClass: this.buttonSpace || '',
                showHelpText: false,
                helpText: '',
                isPrimary: false
            });
        }

        if (this._showPrevious) {
            buttons.push({
                key: 'previous',
                label: this.previousLabel,
                variant: this.previousVariant,
                disabled: false,
                cssClass: this.buttonSpace || '',
                showHelpText: false,
                helpText: '',
                isPrimary: false
            });
        }

        if (this.showCustomButton) {
            buttons.push({
                key: 'custom1',
                label: this.customButtonLabel,
                variant: this.customButtonVariant,
                disabled: this.disableCustomButton,
                cssClass: this.customButtonLabelColor || '',
                showHelpText: this.showCustomButtonHelp,
                helpText: this.customButtonHelpText || '',
                isPrimary: false
            });
        }

        if (this.showCustomButton2) {
            buttons.push({
                key: 'custom2',
                label: this.customButtonLabel2,
                variant: this.customButtonVariant2,
                disabled: false,
                cssClass: this.customButtonLabelColor2 || '',
                showHelpText: false,
                helpText: '',
                isPrimary: false
            });
        }

        if (this._showNext) {
            buttons.push({
                key: 'next',
                label: this.nextLabel,
                variant: 'brand',
                disabled: !this._doNextEnabled,
                cssClass: '',
                showHelpText: false,
                helpText: '',
                isPrimary: true
            });
        }

        if (this.showFinishButton) {
            buttons.push({
                key: 'finish',
                label: this.finishLabel,
                variant: this.finishVariant,
                disabled: this.disableFinishButton,
                cssClass: this.buttonSpace || '',
                showHelpText: false,
                helpText: '',
                isPrimary: true
            });
        }

        return buttons;
    }

    /**
     * Returns true if normal button group should be shown (zoom < 200%)
     */
    get showButtonGroup() {
        return !this.isHighZoom;
    }

    /**
     * Returns true if menu mode should be shown (zoom >= 200%)
     */
    get showMenuMode() {
        return this.isHighZoom;
    }

    /**
     * Returns the primary action button (Next or Finish) for high-zoom mode
     * Returns the last primary button in the list
     */
    get primaryButton() {
        const primaryButtons = this.visibleButtons.filter(btn => btn.isPrimary);
        return primaryButtons.length > 0 ? primaryButtons[primaryButtons.length - 1] : null;
    }

    /**
     * Returns all non-primary buttons for the overflow menu in high-zoom mode
     */
    get menuButtons() {
        const primary = this.primaryButton;
        return this.visibleButtons.filter(btn => !primary || btn.key !== primary.key);
    }

    /**
     * Returns true if there are menu items to display
     */
    get hasMenuItems() {
        return this.menuButtons.length > 0;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Lifecycle
    // ═══════════════════════════════════════════════════════════════════════════

    connectedCallback() {
        this._zoomHandler = this.handleResize.bind(this);
        window.addEventListener('resize', this._zoomHandler);
        this.checkZoomLevel();
    }

    disconnectedCallback() {
        if (this._zoomHandler) {
            window.removeEventListener('resize', this._zoomHandler);
        }
        if (this._resizeTimeout) {
            clearTimeout(this._resizeTimeout);
        }
    }

    renderedCallback() {
        // Only run once after initial render when all @api properties are set
        if (!this._hasRendered) {
            this._hasRendered = true;
            this.handleCurrentTabNumberChange();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Zoom detection methods
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Checks zoom level using outerWidth/innerWidth ratio
     * This approach accounts for display scaling and provides accurate browser zoom detection
     * A ratio of 2.0 or greater indicates 200%+ zoom
     */
    checkZoomLevel() {
        // outerWidth/innerWidth gives the actual browser zoom factor
        // This is more reliable than devicePixelRatio which includes display scaling
        const zoomFactor = window.outerWidth / window.innerWidth;
        this.isHighZoom = zoomFactor >= 2.0;
    }

    /**
     * Debounced resize handler to detect zoom changes
     */
    handleResize() {
        if (this._resizeTimeout) {
            clearTimeout(this._resizeTimeout);
        }
        this._resizeTimeout = setTimeout(() => {
            this.checkZoomLevel();
        }, 100);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Event handlers
    // ═══════════════════════════════════════════════════════════════════════════
    handleButtonClick(event) {
        this.handleMenuSelect(event);
    }

    /**
     * Menu item select handler for high-zoom mode
     * Handles both lightning-menu-item select events and button click events
     */
    handleMenuSelect(event) {
        // Lightning menu fires select event with detail.value (not detail.key)
        // Button clicks use data-key attribute
        let key = null;

        // Try to get key from event.detail.value (lightning-menu-item select event)
        if (event.detail && event.detail.value) {
            key = event.detail.value;
        }
        // Try to get key from event.detail.key (custom event)
        else if (event.detail && event.detail.key) {
            key = event.detail.key;
        }
        // Try to get key from clicked element's data-key attribute
        else if (event.target && event.target.dataset && event.target.dataset.key) {
            key = event.target.dataset.key;
        }
        // Fallback: traverse up the DOM to find data-key if direct target doesn't have it
        else if (event.target) {
            let element = event.target.closest('[data-key]');
            if (element && element.dataset.key) {
                key = element.dataset.key;
            }
        }

        if (!key) {
            console.warn('handleMenuSelect: Could not determine button key from event', event);
            return;
        }
        switch (key) {
            case 'cancel':
                this.fireButtonEvent('cancel');
                break;
            case 'previous':
                this.fireButtonEvent('previous');
                break;
            case 'custom1':
                this.fireButtonEvent('custombutton');
                break;
            case 'custom2':
                this.fireButtonEvent('custombutton2');
                break;
            case 'next':
                this.fireButtonEvent('next');
                break;
            case 'finish':
                this.fireButtonEvent('finish');
                break;
            default:
                console.warn('handleMenuSelect: Unknown button key: ' + key);
        }
    }

    fireButtonEvent(eventName) {
        const buttonEvent = new CustomEvent(eventName, {
            detail: {
                currentTabNumber: this._currentTabNumber
            }
        });
        this.dispatchEvent(buttonEvent);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Tab navigation logic
    // Updates showNext, showPrevious, showFinish based on current tab position
    // ═══════════════════════════════════════════════════════════════════════════

    handleCurrentTabNumberChange() {
        const currentTabNumber = this._currentTabNumber;
        const totalTabs = this._totalTabs;
        const showFinishBtnForExmptProvider = this.showFinishBtnForExmptProvider;
        const showPreviousAlways = this.showPreviousAlways;

        // Determine Next/Finish visibility based on tab position
        // Using == for loose equality to handle string/number comparison
        if (totalTabs == 1 || currentTabNumber == totalTabs) {
            this._showNext = false;
            this._showFinish = true;
        } else {
            if (this.showNextPeakFlow) {
                this._showNext = false;
                this._showFinish = false;
            } else {
                this._showNext = true;
                this._showFinish = false;
            }
        }

        // Determine Previous visibility based on tab position
        if (currentTabNumber == 1 && !showPreviousAlways) {
            this._showPrevious = false;
        } else {
            this._showPrevious = true;
        }

        // Override for single tab or exempt provider
        if (totalTabs == 1 || showFinishBtnForExmptProvider) {
            this._showNext = false;
            this._showFinish = true;
        }
    }
}