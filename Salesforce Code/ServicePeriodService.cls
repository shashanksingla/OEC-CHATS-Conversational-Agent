/**
 * ServicePeriodService
 *
 * One query. Dynamic WHERE clause built from whichever filters the agent supplies.
 * Falls back to ISO-week arithmetic when T_SERV_PERIOD__c returns no rows.
 *
 * T_SERV_PERIOD__c fields:
 *   Id
 *   IDN_EXTNL__c          — external ID used as servicePeriodId
 *   DTE_BEGIN_EFFV__c     — service period start date
 *   DTE_END_EFFV__c       — service period end date
 *   DTE_BATCH_FILE_PMT__c — payment processing date (Thursday payroll)
 *   DTE_BATCH_PRCS_PMT__c — payment release date (Friday)
 *
 * Filters (all optional — agent passes only what it needs):
 *
 *   dateOn        Date     Period window contains this date (TODAY only).
 *   dateFrom      Date     DTE_BEGIN_EFFV__c >= dateFrom.
 *   dateTo        Date     DTE_END_EFFV__c   <= dateTo.
 *   paymentAfter  Date     DTE_BATCH_FILE_PMT__c > paymentAfter (TODAY only).
 *   limitOne      Boolean  Add LIMIT 1 to get the first matching record.
 */
public with sharing class ServicePeriodService {

    private static final Integer DAYS_TO_PROCESSING = 11;

    private static final String BASE_QUERY =
        'SELECT Id, IDN_EXTNL__c, ' +
        '       DTE_BEGIN_EFFV__c, DTE_END_EFFV__c, ' +
        '       DTE_BATCH_FILE_PMT__c, DTE_BATCH_PRCS_PMT__c ' +
        'FROM T_SERV_PERIOD__c';

    // ─── Public API ───────────────────────────────────────────────────────────

    /**
     * Returns service periods matching the supplied filters.
     * Builds one dynamic SOQL query from the active filter fields.
     *
     * @param filters  ServicePeriodFilters — set only the fields you need.
     * @return         List<ServicePeriodResult> ordered by DTE_BEGIN_EFFV__c ASC.
     */
    public static List<ServicePeriodResult> getServicePeriods(ServicePeriodFilters filters) {
        if (filters == null) {
            filters = new ServicePeriodFilters();
        }

        // ── Build WHERE clauses ───────────────────────────────────────────────
        List<String> whereClauses = new List<String>();

        if (filters.dateOn != null) {
            // Period window must contain the supplied date
            String dateOnStr = formatDate(filters.dateOn);
            whereClauses.add('DTE_BEGIN_EFFV__c <= ' + dateOnStr);
            whereClauses.add('DTE_END_EFFV__c >= ' + dateOnStr);
        }

        if (filters.dateFrom != null) {
            whereClauses.add('DTE_BEGIN_EFFV__c >= ' + formatDate(filters.dateFrom));
        }

        if (filters.dateTo != null) {
            whereClauses.add('DTE_END_EFFV__c <= ' + formatDate(filters.dateTo));
        }

        if (filters.paymentAfter != null) {
            whereClauses.add('DTE_BATCH_FILE_PMT__c > ' + formatDate(filters.paymentAfter));
        }

        // ── Assemble query ────────────────────────────────────────────────────
        String query = BASE_QUERY;
        if (!whereClauses.isEmpty()) {
            query += ' WHERE ' + String.join(whereClauses, ' AND ');
        }

        // Order by begin date; paymentAfter intent uses processing date ascending
        String orderField = (filters.paymentAfter != null && filters.dateOn == null
                             && filters.dateFrom == null)
                            ? 'DTE_BATCH_FILE_PMT__c'
                            : 'DTE_BEGIN_EFFV__c';
        query += ' ORDER BY ' + orderField + ' ASC';

        if (filters.limitOne == true) {
            query += ' LIMIT 1';
        }

        // ── Execute ───────────────────────────────────────────────────────────
        List<T_SERV_PERIOD__c> rows = Database.query(query);  // WITH SECURITY_ENFORCED via FLS on query string is not supported; caller must be with sharing

        // ── Map or fall back ──────────────────────────────────────────────────
        if (!rows.isEmpty()) {
            List<ServicePeriodResult> results = new List<ServicePeriodResult>();
            for (T_SERV_PERIOD__c r : rows) {
                results.add(fromRecord(r));
            }
            return results;
        }

        return computeFallback(filters);
    }

    public static ServicePeriodFilters buildFilters(Map<String, Object> requestMap) {
        ServicePeriodFilters filters = new ServicePeriodFilters();
        if (requestMap == null) {
            return filters;
        }

        String dateFilter = CCCAPGeneric.getString(requestMap, 'dateFilter');
        if (String.isNotBlank(dateFilter)) {
            CCCAPGeneric.DateRange dateRange = CCCAPGeneric.resolveDateRange(requestMap);
            if ('TODAY'.equals(dateFilter.trim().toUpperCase())) {
                filters.dateOn = dateRange.startDate;
            } else {
                filters.dateFrom = dateRange.startDate;
                filters.dateTo = dateRange.endDate;
            }
        } else if (isTodaySwitch(requestMap, 'dateOn')) {
            filters.dateOn = Date.today();
        } else if (isTodaySwitch(requestMap, 'paymentAfter')) {
            filters.paymentAfter = Date.today();
        }

        filters.limitOne = CCCAPGeneric.getBoolean(requestMap, 'limitOne', null);
        return filters;
    }

    public static Boolean hasSupportedInput(Map<String, Object> requestMap) {
        if (requestMap == null) {
            return false;
        }

        return String.isNotBlank(CCCAPGeneric.getString(requestMap, 'dateFilter'))
            || isTodaySwitch(requestMap, 'dateOn')
            || isTodaySwitch(requestMap, 'paymentAfter');
    }

    // ─── Filter class ─────────────────────────────────────────────────────────

    public class ServicePeriodFilters {
        /** Period window must contain this date (pass Date.today() for current week). */
        public Date    dateOn;
        /** Lower bound: DTE_BEGIN_EFFV__c >= dateFrom. */
        public Date    dateFrom;
        /** Upper bound: DTE_END_EFFV__c <= dateTo. */
        public Date    dateTo;
        /** First period whose payment run has not yet happened (pass Date.today()). */
        public Date    paymentAfter;
        /** Limit results to 1 record. */
        public Boolean limitOne;
    }

    // ─── Result class ─────────────────────────────────────────────────────────

    public class ServicePeriodResult {
        public String  servicePeriodId;       // IDN_EXTNL__c or computed SP-YYYY-MM-DD
        public Date    serviceBeginDate;      // DTE_BEGIN_EFFV__c
        public Date    serviceEndDate;        // DTE_END_EFFV__c
        public Date    paymentProcessingDate; // DTE_BATCH_FILE_PMT__c
        public Date    paymentReleaseDate;    // DTE_BATCH_PRCS_PMT__c
        public String  status;               // RELEASED | SCHEDULED
        public Boolean fromStoredRecord;
        public String  storedRecordId;
    }

    // ─── Private: map stored record ───────────────────────────────────────────

    private static ServicePeriodResult fromRecord(T_SERV_PERIOD__c r) {
        ServicePeriodResult res   = new ServicePeriodResult();
        res.serviceBeginDate      = r.DTE_BEGIN_EFFV__c;
        res.serviceEndDate        = r.DTE_END_EFFV__c;
        res.paymentProcessingDate = r.DTE_BATCH_FILE_PMT__c;
        res.paymentReleaseDate    = r.DTE_BATCH_PRCS_PMT__c;
        res.fromStoredRecord      = true;
        res.storedRecordId        = r.Id;
        res.servicePeriodId       = String.isNotBlank(r.IDN_EXTNL__c)
            ? r.IDN_EXTNL__c
            : 'SP-' + String.valueOf(r.DTE_BEGIN_EFFV__c).substring(0, 10);
        Date releaseDate = r.DTE_BATCH_PRCS_PMT__c != null
            ? r.DTE_BATCH_PRCS_PMT__c
            : (r.DTE_END_EFFV__c != null ? r.DTE_END_EFFV__c.addDays(12) : null);
        res.status = (releaseDate != null && releaseDate < Date.today())
            ? 'RELEASED' : 'SCHEDULED';
        return res;
    }

    // ─── Private: compute fallback ────────────────────────────────────────────

    private static List<ServicePeriodResult> computeFallback(ServicePeriodFilters f) {
        List<ServicePeriodResult> results = new List<ServicePeriodResult>();

        if (f.dateOn != null) {
            // Single period containing dateOn
            results.add(computeForDate(f.dateOn));
        } else if (f.paymentAfter != null && f.dateFrom == null) {
            // Next upcoming Thursday payroll
            Date base   = f.paymentAfter;
            Integer dow = Integer.valueOf(
                Datetime.newInstance(base, Time.newInstance(0, 0, 0, 0)).format('u'));
            Integer gap = Math.mod(4 - dow + 7, 7);
            Date thu    = base.addDays(gap == 0 ? 7 : gap);
            results.add(computeForMonday(thu.addDays(-(DAYS_TO_PROCESSING + 6))));
        } else if (f.dateFrom != null) {
            // Generate weekly periods across the range
            Date rangeEnd = f.dateTo != null ? f.dateTo : f.dateFrom.addDays(34);
            Date monday   = mondayOf(f.dateFrom);
            Integer guard = 0;
            while (monday <= rangeEnd && guard < 8) {
                ServicePeriodResult r = computeForMonday(monday);
                if (f.dateTo == null || r.serviceEndDate <= f.dateTo) {
                    results.add(r);
                }
                monday = monday.addDays(7);
                guard++;
            }
        } else {
            results.add(computeForDate(Date.today()));
        }

        if (f.limitOne == true && results.size() > 1) {
            return new List<ServicePeriodResult>{ results[0] };
        }
        return results;
    }

    private static ServicePeriodResult computeForDate(Date d) {
        return computeForMonday(mondayOf(d));
    }

    private static ServicePeriodResult computeForMonday(Date monday) {
        Date sunday     = monday.addDays(6);
        Date processing = sunday.addDays(DAYS_TO_PROCESSING);
        Date release    = processing.addDays(1);
        ServicePeriodResult r   = new ServicePeriodResult();
        r.servicePeriodId       = 'SP-' + String.valueOf(monday).substring(0, 10);
        r.serviceBeginDate      = monday;
        r.serviceEndDate        = sunday;
        r.paymentProcessingDate = processing;
        r.paymentReleaseDate    = release;
        r.status                = release < Date.today() ? 'RELEASED' : 'SCHEDULED';
        r.fromStoredRecord      = false;
        r.storedRecordId        = null;
        return r;
    }

    // ─── Private: date formatting for dynamic SOQL ────────────────────────────

    /**
     * Formats a Date as the SOQL date literal "YYYY-MM-DD" (no quotes needed
     * in the WHERE string — Apex Date values in dynamic SOQL are unquoted).
     */
    private static String formatDate(Date d) {
        return String.valueOf(d).substring(0, 10);
    }

    @TestVisible
    public static Boolean isTodaySwitch(Map<String, Object> requestMap, String key) {
        Object rawValue = requestMap == null ? null : requestMap.get(key);
        if (rawValue == null) {
            return false;
        }

        String value = String.valueOf(rawValue).trim().toUpperCase();
        return value == 'TODAY' || value == 'TRUE';
    }

    @TestVisible
    private static Date mondayOf(Date d) {
        Integer dow = Integer.valueOf(
            Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('u'));
        return d.addDays(-(dow - 1));
    }
}