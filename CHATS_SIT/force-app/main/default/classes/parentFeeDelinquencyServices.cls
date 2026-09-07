/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/16/2017                                                          
*  @description    Handler class for Parent Fee Delinquency Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 16-Nov-2017                                                             
*  * Author: Azharuddin Mohammad                                                      
*  * Description: Initial version                                                 
*  *CHAT-1044: Can only be Month of Reported Delinquency Date, month before, or 2 months before
*  *CHAT-1048: Can only be Year of DTE_RPTD_DELINQC, year of month before, or year of 2 months before
*********************************************************************************************/
public class parentFeeDelinquencyServices {
    public static void delinqcMonthYear(List<T_COPAY_DELINQC__c> newParentFeeDelinqcList){
        for(T_COPAY_DELINQC__c eachPFDelinqc : newParentFeeDelinqcList){
            if(eachPFDelinqc.DTE_RPTD_DELINQC__c != null){
                date rptdDate = eachPFDelinqc.DTE_RPTD_DELINQC__c;
                integer rptdDelinqcMonth = rptdDate.month();
                String rptdDelinqcMonth_str = string.valueOf(rptdDelinqcMonth);
                integer Year = rptdDate.year();
                integer pYear = Year - 1;
                String rptdDelinqcYear = string.valueOf(Year);
                String prvYear = string.valueOf(pYear);
                integer prev1MonthInteger = rptdDelinqcMonth - 1;
                integer prev2MonthInteger = rptdDelinqcMonth - 2;
                String prev1MonthInteger_str = string.valueOf(prev1MonthInteger);
                String prev2MonthInteger_str = string.valueOf(prev2MonthInteger);
                
                if(rptdDelinqcMonth > 2){
                    if(eachPFDelinqc.DTE_MONTH_DELINQC__c != null){
                        if( (eachPFDelinqc.DTE_MONTH_DELINQC__c != rptdDelinqcMonth_str)  && (eachPFDelinqc.DTE_MONTH_DELINQC__c != prev1MonthInteger_str) && 
                           (eachPFDelinqc.DTE_MONTH_DELINQC__c != prev2MonthInteger_str)){  // IronDome fix
                               eachPFDelinqc.DTE_MONTH_DELINQC__c.addError('Delinquency Month accepts values only for previous two months range');    
                           }
                    }
                    if(eachPFDelinqc.DTE_YEAR_DELINQC__c != null){
                        if(eachPFDelinqc.DTE_YEAR_DELINQC__c != rptdDelinqcYear){
                            eachPFDelinqc.DTE_YEAR_DELINQC__c.addError('Delinquency Year accepts values only for previous two months range');
                        }
                    }
                }
                
                if(rptdDelinqcMonth == 2) {
                    if(eachPFDelinqc.DTE_MONTH_DELINQC__c != null){
                        if( (eachPFDelinqc.DTE_MONTH_DELINQC__c != rptdDelinqcMonth_str)     &&
                           (eachPFDelinqc.DTE_MONTH_DELINQC__c != prev1MonthInteger_str)  && 
                           (eachPFDelinqc.DTE_MONTH_DELINQC__c != '12')){
                               eachPFDelinqc.DTE_MONTH_DELINQC__c.addError('Delinquency Month accepts values only for previous two months range');
                           }
                    }
                    if(eachPFDelinqc.DTE_YEAR_DELINQC__c != null){
                        if(eachPFDelinqc.DTE_MONTH_DELINQC__c != null){
                            if( ((eachPFDelinqc.DTE_MONTH_DELINQC__c != rptdDelinqcMonth_str) || (eachPFDelinqc.DTE_YEAR_DELINQC__c != rptdDelinqcYear))  &&
                               ((eachPFDelinqc.DTE_MONTH_DELINQC__c != prev1MonthInteger_str) || (eachPFDelinqc.DTE_YEAR_DELINQC__c != rptdDelinqcYear)) && 
                               ((eachPFDelinqc.DTE_MONTH_DELINQC__c != '12') || (eachPFDelinqc.DTE_YEAR_DELINQC__c != prvYear)) ){
                                   eachPFDelinqc.addError('Delinquency Month & Year accepts values only for previous two months range');
                               }
                        }else{
                            if((eachPFDelinqc.DTE_YEAR_DELINQC__c != rptdDelinqcYear) && (eachPFDelinqc.DTE_YEAR_DELINQC__c != prvYear)){
                                eachPFDelinqc.DTE_YEAR_DELINQC__c.addError('Delinquency Year accepts values only for previous two months range');
                            }
                        }
                    }
                }
                if(rptdDelinqcMonth == 1){
                    if(eachPFDelinqc.DTE_MONTH_DELINQC__c != null){
                        if( (eachPFDelinqc.DTE_MONTH_DELINQC__c != rptdDelinqcMonth_str)     &&
                           (eachPFDelinqc.DTE_MONTH_DELINQC__c != '12') &&
                           (eachPFDelinqc.DTE_MONTH_DELINQC__c != '11')){
                               eachPFDelinqc.DTE_MONTH_DELINQC__c.addError('Delinquency Month accepts values only for previous two months range');
                           }
                    }
                    if(eachPFDelinqc.DTE_YEAR_DELINQC__c != null){
                        if(eachPFDelinqc.DTE_MONTH_DELINQC__c != null){
                            if( ((eachPFDelinqc.DTE_MONTH_DELINQC__c != rptdDelinqcMonth_str) || (eachPFDelinqc.DTE_YEAR_DELINQC__c != rptdDelinqcYear))     &&
                               ((eachPFDelinqc.DTE_MONTH_DELINQC__c != '12') || (eachPFDelinqc.DTE_YEAR_DELINQC__c != prvYear)) && 
                               ((eachPFDelinqc.DTE_MONTH_DELINQC__c != '11') || (eachPFDelinqc.DTE_YEAR_DELINQC__c != prvYear)) ){
                                   eachPFDelinqc.addError('Delinquency Month & Year accepts values only for previous two months range');
                               }
                        }else{
                            if((eachPFDelinqc.DTE_YEAR_DELINQC__c != rptdDelinqcYear) && (eachPFDelinqc.DTE_YEAR_DELINQC__c != prvYear)){
                                eachPFDelinqc.DTE_YEAR_DELINQC__c.addError('Delinquency Year accepts values only for previous two months range');
                            }
                        }
                    }
                }   //Rptd Date month is January
            }//Rptd Date is not null
        }
    }// end of delinqcMonthYear method
    
    // for CCCAP-10162 by Shashank
    public static void markReverseRefOnCase(Map<Id,T_COPAY_DELINQC__c> newParentFeeDelinqcMap,Map<Id,T_COPAY_DELINQC__c> oldParentFeeDelinqcMap){
        List<T_SBSD_CASE__c> cases = new list<T_SBSD_CASE__c>();
        List<T_COPAY_DELINQC__c> parentFeetoUpdate = new List<T_COPAY_DELINQC__c>();
        String mode = Trigger.isInsert?'Parent Fee Delinquency Creation':'Parent Fee Delinquency Resolution Update';
        Map<Id,Id> copayVsCase = new Map<Id,Id>();
        Map<Id,T_SBSD_CASE__c> caseMap = new Map<Id,T_SBSD_CASE__c>();
        for(T_COPAY_DELINQC__c eachPFDelinqc : newParentFeeDelinqcMap.values()){
            if(Trigger.isInsert 
               || (eachPFDelinqc.DTE_RESOLN_DELINQC__c!=null && eachPFDelinqc.DTE_RESOLN_DELINQC__c !=oldParentFeeDelinqcMap.get(eachPFDelinqc.Id).DTE_RESOLN_DELINQC__c)){
                   copayVsCase.put(eachPFDelinqc.Id,eachPFDelinqc.IDN_CASE__c);
               }
        }
        for(T_SBSD_CASE__c chatsCase : [select id,CHATS_Reverse_Refer_Mode__c,Program_Type__c
                                        from T_SBSD_CASE__c where id in:copayVsCase.values() and CHATS_Reverse_Refer_Mode__c excludes(:mode) and Program_Type__c in ('TF','LI')])
        {
            caseMap.put(chatsCase.Id,chatsCase);
        }
        for(T_COPAY_DELINQC__c eachPFDelinqc : newParentFeeDelinqcMap.values()){
            if(caseMap.containsKey(eachPFDelinqc.IDN_CASE__c)){
                T_SBSD_CASE__c chatsC = caseMap.get(eachPFDelinqc.IDN_CASE__c);
                chatsC.CHATS_Reverse_Refer_Mode__c = chatsC.CHATS_Reverse_Refer_Mode__c!=null?chatsC.CHATS_Reverse_Refer_Mode__c+';'+mode :mode;
                chatsC.Case_Reverse_Refer_Track__c = true;
                cases.add(chatsC);
                parentFeetoUpdate.add(new T_COPAY_DELINQC__c(Id=eachPFDelinqc.Id,Parent_fee_Reverse_Refer_Track__c = true));
            }
        }
        if(!cases.isEmpty()){
            GenericDMLHandler.updateRecords(cases, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_SBSD_Case__c'},'Class__c'=>'parentFeeDelinquencyServices','Method__c'=>'markReverseRefOnCase'});
        }
        if(!parentFeetoUpdate.isEmpty()){
            update parentFeetoUpdate;
        }
    }
}