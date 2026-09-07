public class APXPolicyRecordsIfElseConditions {
    
    public static Object processRules(SObject sOb,String ruleTypeName){
        try{
	        Rule instance = (Rule)Type.forName(null,'APXPolicyRecordsIfElseConditions.'+ruleTypeName).newInstance();
            return instance.evaluateCondition(sOb);
        }catch(Exception ex){
            Map<String,Object> exceptionMap = new Map<String,Object>();
            exceptionMap.put('Class__c','APXPolicyRecordsIfElseConditions');    
            exceptionMap.put('Method__c','processRules');            
            ExceptionLoggingServices.captureExceptionLog(ex, exceptionMap);
            return true;
        }
    }
    
    public interface Rule{
        Object evaluateCondition(SObject sOb);
    }

    public class T_APPLN_EMPLMT_ADR_LINE_1_Rule implements Rule{
        public Object evaluateCondition(SObject sOb){
            System.debug('Executing T_APPLN_EMPLMT_ADR_LINE_1_Rule class');
            String ADR_LINE_1 = '', ADR_NAM = '';
            if(sOb.get('ADR_LINE_1__c')!=null){
                ADR_LINE_1 = String.valueOf(sOb.get('ADR_LINE_1__c'));
            }
            if(sOb.get('ADR_NAM__c')!=null){
                ADR_NAM = String.valueOf(sOb.get('ADR_NAM__c'));
            }
            String addressLine1 = String.isEmpty(ADR_LINE_1) || String.isEmpty(ADR_NAM)?ADR_LINE_1+ADR_NAM:ADR_NAM+' '+ADR_LINE_1;
            return addressLine1.length()>=35?addressLine1.substring(0,34):addressLine1;
        }
    }

    public class T_INDIV_DSBLTY_CDE_LENGTH_DSBLTY_Rule implements Rule{
        public Object evaluateCondition(SObject sOb){
            
            if(sOb.get('IND_YR_DSBL__c') =='Y' ){
                return true;
            }
            return false;
        }
    }

    public class T_APPLN_EDUC_CDE_TYPE_SCHOOL_Rule implements Rule{
        public Object evaluateCondition(SObject sOb){
            
			String schoolType = String.valueOf(sOb.get('CDE_TYPE_SCHOOL__c')), educSchoolType;
            if(schoolType=='02' || schoolType=='03'){
                educSchoolType = Label.CDE_TYPE_SCHOOL_PSL;
            }else if(schoolType=='04'){
                educSchoolType = Label.CDE_TYPE_SCHOOL_JST;
            }else if(schoolType=='05' || schoolType=='07'){
                educSchoolType = Label.CDE_TYPE_SCHOOL_HJS;
            }else if(schoolType=='06'){
                educSchoolType = Label.CDE_TYPE_SCHOOL_GED;
            }else if(schoolType=='13'){
                educSchoolType = 'SUD'; //CCCAP-15444
            }
            return educSchoolType;
        }
    }
    
    public class T_EMPLMT_INCOME_CDE_FREQ_PAY_ESTMD_Rule implements Rule{
        public Object evaluateCondition(SObject sOb){
            
			String expenseFreq = String.valueOf(sOb.get('CDE_FREQ_EXP__c')), indExpenseFreq;
            if(expenseFreq=='02'){
                indExpenseFreq = Label.CDE_FREQ_EXP_QRT;
            }else if(expenseFreq=='04'){
                indExpenseFreq = Label.CDE_FREQ_EXP_MON;
            }else if(expenseFreq=='05'){
                indExpenseFreq = Label.CDE_FREQ_EXP_2PM;
            }else if(expenseFreq=='06'){
                indExpenseFreq = Label.CDE_FREQ_EXP_ONE;
            }else if(expenseFreq=='08'){
                indExpenseFreq = Label.CDE_FREQ_EXP_WKY;
            }else if(expenseFreq=='09'){
                indExpenseFreq = Label.CDE_FREQ_EXP_1PY;
            }else if(expenseFreq=='10'){
                indExpenseFreq = Label.CDE_FREQ_EXP_2PY;
            }else if(expenseFreq=='12'){
                indExpenseFreq = Label.CDE_FREQ_EXP_E2W;
            }else if(expenseFreq=='13'){
                indExpenseFreq = Label.CDE_FREQ_EXP_E2M;
            }
            return indExpenseFreq;
        }
    }

    public class T_SBSD_CASE_ADR_ADR_LINE_1_Rule implements Rule{
        public Object evaluateCondition(SObject sOb){
           
            String ADR_LINE_1 = '', ADR_NAM = '';
            if(sOb.get('ADR_LINE_1__c')!=null){
                ADR_LINE_1 = String.valueOf(sOb.get('ADR_LINE_1__c'));
            }
            if(sOb.get('ADR_NAM__c')!=null){
                ADR_NAM = String.valueOf(sOb.get('ADR_NAM__c'));
            }
            String addressLine1 = String.isEmpty(ADR_LINE_1) || String.isEmpty(ADR_NAM)?ADR_LINE_1+ADR_NAM:ADR_LINE_1+' '+ADR_NAM;
            return addressLine1.length()>=35?addressLine1.substring(0,34):addressLine1;
        }
    }

    
}