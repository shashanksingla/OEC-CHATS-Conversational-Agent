/**
* @Component Name   : ACSES_InformationCalloutTest
* @Developed By     : Gaurav Trivedi
* @Created Date     : May 14, 2018 
* @Description      : Test class for ACSES_InformationCallout
*					  to test Webservice call from TRAILS database
* *****************************************************************************************************
*										Modification Log
* ***************************************************************************************************
* 	Name				|	Version		|		Date		|					Discription
* ***************************************************************************************************
*						|				|					|	
*
*/
@isTest
global class ACSES_InformationCalloutTest implements WebServiceMock {
    static String stateId = 'Y203120';
    global void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {
        ACSES_Trails_WebService.GetCPFiscalDataResponse_element cpFiscalResponse = new ACSES_Trails_WebService.GetCPFiscalDataResponse_element();
        List<ACSES_Trails_WebService_Fiscal.CustodialParentFiscalDataType> cpFiscalDataList = new List<ACSES_Trails_WebService_Fiscal.CustodialParentFiscalDataType>();
        cpFiscalDataList.add(custodialParentData());
        cpFiscalResponse.CPFiscal = cpFiscalDataList;
        response.put('response_x', cpFiscalResponse);
        //Expense
        ACSES_Trails_WebService.GetNCPFiscalDataResponse_element ncpFiscalResponse = new ACSES_Trails_WebService.GetNCPFiscalDataResponse_element();
        ncpFiscalResponse.NCPFiscal = ncpFiscalData();
        childpaymentData();
        cfData();
    }
    public ACSES_Trails_WebService_Fiscal.CustodialParentFiscalDataType custodialParentData(){
        ACSES_Trails_WebService_Fiscal.CustodialParentFiscalDataType cpf = new ACSES_Trails_WebService_Fiscal.CustodialParentFiscalDataType();
        List<ACSES_Trails_WebService_Fiscal.DisbursementType> disbursementList = new List<ACSES_Trails_WebService_Fiscal.DisbursementType>();
        List<ACSES_Trails_WebService_Fiscal.FiscalChildType> childList = new List<ACSES_Trails_WebService_Fiscal.FiscalChildType>();
        childList.add(fiscalChildType());
        disbursementList.add(disbursementType());
        cpf.Disbursement = disbursementList;
        cpf.CustodialParent = fiscalCustodialParent();
        cpf.Child = childList;
        cpf.NonCustodialParent = fncpType();
        return cpf;
    }
    public ACSES_Trails_WebService_Fiscal.NonCustodialParentFiscalDataType ncpFiscalData(){
        ACSES_Trails_WebService_Fiscal.NonCustodialParentFiscalDataType n = new ACSES_Trails_WebService_Fiscal.NonCustodialParentFiscalDataType();
        List<ACSES_Trails_WebService_Fiscal.FiscalChildType> childList = new List<ACSES_Trails_WebService_Fiscal.FiscalChildType>();
        List<ACSES_Trails_WebService_Fiscal.PaymentType> paymentList = new List<ACSES_Trails_WebService_Fiscal.PaymentType>();
        paymentList.add(paymentType());
        childList.add(fiscalChildType());
        n.NonCustodialParent = fncpType();
        n.Child = childList;
        n.PaymentFreq = 'M';
        n.MonthlySupAmtChild = '76.0';
        n.LegalDocketNum = 'D0162009DR000024';
        n.CommenceDate = '2018-05-14';
        n.AgencyTransType = 'T';
        n.LumpSumamt = '87.0';
        n.Payment = paymentList;
        return n;
    }
    public ACSES_Trails_WebService_Fiscal.PaymentType paymentType(){
        ACSES_Trails_WebService_Fiscal.PaymentType payment = new ACSES_Trails_WebService_Fiscal.PaymentType();
        payment.Transaction_x = financialType();
        payment.commenceDate = System.today();
        payment.childFirstName = 'childFirstName'; //new String[]{'Gaurav', 'Gaurav'};
        payment.childLastName = 'childLastName';   //new String[]{'Trivedi', 'Trivedi'};
        payment.cpStateId = stateId;
        payment.legalDocketNumber = 'D0162009DR000024';
        payment.childStateId = 'Y203121'; //new String[]{stateId,'Y203121'};
        payment.monthlySupportAmtOrder = 56.0;
        payment.paymentFreq = 'M';
        return payment;
    }
    public ACSES_Trails_WebService_Fiscal.FiscalNonCustodialParentType fncpType(){
        ACSES_Trails_WebService_Fiscal.FiscalNonCustodialParentType f = new ACSES_Trails_WebService_Fiscal.FiscalNonCustodialParentType();
        f.Person = personInfo();
        return f;
    }
    public ACSES_Trails_WebService_Fiscal.FiscalChildType fiscalChildType(){
        ACSES_Trails_WebService_Fiscal.FiscalChildType f = new ACSES_Trails_WebService_Fiscal.FiscalChildType();
        f.Person = personInfo();
        return f;
    }
    public ACSES_Trails_WebService_Fiscal.FiscalCustodialParentType fiscalCustodialParent(){
        ACSES_Trails_WebService_Fiscal.FiscalCustodialParentType c = new ACSES_Trails_WebService_Fiscal.FiscalCustodialParentType();
        c.Person = personInfo();
        return c;
    }
    public ACSES_Trails_WebService_Fiscal.DisbursementTypeType disbursmentTypeType(){
        ACSES_Trails_WebService_Fiscal.DisbursementTypeType d = new ACSES_Trails_WebService_Fiscal.DisbursementTypeType();
        d.Code='NC';
        d.Description = 'NAFDC CUR';
        d.DisbursementAmtChild = '42.50';
        return d;
    }
    public ACSES_Trails_WebService_Fiscal.FinancialTransactionType financialType(){
        ACSES_Trails_WebService_Fiscal.FinancialTransactionType f = new ACSES_Trails_WebService_Fiscal.FinancialTransactionType();
        f.TransactionNumber = '162018022325464000101';
        f.Date_x = '2017-07-11';
        f.Amount = '46.0';
        f.TotalPaymAmt = 45.0;
        f.LumpSumPaym = 'N';
        return f;
    }
    public ACSES_Trails_WebService_Fiscal.DisbursementType disbursementType(){
        ACSES_Trails_WebService_Fiscal.DisbursementType d = new ACSES_Trails_WebService_Fiscal.DisbursementType();
        d.Transaction_x = financialType();
        d.Disbursement = disbursmentTypeType();
        d.MonthlySupAmtOrder = '140.00';
        d.CommenceDate = '2018-01-01';
        d.LegalDocketNum = 'D0162009DR000024';
        d.MonthlySupAmtChild = '152.00';
        d.PaymentFreq = 'M';
        return d;
    }
    public ACSES_Trails_WebService_Person.PersonType personInfo(){
        ACSES_Trails_WebService_Person.PersonType person = new ACSES_Trails_WebService_Person.PersonType();
        ACSES_Trails_WebService_Person.PersonNameType name = new ACSES_Trails_WebService_Person.PersonNameType();
        person.DateOfBirth = '2010-10-10';
        person.MaritalStatus = '';
        person.Race = 'Indian';
        person.SocialSecurityNumber = '555555555';
        person.StateID = stateId;
        name.FirstName = 'Gaurav';
        name.LastName = 'Trivedi';
        name.MiddleName = '';
        name.SuffixName = '';
        person.Name = name;
        return person;
    }
    public ACSES_Trails_WebService_Fiscal.ChildPaymentDataType childpaymentData(){
        ACSES_Trails_WebService_Fiscal.ChildPaymentDataType c = new ACSES_Trails_WebService_Fiscal.ChildPaymentDataType();
        List<ACSES_Trails_WebService_Fiscal.NonCustodialParentFiscalDataType> ncpDataList = new List<ACSES_Trails_WebService_Fiscal.NonCustodialParentFiscalDataType>();
        ncpDataList.add(ncpFiscalData());
        c.ncpFiscalDataType = ncpDataList;
        return c;
    }
    public ACSES_Trails_WebService_Fiscal.ChildFiscalDataType cfData(){
        ACSES_Trails_WebService_Fiscal.ChildFiscalDataType cfData = new ACSES_Trails_WebService_Fiscal.ChildFiscalDataType();
        List<ACSES_Trails_WebService_Fiscal.CustodialParentFiscalDataType> cpfDataList = new List<ACSES_Trails_WebService_Fiscal.CustodialParentFiscalDataType>();
        cpfDataList.add(custodialParentData());
        cfData.custodialParentFiscalData = cpfDataList;
        return cfData;
    }

    @isTest static void incomeTest() {
        Test.setMock(WebServiceMock.class, new ACSES_InformationCalloutTest());
        String output = ACSES_InformationCallout.callACSES('Income',stateId,'2018-11-11');
        system.assert(output.length()>0,'output cannot be null');
    }
    @isTest static void expenseTest() {
        Test.setMock(WebServiceMock.class, new ACSES_InformationCalloutTest());
        try {
            String output = ACSES_InformationCallout.callACSES('Expense', stateId, '2018-11-11');
            system.assert(output.length()>0,'output cannot be null');system.assert(output.length()>0,'output cannot be null');
        }catch (Exception e){}
    }
    @isTest static void parentStateIdToNameMap(){
        T_COUNTY__c county = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c cases = TestClassUtility.createCase(true, county.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, System.today().addYears(-18), 'firstName','1', 'lastName','989898989','CC');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, cases.Id, individual.Id,true);
        system.assertEquals(true,string.valueOf(ACSES_InformationCallout.parentStateIdToNameMap(cases.Id)).contains(individual.Id),'Should have client Id');
    }
}