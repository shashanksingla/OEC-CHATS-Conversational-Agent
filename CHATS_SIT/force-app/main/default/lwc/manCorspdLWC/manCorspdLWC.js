import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { helper } from 'c/generic_Utilities';
import correspondenceTargetPdfServlet from '@salesforce/label/c.correspondenceTargetPdfServlet';

export default class ManCorspdLWC extends LightningElement {
   @track param = {IDN_CASE__c: '',
       NME_CORSPD__c:'',
       IDN_CLIENT__c: '',
       IDN_PROVR__c: '',
       CDE_COUNTY__c: '',
       CR107_Checklist__c: '',
       CR107_OTHER_TEXT__c: '',
       CR702_Checklist__c: '',
       IDN_ADJMT__c:'',
       CR702_TEXT__c: '',
       CR212_Checklist__c: '',
       Number_of_Occurrences__c: '',
       Contact_Phone_Number__c:'',
       Disqualification_Hearing_Date__c:'',
       Disqualification_End_Date__c:'',
       Disqualification_Begin_Date__c:''
   };
   @track manualchecklist = {DTE_DEADLINE__c : '',
       DTE_702DEADLINE__c:''
   };
   @track generated ='';
   @track responseCorspd = '';
   @track countyParam = {};
   @track toggleSpinner = false;
   @track isOpen = true;
   @track isDisbaleTrue = false;
   @api cidboolean = false;
   @api cidbooleanCase = false;
   @api pidboolean = false;
   @api pidbooleanProvider = false;
   @api aidboolean = false;
   @api countyidboolean;
   countyidboolean= true;
   @api DQEndDateRequired = false;
   @api childAttr;
   @api cr207CaseReq;
   cr207CaseReq = true;
   @api cr207ProviderReq;
   cr207ProviderReq = true;
   timeoutId;
   get isCR207() {
       return this.param.NME_CORSPD__c === 'CR207';
   }
   get isCR114() {
       return this.param.NME_CORSPD__c === 'CR114';
   }
   get isCaseRequired() {
       return ['CR114', 'CR212', 'CR107', 'CR108', 'CR109', 'CR207', 'CR110'].includes(this.param.NME_CORSPD__c);
   }
   get isDisabled() {
       return this.pidboolean;
   }

   get isCR212(){
       return this.param.NME_CORSPD__c === 'CR212';
   }

   get isRequired() {
       return !this.pidboolean;
   }
   get isadjDisabled() {
       return this.aidboolean;
   }

   get isadjRequired() {
       return !this.aidboolean;
   }

   get isValidCorrespondenceType() {
       const excludedValues = ['CR109', 'CR114', 'CR108', 'CR212', 'CR110'];
       const correspondenceType = this.param.NME_CORSPD__c;
       return !excludedValues.includes(correspondenceType);
   }
   handleNo() {
    const noEvent = new CustomEvent('cancel');
    this.dispatchEvent(noEvent);
}
@ api closeModel() {
    this.isOpen = false;
    this.childAttr = false;
}
   handleInput(evt) {
       const fieldName = evt.target.name; 
       const fieldValue = evt.target.value; 
       if (this.param.hasOwnProperty(fieldName)) {
           this.param[fieldName] = fieldValue;
       }     
   }

   handleDateInput(event){
       const fieldName = event.target.name; 
       const fieldValue = event.target.value; 
       if (this.manualchecklist.hasOwnProperty(fieldName)) {
           this.manualchecklist[fieldName] = fieldValue;
       }
   }
   handleOnChange(event) {
       const correspondenceType = event.detail.value; 
       this.param.NME_CORSPD__c = correspondenceType;
       this.disabledField();
       this.clearAllFields();
   }

   handleCountyChange(event) {
        const countyName = event.detail.value; 
        this.param.CDE_COUNTY__c = countyName;   
    }

   hideProvider() {
       if (this.param.IDN_CASE__c) {
           this.cidbooleanCase = false;
           this.cr207ProviderReq = false;
           this.cr207CaseReq = true;
           this.pidbooleanProvider = true;
       } else {
           this.cr207CaseReq = false;
           this.cr207ProviderReq = false;
           this.cidbooleanCase = false;
           this.pidbooleanProvider = false;
       }
   }
   hideCase() {
       if (this.param.IDN_PROVR__c) {
           this.cr207CaseReq = false;
           this.cidbooleanCase = true;
           this.pidbooleanProvider = false;
           this.cr207ProviderReq = true;
       } else {
           this.cr207CaseReq = false;
           this.cr207ProviderReq = false;
           this.cidbooleanCase = false;
           this.pidbooleanProvider = false;
       }
   }

   clearAllFields() {
       let param = {
           IDN_CASE__c: '',
           IDN_CLIENT__c: '',
           IDN_PROVR__c: '',
           CDE_COUNTY__c: '',
           CR107_Checklist__c: '',
           CR107_OTHER_TEXT__c: '',
           CR702_Checklist__c: '',
           CR702_TEXT__c: '',
           CR212_Checklist__c: '',
           NME_CORSPD__c: this.param.NME_CORSPD__c,
           IDN_ADJMT__c:'',
           Number_of_Occurrences__c: '',
           Contact_Phone_Number__c:'',
           Disqualification_Hearing_Date__c:'',
           Disqualification_End_Date__c:'',
           Disqualification_Begin_Date__c:''
       };
       this.param=JSON.parse(JSON.stringify(param));
       this.manualchecklist.DTE_DEADLINE__c = '';
     this.manualchecklist.DTE_702DEADLINE__c = '';
}

   disabledField(){
       let params={correspondenceType: this.param.NME_CORSPD__c};
       helper.callServer(this,'ManualCorrespondenceController','performdisable',(function(response){
           if(response){
                   if (response === 'C') {
                                   this.pidboolean = true;
                                   this.cidboolean = false;
                                   this.aidboolean = true;
                               } else if (response === 'P') {
                                   this.cidboolean = true;
                                   this.pidboolean = false;
                                   this.aidboolean = true;
                               } else {
                                   this.cidboolean = false;
                                   this.pidboolean = false;
                                   this.aidboolean = false;
                               }
                   
                               if (this.param.NME_CORSPD__c === 'CR107') {
                                   const d = new Date();
                                   d.setDate(d.getDate() + 15);
                   
                                   if ( this.manualchecklist && !this.manualchecklist.DTE_DEADLINE__c) {
                                       const deadLineDate = d.toISOString();
                                       this.manualchecklist = {
                                           ...this.manualchecklist,
                                           DTE_DEADLINE__c: deadLineDate
                                       };
                                   }
                               }
               }
           }).bind(this), JSON.stringify(params));          
       }

       toastMessage(state, msg) {
           const event = new ShowToastEvent({
               title: state, 
               message: msg, 
               variant: state.toLowerCase(), 
           });
           this.dispatchEvent(event); 
       }

       handleSubmit() {
           const newparam = this.param;
           const manual = this.manualchecklist || {};

           // CR107 Logic
           if (newparam.NME_CORSPD__c === 'CR107' &&((manual.DTE_DEADLINE__c === '' || manual.DTE_DEADLINE__c === undefined || manual.DTE_DEADLINE__c=== null) ||(newparam.CR107_Checklist__c === '' || newparam.CR107_Checklist__c === undefined || newparam.CR107_Checklist__c.length===0))) {
            if((newparam.CR107_OTHER_TEXT__c != null || newparam.CR107_OTHER_TEXT__c != '')&& (manual.DTE_DEADLINE__c === '' || manual.DTE_DEADLINE__c === undefined || (manual.DTE_DEADLINE__c === null))) {
                this.toastMessage('Error', 'Please provide all the Mandatory Information.');
            } else if (newparam.CR107_OTHER_TEXT__c != null && newparam.CR107_OTHER_TEXT__c != '') {
                this.updateItem();
            } else {
                this.toastMessage('Error', 'Please provide all the Mandatory Information.');
            }
        }
           // CR702 Logic
           else if (newparam.NME_CORSPD__c === 'CR702' &&
            ((manual.DTE_702DEADLINE__c === '' || manual.DTE_702DEADLINE__c === undefined) ||
                (newparam.CR702_Checklist__c === '' || newparam.CR702_Checklist__c === undefined))
        ) {
            if ((newparam.CR702_TEXT__c != null && newparam.CR702_TEXT__c != '') && (manual.DTE_702DEADLINE__c === '' || manual.DTE_702DEADLINE__c === undefined)) {
                this.toastMessage('Error', 'Please provide all the Mandatory Information.');
            } else if (newparam.CR702_TEXT__c != null && newparam.CR702_TEXT__c != '') {
                this.updateItem();
            } else {
                this.toastMessage('Error', 'Please provide all the Mandatory Information.');
            }
        }
           // CR114 Logic
           else if (newparam.NME_CORSPD__c === 'CR114') {
               if (!newparam.IDN_CLIENT__c || !newparam.IDN_CASE__c) {
                   this.toastMessage('Error', 'Please provide all the Mandatory Information.');
               } else {
                   this.updateItem();
               }
           }
           // CR108 Logic
           else if (newparam.NME_CORSPD__c === 'CR108') {
               if (newparam.IDN_CASE__c) {
                   this.updateItem();
               } else {
                   this.toastMessage('Error', 'Please provide all the Mandatory Information.');
               }
           }
           // CR207 Logic
           else if (newparam.NME_CORSPD__c === 'CR207') {
               if (newparam.IDN_ADJMT__c != null) {
                   if (!newparam.IDN_PROVR__c && !newparam.IDN_CASE__c) {
                       this.toastMessage('Error', 'Please provide valid Case ID/Provider ID and associated Adjustment ID.');
                   } else {
                       if (newparam.IDN_CASE__c != null && newparam.IDN_CLIENT__c == null) {
                           this.toastMessage('Error', 'Please provide all the Mandatory Information.');
                       } else {
                           this.updateItem();
                       }
                   }
               } else {
                   this.toastMessage('Error', 'Please provide valid Case ID/Provider ID and associated Adjustment ID.');
               }
           }
           // CR212 Logic
           else if (newparam.NME_CORSPD__c === 'CR212') {
            if ((newparam.IDN_CASE__c) && newparam.CR212_Checklist__c.length>0) {
                this.updateItem();
            } else {
                this.toastMessage('Error', 'Please provide all the Mandatory Information.');
            }
        }
           // CR110 Logic
           else if (newparam.NME_CORSPD__c === 'CR110') {
               let isFormValid = true;
               if (
                   !newparam.IDN_CASE__c ||
                   !newparam.IDN_CLIENT__c ||
                   !newparam.Disqualification_Begin_Date__c ||
                   !newparam.Contact_Phone_Number__c ||
                   !newparam.Disqualification_Hearing_Date__c ||
                   !newparam.Number_of_Occurrences__c
               ) {
                   isFormValid = false;
               }
               if (!newparam.Disqualification_End_Date__c && this.DQEndDateRequired) {
                   isFormValid = false;
               }
               if (isFormValid) {
                   this.updateItem();
               } else {
                   this.toastMessage('Error', 'Please enter all the Mandatory Information');
               }
           }
           else if (
            newparam.NME_CORSPD__c !== 'choose one' &&
            ((newparam.IDN_CASE__c != null && newparam.IDN_CASE__c != '' ) || (newparam.IDN_PROVR__c != null && newparam.IDN_PROVR__c != '' && newparam.CDE_COUNTY__c != null && newparam.CDE_COUNTY__c !== ' '&& newparam.CDE_COUNTY__c !== ''))
        )  {
               this.updateItem();
           } else {
               this.toastMessage('Error', 'Please provide all the Mandatory Information.');
           }
       }

       updateItem() {
               if (this.validateCR107()) {
                   this.toggleSpinner = true;
                   this.isDisbaleTrue = true;      
                   let isCR114Valid = false;
                   let isCR207Valid = false;
                   let isValidCounty = true;
       
                   const newParam1 = this.param;
       
                   // Validate County
                   if (newParam1.CDE_COUNTY__c) {
                       let param1= { county: newParam1.CDE_COUNTY__c };

                           helper.callServer(this,'ManualCorrespondenceController','validateCounty',(function(response){
                               try {
                               if (!response.isValid) {
                                   isValidCounty = false;
                                   this.toggleSpinner = false;
                                   this.isDisbaleTrue = false;
                                   this.toastMessage('Error', 'The county ' + response.countyName +' does not match your assigned county(ies).');
                                   return;
                               }
                           } catch (error) {
                               this.toggleSpinner = false;
                               this.isDisbaleTrue = false;
                               this.toastMessage('Error', 'Error in validating county');
                               return;
                           }
                           }).bind(this),JSON.stringify(param1));
                   }
       
                   // Validate Case Id
                   if (newParam1.IDN_CASE__c) {
                       let param2= { caseId: newParam1.IDN_CASE__c }
 
                           helper.callServer(this,'ManualCorrespondenceController','validateCase',(function(response){
                               if(response){
                                    try{
                                       if (response == 'ValidCase') {
                                           isCR114Valid = true;
                                           isCR207Valid = true;
                                           if (!['CR114', 'CR207', 'CR110'].includes(newParam1.NME_CORSPD__c)) {
                                               var time = 1;
                                                this.timeoutId=setTimeout(() => {
                                                    this.callProcessManualCorr();
                                                }, time * 5000);
                                           }
                                       } else if (response === 'InvalidCase') {
                                           this.toggleSpinner = false;
                                           this.isDisbaleTrue = false;
                                           this.toastMessage('Error', 'Please provide the valid Case Id.');
                                           return;
                                       } else if (response === 'InvalidCaseCounty') {
                                           this.toggleSpinner = false;
                                           this.isDisbaleTrue = false;
                                           this.toastMessage('Error', 'The case ' + newParam1.IDN_CASE__c + ' does not belong to your assigned county(ies).');
                                           return;
                                       }
                                   } catch (error) {
                                       this.toggleSpinner = false;
                                       this.isDisbaleTrue = false;
                                       this.toastMessage('Error', 'Error in validating the Case Id');
                                       return;
                                   }
                               }
                    
                           }).bind(this),JSON.stringify(param2));

                   }
       
               //     // Validate Provider Id
                   if (newParam1.IDN_PROVR__c) {
                       let isCR207ProValid = false;
                           let param3=  { providerId: parseInt(newParam1.IDN_PROVR__c) }
                           helper.callServer(this,'ManualCorrespondenceController','validateProvider',(function(response){
                               if(response){
                               try{
                                   if (response === 'ValidProvider') {
                                       isCR207ProValid = true;
                                       if (newParam1.NME_CORSPD__c !== 'CR207' && isValidCounty) {
                                        if (this.timeoutId) {
                                            clearTimeout(this.timeoutId);
                                        }
                                           var time = 1;
                                                this.timeoutId=setTimeout(() => {
                                                    this.callProcessManualCorr();
                                                }, time * 5000);
                                       }
                                   } else if (response === 'InvalidProvider') {
                                       this.toggleSpinner = false;
                                       this.isDisbaleTrue = false;
                                       this.toastMessage('Error', 'Please provide the valid Provider Id.');
                                       return;
                                   } else if (response === 'InvalidProviderCounty') {
                                       if (newParam1.NME_CORSPD__c === 'CR702') {
                                        if (this.timeoutId) {
                                            clearTimeout(this.timeoutId);
                                        }
                                           var time = 1;
                                                this.timeoutId=setTimeout(() => {
                                                    this.callProcessManualCorr();
                                                }, time * 5000);
                                       } else {
                                           this.toggleSpinner = false;
                                           this.isDisbaleTrue = false;
                                           this.toastMessage('Error', 'The provider '+ newParam1.IDN_PROVR__c +  ' does not belong to your assigned county(ies).');
                                           return;
                                       }
                                   }
                               } catch (error) {
                                   this.toggleSpinner = false;
                                   this.isDisbaleTrue = false;
                                   this.toastMessage('Error', 'Error in validating the Provider Id');
                                   return;
                               }
                           }
                   }).bind(this),JSON.stringify(param3));

                   }
       
               //     // Validate Child/Client Id
                   if (newParam1.IDN_CLIENT__c) {
                       let param4={ client: newParam1.IDN_CLIENT__c }
                       if (this.timeoutId) {
                        clearTimeout(this.timeoutId);
                    }
                       var time = 1;
                            this.timeoutId=setTimeout(() => {
                                helper.callServer(this,'ManualCorrespondenceController','validateChild',(function(response){
                                    if(response){
                                    try{
                                        if (response === 'ValidChild') {
                                            if (!['CR114', 'CR207'].includes(newParam1.NME_CORSPD__c)) {
                                                //this.callProcessManualCorr();
                                                 if (this.timeoutId) {
                                                    clearTimeout(this.timeoutId);
                                                }
                                                   var time = 1;
                                                        this.timeoutId=setTimeout(() => {
                                                            this.callProcessManualCorr();
                                                        }, time * 5000);
                                            } else if (isCR114Valid && newParam1.NME_CORSPD__c === 'CR114') {
                                                //this.callProcessManualCorr();
                                                 if (this.timeoutId) {
                                                    clearTimeout(this.timeoutId);
                                                }
                                                   var time = 1;
                                                        this.timeoutId=setTimeout(() => {
                                                            this.callProcessManualCorr();
                                                        }, time * 5000);
                                            }
                                        } else if (response === 'InvalidChild') {
                                            if (newParam1.NME_CORSPD__c === 'CR110') {
                                                this.toggleSpinner = false;
                                                this.isDisbaleTrue = false;
                                                this.toastMessage('Error', 'Please provide the valid Individual ID.');
                                            } else if (newParam1.NME_CORSPD__c === 'CR207') {
                                                // Do nothing as 'validateCaseClientAssociation' will handle this
                                            } else {
                                                this.toggleSpinner = false;
                                                this.isDisbaleTrue = false;
                                                this.toastMessage('Error', 'Please provide the valid Child Id.');
                                            }
                                            return;
                                        }
                                    } catch (error) {
                                        this.toggleSpinner = false;
                                        this.isDisbaleTrue = false;
                                        this.toastMessage('Error', 'Error in validating the Child Id');
                                        return;
                                    }}
                                }).bind(this),JSON.stringify(param4));
                            }, time * 5000);

                   }     
                }        
                   }

       validateCR107(){
           const newparam = this.param;
           let isValid = newparam.NME_CORSPD__c !== 'CR107';
           const checkList = String(newparam.CR107_Checklist__c || '');
           const items = checkList.split(',');
   
           if (items.length === 2 && items.includes('01') && items.includes('18')) {
               this.toastMessage('Error','Please select another Missing Verification that impacts case eligibility to proceed with this correspondence.' );
           } else if (items.length === 1 && items.includes('01')) {
               this.toastMessage('Error','Another missing verification selection must be made to proceed. This notice cannot be used for only Child Care information requests, as this does not impact a family’s eligibility. Please use CR212.' );
           } else if (items.length === 1 && items.includes('18')) {
               this.toastMessage('Error','Please select another Missing Verification that impacts case eligibility to proceed with this correspondence.' );
           } else {
               isValid = true;
           }
           return isValid;
       }
                   
       callProcessManualCorr (){
               this.toggleSpinner = true; 
               const newParam1 = this.param;
               let numOfOccurrencesString = newParam1.Number_of_Occurrences__c? newParam1.Number_of_Occurrences__c.toString(): null;
               let params={corspdName: newParam1.NME_CORSPD__c,
               caseId: newParam1.IDN_CASE__c,
               providerId: parseInt(newParam1.IDN_PROVR__c),
               countyCode: newParam1.CDE_COUNTY__c,
               cr107Checklist: newParam1.CR107_Checklist__c ? newParam1.CR107_Checklist__c.join(';'): '',
               cr107Other: newParam1.CR107_OTHER_TEXT__c,
               cr702Checklist: newParam1.CR702_Checklist__c ? newParam1.CR702_Checklist__c.join(';'): '',
               cr702Text: newParam1.CR702_TEXT__c,
               //dteOfDeadline: this.manualchecklist.DTE_DEADLINE__c ? this.manualchecklist.DTE_DEADLINE__c  : this.manualchecklist.DTE_702DEADLINE__c,
               dteOfDeadline: this.manualchecklist.DTE_DEADLINE__c ? this.manualchecklist.DTE_DEADLINE__c : (this.manualchecklist.DTE_702DEADLINE__c ? this.manualchecklist.DTE_702DEADLINE__c : ''),
               clientId: newParam1.IDN_CLIENT__c,
               adjustmentId: newParam1.IDN_ADJMT__c,
               cr212checklist: newParam1.CR212_Checklist__c ?newParam1.CR212_Checklist__c.join(';'): '',
               DQBeginDate: newParam1.Disqualification_Begin_Date__c,
               DQEndDate: newParam1.Disqualification_End_Date__c,
               DQHearingDate: newParam1.Disqualification_Hearing_Date__c,
               numOfOccurrences: numOfOccurrencesString,
               ContactPhoneNumber: newParam1.Contact_Phone_Number__c};
        helper.callServer(this, 'ManualCorrespondenceController', 'processManualCorspd',(function(response){
            if(response){
                if (response.isSuccessful) {
                    try{
                        this.responseCorspd = response.objectData.corrId;
                        this.callManualWebservice();
                    } catch (error) {
                        this.toggleSpinner = false;
                        this.toastMessage('Error', 'Error in creating the Manual Correspondence Request');
                        this.isDisableTrue = false; // Reset disable flag
                        console.error('Error in callProcessManualCorr:', error);
                    }
                } else {
                    this.toggleSpinner = false;
                    this.toastMessage('Error', response.errorMessage);
                    this.isDisableTrue = false; // Reset disable flag
                }
            }
        }).bind(this),JSON.stringify(params));
    }

       callManualWebservice(){
               this.toggleSpinner = true;
               const corrSfid = this.responseCorspd;
               const newParam1 = this.param;
               let params =  { corrSfid: corrSfid,
               provdrId: newParam1.IDN_PROVR__c,
               casId: newParam1.IDN_CASE__c}
               helper.callServer(this, 'ManualCorrespondenceController','getManualCorspdDetails',(function(response){
                   try{
                       if (response) {
                           const path = JSON.stringify(response.path);
                           const fileName = JSON.stringify(response.fileName);
                           var path1 = path.slice(1, -1);
                           var fileName1 = fileName.slice(1, -1);
                           var labelUrl = correspondenceTargetPdfServlet;
                           var url = labelUrl + 'pathInAws=' + path1 + '&fileName=' + fileName1;
                           this.generated = 'success';
                           //generated='success';
                           var pdfWin= window.open("/apex/CorrespondencePage?fileName="+fileName1, "", "height=650,width=840");
                       } else {
                           this.toggleSpinner=false;
                           this.toastMessage('Error', 'AEM Service Exception - Failed to retrieve response from AEM Service');
                       }
                   } catch (error) {
                       console.error('Error in callManualWebservice:', error);
                       this.toggleSpinner = false;
                       this.toastMessage('Error', 'Exception occurred in Get Manual Correspondence Details Method');
                   } finally {
                       this.toggleSpinner = false; 
                   }
                   if (this.timeoutId) {
                    clearTimeout(this.timeoutId);
                }
                   this.timeoutId=setTimeout(() => {
                       if (this.generated === 'success') {
                           this.manualPrintMove(corrSfid);
                       }
                   }, 7000);
           
                   // Reset component state if successful
                   if (this.generated === 'success') {
                       //this.isOpen = false;
                       this.childAttr = false;
                       this.isDisableTrue = false; // Reset disable flag
                   }
               }).bind(this),JSON.stringify(params)); 
       }
   
   
       manualPrintMove(corrSfid){
               let params= { corrSfid: corrSfid};
               helper.callServer(this, 'ManualCorrespondenceController','processManualCorspdPrint', (function(response){
   try{
   if (response) {
       if (response.returnStatus !== 'Success') {
           this.toastMessage('Warning','The record you selected to print has failed due to web service unavailability. Please try again after sometime');
           this.isDisableTrue = false; // Reset disable flag
       } else {
           this.toastMessage('Success', 'Success');
       }
       this.handleNo();       // Close modal
       this.childAttr = false; // Reset child attribute
   } else {
       this.toastMessage('Warning','The record you selected to print has failed due to web service unavailability. Please try again after sometime');
       this.isDisableTrue = false; // Reset disable flag
   }
} catch (error) {
   console.error('Error in manualPrintMove:', error);
   this.isDisableTrue = false; // Reset disable flag
}
if(this.timeoutId){
    clearTimeout(this.timeoutId);
}
}).bind(this),JSON.stringify(params));
       }
       }