import LightningDatatable from 'lightning/datatable';
import customHyperlinkTemplate from './customHyperlinkTemplate.html';
import textWithTooltipTemplate from './textWithTooltipTemplate.html';

export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        customHyperlink: {
            template: customHyperlinkTemplate,
            typeAttributes: ['recordId', 'rowId', 'value']
        },
        textWithTooltip: {
            template: textWithTooltipTemplate,
            typeAttributes: ['value']
        }
    };
}