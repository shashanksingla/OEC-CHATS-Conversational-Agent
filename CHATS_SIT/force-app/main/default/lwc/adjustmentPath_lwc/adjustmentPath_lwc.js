import { LightningElement, api, track } from 'lwc';

export default class AdjustmentPath_lwc extends LightningElement {
    @api currentTabNumber = 1;

    // @track backing field for tabNames to ensure deep reactivity
    @track _tabNames = [];

    @api
    get tabNames() {
        return this._tabNames;
    }
    set tabNames(value) {
        // Deep copy for arrays to ensure reactivity
        if (value !== null && value !== undefined) {
            this._tabNames = JSON.parse(JSON.stringify(value));
        } else {
            this._tabNames = [];
        }
    }

    /**
     * Computed getter for tabMetadata - rebuilds whenever currentTabNumber or tabNames changes.
     * This ensures the path updates reactively when the parent changes currentTabNumber.
     */
    get tabMetadata() {
        if (!this.tabNames || this.tabNames.length === 0) {
            return [];
        }
        return this.tabNames.map((tabName, index) => {
            const tabNumber = index + 1;
            const isCurrent = (parseInt(this.currentTabNumber, 10) || 1) === tabNumber;
            return {
                tabNumber: tabNumber,
                tabName: tabName,
                tabClass: this.getTabClass(tabNumber),
                isCurrentStep: isCurrent ? 'step' : null,
                isCurrentStepSelected: isCurrent
            };
        });
    }

    /**
     * Returns true if tabMetadata has at least one entry.
     */
    get hasTabMetadata() {
        return this.tabMetadata && this.tabMetadata.length > 0;
    }

    /**
     * Returns the appropriate SLDS class based on tab state relative to currentTabNumber.
     * - Completed (currentTabNumber > tabNumber): 'slds-is-complete slds-path__item'
     * - Current (currentTabNumber === tabNumber): 'slds-is-active slds-is-current slds-path__item'
     * - Future (currentTabNumber < tabNumber): 'slds-is-incomplete slds-path__item'
     */
    getTabClass(tabNumber) {
        const current = parseInt(this.currentTabNumber, 10) || 1;
        if (current > tabNumber) {
            return 'slds-is-incomplete slds-path__item';
        } else if (current === tabNumber) {
            return 'slds-is-active slds-is-current slds-path__item';
        } else {
            return 'slds-is-incomplete slds-path__item';
        }
    }
}