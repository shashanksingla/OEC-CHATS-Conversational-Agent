/**
* This class is used for decoding the bit set for validFor
* @author Nikunj Nilesh Doshi (ndoshi@deloitte.com)
*/

public class APXBitSet {
    public Map < String, Integer > alphaNumCharCodes {
        get;
        set;
    }
    public Map < String, Integer > base64CharCodes {
        get;
        set;
    }
    
    public APXBitSet() {
        LoadCharCodes();
    }
    
    
    /**
* @description Method loads the character codes for all letters
*/
    public void LoadCharCodes() {
        alphaNumCharCodes = new Map < String, Integer > {
            'A' => 65,
                'B' => 66,
                'C' => 67,
                'D' => 68,
                'E' => 69,
                'F' => 70,
                'G' => 71,
                'H' => 72,
                'I' => 73,
                'J' => 74,
                'K' => 75,
                'L' => 76,
                'M' => 77,
                'N' => 78,
                'O' => 79,
                'P' => 80,
                'Q' => 81,
                'R' => 82,
                'S' => 83,
                'T' => 84,
                'U' => 85,
                'V' => 86,
                'W' => 87,
                'X' => 88,
                'Y' => 89,
                'Z' => 90
                };
                    base64CharCodes = new Map < String, Integer > ();
        //all lower cases
        Set < String > pUpperCase = alphaNumCharCodes.keySet();
        for (String pKey: pUpperCase) {
            //the difference between upper case and lower case is 32
            alphaNumCharCodes.put(pKey.toLowerCase(), alphaNumCharCodes.get(pKey) + 32);
            //Base 64 alpha starts from 0 (The ascii charcodes started from 65)
            base64CharCodes.put(pKey, alphaNumCharCodes.get(pKey) - 65);
            base64CharCodes.put(pKey.toLowerCase(), alphaNumCharCodes.get(pKey) - (65) + 26);
            
            base64CharCodes.put('+', 62);   
        }
        //numerics
        for (Integer i = 0; i <= 9; i++) {
            alphaNumCharCodes.put(string.valueOf(i), i + 48);
            //base 64 numeric starts from 52
            base64CharCodes.put(string.valueOf(i), i + 52);
        }
    }
    
    
    /**
*@description Method decodes the bit set to integer
*@param String 
*@param List<Integer>
*@return List<Integer>
*/
    public List < Integer > testBits(String pValidFor, List < Integer > nList) {
        List < Integer > results = new List < Integer > ();
        List < Integer > pBytes = new List < Integer > ();
        Integer bytesBeingUsed = (pValidFor.length() * 6) / 8;
        
        Integer pFullValue = 0;
        if (bytesBeingUsed <= 1){
            return results;
        }
        
        for (Integer i = 0; i < pValidFor.length(); i++) {
            pBytes.Add((base64CharCodes.get((pValidFor.Substring(i, i + 1)))));
        }
        
        for (Integer i = 0; i < pBytes.size(); i++) {
            Integer pShiftAmount = (pBytes.size() - (i + 1)) * 6; //used to shift by a factor 6 bits to get the value
            pFullValue = pFullValue + (pBytes[i] << (pShiftAmount));
        }
        
        Integer bit;
        Integer targetOctet;
        Integer shiftBits;
        Integer tBitVal;
        Integer n;
        Integer nListSize = nList.size();
        for (Integer i = 0; i < nListSize; i++) {
            n = nList[i];
            bit = 7 - (Math.mod(n, 8));
            targetOctet = (bytesBeingUsed - 1) - (n >> bytesBeingUsed);
            //shiftBits = (targetOctet * 8) + bit;
            shiftBits = bytesBeingUsed * 8 - n - 1;
            tBitVal = ((Integer)(2 << (shiftBits - 1)) & pFullValue) >> shiftBits;
            if (tBitVal == 1){
            	results.add(n);
            }
                
        }
        return results;
    }
    
    
    // Returns a list of all parent indexes for which this dependent entry is valid
    public List<Integer> validFor(String pValidFor) {
        // Target list
        List<Integer> ret = new List<Integer>();
        
        // Start at offset 0
        Integer target = 0;
        
        // Process each character in order
        for(Integer i=0; i < pValidFor.length();i++){
            //get current character value
            Integer cur = (Base64CharCodes.get((pValidFor.Substring(i, i+1))));
            
            // 6 bits per character, starting at bit position 5
            for (Integer j = 0; j < 6; j++) {
                // Is the current bit set?
                if ((cur & 32) == 32) {
                    // Yes, this index is valid
                    ret.add(target);
                }
                // Shift the next bit into position
                cur <<= 1;
                
                // Move to the next target index
                target++;
            }
        }
        
        return ret;
    }    
    
    
    
    
    
    
    
    
}