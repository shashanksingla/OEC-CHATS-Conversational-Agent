/*
 * This is a util class is used to provide some helper methods 
 * for apex classes.
 * */
public class ApexUtil {
 
    public static Schema.DisplayType getFieldType(String sObjName, String fieldName){
         //get SobjectType
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(sObjName);
        Schema.DescribeSObjectResult result = objType.getDescribe();
        Schema.DisplayType fDataType = result.fields.getMap().get(fieldName).getDescribe().getType();
        return  fDataType;     
    }

    public static Integer getFieldLength(String sObjName, String fieldName){
         //get SobjectType
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(sObjName);
        Schema.DescribeSObjectResult result = objType.getDescribe();
        Schema.DescribeFieldResult dfr =result.fields.getMap().get(fieldName).getDescribe();
        return  dfr.getLength();     
    }
    
    public static boolean isvalidField(String ObjectName, String fieldName){
        //get SobjectType
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(ObjectName);
        if(objType == null)
            return false;
        Schema.DescribeSObjectResult result = objType.getDescribe();
        Map<String, Schema.SObjectField> fMap = result.fields.getMap();
        if(fMap.get(fieldName) != null){
            Schema.SObjectField fieldObj = fMap.get(fieldName);
            if(fieldObj.getDescribe().isCalculated()){
                return false;
            }
            if(fieldObj.getDescribe().isAutoNumber()){
                return false;
            }
            return true;
        }
        return false;
    }

    public static boolean isvalidObject(String ObjectName){
        //get SobjectType
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(ObjectName);
        if(objType == null)
            return false;
        return true;
    }
    
    
    
    public static sObject obfuscateFieldData(String objName, sObject sObj, String fieldName,String staticResourceName){
        if((String.isEmpty(objName) || String.isEmpty(fieldName) || sObj == null)){
            return null;
        }
        Schema.DisplayType fDataType = getFieldType(objName,  fieldName);
        Integer fieldLen =  getFieldLength(objName, fieldName);
        if(fDataType == Schema.DisplayType.ADDRESS){
            return sobj;
        }

        if(fDataType == Schema.DisplayType.CURRENCY){
             System.debug('Data Type of the field is Currency. Field Name is  = '+fieldName);  
            Decimal  currencyVal =(Decimal )sObj.get(fieldName);
            String UpdatedValue = ObfuscateDataUtil.obfuscateNumberData(string.valueOf( currencyVal),staticResourceName);
            if(!String.isEmpty(UpdatedValue)){
                Decimal updatedCurrencyVal = Decimal.valueOf(UpdatedValue );
                sobj.put(fieldName, updatedCurrencyVal);
            }
            return sobj;
        }

        if(fDataType == Schema.DisplayType.DATE){
            System.debug('Data Type of the field is Date. Field Name is  = '+fieldName);  
            Date currdateValue =(Date)sObj.get(fieldName);
            Date updatedDate = ObfuscateDataUtil.obfuscateStringDate(currdateValue);
            if(updatedDate != null){
                sobj.put(fieldName, updatedDate);
            }
            System.debug('currdateValue = '+currdateValue);
            System.debug('updatedDate for DATE datatype = '+updatedDate);
            
            return sobj;
        }

        if(fDataType == Schema.DisplayType.DATETIME){
            System.debug('Data Type of the field is Datetime. Field Name is  = '+fieldName);  
            DateTime currDateTime =(DateTime)sObj.get(fieldName);
            DateTime updatedDatetime = ObfuscateDataUtil.obfuscateStringDateTime(currDateTime);
            if(updatedDatetime != null){
                sobj.put(fieldName, updatedDatetime);
            }
            
            return sobj;
        }
        
        
        if(fDataType == Schema.DisplayType.DOUBLE){
            System.debug('Data Type of the field is Double. Field Name is  = '+fieldName);  
            DOUBLE doubleValue =(DOUBLE)sObj.get(fieldName);
            String updatedValue =  ObfuscateDataUtil.obfuscateNumberData(String.valueOf(doubleValue),staticResourceName);
            if(!String.isEmpty(UpdatedValue)){
                DOUBLE updateddoubleValue = Double.valueOf(updatedValue);
                sobj.put(fieldName, updateddoubleValue);
            }
            return sobj;
        }
        
        if(fDataType == Schema.DisplayType.EMAIL){
            System.debug('Data Type of the field is Email. Field Name is  = '+fieldName);  
            String emailStr =(String)sObj.get(fieldName);
            String emailName = ObfuscateDataUtil.obfuscateEmailWithStaticData(emailStr);
            if(!String.isEmpty(emailName)){
                emailName = emailName.length() > fieldLen ? emailName.substring(0, fieldLen -1) : emailName;
                sobj.put(fieldName, emailName);
            }
            return sobj;
        }
        
        if(fDataType == Schema.DisplayType.ENCRYPTEDSTRING){
            System.debug('Data Type of the field is EncryptedString. Field Name is  = '+fieldName);  
           return sobj;
        }
        if(fDataType == Schema.DisplayType.ID){
            System.debug('Data Type of the field is ID. Field Name is  = '+fieldName);  
           return sobj;
        }
        if(fDataType == Schema.DisplayType.INTEGER){
            System.debug('Data Type of the field is Integer. Field Name is  = '+fieldName);  
            Integer intVal =(Integer)sObj.get(fieldName);
            
            String updatedValue = ObfuscateDataUtil.obfuscateNumberData(String.valueOf(intVal),staticResourceName);
            if(!String.isEmpty(UpdatedValue)){
                Integer updatedIntVal = Integer.valueOf(updatedValue);
                sobj.put(fieldName, updatedIntVal);
            }
            return sobj;
        }
        if(fDataType == Schema.DisplayType.JSON){
            System.debug('Data Type of the field is JSON. Field Name is  = '+fieldName);  
           return sobj;
        }
        
        if(fDataType == Schema.DisplayType.LOCATION){
            System.debug('Data Type of the field is Location. Field Name is  = '+fieldName);  
           return sobj;
        }
        
        if(fDataType == Schema.DisplayType.LONG){
            System.debug('Data Type of the field is Long. Field Name is  = '+fieldName);  
            long longval =(LONG) sObj.get(fieldName);
            String updatedValue = ObfuscateDataUtil.obfuscateNumberData(String.valueof(longval),staticResourceName);
            if(!String.isEmpty(UpdatedValue)){
                long updatedLongVal = long.valueOf(updatedValue);
                sobj.put(fieldName, updatedLongVal);
            }
            return sobj;
        }
        
        if(fDataType == Schema.DisplayType.MULTIPICKLIST){
            System.debug('Data Type of the field is Multipicklist. Field Name is  = '+fieldName);  
           return sobj;
        }
        
        if(fDataType == Schema.DisplayType.PERCENT){
            System.debug('Data Type of the field is PERCENT. Field Name is  = '+fieldName);  
           return sobj;
        }
        
        if(fDataType == Schema.DisplayType.PHONE){
            System.debug('Data Type of the field is PHONE. Field Name is  = '+fieldName);  
            String phoneStr =(String)sObj.get(fieldName);
            String phoneValue = ObfuscateDataUtil.obfuscatePhoneData(phoneStr);
            if(!String.isEmpty(phoneStr)){
                if(!String.isEmpty(phoneValue)){
                    sobj.put(fieldName, phoneValue);
                }
            }
            System.debug('phoneStr = '+phoneStr);
            System.debug('UPDATED phoneValue for DataType = '+phoneValue);

            return sobj;
        }
        
        if(fDataType == Schema.DisplayType.PICKLIST){
            System.debug('Data Type of the field is PICKLIST. Field Name is  = '+fieldName);  
            return sobj;
        }
        
        if(fDataType == Schema.DisplayType.REFERENCE){
            System.debug('Data Type of the field is REFERENCE. Field Name is  = '+fieldName);  
           return sobj;
        }
        
        if(fDataType == Schema.DisplayType.STRING){
            System.debug('Data Type of the field is STRING. Field Name is  = '+fieldName);  
            
            String textStr =(String)sObj.get(fieldName);
            String updatedTextStrVal = ObfuscateDataUtil.obfuscateTextDataWithString(textStr,staticResourceName);
            if(staticResourceName == 'Fname' || staticResourceName == 'Lname'){
                updatedTextStrVal= updatedTextStrVal.replaceAll( '\\s+', '');
                //if(updatedTextStrVal != null && updatedTextStrVal.Length() >32 ){
                    //updatedTextStrVal = updatedTextStrVal.substring(0, 31);
               // }
                updatedTextStrVal = updatedTextStrVal.length()>  fieldLen ? updatedTextStrVal.substring(0, fieldLen -1) : updatedTextStrVal;
            }
            if(!String.isEmpty(updatedTextStrVal)){
                updatedTextStrVal = updatedTextStrVal.length() > fieldLen ? updatedTextStrVal.substring(0, fieldLen -1) : updatedTextStrVal;
                sobj.put(fieldName, updatedTextStrVal);                
            }
            
            System.debug('textStr = '+textStr);
            System.debug('UPDATED updatedTextStrVal for String DataType = '+updatedTextStrVal);            
            return sobj;
        }
        
        if(fDataType == Schema.DisplayType.TEXTAREA){
            System.debug('Data Type of the field is TEXTAREA. Field Name is  = '+fieldName);  
            String textStr =(String)sObj.get(fieldName);
            String updatedTextStrVal = ObfuscateDataUtil.obfuscateTextDataWithString(textStr, staticResourceName);
            
            if(!String.isEmpty(updatedTextStrVal)){
                updatedTextStrVal = updatedTextStrVal.length() >  fieldLen ? updatedTextStrVal.substring(0, fieldLen -1) : updatedTextStrVal;
                sobj.put(fieldName, updatedTextStrVal);
            }
            
            System.debug('textStr = '+textStr);
            System.debug('UPDATED TextaArea DataType  = '+updatedTextStrVal);            

            return sobj;
        }
        
        if(fDataType == Schema.DisplayType.URL){
            System.debug('Data Type of the field is URL. Field Name is  = '+fieldName);  
           return sobj;
        }
        return sobj;
       // return 'InvalidDataType';
    }
}