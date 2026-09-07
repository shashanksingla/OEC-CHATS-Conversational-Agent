({
	monthAverageCalculator : function(cmp,obj,type) {
        try{
            var calculatedAmount= [];
            var endDate = cmp.get("v.endDate") ? cmp.get("v.endDate"): new Date();
            var first3Month, first6Month, first9Month, first12Month;
            var first3MonthAmount = 0, first6MonthAmount = 0, first9MonthAmount = 0, first12MonthAmount = 0;
            if(obj){
                this.sortDesc('FinancialDateSort',obj);
                obj.forEach(function(amt){
                    if(amt.FinancialDate){
                        var financialDateParse = Date.parse(amt.FinancialDate);
                        //First 90 Days data
                        first3Month = new Date(endDate);
                        first3Month.setDate(first3Month.getDate()-90);
                        var first3MonthParse = Date.parse(first3Month);
                        if(financialDateParse >= first3MonthParse){
                            first3MonthAmount += parseFloat(amt.Amount);
                        }
                        //First 180 days data
                        first6Month = new Date(endDate);
                        first6Month.setDate(first6Month.getDate()-180);
                        var first6MonthParse = Date.parse(first6Month);
                        if(financialDateParse >= first6MonthParse){
                            first6MonthAmount += parseFloat(amt.Amount);
                        }
                        //First 270 days data
                        first9Month = new Date(endDate);
                        first9Month.setDate(first9Month.getDate()-270);
                        var first9MonthParse = Date.parse(first9Month);
                        if(financialDateParse >= first9MonthParse){
                            first9MonthAmount += parseFloat(amt.Amount);
                        }
                        //First 365 days data
                        first12Month = new Date(endDate);
                        first12Month.setDate(first12Month.getDate()-365);
                        var first12MonthParse = Date.parse(first12Month);
                        if(financialDateParse >= first12MonthParse){
                            first12MonthAmount += parseFloat(amt.Amount);
                        }
                    }
                });
            }
            if(first3MonthAmount || first3MonthAmount === 0)
                calculatedAmount.push(first3MonthAmount);
            if(first6MonthAmount || first6MonthAmount === 0)
                calculatedAmount.push(first6MonthAmount);
            if(first9MonthAmount || first9MonthAmount === 0)
                calculatedAmount.push(first9MonthAmount);
            if(first12MonthAmount || first12MonthAmount === 0)
                calculatedAmount.push(first12MonthAmount);
            cmp.set("v.trxAmt",calculatedAmount);
        }catch(e){
            this.errorChecker(cmp,['Oops! error while calculating month average. '+e]);
        }
    },
    sortDesc: function(field, records) {
        var sortAsc = false;
        records.sort(function(a,b){
            var t1 = a[field] == b[field],
                t2 = a[field] > b[field];
            return t1? 0: (sortAsc?-1:1)*(t2?-1:1);
        });
    },
    sendACSESRequest: function(cmp){
        this.resetAllAttributes(cmp);
        var otherError, payment,ncpData,cpData,expenseChildInfoList;
        var parentStateId = cmp.get("v.parentStateId");
        var supportType = cmp.get("v.supportType");
        var endDate = cmp.get("v.endDate");
        var action = cmp.get("c.callACSES");
        action.setParams({ "supportType" : supportType,"parentId": parentStateId, "endDate": endDate});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resp = JSON.parse(response.getReturnValue());
                this.setColumnsforAllTable(cmp);
                if(resp){
                    cmp.set("v.resultFlag",true);
                    if(supportType === "Expense"){
                        cmp.set('v.incomeFlag',false);
                        if(resp.Payment){
                            payment = this.paymentObjectCreation(resp.Payment);
                            cmp.set("v.expenseInfo",payment);
                            this.checkIncome(cmp);
			    
			    //Changes to get the child information from Expense Response
                            expenseChildInfoList = this.getChildInfoFromPayment(resp.Payment);
                            cmp.set("v.childInfo",expenseChildInfoList);
                        }if(resp.NonCustodialParent){
                            ncpData = this.transformNcpResult(resp.NonCustodialParent);
                            cmp.set("v.nonCustodialParent",ncpData);
				//if(ncpData.child)
                                //cmp.set("v.childInfo",ncpData.child);
                        }
		}else if(supportType === "Income"){
                        cmp.set('v.incomeFlag',true);
                        cpData = this.transformCPResult(cmp,resp);
                        if(cpData){
                            if(cpData.payment){
                                cmp.set("v.incomeInfo",cpData.payment);
                                this.checkIncome(cmp);
                            }if(cpData.custodialParent)
                                cmp.set("v.custodialParent",cpData.custodialParent);
                            if(cpData.ncp)
                                cmp.set("v.nonCustodialParent",cpData.ncp);
                            if(cpData.child)
                                cmp.set("v.childInfo",cpData.child);
                        }
                    }
                }else{
                    otherError = ['Oops!! We didn\'t receive any result from ACSES.'];
                }
            }else if (state === "ERROR")
                this.errorChecker(cmp,response.getError());
            else
                otherError = ['Oops!! there is some problem with you request. Please try again or contact your administrator.'];

            if(otherError)
                this.errorChecker(cmp,otherError);

            cmp.set("v.toggleSpinner", false);
        });
        $A.enqueueAction(action);
    },
    checkIncome : function(cmp){
        cmp.set("v.sortAsc", true);
        if(cmp.get("v.supportType") == 'Income'){
            cmp.set("v.incomeFlag",true);
            this.monthAverageCalculator(cmp,cmp.get("v.incomeInfo"),"v.incomeInfo");
        }else{
            cmp.set("v.incomeFlag",false);
            this.monthAverageCalculator(cmp,cmp.get("v.expenseInfo"),"v.expenseInfo");
        }
    },
    errorChecker: function(cmp, errors){
        var errMsg = [];
        cmp.set("v.message","error");
        cmp.set("v.resultFlag",false);
        cmp.set("v.toggleSpinner", false);
        if(errors){
            errors.forEach(function(err){
                if(err.message)
                    errMsg.push(err.message);
                else
                    errMsg.push(err);
            });
            if(errMsg)
                cmp.set("v.recordError",errMsg);
        }else{
            cmp.set("v.recordError","There is an unknown problem. Please contact your administrator.");
        }
    },
    setColumnsforAllTable : function(cmp){
        cmp.set('v.cpColumns', [
            {label: 'Parent ID', type: 'string', fieldName: 'stateId'},
            {label: 'First Name', type: 'string', fieldName: 'firstName'},
            {label: 'Middle Initial', type: 'string', fieldName: 'middleName'},
            {label: 'Last Name', type: 'string', fieldName: 'lastName'},
            {label: 'Date of Birth', type: 'date', fieldName: 'dateOfBirth'},
            {label: 'Marital Status', type: 'string', fieldName: 'maritalStatus'},
            {label: 'Race', type: 'string', fieldName: 'race'},
            {label: 'SSN', type: 'string', fieldName: 'ssn'}
        ]);
        cmp.set('v.ncpColumns', [
            {label: 'First Name', type: 'string', fieldName: 'firstName'},
            {label: 'Last Name', type: 'string', fieldName: 'lastName'},
            {label: 'Date of Birth', type: 'date', fieldName: 'dateOfBirth'},
            {label: 'Marital Status', type: 'string', fieldName: 'maritalStatus'},
            {label: 'State Id', type: 'string', fieldName: 'stateId'},
            {label: 'Race', type: 'string', fieldName: 'race'},
            {label: 'SSN', type: 'integer', fieldName: 'ssn'}
        ]);
        cmp.set('v.childColumns',[
            {label: 'Child Name', type: 'string', fieldName: 'firstName'},
            {label: 'Child Date of Birth', type: 'date', fieldName: 'dateOfBirth'},
            {label: 'Child State ID', type: 'string', fieldName: 'stateId'},
            {label: 'Child SSN', type: 'string', fieldName: 'ssn'},
            {label: 'Child Race', type: 'string', fieldName: 'race'}
        ]);
        cmp.set('v.incomeColumns', [
            {label: 'Disbursement Type', type: 'string', fieldName: 'Description'},
            {label: 'Legal Docket Number', type: 'integer', fieldName: 'legalDocketNumber'},
            {label: 'Commencement Date', type: 'date', fieldName: 'commenceDate'},
            {label: 'Transaction Number', type: 'integer', fieldName: 'TransactionNumber'},
            {label: 'Transaction Date', type: 'date', fieldName: 'FinancialDate'},
            {label: 'Transcation Amount', type: 'currency', typeAttributes: { currencyCode: 'USD'}, fieldName: 'Amount'},
            {label: 'MSO Amount', type: 'currency', typeAttributes: { currencyCode: 'USD'}, fieldName: 'monthlySupportAmtOrder'},
            {label: 'Payment Frequency', type: 'integer', fieldName: 'paymentFreq'},
            {label: 'Lump Sum Indicator', type: 'integer', fieldName: 'LumpSumPaym'}
        ]);
        cmp.set('v.expenseColumns', [
            {label: 'Legal Docket Number', type: 'integer', fieldName: 'legalDocketNumber'},
            {label: 'Commencement Date', type: 'date', fieldName: 'commenceDate'},
            {label: 'Transaction Number', type: 'integer', fieldName: 'TransactionNumber'},
            {label: 'Transaction Date', fieldName: 'FinancialDate', type: 'date'},
            {label: 'Transcation Amount', type: 'currency', typeAttributes: { currencyCode: 'USD'}, fieldName: 'Amount'},
            {label: 'MSO Amount', type: 'currency', typeAttributes: { currencyCode: 'USD'}, fieldName: 'monthlySupportAmtOrder'},
            {label: 'Payment Frequency', type: 'integer', fieldName: 'paymentFreq'},
            {label: 'Lump Sum Indicator', type: 'integer', fieldName: 'LumpSumPaym'}
        ]);
    },
    paymentObjectCreation: function(payment){
        var paymnt = [];
        payment.forEach(function(pay){
            var pmt = {};
            pmt.legalDocketNumber = pay.legalDocketNumber? pay.legalDocketNumber: pay.LegalDocketNum;
            pmt.commenceDate = pay.commenceDate? pay.commenceDate: pay.CommenceDate;
            pmt.commenceDate = $A.localizationService.formatDate(pmt.commenceDate);
            pmt.TransactionNumber = pay.Transaction_x.TransactionNumber;
            pmt.FinancialDate = $A.localizationService.formatDate(pay.Transaction_x.Date_x);
            pmt.FinancialDateSort = pay.Transaction_x.Date_x;
            pmt.Amount = pay.Transaction_x.Amount;
            pmt.monthlySupportAmtOrder = pay.monthlySupportAmtOrder?pay.monthlySupportAmtOrder:pay.MonthlySupAmtOrder;
            pmt.paymentFreq = pay.paymentFreq?pay.paymentFreq:pay.PaymentFreq;
            pmt.LumpSumPaym = pay.Transaction_x.LumpSumPaym;
            pmt.Description = pay.Disbursement && pay.Disbursement.Description?pay.Disbursement.Description:'';
            paymnt.push(pmt);
        });
        return paymnt;
    },
	
    getChildInfoFromPayment: function(payment){
        var childInfo = [];
        var tempStoreFirstName = [];
        payment.forEach(function(pay1){
            if(tempStoreFirstName.length > 0){
                if(!tempStoreFirstName.includes(pay1.childStateId)){
                    var chld = {};
            		chld.firstName = pay1.childFirstName;
            		chld.dateOfBirth = $A.localizationService.formatDate(pay1.childDateOfBirth);
            		chld.stateId = pay1.childStateId;
            		chld.ssn = pay1.childSSN;
            		chld.race = pay1.childRace;
                    
                    tempStoreFirstName.push(pay1.childStateId);
                    childInfo.push(chld);
                }
            } else {
                var chld = {};
            	chld.firstName = pay1.childFirstName;
            	chld.dateOfBirth = $A.localizationService.formatDate(pay1.childDateOfBirth);
            	chld.stateId = pay1.childStateId;
            	chld.ssn = pay1.childSSN;
            	chld.race = pay1.childRace;
                    
                tempStoreFirstName.push(pay1.childStateId);
                childInfo.push(chld);
                
            }
        });
        return childInfo;
    },
    
    transformNcpResult: function(n){
        var arrayObj = [];
        var ncpObj = {};
        ncpObj.firstName = n.Person.Name.FirstName;
        ncpObj.lastName = n.Person.Name.LastName;
        if(n.Person.DateOfBirth){
        	ncpObj.dateOfBirth = $A.localizationService.formatDate(n.Person.DateOfBirth);    
        }
        ncpObj.ssn = n.Person.SocialSecurityNumber;
        ncpObj.maritalStatus = n.Person.MaritalStatus;
        ncpObj.race = n.Person.Race;
        ncpObj.stateId = n.Person.StateID;
        arrayObj.push(ncpObj)
        return arrayObj;
    },
    resetAllAttributes: function(cmp){
        cmp.set("v.expenseInfo",'');
        cmp.set("v.nonCustodialParent",'');
        cmp.set("v.trxAmt",null);
	cmp.set("v.childInfo",null);
    },
    transformCPResult: function(cmp, cp){
        try{
            var cData = {};
            cData.payment = [];
            var paymentArray = [],custodialParent = [], childs = [], ncp = [], childInfo = [];
            cp.forEach(function(c){
                if(c.Disbursement){
                    paymentArray = c.Disbursement.reduceRight(function(c, i){
                        c.unshift(i);
                        return c;
                    },paymentArray);
                }if(c.CustodialParent && c.CustodialParent.Person){
                    custodialParent.push(c.CustodialParent.Person);
                }
                if(c.NonCustodialParent && c.NonCustodialParent.Person){
                    ncp.push(c.NonCustodialParent.Person);
                }
                if(c.Child){
                    childs = c.Child.reduceRight(function(c, i){
                        c.unshift(i);
                        return c;
                    },childs);
                    if(childs){
                        childs.forEach(function(ch){
                        	if(ch.Person){
                        		childInfo.push(ch.Person);
                        	}
                        });
                    }
                }
            });
            if(custodialParent)
                cData.custodialParent = this.getPerson(this.deduplicate(custodialParent,"StateID"));
            if(ncp)
                cData.ncp = this.getPerson(this.deduplicate(ncp,"StateID"));
            if(childInfo && childInfo[0] != null)
                cData.child = this.getPerson(this.deduplicate(childInfo,"StateID"));
            if(paymentArray)
                cData.payment = this.paymentObjectCreation(paymentArray);
            return cData;
        }catch(e){
            this.errorChecker(cmp,['Oops! error while transforming custodial parent information. '+e]);
        }
    },
    getPerson : function(person){
        var personInfo = [];
        person.forEach(function(pa){
            var prnt = {};
            prnt.stateId = pa.StateID;
            if(pa.Name){
                prnt.firstName = pa.Name.FirstName? pa.Name.FirstName:'';
                prnt.lastName = pa.Name.LastName? pa.Name.LastName:'';
                prnt.middleName = pa.Name.MiddleName? pa.Name.MiddleName:'';
            }
            prnt.dateOfBirth = $A.localizationService.formatDate(pa.DateOfBirth);
            prnt.maritalStatus = pa.MaritalStatus;
            prnt.ssn = pa.SocialSecurityNumber;
            prnt.race = pa.Race;
            personInfo.push(prnt);
        });
        return personInfo;
    },
    deduplicate: function (array, prop) {
        return Array.from(new Map(array.map(i => [(prop in i) ? i[prop] : i, i])).values());
    }
})