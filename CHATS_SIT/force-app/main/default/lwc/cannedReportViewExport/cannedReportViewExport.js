import { LightningElement, api, track } from 'lwc';
import getReportAWS from '@salesforce/apex/CannedReportInboxApxCtrl.geReportFromAWS';

export default class CannedReportViewExport extends LightningElement {
    @api searchitemname;
    @api reportid;
    @track showSpinner;

    handleButtonClick() {
        let fileName = '';
        this.showSpinner = true;

        if (this.reportid !== null && this.reportid !== undefined && this.reportid !== '' && this.searchitemname !== null
            && this.searchitemname !== undefined && this.searchitemname !== '') {
            if (this.reportid === 'RE213') {
                fileName = this.reportid + '_' + this.searchitemname + '.xlsx';
            } else {
                fileName = this.reportid + '_' + this.searchitemname + '.csv';
            }
        }
        if (fileName !== undefined && fileName !== '') {
            getReportAWS({
                fileName: fileName
            })
                .then(result => {
                    let str = result;
                    let strReport = this.s2ab(atob(str));
                    var blob = new Blob([strReport], {
                        type: ''
                    });
                    let downloadLink;
                    downloadLink = this.template.querySelector(".hyper-link");
                    downloadLink.download = fileName;
                    downloadLink.href = URL.createObjectURL(blob);
                    downloadLink.style.display = "none";
                    downloadLink.click();
                    this.showSpinner = false;
                })
                .catch(error => {
                    console.log('error---' + error);
                    this.showSpinner = false;
                });
        }

    }
    s2ab(s) {
        var buf = new ArrayBuffer(s.length);
        var view = new Uint8Array(buf);
        for (let i = 0; i !== s.length; ++i) {
            view[i] = s.charCodeAt(i) & 0xFF;
        }
        return buf;
    }
}