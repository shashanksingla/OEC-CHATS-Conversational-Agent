/*
 * This util class is used to provide some helper methods for Data Obfuscation
 * for apex classes.
 * */

public class ObfuscateDataUtil {
    
    public static Map<String, String[]> staticResourceMap = new Map<String, String[]>();


    public static String obfuscateEmailWithStaticData(String emailStr){
        String emailName ='';
        String fName='Fname';
        String lName ='Lname';
        String[] randomFname = null;
        String[] randomLname = null;
        if(!String.isEmpty(fName)){
            String staticResName = fName.toUpperCase();
            if(staticResourceMap.get(staticResName) != null){
                 randomFname = staticResourceMap.get(staticResName);
            }else{
                randomFname = getRandomStrDataFromStaticResource(fName);
                staticResourceMap.put(staticResName, randomFname);
            }
        }

        String maskedFString = '';
        maskedFString = findRandomStringFromList(randomFname);
        if(!String.isEmpty(maskedFString)){
            maskedFString = maskedFString.replaceAll(' ', '');
            maskedFString = maskedFString.replaceAll('\n', '');
            maskedFString = maskedFString.replaceAll('\r', '');
        }
        
        if(!String.isEmpty(lName)){
            String staticResName = lName.toUpperCase();
            if(staticResourceMap.get(staticResName) != null){
                 randomLname = staticResourceMap.get(staticResName);
            }else{
                randomLname = getRandomStrDataFromStaticResource(lName);
                staticResourceMap.put(staticResName, randomLname);
            }
        }

        String maskedLString = '';
        maskedLString = findRandomStringFromList(randomLname);

        if(!String.isEmpty(maskedLString)){
            maskedLString = maskedLString.replaceAll(' ', '');
            maskedLString = maskedLString.replaceAll('\n', '');
            maskedLString = maskedLString.replaceAll('\r', '');
        }

        
        if(String.isEmpty(maskedFString))
            maskedFString ='UnknownFirstName';

        
        if(String.isEmpty(maskedLString))
            maskedLString ='UnknownLastName';
        
        System.debug('##### maskedFString = '+maskedFString);
        System.debug('##### maskedLString = '+maskedLString);
        //Mask domain part
        emailName = maskedFString+'.'+maskedLString+'@example.com';
        
        return emailName;
    }   
    
    public static String obfuscateTextDataWithString(String textStr, String staticResourceName){
        String updatedtextStr ='';
        if( String.isEmpty(textStr)){
           return updatedtextStr;
        }
        
        System.debug('##### staticResourceName = '+staticResourceName);
         if(staticResourceName == 'SSN'){
             return obfuscateSSNData(textStr);
         }else if(StaticResourceName == 'REDACTED'){
             return 'REDACTED';
         }else if(StaticResourceName == 'PHONE'){
              return obfuscatePhoneData(textStr);
         }
        
        List<String> wordList = textStr.split('\\s'); //splits the string based on whiteSpace
        System.debug('#### text to replace '+textStr);
        System.debug('#### wordList '+wordList);
        String[] randomStr = null;
            
        if(!String.isEmpty(staticResourceName)){
            String staticResName = staticResourceName.toUpperCase();
            if(staticResourceMap.get(staticResName) != null){
                 randomStr = staticResourceMap.get(staticResName);
            }else{
                randomStr = getRandomStrDataFromStaticResource(staticResourceName);
                staticResourceMap.put(staticResName, randomStr);
            }
        }
           
        if(randomStr == null){
            randomStr = new String[] {'z','x','y','v'};
        }
        
        //String[] randomStr = getRandomStrDataFromStaticResource(staticResourceName);
        for(String str : wordList){
            str = str.length() > 0 ?str.trim():str;
            if(!String.isEmpty(str)){
                String maskedString = '';
                maskedString = findRandomStringFromList(randomStr);
                updatedtextStr = updatedtextStr + ' ' +maskedString.trim();
            }
        }
        System.debug('#### updatedtextStr '+updatedtextStr);
        return updatedTextStr.trim();        
    }
    
    public static String obfuscatePhoneData(String phoneStr){
        String replacedPhoneValue ='';
         if(phoneStr == null){
            return replacedPhoneValue;
        }
        List<String> randomStr = new List<String>{'1','3','9','5', '0','2','4','6','7'};
        //convert to phone type using regex expressions
        //
        
        //String formattedphoneStr = phoneStr.replaceFirst('(\\d{3})(\\d{3})(\\d+)', '($1) $2-$3');
        //System.debug('##### number = '+formattedphoneStr);

        //Mask phone part
        //Mask all chars of phone if it is less 4 chars otherwise mask all except first and last char
       
         //phoneData = maskString(phoneStr,0,phoneStr.length(),findRandomStringFromList(randomStr));
         String npaValue = generateRandomCustomDigitNumber(3,303);
         String nxxValue = generateRandomCustomDigitNumber(2,10);
         String remDigits = generateRandomCustomDigitNumber(4,1000);
         replacedPhoneValue = npaValue + +'0'+ nxxValue+remDigits;
        
        //ignore format for now
        return replacedPhoneValue;
        /*
         System.debug('##### replaceNPANXXvalue = '+replacedPhoneValue);
         String phoneRegExp = '(\\d{3})(\\d{3})';
         replacedPhoneValue = replacedPhoneValue.replaceFirst('(\\d{3})(\\d{3})(\\d+)', '($1) $2-$3');
         //System.debug('##### number = '+formattedphoneStr);
           
        return replacedPhoneValue;  */
     }

     public static String obfuscateNumberData(String numStr , String staticResourceName){
        String numValue ='';
         if(numStr == null){
            return numValue;
        }
        
         System.debug('##### staticResourceName = '+staticResourceName);
        
         if(staticResourceName == 'SSN'){
             return obfuscateSSNData(numStr);
         }else if(staticResourceName ==  'REDACTED' && ! numStr.isNumeric()){
             return numStr = 'REDACTED';
         }
        numStr = numStr.substring(0, numstr.indexOf('.') > 0 ? numstr.indexof('.'): numstr.length());
        List<String> randomStr = new List<String>{'1','3','9','5'};
        //Mask phone part
        //Mask all chars of phone if it is less 4 chars otherwise mask all except first and last char
        if(numStr.length() < 4){
            numValue = maskString(numStr,0,numStr.length(),findRandomStringFromList(randomStr));
        }else{
            numValue = maskString(numStr,1,numStr.length()-1,findRandomStringFromList(randomStr));
        }
        
        return numValue;  
     }
    
     public static String obfuscateSSNData(String numStr){
        String numValue ='';
         if(numStr == null){
            return numValue;
        }
         String first3digitNum = generateRandomCustomDigitNumber(3,303);
         String twodigitNum = '00';
         String remDigits = generateRandomCustomDigitNumber(4,1000);
         numValue =  first3digitNum +   twodigitNum +remDigits;
         System.debug('##### SSN numValue = '+numValue);    
         return numValue;  
     }
    
    
     public static String obfuscateStringData(String strValue){
        String strData ='';
         if(strValue == null){
            return strData;
        }
        List<String> randomStr = new List<String>{'1','3','9','5'};
        //Mask phone part
        //Mask all chars of phone if it is less 4 chars otherwise mask all except first and last char
        if(strValue.length() < 4){
            strData = maskString(strValue,0,strValue.length(),findRandomStringFromList(randomStr));
        }else{
            strData = maskString(strValue,1,strValue.length()-1,findRandomStringFromList(randomStr));
        }            
        return strData;  
     }

     public static Date obfuscateStringDate(Date dateValue){
          System.debug('#####  dateValue = '+dateValue);  
         Datetime currDate = system.now();
         Integer currYear = currDate.year();
         if(currYear < 1703 ){
             //default 1707 as salesforce don't support any year which is below 1700
             //if user tries to update the date which is below 1700 year you get
             //field_integrity_exception
             currYear = 1707;
         }
         Date updatedDateValue= date.newInstance(currYear, currDate.month(), currDate.day());
         if(dateValue == null){
            return updatedDateValue;
        }
        List<String> randomStr = new List<String>{'-1','1','-2','2'};
        //Mask date value
        //Mask date value to new value based on the random number
        Integer updatedYear = dateValue.year()+Integer.valueOf(findRandomStringFromList(randomStr));
         if(updatedYear > currYear){
             updatedYear = currYear - 1;
         }

        //BPS - Fixes to Year, Month & Day

         if(updatedYear < 1700){
             updatedYear = 1701;
         }
         
        Integer updatedMonth = dateValue.month()+Integer.valueOf(findRandomStringFromList(randomStr));
        Integer updatedDay = dateValue.day()+Integer.valueOf(findRandomStringFromList(randomStr));
        if(updatedMonth > 12){
            updatedMonth = updatedMonth - 2;
        }
        if(updatedMonth < 1){
            updatedMonth = updatedMonth + 2;
        }
        
        if(updatedDay > 28){
            updatedDay = updatedDay - 6;
        }
        if(updatedDay < 1){
            updatedDay = updatedDay + 3;
        }

        updatedDateValue = date.newInstance(updatedYear, updatedMonth, updatedDay);

//        updatedDateValue = date.newInstance(updatedYear, 
//                                                 dateValue.month()+Integer.valueOf(findRandomStringFromList(randomStr)), 
//                                                 dateValue.day()+Integer.valueOf(findRandomStringFromList(randomStr)));

        return updatedDateValue;  
     }

     public static DateTime obfuscateStringDateTime(DateTime dateValue){
        System.debug('#####  datetimeValue = '+dateValue);  
         Datetime currDate = system.now();
         Integer currYear = currDate.year();
         if(currYear < 1703 ){
             //default 1707 as salesforce don't support any year which is below 1700
             //if user tries to update the date which is below 1700 year you get
             //field_integrity_exception
             currYear = 1707;
         }
         
         DateTime updatedDateValue= date.newInstance(currYear, currDate.month(), currDate.day());
         if(dateValue == null){
            return updatedDateValue;
        }
        List<String> randomStr = new List<String>{'-1','1','-2','2'};
        //Mask date value
        //Mask date value to new value based on the random number
        Integer updatedYear = dateValue.year()+Integer.valueOf(findRandomStringFromList(randomStr));
         if(updatedYear > currYear){
             updatedYear = currYear - 1;
         }

        //BPS - Fixes to Year, Month & Day

         if(updatedYear < 1700){
             updatedYear = 1701;
         }
        
        Integer updatedMonth = dateValue.month()+Integer.valueOf(findRandomStringFromList(randomStr));
        Integer updatedDay = dateValue.day()+Integer.valueOf(findRandomStringFromList(randomStr));
        if(updatedMonth > 12){
            updatedMonth = updatedMonth - 2;
        }
        if(updatedMonth < 1){
            updatedMonth = updatedMonth + 2;
        }
        
        if(updatedDay > 28){
            updatedDay = updatedDay - 6;
        }
        if(updatedDay < 1){
            updatedDay = updatedDay + 3;
        }

        updatedDateValue = date.newInstance(updatedYear, updatedMonth, updatedDay);

//        updatedDateValue = date.newInstance(updatedYear, 
//                                                 dateValue.month()+Integer.valueOf(findRandomStringFromList(randomStr)), 
//                                                 dateValue.day()+Integer.valueOf(findRandomStringFromList(randomStr)));

        return updatedDateValue;  
     }

    
    public static String maskString(String textToMask, integer startPos, Integer endPos, String maskChar){

        if(textToMask == null || textToMask.equals(''))
            return '';
        
        if(startPos < 0)
            startPos = 0;
        
        if( endPos > textToMask.length() )
            endPos = textToMask.length();
            
        if(startPos > endPos){
            //TODO:
            //throw new Exception("endPos index cannot be greater than startPos index");
            //for now swap the values
            startPos = startPos + endPos;
            endPos = startPos-endPos;
            startPos = startPos- endPos;            
        }
        
        integer maskLength = endPos - startPos;
        
        if(maskLength == 0)
            return textToMask;
        
        String sbMaskString = '';
        
        for(integer i = 0; i < maskLength; i++){
            sbMaskString = sbMaskString +maskChar;
        }
        
        String maskedData = textToMask.substring(0, startPos) + sbMaskString + textToMask.substring(startPos + maskLength);
        System.debug('#########  maskedData ###### '+maskedData);
        return maskedData;        
    }
    
   
    //method to return random value between 2 numbers
    public static Integer generateRandomFromRange(integer startNum, integer endNum){
        Integer returnValue;
        //Logic- first we will generate random boolean value which will decide if we want to
        //add the random number from startNum or will subtract random number from endNum
        Integer randomNumber = Integer.valueof((math.random() * 10));
        boolean addSubFlag= math.mod(randomNumber,2) == 0 ? true : false;
        
        integer diffInRange = endNum-startNum;
        //Now find random number staring from 0 to diffInRange
        Integer randomNum = Math.mod(Math.round(Math.random()*diffInRange+1),diffInRange);
        
        //If addSubFlag is true, we will add random number generated between 0 and diffInRange from start number
        //else we will subtract random number from end number
        if(addSubFlag){
            if(diffInRange > 1)
                returnValue =startNum + randomNum;
            else
                returnValue =startNum;
        }else{
            if(diffInRange > 1)
                returnValue = endNum - randomNum;
            else
                returnValue =endNum;
        }
        return returnValue;
    }
    
    //method to return random number between 0 and size-1
    public static Integer generateRandomNumber(Integer size){
        Decimal d = math.random() * size;
        return d.intValue();
    }
    
    //method to return boolean number randomly
    public static Boolean generateRandomBoolean(){
        integer randomNumber = Integer.valueof((math.random() * 10));
        boolean returnValue= math.mod(randomNumber,2) == 0 ? true : false;
        return returnValue;
    }
    
    //Finding a random string value from list of strings
    public static String findRandomStringFromList(List<String> values){
        Integer randomNumber = generateRandomFromRange(0,values.size()-1);
        System.debug('#########  randomNumber ###### '+randomNumber);
        System.debug('#########   values[randomNumber] ###### '+ values[randomNumber]);
        return values[randomNumber];
    }
    //Generate Random number for Phone first 3 digits
    public static String generateRandomCustomDigitNumber(Integer size, Integer minValue){
        
        
         integer STRING_LENGTH = size;
         double MAX = Math.pow(10,STRING_LENGTH) - 1; // for example Returns 999 if size is 3
        
        double randnumber =  Math.Round(Math.Random() * MAX);
        Integer intval = randnumber.intValue();
        if(intVal < minValue)
             intval = intval + minValue;
        System.debug('##### intval = '+intval);
        
         //String randNum = String.valueOf(Math.Round(Math.Random() * MAX)).leftPad(STRING_LENGTH,'0');
        return String.valueOf(intval);
    }
    //getRandomString Data from static resource
    public static String[] getRandomStrDataFromStaticResource(String resourceName) {
       staticResource statRes = StaticResourceUtil.getStaticResourceDataByName(resourceName);
       if(statRes == null){
           return null;
       }
       
       String[] csvFileLines = new String[]{}; 
        blob body = statRes.body;
        //String encodedString = EncodingUtil.convertToHex(body);
        String decodeString =  EncodingUtil.base64Encode(body);
        String csvAsString = body.toString();
         //System.debug('csvAsString == '+csvAsString);
         // Split CSV String to lines
         csvFileLines = csvAsString.split('\n'); 
        for(Integer i=0; i<csvFileLines.size(); i++){
           // System.debug('array value at '+i + '  '+csvFileLines[i]);
        }
       // SYstem.debug('body == '+csvAsString);
       return csvFileLines;
       
    }

}