// REST endpoint for CCCAP provider, county, attendance, and holiday data.
@RestResource(urlMapping='/CccapPortalApi/v1/*')
global with sharing class CccapPortalApiV1 {
    
    private static final String ACTION_PROVIDER       = 'getProviderData';
    private static final String ACTION_CASE           = 'getCaseData';
    private static final String ACTION_AUTH           = 'getAuthData';
    private static final String ACTION_COUNTY         = 'getCountyData';
    private static final String ACTION_SERVICE_PERIOD = 'getServicePeriods';
    private static final String ACTION_SCHEDULES      = 'getSchedules';
    private static final String ACTION_FISCAL_RATES   = 'getFiscalRates';
    private static final String ACTION_PAYMENT_HISTORY = 'getPaymentHistory';
    private static final String ACTION_HOLIDAY_LIST    = 'getHolidayList';
    private static final String DECL_SCHEDULES_URL =
        'callout:DECL_Credential/services/apexrest/cccap/getSchedules/';
    
    private static final String STATUS_COUNTY_ACTIVE = 'APV';
    private static final String STATUS_OPEN_CASE     = 'OPN';
    private static final String CLASS_NAME           = 'CccapPortalApiV1';
    
    @HttpPost
    global static void doPost() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;
        String requestURI = req.requestURI;
        String action = requestURI.substring(requestURI.lastIndexOf('/') + 1);
        
        res.addHeader('Content-Type', 'application/json');
        
        try {
            Map<String, Object> body = (Map<String, Object>)
                JSON.deserializeUntyped(req.requestBody.toString());
            
            CccapPortalApiV1ResponseWrapper.ApiResponse result;
            
            if      (ACTION_PROVIDER.equals(action))       result = getProviderData(body);
            else if (ACTION_CASE.equals(action))           result = getCaseData(body);
            else if (ACTION_AUTH.equals(action))           result = getAuthData(body);
            else if (ACTION_COUNTY.equals(action))         result = getCountyData(body);
            else if (ACTION_SERVICE_PERIOD.equals(action)) result = getServicePeriods(body);
            else if (ACTION_SCHEDULES.equals(action))      result = getSchedules(body);
            else if (ACTION_FISCAL_RATES.equals(action))   result = getFiscalRates(body);
            else if (ACTION_PAYMENT_HISTORY.equals(action)) result = getPaymentHistory(body);
            else if (ACTION_HOLIDAY_LIST.equals(action))    result = getHolidayList(body);
            
            
            else {
                res.statusCode   = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    new CccapPortalApiV1ResponseWrapper.ApiResponse('Unknown action: ' + action)));
                return;
            }
            
            res.statusCode   = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(result));
            
        } catch (Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(
                ex, new Map<String, Object>{ 'Class__c' => CLASS_NAME, 'Method__c' => 'doPost' });
            res.statusCode   = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(
                new CccapPortalApiV1ResponseWrapper.ApiResponse(
                    'Provider data request could not be completed')));
        }
    }
    
    // Returns provider, fiscal agreement, and closure data.
    private static CccapPortalApiV1ResponseWrapper.ApiResponse getProviderData(
        Map<String, Object> params) {
            String userId = CCCAPGeneric.getString(params, 'userId');
            List<String> providerIds = new List<String>();
            if (String.isBlank(userId)) {
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                    'getProviderData requires userId');
            }
            
            try {
                List<Provider_Persona_MD__mdt> records = [
                    SELECT Id, RecordId__c
                    FROM Provider_Persona_MD__mdt
                    WHERE User_Id__c =: userId
                ];
                if (records.isEmpty()) {
                    return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                        'No provider persona mapping found for supplied userId');
                }
                
                String providerName = records[0].RecordId__c;
                CCCAPGeneric.DateRange activeDateRange = CCCAPGeneric.resolveDateRangeOrToday(params);
                Date activeStartDate = activeDateRange.startDate;
                Date activeEndDate = activeDateRange.endDate;
                
                List<T_CHATS_PROVR_STATUS__c> providers = [
                    SELECT Id, Name, NAM_FACILITY__c, TXT_CHATS_RATING__c, CDE_STATUS_PROVR__c,
                    CDE_TYPE_PROVR__c, CDE_TYPE_LICENSE__c, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c
                    FROM T_CHATS_PROVR_STATUS__c
                    WHERE Name =:providerName
                    WITH SYSTEM_MODE
                ];
                providerIds.add(providers[0].Id);
                List<T_PROVR_FISCAL_AGREMENT__c> faList = [
                    SELECT Id, Name, ID_SERVICE__c, CDE_COUNTY__c, CDE_COUNTY__r.Name,
                    CDE_TYPE_STATUS__c, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c,
                    (SELECT Id,CDE_RATE_TYPE__c,
                     IDN_EXTNL__c,
                     TXT_CHATS_RATING__c,
                     DTE_BEGIN_EFFV__c, DTE_END_EFFV__c
                     FROM Rate_Schedules__r
                     WHERE DTE_BEGIN_EFFV__c <= :activeEndDate
                     AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c >= :activeStartDate)
                     ORDER BY DTE_BEGIN_EFFV__c ASC)
                    FROM T_PROVR_FISCAL_AGREMENT__c
                    WHERE ID_SERVICE__c IN :providerIds
                    AND DTE_BEGIN_AGRMT__c <= :activeEndDate
                    AND (DTE_END_AGRMT__c = null OR DTE_END_AGRMT__c >= :activeStartDate)
                    WITH SYSTEM_MODE
                    ORDER BY ID_SERVICE__c ASC, DTE_BEGIN_AGRMT__c DESC
                ];
                
                List<T_PROVR_CLOSURE__c> closures = [
                    SELECT Id, IDN_PROVIDER__c, CDE_COUNTY__c, DTE_BEGIN_CLOSURE__c,
                    IND_ACTIVE__c, TXT_COMMENTS__c
                    FROM T_PROVR_CLOSURE__c
                    WHERE IDN_PROVIDER__c IN :providerIds
                    AND IND_ACTIVE__c = true
                    AND DTE_BEGIN_CLOSURE__c >= :activeStartDate
                    AND DTE_BEGIN_CLOSURE__c <= :activeEndDate
                    WITH SYSTEM_MODE
                    ORDER BY IDN_PROVIDER__c ASC, DTE_BEGIN_CLOSURE__c ASC
                ];
                
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(true,
                                                                       new Map<String, Object>{
                                                                           'providers'        => providers,
                                                                               'fiscalAgreements' => faList,
                                                                               'providerClosures' => closures
                                                                               });
                
            } catch (Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(
                    ex, new Map<String, Object>{ 'Class__c' => CLASS_NAME, 'Method__c' => 'getProviderData' });
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(ex.getMessage());
            }
        }
    
    // Returns fiscal-rate and fee rows for rate schedules belonging to the provider's agreements.
    private static CccapPortalApiV1ResponseWrapper.ApiResponse getFiscalRates(
        Map<String, Object> params) {
            List<String> providerIds = CCCAPGeneric.getStringList(params, 'providerIds');
            List<String> requestedScheduleIds = CCCAPGeneric.getStringList(params, 'fiscalScheduleIds');
            if (providerIds.isEmpty()) {
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                    'getFiscalRates requires providerIds');
            }
            
            try {
                CCCAPGeneric.DateRange activeDateRange = CCCAPGeneric.resolveDateRangeOrToday(params);
                Date activeStartDate = activeDateRange.startDate;
                Date activeEndDate = activeDateRange.endDate;
                
                Set<Id> agreementIds = new Set<Id>();
                for (T_PROVR_FISCAL_AGREMENT__c agreement : [
                    SELECT Id
                    FROM T_PROVR_FISCAL_AGREMENT__c
                    WHERE ID_SERVICE__c IN :providerIds
                    AND DTE_BEGIN_AGRMT__c <= :activeEndDate
                    AND (DTE_END_AGRMT__c = null OR DTE_END_AGRMT__c >= :activeStartDate)
                    WITH SYSTEM_MODE
                ]) {
                    agreementIds.add(agreement.Id);
                }
                if (agreementIds.isEmpty()) {
                    return new CccapPortalApiV1ResponseWrapper.ApiResponse(true,
                                                                           new Map<String, Object>{
                                                                               'fiscalSchedules' => new List<T_FISCAL_SCH__c>(),
                                                                                   'fiscalRates' => new List<batchsit_t_fiscal_rate__x>(),
                                                                                   'fiscalRateFees' => new List<T_FISCAL_RAT_FEES__c>()
                                                                                   });
                }
                
                List<T_FISCAL_SCH__c> fiscalSchedules = [
                    SELECT Id, Name, IDN_EXTNL__c, IDN_AGRMT_FISCAL__c,
                    CDE_RATE_TYPE__c, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c,
                    TXT_CHATS_RATING__c
                    FROM T_FISCAL_SCH__c
                    WHERE IDN_AGRMT_FISCAL__c IN :agreementIds
                    AND DTE_BEGIN_EFFV__c <= :activeEndDate
                    AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c >= :activeStartDate)
                    WITH SYSTEM_MODE
                    ORDER BY IDN_AGRMT_FISCAL__c ASC, DTE_BEGIN_EFFV__c ASC
                ];
                
                Set<Id> scheduleRecordIds = new Set<Id>();
                Set<String> scheduleExternalIds = new Set<String>();
                for (T_FISCAL_SCH__c schedule : fiscalSchedules) {
                    if (requestedScheduleIds.isEmpty() || requestedScheduleIds.contains(schedule.IDN_EXTNL__c)) {
                        scheduleRecordIds.add(schedule.Id);
                        if (String.isNotBlank(schedule.IDN_EXTNL__c)) {
                            scheduleExternalIds.add(schedule.IDN_EXTNL__c);
                        }
                    }
                }
                
                List<batchsit_t_fiscal_rate__x> fiscalRates = scheduleExternalIds.isEmpty()
                    ? new List<batchsit_t_fiscal_rate__x>()
                    : [
                        SELECT idn_fiscal_sch__c,
                        cde_age_group__c, cde_care_unit__c, cde_rate_type__c,
                        amt_cty__c, amt_fa__c, amt_provr__c
                        FROM batchsit_t_fiscal_rate__x
                        WHERE idn_fiscal_sch__c IN :scheduleExternalIds
                    ];
                        List<T_FISCAL_RAT_FEES__c> fiscalRateFees = scheduleRecordIds.isEmpty()
                        ? new List<T_FISCAL_RAT_FEES__c>()
                        : [
                            SELECT Id, Name, IDN_FISCAL_SCH__c,
                            CDE_ACT_FREQ__c, CDE_REG_FREQ__c, CDE_TRANS_FREQ__c,
                            TXT_ACT_MONTH__c, TXT_REG_MONTH__c, TXT_TRANS_MONTH__c,
                            AMT_ACT_FA__c,AMT_REG_FA__c,AMT_TRANS_FA__c
                            FROM T_FISCAL_RAT_FEES__c
                            WHERE IDN_FISCAL_SCH__c IN :scheduleRecordIds
                        ];
                            
                            return new CccapPortalApiV1ResponseWrapper.ApiResponse(true,
                                                                                   new Map<String, Object>{
                                                                                       'fiscalSchedules' => fiscalSchedules,
                                                                                           'fiscalRates' => fiscalRates,
                                                                                           'fiscalRateFees' => fiscalRateFees
                                                                                           });
            } catch (Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(
                    ex, new Map<String, Object>{ 'Class__c' => CLASS_NAME, 'Method__c' => 'getFiscalRates' });
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                    'Fiscal-rate source is unavailable');
            }
        }
    
    // Returns active cases and related children.
    private static CccapPortalApiV1ResponseWrapper.ApiResponse getCaseData(
        Map<String, Object> params) {
            
            List<String> countyIds   = CCCAPGeneric.getStringList(params, 'countyIds');
            List<String> providerIds = CCCAPGeneric.getStringList(params, 'providerIds');
            String singleCounty = CCCAPGeneric.getString(params, 'countyCode');
            if (String.isNotBlank(singleCounty) && !countyIds.contains(singleCounty)) countyIds.add(singleCounty);
            if (countyIds.isEmpty()) {
                return new CccapPortalApiV1ResponseWrapper.ApiResponse('getCaseData requires countyIds');
            }
            
            try {
                CCCAPGeneric.DateRange activeDateRange = CCCAPGeneric.resolveDateRangeOrToday(params);
                Date activeStartDate = activeDateRange.startDate;
                Date activeEndDate = activeDateRange.endDate;
                
                String soql =
                    'SELECT Id, Name, CDE_COUNTY__c, IDN_EXTNL__c, '
                    + '(SELECT IDN_CLIENT__c, IDN_CLIENT__r.NAM_FIRST__c, IDN_CLIENT__r.NAM_LAST__c, '
                    + ' IDN_CLIENT__r.DTE_DOB__c, IDN_CLIENT__r.CDE_GENDER__c, IND_CRTKR__c, '
                    + ' DTE_BEGIN_EFFV__c, DTE_END_EFFV__c, Individual_Status__c '
                    + ' FROM CaseIndividuals__r '
                    + ' WHERE DTE_BEGIN_EFFV__c <= :activeEndDate '
                    + 'AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c >= :activeStartDate)) '
                    + 'FROM T_SBSD_CASE__c '
                    + 'WHERE CDE_COUNTY__c IN (' + buildInClause(countyIds) + ') ';
                
                if (!providerIds.isEmpty()) {
                    soql += 'AND IDN_PROVR__c IN (' + buildInClause(providerIds) + ') ';
                }
                soql += 'WITH SYSTEM_MODE ORDER BY CDE_COUNTY__c ASC, Name ASC';
                
                List<T_SBSD_CASE__c> cases = Database.query(soql);
                
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(true,
                                                                       new Map<String, Object>{ 'cases' => cases });
                
            } catch (Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(
                    ex, new Map<String, Object>{ 'Class__c' => CLASS_NAME, 'Method__c' => 'getCaseData' });
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(ex.getMessage());
            }
        }
    
    // Returns active authorizations for the requested scope.
    private static CccapPortalApiV1ResponseWrapper.ApiResponse getAuthData(
        Map<String, Object> params) {
            
            List<String> caseIds     = CCCAPGeneric.getStringList(params, 'caseIds');
            List<String> countyIds   = CCCAPGeneric.getStringList(params, 'countyIds');
            List<String> providerIds = CCCAPGeneric.getStringList(params, 'providerIds');
            List<String> authIds     = CCCAPGeneric.getStringList(params, 'authIds');
            List<String> authNames   = CCCAPGeneric.getStringList(params, 'authNames');
            List<String> salesforceAuthIds = new List<String>();
            List<String> externalAuthIds = new List<String>();
            for (String authId : authIds) {
                try {
                    Id.valueOf(authId);
                    salesforceAuthIds.add(authId);
                } catch (Exception ignored) {
                    externalAuthIds.add(authId);
                }
            }
            
            String sc = CCCAPGeneric.getString(params, 'caseId');
            String sy = CCCAPGeneric.getString(params, 'countyCode');
            String sp = CCCAPGeneric.getString(params, 'providerId');
            if (String.isNotBlank(sc) && !caseIds.contains(sc))         caseIds.add(sc);
            if (String.isNotBlank(sy) && !countyIds.contains(sy))       countyIds.add(sy);
            if (String.isNotBlank(sp) && !providerIds.contains(sp))     providerIds.add(sp);
            
            if (caseIds.isEmpty() && countyIds.isEmpty() && providerIds.isEmpty()
                && authIds.isEmpty() && authNames.isEmpty()) {
                    return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                        'getAuthData requires caseIds, countyIds, providerIds, authIds, or authNames');
                }
            
            try {
                CCCAPGeneric.DateRange activeDateRange = CCCAPGeneric.resolveDateRangeOrToday(params);
                Date activeStartDate = activeDateRange.startDate;
                Date activeEndDate = activeDateRange.endDate;
                
                String soql =
                    'SELECT Id, Name, IDN_EXTNL__c, IDN_CASE__c, IDN_PROVR__c, IDN_CLIENT__c, '
                    + 'IDN_SLOT_CONTRACT__c, CDE_COUNTY__c, AMT_ACTV_AUTH__c, AMT_RGSTR_AUTH__c, AMT_TRANSP_AUTH__c, '
                    + 'CDE_TYPE_VERIF__c, CDE_TRANS_FEE__c, CDE_CHILD_ENROLLED_IN_UPK__c, '
                    + 'Contract_for_Slots_indicator__c, Do_we_need_to_allow_drop_in_days_for__c, '
                    + 'DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, toLabel(Authorization_Status__c), '
                    + 'Number_of_Drop_in_Days__c '
                    + 'FROM T_AUTH__c '
                    + 'WHERE DTE_BEGIN_EFFV_AUTH__c <= :activeEndDate '
                    + 'AND (DTE_END_EFFV_AUTH__c = null OR DTE_END_EFFV_AUTH__c >= :activeStartDate) ';
                
                if (!caseIds.isEmpty())     soql += 'AND IDN_CASE__c IN ('   + buildInClause(caseIds)     + ') ';
                if (!countyIds.isEmpty())   soql += 'AND CDE_COUNTY__c IN (' + buildInClause(countyIds)   + ') ';
                if (!providerIds.isEmpty()) soql += 'AND IDN_PROVR__c IN ('  + buildInClause(providerIds) + ') ';
                if (!salesforceAuthIds.isEmpty() || !externalAuthIds.isEmpty()) {
                    List<String> authFilters = new List<String>();
                    if (!salesforceAuthIds.isEmpty()) authFilters.add('Id IN (' + buildInClause(salesforceAuthIds) + ')');
                    if (!externalAuthIds.isEmpty()) {
                        authFilters.add('IDN_EXTNL__c IN (' + buildInClause(externalAuthIds) + ')');
                        authFilters.add('Name IN (' + buildInClause(externalAuthIds) + ')');
                    }
                    soql += 'AND (' + String.join(authFilters, ' OR ') + ') ';
                }
                if (!authNames.isEmpty())   soql += 'AND Name IN ('          + buildInClause(authNames)   + ') ';
                soql += 'WITH SYSTEM_MODE ORDER BY CDE_COUNTY__c ASC, Name ASC';
                
                List<T_AUTH__c> authorizations = Database.query(soql);
                Set<Id> slotContractIds = new Set<Id>();
                Set<String> authorizationExternalIds = new Set<String>();
                for (T_AUTH__c authorization : authorizations) {
                    if (authorization.IDN_SLOT_CONTRACT__c != null) {
                        slotContractIds.add(authorization.IDN_SLOT_CONTRACT__c);
                    }
                    if (String.isNotBlank(authorization.IDN_EXTNL__c)) {
                        authorizationExternalIds.add(authorization.IDN_EXTNL__c);
                    }
                }
                List<T_SLOT_CONTRACT__c> slotContracts = slotContractIds.isEmpty()
                    ? new List<T_SLOT_CONTRACT__c>()
                    : [
                        SELECT Id, Name, IDN_PROVIDER__c, IDN_AUTH__c, IDN_ADDENDUM__c,
                        CDE_COUNTY__c, CDE_CARE_UNIT__c, CDE_CARE_LEVEL__c, CDE_RATE_TYPE__c,
                        CDE_PRG_TYPE__c, CNT_DAYS_OF_MONTH__c, CNT_DAYS_OF_WEEK__c,
                        DTE_BEGIN_SLOT__c, DTE_END_SLOT__c, IND_OCCUPIED__c,
                        IND_FUTURE_VACANT__c, IND_AVAILABLE__c, SLOT_CONTRACT_DESCRIPTION__c
                        FROM T_SLOT_CONTRACT__c
                        WHERE Id IN :slotContractIds
                        WITH SYSTEM_MODE
                    ];
                        List<batchsit_t_auth_encmbr__x> encumbrances = authorizationExternalIds.isEmpty()
                        ? new List<batchsit_t_auth_encmbr__x>()
                        : [
                            SELECT Id, idn_auth__c, idn_encmbr_auth__c, dte_care__c,
                            cnt_hour_care__c, cnt_hour_attnd_actual__c, cde_status_encmbr__c,
                            cde_type_unit_care__c, cde_level_care__c, ind_0_36_months__c
                            FROM batchsit_t_auth_encmbr__x
                            WHERE idn_auth__c IN :authorizationExternalIds 
                            and dte_care__c>=:activeStartDate and dte_care__c<=:activeEndDate
                        ];
                            List<batchsit_t_auth_copay__x> authorizationCopays = authorizationExternalIds.isEmpty()
                            ? new List<batchsit_t_auth_copay__x>()
                            : [
                                SELECT Id, idn_auth__c, idn_copay_auth__c,
                                dte_begin_effv__c, dte_end_effv__c, amt_copay_auth__c
                                FROM batchsit_t_auth_copay__x
                                WHERE idn_auth__c IN :authorizationExternalIds
                            ];
                                
                                return new CccapPortalApiV1ResponseWrapper.ApiResponse(true,
                                                                                       new Map<String, Object>{
                                                                                           'authorizations' => authorizations,
                                                                                               'slotContracts' => slotContracts,
                                                                                               'encumbrances' => encumbrances,
                                                                                               'authorizationCopays' => authorizationCopays
                                                                                               });
                
            } catch (Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(
                    ex, new Map<String, Object>{ 'Class__c' => CLASS_NAME, 'Method__c' => 'getAuthData' });
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(ex.getMessage());
            }
        }
    
    // Returns active county rate plans and attendance limits.
    private static CccapPortalApiV1ResponseWrapper.ApiResponse getCountyData(
        Map<String, Object> params) {
            
            List<String> countyIds = CCCAPGeneric.getStringList(params, 'countyIds');
            String single = CCCAPGeneric.getString(params, 'countyCode');
            if (String.isNotBlank(single) && !countyIds.contains(single)) countyIds.add(single);
            if (countyIds.isEmpty()) {
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                    'getCountyData requires countyIds or countyCode');
            }
            
            try {
                CCCAPGeneric.DateRange activeDateRange = CCCAPGeneric.resolveDateRangeOrToday(params);
                Date activeStartDate = activeDateRange.startDate;
                Date activeEndDate = activeDateRange.endDate;
                
                List<T_COUNTY_RATE__c> ratePlans = [
                    SELECT Id, Name, CDE_STATUS__c, IDN_COUNTY__c,IDN_COUNTY__r.Name,
                    DTE_BEGIN_EFFV_RATE__c, DTE_END_EFFV_RATE__c,
                    PAYMENT_Q13_a__c, PAYMENT_Q13_b__c, PAYMENT_Q13_c__c,
                    PAYMENT_Q13_d__c, PAYMENT_Q13_e__c, PAYMENT_Q13_2__c,
                    PAYMENT_Q13_1__c, PAYMENT_Q14__c, PAYMENT_Q14_1__c, PAYMENT_Q14_2__c,
                    PAYMENT_Q14_3__c
                    FROM T_COUNTY_RATE__c
                    WHERE CDE_STATUS__c           = :STATUS_COUNTY_ACTIVE
                    AND IND_RATE_PLAN_TEMPLT__c = false
                    AND IDN_COUNTY__c           IN :countyIds
                    AND DTE_BEGIN_EFFV_RATE__c  <= :activeEndDate
                    AND (DTE_END_EFFV_RATE__c = null OR DTE_END_EFFV_RATE__c >= :activeStartDate)
                    WITH SYSTEM_MODE
                    ORDER BY IDN_COUNTY__c ASC, DTE_BEGIN_EFFV_RATE__c DESC
                ];
                
                List<Map<String, Object>> result = new List<Map<String, Object>>();
                for (T_COUNTY_RATE__c p : ratePlans) {
                    result.add(new Map<String, Object>{
                        'planId'                  => p.Id,
                            'planName'                => p.Name,
                            'countyId'                => p.IDN_COUNTY__c,
                            'countyName'			  => p.IDN_COUNTY__r.Name,
                            'status'                  => p.CDE_STATUS__c,
                            'effectiveBeginDate'      => p.DTE_BEGIN_EFFV_RATE__c,
                            'effectiveEndDate'        => p.DTE_END_EFFV_RATE__c,
                            'absenceDaysTier1'        => p.PAYMENT_Q13_a__c,
                            'absenceDaysTier2'        => p.PAYMENT_Q13_b__c,
                            'absenceDaysTier3'        => p.PAYMENT_Q13_c__c,
                            'absenceDaysTier4'        => p.PAYMENT_Q13_d__c,
                            'absenceDaysTier5'        => p.PAYMENT_Q13_e__c,
                            'allowPaidHolidays?'       => p.PAYMENT_Q13_2__c,
                            'countyholidayList'       => p.PAYMENT_Q13_1__c,
                            'allowDropInDays'         => p.PAYMENT_Q14__c,
                            'maxDropInDaysPerMonth'   => p.PAYMENT_Q14_1__c,
                            'dropInResponse'          => p.PAYMENT_Q14_2__c,
                            'manageDropInAtAuthLevel' => p.PAYMENT_Q14_3__c
                            });
                }
                
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(true,
                                                                       new Map<String, Object>{ 'countyRatePlans' => result });
                
            } catch (Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(
                    ex, new Map<String, Object>{ 'Class__c' => CLASS_NAME, 'Method__c' => 'getCountyData' });
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(ex.getMessage());
            }
        }
    
    // Returns service periods via the shared service-period filter builder.
    private static CccapPortalApiV1ResponseWrapper.ApiResponse getServicePeriods(
        Map<String, Object> params) {
            try {
                if (!ServicePeriodService.hasSupportedInput(params)) {
                    return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                        'getServicePeriods requires dateFilter, dateOn, or paymentAfter');
                }
                
                ServicePeriodService.ServicePeriodFilters f =
                    ServicePeriodService.buildFilters(params);
                
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(true,
                                                                       new Map<String, Object>{
                                                                           'servicePeriods' => ServicePeriodService.getServicePeriods(f)
                                                                               });
            } catch (Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(
                    ex, new Map<String, Object>{ 'Class__c' => CLASS_NAME, 'Method__c' => 'getServicePeriods' });
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(ex.getMessage());
            }
        }
    
    // Returns read-only sub-payment history scoped to the authenticated provider and service periods.
    private static CccapPortalApiV1ResponseWrapper.ApiResponse getPaymentHistory(
        Map<String, Object> params) {
            List<String> providerIds = CCCAPGeneric.getStringList(params, 'providerIds');
            if (providerIds.isEmpty()) {
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                    'getPaymentHistory requires providerIds');
            }
            if (String.isBlank(CCCAPGeneric.getString(params, 'dateFilter'))) {
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                    'getPaymentHistory requires dateFilter');
            }
            try {
                CCCAPGeneric.DateRange serviceDateRange = CCCAPGeneric.resolveDateRange(params);
                Date serviceStartDate = serviceDateRange.startDate;
                Date serviceEndDate = serviceDateRange.endDate;
                Set<Id> servicePeriodRecordIds = new Set<Id>();
                Set<String> servicePeriodIds = new Set<String>();
                for (T_SERV_PERIOD__c servicePeriod : [
                    SELECT Id, IDN_EXTNL__c
                    FROM T_SERV_PERIOD__c
                    WHERE DTE_BEGIN_EFFV__c <= :serviceEndDate
                    AND DTE_END_EFFV__c >= :serviceStartDate
                    AND IDN_EXTNL__c != null
                    WITH SYSTEM_MODE
                ]) {
                    servicePeriodRecordIds.add(servicePeriod.Id);
                    servicePeriodIds.add(servicePeriod.IDN_EXTNL__c);
                }
                
                if (servicePeriodIds.isEmpty()) {
                    return new CccapPortalApiV1ResponseWrapper.ApiResponse(true,
                                                                           new Map<String, Object>{
                                                                               'servicePeriodStart' => serviceStartDate,
                                                                                   'servicePeriodEnd' => serviceEndDate,
                                                                                   'servicePeriodIds' => new List<String>(),
                                                                                   'payments' => new List<T_PAYMT__c>(),
                                                                                   'subPayments' => new List<batchsit_t_sub_pmt__x>()
                                                                                   });
                }
                
                List<T_PAYMT__c> payments = [
                    SELECT Id, IDN_EXTNL__c, IDN_PROVR__c, IDN_PERIOD_SERV__c,
                    DTE_PAID_PMT__c, CDE_STATUS_PMT__c, CDE_METHOD_PMT__c,
                    AMT_PMT__c, AMT_SLOT_PMT__c
                    FROM T_PAYMT__c
                    WHERE IDN_PROVR__c IN :providerIds
                    AND IDN_PERIOD_SERV__c IN :servicePeriodRecordIds
                    AND IDN_EXTNL__c != null
                    WITH SYSTEM_MODE
                    ORDER BY IDN_PERIOD_SERV__c ASC, DTE_PAID_PMT__c ASC
                ];
                Set<String> paymentExternalIds = new Set<String>();
                for (T_PAYMT__c payment : payments) {
                    paymentExternalIds.add(payment.IDN_EXTNL__c);
                }
                
                List<batchsit_t_sub_pmt__x> subPayments = paymentExternalIds.isEmpty()
                    ? new List<batchsit_t_sub_pmt__x>()
                    : [
                        SELECT Id, ExternalId, idn_pmt_sub__c, idn_auth__c, idn_period_serv__c,
                        idn_slot_contract__c, cde_status_pmt_sub__c,
                        amt_total_pmt_sub__c, amt_rate_pmt_sub__c,
                        amt_copay_pmt_sub__c, amt_slot_pmt_sub__c
                        FROM batchsit_t_sub_pmt__x
                        WHERE idn_pmt__c IN :paymentExternalIds
                        AND idn_period_serv__c IN :servicePeriodIds
                        WITH SYSTEM_MODE
                        ORDER BY idn_period_serv__c ASC, idn_auth__c ASC
                    ];
                        Set<String> subPaymentExternalIds = new Set<String>();
                Set<Decimal> subPaymentNumericIds = new Set<Decimal>();
                for (batchsit_t_sub_pmt__x subPayment : subPayments) {
                    if (subPayment.idn_pmt_sub__c != null) {
                        subPaymentExternalIds.add(String.valueOf(subPayment.idn_pmt_sub__c));
                        subPaymentNumericIds.add(subPayment.idn_pmt_sub__c);
                    }
                }
                List<batchsit_t_sub_pmt_detail__x> paymentDetails = subPaymentExternalIds.isEmpty()
                    ? new List<batchsit_t_sub_pmt_detail__x>()
                    : [
                        SELECT Id, idn_detail_pmt_sub__c, idn_pmt_sub__c, idn_fiscal_rat_fee__c,
                        dte_care__c, cde_type_unit_care__c, cde_unit_care_exptd__c,
                        cde_type_info_addntl__c, cde_time_trdnl__c, cde_status_detail_pmt_sub__c,
                        cde_level_care__c, amt_rate__c, amt_total__c, amt_act_paid__c,
                        amt_copay__c, amt_reg_paid__c, amt_slot_paid__c, amt_trans_paid__c,
                        ind_0_36_months_enroll_pmt__c, ind_adjmt__c, ind_claim__c, ind_recovery__c
                        FROM batchsit_t_sub_pmt_detail__x
                        WHERE idn_pmt_sub__c IN :subPaymentExternalIds
                    ];
                        List<batchsit_t_sub_pmt_detail_hist__x> paymentDetailHistory = subPaymentNumericIds.isEmpty()
                        ? new List<batchsit_t_sub_pmt_detail_hist__x>()
                        : [
                            SELECT Id, idn_detail_pmt_sub_hist__c, idn_detail_pmt_sub__c, idn_pmt_sub__c,
                            idn_fiscal_rat_fee__c, dte_care__c, cde_type_unit_care__c,
                            cnt_unit_care_exptd__c, cnt_unit_care_actual__c, cde_type_info_addntl__c,
                            cde_time_trdnl__c, cde_status_detail_pmt_sub__c, cde_level_care__c,
                            amt_rate__c, amt_total__c, amt_act_paid__c, amt_copay__c,
                            amt_reg_paid__c, amt_trans_paid__c, ind_slots_for_cntrct__c,
                            ind_adjmt__c, ind_record_delete_logcl__c
                            FROM batchsit_t_sub_pmt_detail_hist__x
                            WHERE idn_pmt_sub__c IN :subPaymentNumericIds
                        ];
                            return new CccapPortalApiV1ResponseWrapper.ApiResponse(true,
                                                                                   new Map<String, Object>{
                                                                                       'servicePeriodStart' => serviceStartDate,
                                                                                           'servicePeriodEnd' => serviceEndDate,
                                                                                           'servicePeriodIds' => servicePeriodIds,
                                                                                           'payments' => payments,
                                                                                           'subPayments' => subPayments,
                                                                                           'paymentDetails' => paymentDetails,
                                                                                           'paymentDetailHistory' => paymentDetailHistory
                                                                                           });
            } catch (Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(
                    ex, new Map<String, Object>{ 'Class__c' => CLASS_NAME, 'Method__c' => 'getPaymentHistory' });
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                    'Payment history source is unavailable');
            }
        }
    private static CccapPortalApiV1ResponseWrapper.ApiResponse getHolidayList(
        Map<String, Object> params) {
            
            try {
                CCCAPGeneric.DateRange dateRange = CCCAPGeneric.resolveOptionalDateRange(params);
                Date holidayStartDate = dateRange == null ? null : dateRange.startDate;
                Date holidayEndDate = dateRange == null ? null : dateRange.endDate;
                
                String soql =
                    'SELECT toLabel(CDE_HOL__c), DTE_HOL__c, DTE_OBSERVED_HOL__c '
                    + 'FROM T_YEAR_HOL__c';
                if (dateRange != null) {
                    soql += ' WHERE (DTE_HOL__c >= :holidayStartDate '
                        + 'AND DTE_HOL__c <= :holidayEndDate) '
                        + 'OR (DTE_OBSERVED_HOL__c >= :holidayStartDate '
                        + 'AND DTE_OBSERVED_HOL__c <= :holidayEndDate)';
                }
                soql += ' ORDER BY DTE_HOL__c ASC';
                
                List<T_YEAR_HOL__c> holidays = Database.query(soql);
                
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(true,
                                                                       new Map<String, Object>{ 'holidayList' => holidays });
            } catch (Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(
                    ex, new Map<String, Object>{ 'Class__c' => CLASS_NAME, 'Method__c' => 'getHolidayList' });
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(ex.getMessage());
            }
        }
    
    // Returns schedules for the requested scope via DECL schedules endpoint.
    private static CccapPortalApiV1ResponseWrapper.ApiResponse getSchedules(
        Map<String, Object> params) {
            
            List<String> providerIds = CCCAPGeneric.getStringList(params, 'providerIds');
            List<String> authNames = CCCAPGeneric.getStringList(params, 'authNames');
            
            if (providerIds.isEmpty()) {
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                    'getSchedules requires providerIds');
            }
            
            try {
                String dateFilterInput = CCCAPGeneric.getString(params, 'dateFilter');
                if (String.isBlank(dateFilterInput)) {
                    return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                        'getSchedules requires dateFilter');
                }
                CCCAPGeneric.DateRange dateRange = CCCAPGeneric.resolveDateRangeFromParams(params);
                
                Set<Id> accIds = new Set<Id>();
                for(T_CHATS_PROVR_STATUS__c prov : [select Program_Name__c from T_CHATS_PROVR_STATUS__c where id in :providerIds with SYSTEM_MODE]){
                    accIds.add(prov.Program_Name__c);
                }
                
                List<String> declProviderIds = new List<String>();
                for (Id accId : accIds) {
                    declProviderIds.add(String.valueOf(accId));
                }
                if (declProviderIds.isEmpty()) {
                    return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                        'No mapped provider account IDs found for supplied providerIds');
                }
                
                Map<String, Object> declRequest = new Map<String, Object>{
                    'providerIds' => declProviderIds,
                        'dateFilter' => 'DATE_RANGE',
                        'dateFrom' => String.valueOf(dateRange.startDate),
                        'dateTo' => String.valueOf(dateRange.endDate)
                        };
                            if (!authNames.isEmpty()) {
                                declRequest.put('authNames', authNames);
                            }
                
                HttpRequest req = new HttpRequest();
                req.setEndpoint(DECL_SCHEDULES_URL);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('Accept', 'application/json');
                req.setMethod('POST');
                req.setBody(JSON.serialize(declRequest));
                
                HttpResponse response = new Http().send(req);
                if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
                    ExceptionLoggingServices.captureExceptionLog(
                        response,
                        req,
                        new Map<String, Object>{ 'Class__c' => CLASS_NAME, 'Method__c' => 'getSchedules' }
                    );
                    return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                        'DECL schedules API call failed with status ' + response.getStatusCode());
                }
                
                Map<String, Object> declResponse =
                    (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if (!CCCAPGeneric.getBoolean(declResponse, 'success', false)) {
                    return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                        'Attendance source is unavailable');
                }
                
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(true,
                                                                       new Map<String, Object>{
                                                                           'schedules' => declResponse.get('schedules')
                                                                               });
                
            } catch (Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(
                    ex, new Map<String, Object>{ 'Class__c' => CLASS_NAME, 'Method__c' => 'getSchedules' });
                return new CccapPortalApiV1ResponseWrapper.ApiResponse(
                    'Attendance source is unavailable');
            }
        }
    
    // Builds an escaped SOQL IN clause.
    @TestVisible
    private static String buildInClause(List<String> values) {
        List<String> quoted = new List<String>();
        for (String val : values) quoted.add('\'' + String.escapeSingleQuotes(val) + '\'');
        return String.join(quoted, ',');
    }
    
    @TestVisible
    private static String buildNumericInClause(List<String> values) {
        List<String> numbers = new List<String>();
        for (String value : values) {
            if (!Pattern.matches('^[0-9]+$', value)) {
                throw new IllegalArgumentException('Provider name must be numeric');
            }
            numbers.add(value);
        }
        return String.join(numbers, ',');
    }
}