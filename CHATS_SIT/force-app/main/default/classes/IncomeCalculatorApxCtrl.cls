public with sharing class IncomeCalculatorApxCtrl implements IRequest {
    
    public String jsonParam;
    private static Map<String, Object > requestObj;
    
    public Object processRequest(String methodName, String jsonParam) {
        Object response = new LightningServerResponse(true,'',new Map<String,Object>());
        this.jsonParam = jsonParam;
        
        if(jsonParam!=null){
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);
        }
        if (methodName == 'getFPGValues') {
            response = getFPGValues();
        }else if(methodName == 'getCountyData'){
            response = getCountyData(Integer.valueOf(requestObj.get('county')));
        }else if(methodName == 'parentFeeDataAll'){
            response = parentFeeDataAll((Decimal)requestObj.get('annualIncome'),Decimal.valueOf(getMapValue('inputFPG')),Integer.valueOf(requestObj.get('noOfChildReq')),Integer.valueOf(requestObj.get('county')),Integer.valueOf(requestObj.get('familySize')));
        }
        return response;
    }
    private static String getMapValue(string fieldName){
        return (String)requestObj.get(fieldName);
    }
    @AuraEnabled
    public static LightningServerResponse getCountyData(Integer county){
        Map<String, Object> objectData = new map<String, Object>();
        //Removed unused variable on 5/13/2018 BG  
        String message;
        // Double vale = county;
        List<T_COUNTY_PLAN__c> countyPlans = [SELECT DTE_BEGIN_EFFEV__c, DTE_END_EFFEV__c, ELIGIBILITY_Q1_1__c, Id, Name FROM T_COUNTY_PLAN__c
                                              WHERE CDE_COUNTY__r.CDE_COUNTY__c =:county
                                              AND  DTE_BEGIN_EFFEV__c <= Today
                                              AND  (DTE_END_EFFEV__c >= Today OR DTE_END_EFFEV__c = NULL) LIMIT 1];
        if(!countyPlans.isEmpty()){
            objectData.put('data', countyPlans.get(0));
        }
        return new LightningServerResponse(true, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getFPGValues(){
        Map<String, Object> objectData = new map<String, Object>();
        List<APXInputPicklistCtrl.PicklistEntryDefinition> picklistValues = APXInputPicklistCtrl.getPicklistValues('Field_Utility__c', 'R00393__c');
        Decimal c1=0, c2=0;
        for(APXInputPicklistCtrl.PicklistEntryDefinition ple : picklistValues){
            if(ple.value == '1'){
                c1 = Decimal.valueOf(ple.label);
            }
            if(ple.value == 'ADD'){
                c2 = Decimal.valueOf(ple.label);
            }
        }
        objectData.put('c1', c1);
        objectData.put('c2', c2);
        return new LightningServerResponse(true, null, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse parentFeeDataAll(Decimal annualIncome, Decimal inputFPG, integer noOfChildReq, Integer county, Integer familySize){
        Map<String, Object> objectData = new map<String, Object>();
        Decimal fullTimeFee;
        Decimal partTimeFee;
        Boolean isCalculationDone = false;
        //change from 205 to 115 for CCCAP-1341 Executive order
        Decimal fpg205 = 115;
        //Decimal inputFPG = Decimal.valueOf(fpg);
        //Removed unused variable on 5/13/2018 BG  
        String message;
        Decimal SMIPercent;
        Decimal baseParentFee;
        /*
        for(batchsit_t_copay_calculation__x copay : [Select id,percentage_min_value__c,percentage_max_value__c,idn_calc_copay__c,amt_fee_base_parent__c,amt_addon__c
                                                     from batchsit_t_copay_calculation__x where percentage_min_value__c=:inputFPG ]){
                                                         isCalculationDone=true;
                                                         fullTimeFee = Math.floor(((annualIncome/12)*(copay.amt_fee_base_parent__c/100))+((noOfChildReq -1)*(copay.amt_addon__c)));
                                                         objectData.put('fullTimeFee',fullTimeFee);
                                                         objectData.put('addOnFee',copay.amt_addon__c);
                                                         objectData.put('baseParentFee',copay.amt_fee_base_parent__c);
                                                         break;
                                                         
                                                     }
        if(!isCalculationDone){
            if(inputFPG >115){
                for(batchsit_t_copay_calculation__x copay : [Select id,percentage_min_value__c,percentage_max_value__c,idn_calc_copay__c,amt_fee_base_parent__c,amt_addon__c
                                                             from batchsit_t_copay_calculation__x where percentage_min_value__c=:fpg205 ]){
                                                                 fullTimeFee = Math.floor(((annualIncome/12)*(copay.amt_fee_base_parent__c/100))+((noOfChildReq -1)*(copay.amt_addon__c)));
                                                                 objectData.put('fullTimeFee',fullTimeFee);
                                                                 objectData.put('addOnFee',copay.amt_addon__c);
                                                                 objectData.put('baseParentFee',copay.amt_fee_base_parent__c);
                                                                 break;
                                                                 
                                                             }
            }else{
                for(batchsit_t_copay_calculation__x copay : [Select id,percentage_min_value__c,percentage_max_value__c,idn_calc_copay__c,amt_fee_base_parent__c,amt_addon__c
                                                             from batchsit_t_copay_calculation__x where   percentage_max_value__c >=: inputFPG and percentage_min_value__c <: inputFPG]){
                                                                 fullTimeFee = Math.floor(((annualIncome/12)*(copay.amt_fee_base_parent__c/100))+((noOfChildReq -1)*(copay.amt_addon__c)));
                                                                 objectData.put('fullTimeFee',fullTimeFee);
                                                                 objectData.put('addOnFee',copay.amt_addon__c);
                                                                 objectData.put('baseParentFee',copay.amt_fee_base_parent__c);
                                                                 break;
                                                                 
                                                             }
            }
            
        }
		*/
        Integer FPIGConstant1;
        Integer FPIGConstant2;
        Integer FPIGIncome;
        Decimal FPIGPercent;
        Schema.DescribeFieldResult fieldResult = Field_Utility__c.R00393__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f : ple){
            if(f.getValue() == '1'){
                FPIGConstant1 = Integer.valueOf(f.getLabel());
            }
            if(f.getValue() == 'ADD'){
                FPIGConstant2 = Integer.valueOf(f.getLabel());
            }
        }
        FPIGIncome = FPIGConstant1+((familySize-1)*FPIGConstant2);
        FPIGPercent = ((annualIncome/FPIGIncome)*100);
        // below changes to be effective from 08/01/2026 , for CCCAP-13258
        Boolean pfChangeEffective = Date.today() >= Date.valueOf(system.label.Parent_Fee_Formula_Change);
        if(pfChangeEffective == true){
              FPIGPercent = FPIGPercent.setScale(3,RoundingMode.DOWN); 
            //modified parent Fee calculation logic & commented add on Fee as per CCCAP-13258
            if (inputFPG <= 100)
            {
                baseParentFee = (annualIncome * 0.01) / 12;
                baseParentFee = baseParentFee.setScale(0, RoundingMode.DOWN);
                fullTimeFee = baseParentFee;
                // objectData.put('addOnFee', 0);
            } 
            else if (inputFPG > 100 && inputFPG <= 130)
            {
                Decimal extra1 = (annualIncome >= FPIGIncome) ? (annualIncome - FPIGIncome) : 0;
                baseParentFee = ((annualIncome * 0.01) + (extra1 * 0.02));
                baseParentFee = baseParentFee/12;
                baseParentFee = baseParentFee.setScale(0, RoundingMode.DOWN); //Math.floor((annualIncome * 0.01 +(annualIncome- FPIGIncome)*(0.14))/12);
                fullTimeFee = baseParentFee; //Math.floor((annualIncome *0.01 +(annualIncome- FPIGIncome)*(0.14))/12 +(noOfChildReq -1)*15);
                //Integer addOnFee = (noOfChildReq -1)*15;
                //objectData.put('addOnFee',addOnFee);
            }
            else if (inputFPG > 130 && inputFPG <= 160)
            {
                Decimal extra1 = (annualIncome >= FPIGIncome) ? (annualIncome - FPIGIncome) : 0;
                Decimal extra2 = (annualIncome > (1.3 * FPIGIncome)) ? (annualIncome - (1.3 * FPIGIncome)) : 0;
                baseParentFee = (annualIncome * 0.01 + extra1 * 0.02 + extra2 * 0.02) / 12;
                baseParentFee = baseParentFee.setScale(0, RoundingMode.DOWN);
                fullTimeFee = baseParentFee; 
            }
            else if (inputFPG > 160 && inputFPG <= 1000)
            {
                Decimal extra1 = (annualIncome >= FPIGIncome) ? (annualIncome - FPIGIncome) : 0;
                Decimal extra2 = (annualIncome > (1.3 * FPIGIncome)) ? (annualIncome - (1.3 * FPIGIncome)) : 0;
                Decimal extra3 = (annualIncome > (1.6 * FPIGIncome)) ? (annualIncome - (1.6 * FPIGIncome)) : 0;
                baseParentFee = (annualIncome * 0.01 + extra1 * 0.02 + extra2 * 0.02 + extra3 * 0.02) / 12;
                baseParentFee = baseParentFee.setScale(0, RoundingMode.DOWN);
                fullTimeFee = baseParentFee;
            }else{
                baseParentFee = 0;
                fullTimeFee = 0;
            }
        }else{
            FPIGPercent = FPIGPercent.setScale(3);
            if(inputFPG <= 100){
                baseParentFee = Math.floor((annualIncome*0.01)/12); // (Base Parent Fee = Annual Income * 0.01 / 12)
                objectData.put('addOnFee',0);
                fullTimeFee = baseParentFee; // (Fulltime Fee = Base Parent Fee + Addon)
            } else {
                fullTimeFee = Math.floor((annualIncome *0.01 +(annualIncome- FPIGIncome)*(0.14))/12 +(noOfChildReq -1)*15);
                baseParentFee = Math.floor((annualIncome * 0.01 +(annualIncome- FPIGIncome)*(0.14))/12);
                Integer addOnFee = (noOfChildReq -1)*15;
                objectData.put('addOnFee',addOnFee);
            }
        }
        if(fullTimeFee != null){
            partTimeFee = Math.floor((0.55)*(fullTimeFee));
        }
        objectData.put('baseParentFee', baseParentFee);
        objectData.put('fullTimeFee', fullTimeFee);
        objectData.put('partTimeFee', partTimeFee);
        objectData.put('FPIGPercent', FPIGPercent);
        objectData.put('FPIGIncome', FPIGIncome);
        Date todayDate = System.today();
        Date nullDate;
        Decimal countyMaxIncome;
        Map<String, Decimal> R000757Map = new Map<String, Decimal>();
        R00757__mdt[] metadataMap = [SELECT Label__c, Value__c,dte_start_effv__c,dte_end_effv__c FROM R00757__mdt];
        for(R00757__mdt mdt : metadataMap){
            if(mdt.dte_start_effv__c <= todayDate && (mdt.dte_end_effv__c >= todayDate || mdt.dte_end_effv__c == null)){
                R000757Map.put(mdt.Label__c, Decimal.valueOf(mdt.Value__c));
            }
        }
        if(R000757Map != NULL && R000757Map.size() > 0){
            if(familySize > 10){
                SMIPercent = R000757Map.get('10') + (familySize-10)*(R000757Map.get('Addon')*(R000757Map.get('SMIA')));
            }else{
                SMIPercent = R000757Map.get(String.valueOf(familySize))*(R000757Map.get('SMIA'));
            }
            SMIPercent = SMIPercent*(0.85);
            SMIPercent = SMIPercent.setScale(2);
            objectData.put('SMIPercent', SMIPercent);
        }
        if(county != null){
            List<T_COUNTY_PLAN__c> countyPlans = [SELECT DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c,ELIGIBILITY_Q1_1__c,Id,Name FROM T_COUNTY_PLAN__c 
                                                  WHERE CDE_COUNTY__r.CDE_COUNTY__c =:county
                                                  AND  DTE_BEGIN_EFFEV__c <= Today
                                                  AND  (DTE_END_EFFEV__c >= Today OR DTE_END_EFFEV__c = NULL) LIMIT 1];
            if(!countyPlans.isEmpty()){
                objectData.put('data', countyPlans.get(0));
                countyMaxIncome = (FPIGIncome * countyPlans.get(0).ELIGIBILITY_Q1_1__c)/100;
                objectData.put('countyMaxIncome', countyMaxIncome);
            } 
        }
        return new LightningServerResponse(true, message, objectData);
    }
}