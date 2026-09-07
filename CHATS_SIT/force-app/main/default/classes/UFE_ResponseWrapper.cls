global class UFE_ResponseWrapper {
    public string application_id{get;set;}
    public string home_county{get;set;}
    public string application_status{get;set;}
    public string case_id{get;set;}
    public string case_mode{get;set;}
    public string case_status{get;set;}
    public string waitlist_status{get;set;}
    public string eligibility_status{get;set;}
    public string referral_type{get;set;}
    public string rejection_reason{get;set;}
    public date submitted_date{get;set;}
    public date redetermination_date{get;set;}
    public List<String> parent_emails = new List<String>();
    public string user_facing_application_id{get;set;}
    public string user_facing_case_id{get;set;}
}