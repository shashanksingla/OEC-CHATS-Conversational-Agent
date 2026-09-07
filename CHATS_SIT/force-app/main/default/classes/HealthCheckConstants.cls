public class HealthCheckConstants {
    
    public static final String FETCH_COUNTY_DEV_URL = 'https://chatstranswsdevapp.herokuapp.com/AuthEncumbr/FetchCounty';
    public static final String COUNTY_ID_DEV = 'a1Om0000000qgfnEAA';
    
    public static final String FETCH_COUNTY_CI_URL = 'https://chatstranswsintapp.herokuapp.com/AuthEncumbr/FetchCounty';
    public static final String COUNTY_ID_CI = 'a1Qm00000014pzQEAQ';
    
   	public static final String FETCH_COUNTY_SIT_URL = 'https://chatstranswssitfullapp.herokuapp.com/AuthEncumbr/FetchCounty';
    public static final String COUNTY_ID_SIT = 'a1O0t000000DoUXEA0';
    
	public static final String FETCH_COUNTY_PLT_URL = 'https://chatstranswspltapp.herokuapp.com/AuthEncumbr/FetchCounty';
    public static final String COUNTY_ID_PLT = 'a0y2a000000SplEAAS';    
    
    
   public static final String FETCH_AUTHCOPAY_DEV_URL = 'https://chatstranswsdevapp.herokuapp.com/AuthCopay/FetchRecords';
   public static final String CASE_ID_DEV = 'a25m0000000RASvAAO';
    
   public static final String FETCH_AUTHCOPAY_CI_URL = 'https://chatstranswsintapp.herokuapp.com/AuthCopay/FetchRecords';
   public static final String CASE_ID_CI = 'a27m0000000AzCBAA0';
    
   public static final String FETCH_AUTHCOPAY_SIT_URL = 'https://chatstranswsintapp.herokuapp.com/AuthCopay/FetchRecords';
   public static final String CASE_ID_SIT = 'a250t0000008CAcAAM';
    
    public static final String FETCH_AUTHCOPAY_PLT_URL = 'https://chatstranswspltapp.herokuapp.com/AuthCopay/FetchRecords';
   public static final String CASE_ID_PLT = 'a1g2a0000006RnDAAU';
    
    
   public static final String FETCH_FETCH_ENCMBR_DEV_URL = 'https://chatstranswsdevapp.herokuapp.com/AuthEncumbr/FetchRecords';
   public static final String AUTH_ID_DEV = 'a1fg0000001nw1EAAQ';   
   public static final String FETCH_FETCH_ENCMBR_CI_URL = 'https://chatstranswsintapp.herokuapp.com/AuthEncumbr/FetchRecords';
    public static final String AUTH_ID_CI = 'a1fg0000001nw1EAAQ';
     public static final String FETCH_FETCH_ENCMBR_SIT_URL = 'https://chatstranswssitfullapp.herokuapp.com/AuthEncumbr/FetchRecords';
    public static final String AUTH_ID_SIT = 'a1A0t00000273anEAA';
    public static final String FETCH_FETCH_ENCMBR_PLT_URL = 'https://chatstranswspltapp.herokuapp.com/AuthEncumbr/FetchRecords';
    public static final String AUTH_ID_PLT = 'a0k2a000000cnktAAA';
    
   public static final String FETCH_CORR_DEV_URL = 'https://chatsdevapp.herokuapp.com/correspondence/search';
     public static final String FETCH_CORR_CI_URL = 'https://chatsintapp.herokuapp.com/correspondence/search';
   public static final String FETCH_CORR_SIT_URL = 'https://chatssitfullapp.herokuapp.com/correspondence/search';
    public static final String FETCH_CORR_PLT_URL = 'https://chatspltapp.herokuapp.com/correspondence/search';
     public static final String COUNTY_NAME = 'Adams';
    
    
     public static final String AUTH_STATUS_UPDATE_DEV_URL = 'https://chatstranswsdevapp.herokuapp.com/AuthStatus/UpdateRecord';
     public static final String AUTH_STATUS_UPDATE_CI_URL = 'https://chatstranswsintapp.herokuapp.com/AuthStatus/UpdateRecord';
     public static final String AUTH_STATUS_UPDATE_SIT_URL = 'https://chatstranswssitfullapp.herokuapp.com/AuthStatus/UpdateRecord';
    public static final String AUTH_STATUS_UPDATE_PLT_URL = 'https://chatstranswspltapp.herokuapp.com/AuthStatus/UpdateRecord';
    
     public static final String AUTH_STATUS_UPDATE_JSON = '{"idn_status_auth":"3965",'+
        '"cde_Reason_Change_Auth":"T",'+
        '"cde_Status_Auth":"T",'+
        '"dte_Begin_Effv":  "2019-12-12",'+
        '"dte_End_Effv":"2012-12-12",'+
        '"idn_Auth":"T",'+
        '"lastmodifieddate":"2012-12-12 12:12:12",'+
        '"lastmodifiedbyid":"test"}';
    
    public static final String AUTH_COPAY_UPDATE_DEV_URL = 'https://chatstranswsdevapp.herokuapp.com/AuthCopay/UpdateRecords';
    public static final String AUTH_COPAY_UPDATE_CI_URL = 'https://chatstranswsintapp.herokuapp.com/AuthCopay/UpdateRecords';
    public static final String AUTH_COPAY_UPDATE_SIT_URL = 'https://chatstranswssitfullapp.herokuapp.com/AuthCopay/UpdateRecords';
    public static final String AUTH_COPAY_UPDATE_PLT_URL = 'https://chatstranswspltapp.herokuapp.com/AuthCopay/UpdateRecords';
    
   public static final String AUTH_COPAY_UPDATE_JSON = '[{"dte_begin_effv":"2010-12-01",'
        +'"amt_copay_auth":"10",'
        +'"lastmodifiedbyid": "vishu",'
        +'"lastmodifieddate" :"2018-28-08 09:03:24"'
        +'},'
        +'{"dte_begin_effv":"2010-12-01",'
        +'"amt_copay_auth":"10",'
        +'"lastmodifiedbyid": "vishu" ,'
        +'"lastmodifieddate" :"2018-28-08 09:03:24"'
        +'}]';
    
   public static final String AUTH_ENCMB_UPDATE_DEV_URL='https://chatstranswsdevapp.herokuapp.com/AuthEncumbr/UpdateRecord';
     public static final String AUTH_ENCMB_UPDATE_CI_URL='https://chatstranswsintapp.herokuapp.com/AuthEncumbr/UpdateRecord';
   public static final String AUTH_ENCMB_UPDATE_SIT_URL='https://chatstranswssitfullapp.herokuapp.com/AuthEncumbr/UpdateRecord';
    public static final String AUTH_ENCMB_UPDATE_PLT_URL='https://chatstranswspltapp.herokuapp.com/AuthEncumbr/UpdateRecord';
    
    
    
     public static final String AUTH_ENCMBR_UPDATE_JSON = '[{'
        +'"cde_Level_Care":"5",'
        +'"cde_Status_Encmbr":"4",'
        +'"cde_Type_Unit_care":"4",'
        +'"cnt_Hour_Attend_Actual":"0",'
        +'"cnt_Hour_Care":"0",'
        +'"nbr_seq_hist":"1",'
        +'"lastmodifieddate":"2012-12-12 10:10:10",'
        +'"lastmodifiedbyid":"sahil"'
        +'}]';
    
    
     public static final String CASE_COPAY_UPDATE_DEV_URL= 'https://chatstranswsdevapp.herokuapp.com/CaseCopay/UpdateRecord';
   public static final String CASE_COPAY_UPDATE_CI_URL= 'https://chatstranswsintapp.herokuapp.com/CaseCopay/UpdateRecord';
    public static final String CASE_COPAY_UPDATE_SIT_URL= 'https://chatstranswssitfullapp.herokuapp.com/CaseCopay/UpdateRecord';
    public static final String CASE_COPAY_UPDATE_PLT_URL= 'https://chatstranswspltapp.herokuapp.com/CaseCopay/UpdateRecord';
    
   public static final String CASE_COPAY_UPDATE_JSON = '{ "amt_Copay_Case_Assesd":"1",'
        +'"amt_Copay_Case_Ft":"1",'
        +'"amt_Copay_Case_Pt":"1",'
        +'"cde_Reason_Ovrd":"R",'
        +'"cde_Rec_Copay":"R",'
        +'"dte_Begin_Effv":"2012-12-12",'
        +'"dte_End_Effv":"2012-12-12",'
        +'"nbr_Seq_Hist":"1",'
        +'"lastmodifiedbyid":"sahilnew",'
        +'"lastmodifieddate":"2012-12-12 12:12:12",'
        +'"amt_Copay_Case_Ft_Qlty":"1" ,'
        +'"amt_Copay_Case_Pt_Qlty":"1" ,'
        +'"ind_Qlty":"Y"'
        +'}';   
    
   public static final String SUB_PYMT_DTL_UPDATE_DEV_URL = 'https://chatstranswsdevapp.herokuapp.com/SubpaymentDetail/UpdateExistingAdjustment';
   public static final String SUB_PYMT_DTL_UPDATE_CI_URL = 'https://chatstranswsintapp.herokuapp.com/SubpaymentDetail/UpdateExistingAdjustment';
   public static final String SUB_PYMT_DTL_UPDATE_SIT_URL = 'https://chatstranswssitfullapp.herokuapp.com/SubpaymentDetail/UpdateExistingAdjustment';
    public static final String SUB_PYMT_DTL_UPDATE_PLT_URL = 'https://chatstranswspltapp.herokuapp.com/SubpaymentDetail/UpdateExistingAdjustment';
    
   public static final String SUB_PYMT_DTL_UPDATE_JSON = '{"subPaymtDtlId":['
        +'{"lastModifiedById":"sahil","lastModifiedDate":"2012-12-12 10:10:10"},'
        +'{ "lastModifiedById":"sahil","lastModifiedDate":"2012-12-12 10:10:10"}'
        +']}';
    
   public static final String CREATE_AUTH_ENCMBR_DEV_URL = 'https://chatstranswsdevapp.herokuapp.com/AuthEncumbr/CreateRecord';
   public static final String CREATE_AUTH_ENCMBR_CI_URL = 'https://chatstranswsintapp.herokuapp.com/AuthEncumbr/CreateRecord';
   public static final String CREATE_AUTH_ENCMBR_SIT_URL = 'https://chatstranswssitfullapp.herokuapp.com/AuthEncumbr/CreateRecord';
    public static final String CREATE_AUTH_ENCMBR_PLT_URL = 'https://chatstranswspltapp.herokuapp.com/AuthEncumbr/CreateRecord';
    
   public static final String CREATE_AUTH_ENCMBR_JSON = '[{'
        +'"cde_Level_Care":"5",'
        +'"cde_Status_Encmbr":"4",'
        +'"cde_Type_Unit_Care":"4",'
        +'"cnt_Hour_Attnd_Actual":"0",'
        +'"cnt_Hour_Care":"0",'
        +'"dte_Care":"2012-12-12",'
        +'"createdbyid":"test",'
        +'"createddate":"2012-12-12 10:10:10",'
        +'"nbr_Seq_Hist":"1",'
        +'"lastmodifieddate":"2012-12-12 10:10:10",'
        +'"lastmodifiedbyid":"sahil"'
        +'}]';
    
    
   public static final String CREATE_AUTH_STATUS_DEV_URL = 'https://chatstranswsdevapp.herokuapp.com/AuthStatus/CreateRecord';
   public static final String CREATE_AUTH_STATUS_CI_URL = 'https://chatstranswsintapp.herokuapp.com/AuthStatus/CreateRecord';
   public static final String CREATE_AUTH_STATUS_SIT_URL ='https://chatstranswssitfullapp.herokuapp.com/AuthStatus/CreateRecord';
    public static final String CREATE_AUTH_STATUS_PLT_URL ='https://chatstranswspltapp.herokuapp.com/AuthStatus/CreateRecord';
    
   public static final String CREATE_AUTH_STATUS_JSON = '{"cde_Reason_Change_Auth":"T",'
        +'"cde_Status_Auth":"T",'
        +'"dte_Begin_Effv":"2019-12-12",'
        +'"dte_End_Effv":"2012-12-12",'
        +'"nbr_seq_hist": "2",'
        +'"createdbyid": "T",'
        +'"createddate": "2012-12-12 12:12:12",'
        +'"lastmodifieddate":"2012-12-12 12:12:12",'
        +'"lastmodifiedbyid":"salesforce"}';
    
    
   public static final String CREATE_CASE_COPAY_DEV_URL = 'https://chatstranswsdevapp.herokuapp.com/CaseCopay/CreateRecord';
   public static final String CREATE_CASE_COPAY_CI_URL = 'https://chatstranswsintapp.herokuapp.com/CaseCopay/CreateRecord';
   public static final String CREATE_CASE_COPAY_SIT_URL = 'https://chatstranswssitfullapp.herokuapp.com/CaseCopay/CreateRecord';
    public static final String CREATE_CASE_COPAY_PLT_URL = 'https://chatstranswspltapp.herokuapp.com/CaseCopay/CreateRecord';
    
   public static final String CREATE_CASE_COPAY_JSON = '{"amt_Copay_Case_Assesd":"1" ,'
        +'"amt_Copay_Case_Ft":"1",'
        +'"amt_Copay_Case_Pt":"1",'
        +'"cde_Reason_Ovrd":"R",'
        +'"cde_Rec_Copay":"R",'
        +'"dte_Begin_Effv":"2012-12-12",'
        +'"dte_End_Effv":"2012-12-12",'
        +'"nbr_Seq_Hist":"1",'
        +'"lastmodifiedbyid":"sahil",'
        +'"lastmodifieddate":"2012-12-12 12:12:12",'
        +'"createdbyid":"sahil",'
        +'"createddate":"2012-12-12 12:12:12",'
        +'"amt_Copay_Case_Ft_Qlty":"1" ,'
        +'"amt_Copay_Case_Pt_Qlty":"1" ,'
        +'"ind_Qlty":"Y"'
        +'}'; 
    
    // Update Care level
    
   public static final String Update_Care_Lvl_DEV_URL = 'https://chatstranswssitfullapp.herokuapp.com/AuthEncumbr/UpdateRecordsForCareLevel';
    public static final String Update_Care_Lvl_CI_URL = 'https://chatstranswssitfullapp.herokuapp.com/AuthEncumbr/UpdateRecordsForCareLevel';
   public static final String Update_Care_Lvl_SIT_URL = 'https://chatstranswssitfullapp.herokuapp.com/AuthEncumbr/UpdateRecordsForCareLevel';
    public static final String Update_Care_Lvl_PLT_URL = 'https://chatstranswspltapp.herokuapp.com/AuthEncumbr/UpdateRecordsForCareLevel';
    
   public static final String Update_Care_Lvl_JSON ='{"start_Date_36M":"2018-04-09 00:00:00","start_Date_SA":"2018-04-16 00:00:00"}';
    
   public static final String GENERATE_CORR_DEV_URL ='https://chatsdevapp.herokuapp.com/correspondence/generate?userId=userTest&corspdId=a1Qm0000000igYhEAI';
   public static final String GENERATE_CORR_CI_URL = 'https://chatsintapp.herokuapp.com/correspondence/generate?userId=userTest&corspdId=a1Sm0000003xjtnEAA';
   public static final String GENERATE_CORR_SIT_URL= 'https://chatssitfullapp.herokuapp.com/correspondence/generate?userId=userTest&corspdId=a1Q0t000000kPTEEA2';
    public static final String GENERATE_CORR_PLT_URL= 'https://chatspltapp.herokuapp.com/correspondence/generate?userId=userTest&corspdId=00541000005snuYAAQ';
    
}