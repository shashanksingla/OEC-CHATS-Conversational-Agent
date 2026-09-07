public class SIDMODRequestWrapper {
    public static String caseNumber;	//A123456
    public static String countyCode;
    public static String comment;
    public String stateId; // added for CCCAP-10315 for SIDMOD Notify Feature
    public  cls_person person;
    public class cls_person {
        public String ssn;	//123456789
        public String alienNumber;	//A22223333
        public String sex;	//F
        public String personStatus;	//Active
        public String dateOfBirth;	//1990-02-14
        public String lastName;	//Johnson
        public String firstName;	//Alice
        public String middleName;	//Marie
        public String suffixName;	//JR
        public cls_dateOfDeath dateOfDeath;
        public cls_contactDetails contactDetails;
        public cls_address address;
    }
    class cls_dateOfDeath {
    }
    public class cls_contactDetails {
        public String email;	//alice.johnson@email.com
        public Map<String,String> primaryPhone; // type &  number
        public Map<String,String> secondaryPhone; // type &  number
    }
    /*class cls_primaryPhone {
        //public String number;	//5555555555
        public String type;	//Mobile
    }
    class cls_secondaryPhone {
        //public String number;	//5555555555
        public String type;	//Mobile
    }*/
    class cls_address {
        public String address1;	//456 Elm Street
        public String address2;	//Apt 3B
        public String city;	//Maplewood
        public String state;	//WA
        public String zip;	//07040
        public String country;	//USA
        public String addressType;	//Home
    }
}