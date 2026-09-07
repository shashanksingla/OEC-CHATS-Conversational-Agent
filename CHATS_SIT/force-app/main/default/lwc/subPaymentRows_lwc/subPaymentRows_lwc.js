import { LightningElement, api } from 'lwc';

export default class SubPaymentRows_lwc extends LightningElement {
    @api servicePeriodObj;
    @api subPaymentObj;
    @api authorizationObj;
    @api paymentObj;
    @api slotCntcheckbox;
    @api isSelected = false;

    /**
     * Returns true when the component should render the slot-based layout (8 columns).
     * Returns false when the case-based layout (12 columns) should be rendered.
     */
    get isSlotView() {
        return this.slotCntcheckbox === true;
    }

    /**
     * Returns CSS class for row highlighting when selected via keyboard.
     */
    get rowClass() {
        return this.isSelected ? 'selected-row' : '';
    }

    /**
     * Returns the formatted currency value for the slot-based view.
     * Displays subPymtSlotContractAmt from subPaymentObj.
     */
    get formattedSlotAmount() {
        const amt = this.subPaymentObj && this.subPaymentObj.subPymtSlotContractAmt;
        if (amt == null) {
            return '';
        }
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(amt);
    }

    /**
     * Returns the formatted currency value for the case-based view.
     * Displays subPymtAmount from subPaymentObj.
     */
    get formattedCaseAmount() {
        const amt = this.subPaymentObj && this.subPaymentObj.subPymtAmount;
        if (amt == null) {
            return '';
        }
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(amt);
    }

    /**
     * Handles radio button selection.
     * Fires the 'subpaymentselect' custom event with the subPaymentObj in the detail.
     */
    handleRadioSelect() {
        const selectEvent = new CustomEvent('subpaymentselect', {
            detail: { subPaymentObj: this.subPaymentObj },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(selectEvent);
    }
}