public class SoundexUtil{
	/*
	 * Logic change added as per CHATS-2950
	 * date - 04/05/2018
	 * 
	*/
    public static integer soundexLength = 4;
    
    private static map<String,String> soundexMap = new map<String,String>{'A'=>'0','B'=>'1','C'=>'2','D'=>'3','E'=>'0',
        'F'=>'1','G'=>'2','H'=>'0','I'=>'0','J'=>'2',
        'K'=>'2','L'=>'4','M'=>'5','N'=>'5','O'=>'0',
        'P'=>'1','Q'=>'2','R'=>'6','S'=>'2','T'=>'3',
        'U'=>'0','V'=>'1','W'=>'0','X'=>'2','Y'=>'0','Z'=>'2'};
            
            public static string toSoundex(String input){
                String prevChar = ' ';
                if (input == NULL || input.length() == 0){
                    return input;
                }
                String normStr = input.toUpperCase();
                //Append first character to encoded string
                String soundexStr = normStr.substring(0,1);
                integer strLength = normStr.length();
                for (integer i=1; i<strLength && soundexStr.length()<soundexLength; i++){
                    String key=normStr.substring(i,i+1);
                    String soundexChar = soundexMap.get(key);
                    if (soundexChar== soundexMap.get(normStr.substring(0,1)) && i ==1)
                    {
                        soundexChar = soundexMap.get(key);
                    }
                    else
                    {                    
                    if (soundexChar != NULL && !soundexChar.equals('0') && !soundexChar.equals(prevChar)){
                        soundexStr = soundexStr+soundexChar;
                        //prevChar = soundexChar;
                    }
                    prevChar = soundexChar;
                    }
                }
                //Pad soundex string if the length is less than 4
                while (soundexStr.length() < soundexLength){
                    soundexStr = soundexStr+'0';
                }
                return soundexStr;
            }
}