@isTest
public class parentFeeDelinqcTest {
    
    static testmethod void parFeeTest(){
        List<T_COPAY_DELINQC__c> parentFeeTestList = new List<T_COPAY_DELINQC__c>();
        date d1 = date.newInstance(2017,11,05);
        date d2 = date.newInstance(2017,01,10);
        date d3 = date.newInstance(2017,02,15);
        T_COPAY_DELINQC__c pfList1 = new T_COPAY_DELINQC__c();
        T_COPAY_DELINQC__c pfList2 = new T_COPAY_DELINQC__c();
        T_COPAY_DELINQC__c pfList3 = new T_COPAY_DELINQC__c();
        T_COPAY_DELINQC__c pfList4 = new T_COPAY_DELINQC__c();
        T_COPAY_DELINQC__c pfList5 = new T_COPAY_DELINQC__c();
        T_COPAY_DELINQC__c pfList6 = new T_COPAY_DELINQC__c();
        T_COPAY_DELINQC__c pfList7 = new T_COPAY_DELINQC__c();
        T_COPAY_DELINQC__c pfList8 = new T_COPAY_DELINQC__c();
        T_COPAY_DELINQC__c pfList9 = new T_COPAY_DELINQC__c();
        pfList1.DTE_MONTH_DELINQC__c = '8';
        pfList1.DTE_RPTD_DELINQC__c = d1;
        parentFeeTestList.add(pfList1);
        
        pfList2.DTE_MONTH_DELINQC__c = '11';
        pfList2.DTE_RPTD_DELINQC__c = d1;
        pfList2.DTE_YEAR_DELINQC__c = '2016';
        parentFeeTestList.add(pfList2);
        
        //Feb date Validations
        pfList3.DTE_MONTH_DELINQC__c = '5';
        pfList3.DTE_RPTD_DELINQC__c = d3;
        parentFeeTestList.add(pfList3);
        
        pfList4.DTE_MONTH_DELINQC__c = '1';
        pfList4.DTE_RPTD_DELINQC__c = d3;
        pfList4.DTE_YEAR_DELINQC__c = '2016';
        parentFeeTestList.add(pfList4);
        
        pfList5.DTE_RPTD_DELINQC__c = d3;
        pfList5.DTE_YEAR_DELINQC__c = '2015';
        parentFeeTestList.add(pfList5);
        
        //Jan date Validations
        pfList6.DTE_MONTH_DELINQC__c = '4';
        pfList6.DTE_RPTD_DELINQC__c = d2;
        parentFeeTestList.add(pfList6);
        
        pfList7.DTE_MONTH_DELINQC__c = '1';
        pfList7.DTE_RPTD_DELINQC__c = d2;
        pfList7.DTE_YEAR_DELINQC__c = '2016';
        parentFeeTestList.add(pfList7);
        
        pfList8.DTE_RPTD_DELINQC__c = d2;
        pfList8.DTE_YEAR_DELINQC__c = '2015';
        parentFeeTestList.add(pfList8);
        
        pfList9.DTE_MONTH_DELINQC__c = '10';
        pfList9.DTE_RPTD_DELINQC__c = d1;
        pfList9.DTE_YEAR_DELINQC__c = '2017';
        pfList9.AMT_DELINQC_COPAY_ENRLMT__c = 1;
        
        test.startTest();
        insert pfList9;
        if(parentFeeTestList.size() > 0){
            //insert parentFeeTestList;
            parentFeeDelinquencyServices.delinqcMonthYear(parentFeeTestList);
        }
        System.assertEquals('8',parentFeeTestList[0].DTE_MONTH_DELINQC__c );
        test.stopTest();
    }
}