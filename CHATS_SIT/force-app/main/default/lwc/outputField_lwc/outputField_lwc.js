import { LightningElement, api, track } from 'lwc';
import LOCALE from "@salesforce/i18n/locale";

export default class outputField_lwc extends LightningElement {
    @api hideLabel = false;
    @api label;

    // Internal tracked backing field for reactivity
    @track _value;
    @track updatedValue;
    @api type = 'NONE';
    @api usePlainValue = false;
    @api convertTime = false;
    @api suffix;
    @api format;
    @api currencyCode;

    // Getter/setter for value to ensure reactivity when parent updates
    // FIX #1: @api is on the getter only — no separate "@api value" declaration
    @api
    get value() {
        return this._value;
    }
    set value(val) {
        // Deep copy for objects/arrays to ensure reactivity; assign primitives directly
        if (val && typeof val === 'object') {
            this._value = JSON.parse(JSON.stringify(val));
        } else {
            this._value = val;
        }
        // Re-process value when it changes
        this.doInit();
    }

    connectedCallback() {
        this.doInit();
    }

    doInit() {
        // Reset updatedValue to avoid stale suffix concatenation
        this.updatedValue = null;

        if (!this.usePlainValue && (this.type === 'DECIMAL' || this.type === 'DOUBLE')) {
            // FIX #4: Null check on this._value before calling operations
            if (!this._value) {
                this.updatedValue = 0;
            } else {
                try {
                    const decimalValue = parseFloat(this._value).toFixed(2);
                    this.updatedValue = decimalValue;
                } catch (ex) {
                    console.error('Error parsing decimal value:', ex);
                }
            }
        } else if (this.convertTime && this.isDate) {
            // FIX #4: Null check on this._value before creating Date object
            if (this._value != null && this._value !== undefined) {
                const date = new Date(this._value);
                // FIX #2: 'const' declaration added for formattedDate
                // FIX #3: formattedDate is a string from Intl.DateTimeFormat.format()
                //         — date part extraction uses the 'date' object, NOT formattedDate
                const formattedDate = new Intl.DateTimeFormat(LOCALE).format(date);
                const dd = String(date.getDate()).padStart(2, '0');
                const MM = String(date.getMonth() + 1).padStart(2, '0');
                const yyyy = date.getFullYear();
                this.updatedValue = `${MM}/${dd}/${yyyy}`;
                console.log('Locale formatted date:', formattedDate);
            }
        }

        // Apply suffix to updatedValue only (not to _value to avoid infinite loop)
        // FIX #5: Explicit string concatenation instead of += to avoid direct mutation
        if (this.suffix && this.updatedValue != null) {
            this.updatedValue = this.updatedValue + this.suffix;
        }
    }

    get isUIDate() {
        return this.type === 'UIDATE';
    }
    get isDate() {
        return this.type === 'DATE';
    }
    get isNoneOrStringOrEmailOrPhone() {
        return ['NONE', 'STRING', 'EMAIL', 'PHONE'].includes(this.type);
    }
    get isDecimalOrDouble() {
        return ['DECIMAL', 'DOUBLE'].includes(this.type);
    }
    get isCurrency() {
        return this.type === 'CURRENCY';
    }
}