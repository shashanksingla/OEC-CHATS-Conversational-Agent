public class CCCAPGeneric {
    public static DateRange resolveDateRange(Map<String, Object> requestMap) {
        String filter = getString(requestMap, 'dateFilter');
        filter = normalizeDateFilter(filter);
        
        Date today = Date.today();
        
        if (filter == 'TODAY') {
            return new DateRange(today, today);
        }
        
        if (filter == 'THIS_MONTH') {
            Date startDate = today.toStartOfMonth();
            return new DateRange(
                startDate,
                startDate.addMonths(1).addDays(-1)
            );
        }
        
        if (filter == 'LAST_MONTH') {
            Date startDate = today.toStartOfMonth().addMonths(-1);
            return new DateRange(
                startDate,
                startDate.addMonths(1).addDays(-1)
            );
        }
        
        if (filter == 'LAST_N_MONTHS') {
            Integer months = getInteger(requestMap, 'periodCount');
            
            if (months == null || months < 1) {
                throw new RequestException(
                    'periodCount must be greater than zero.'
                );
            }
            
            Date startDate = today.toStartOfMonth().addMonths(-(months - 1));
            return new DateRange(startDate, today);
        }
        
        if (filter == 'LAST_N_DAYS') {
            Integer days = getInteger(requestMap, 'periodCount');
            
            if (days == null || days < 1) {
                throw new RequestException(
                    'periodCount must be greater than zero.'
                );
            }
            
            return new DateRange(today.addDays(-(days - 1)), today);
        }
        
        if (filter == 'DATE_RANGE') {
            String dateFrom = getString(requestMap, 'dateFrom');
            String dateTo = getString(requestMap, 'dateTo');
            
            if (String.isBlank(dateFrom) || String.isBlank(dateTo)) {
                throw new RequestException(
                    'dateFrom and dateTo are required for DATE_RANGE.'
                );
            }
            
            Date startDate = Date.valueOf(dateFrom);
            Date endDate = Date.valueOf(dateTo);
            
            if (startDate > endDate) {
                throw new RequestException(
                    'dateFrom cannot be later than dateTo.'
                );
            }
            
            return new DateRange(startDate, endDate);
        }
        
        throw new RequestException('Unsupported dateFilter: ' + filter);
    }

    public static DateRange resolveDateRangeFromParams(Map<String, Object> requestMap) {
        return resolveDateRange(requestMap);
    }

    public static DateRange resolveDateRangeOrToday(Map<String, Object> requestMap) {
        if (hasDateScope(requestMap)) {
            return resolveDateRangeFromParams(requestMap);
        }

        Map<String, Object> defaultDateParams = new Map<String, Object>();
        if (requestMap != null) {
            defaultDateParams.putAll(requestMap);
        }
        defaultDateParams.put('dateFilter', 'TODAY');
        return resolveDateRange(defaultDateParams);
    }

    public static DateRange resolveOptionalDateRange(Map<String, Object> requestMap) {
        if (!hasDateScope(requestMap)) {
            return null;
        }
        return resolveDateRangeFromParams(requestMap);
    }

    public static Boolean hasDateScope(Map<String, Object> requestMap) {
        if (requestMap == null) {
            return false;
        }
        return String.isNotBlank(getString(requestMap, 'dateFilter'))
            || String.isNotBlank(getString(requestMap, 'dateFrom'))
            || String.isNotBlank(getString(requestMap, 'dateTo'))
            || getInteger(requestMap, 'periodCount') != null;
    }

    private static String normalizeDateFilter(String filter) {
        if (String.isBlank(filter)) {
            return 'DATE_RANGE';
        }

        String normalized = filter.trim().toUpperCase().replace('-', '_');
        if (normalized == 'DATERANGE') {
            return 'DATE_RANGE';
        }
        return normalized;
    }
    public static List<String> getStringList(
        Map<String, Object> requestMap,
        String key
    ) {
        List<String> values = new List<String>();
        Object rawValue = requestMap.get(key);
        
        if (rawValue == null) {
            return values;
        }
        
        if (rawValue instanceof List<Object>) {
            for (Object value : (List<Object>) rawValue) {
                if (value != null && !String.isBlank(String.valueOf(value))) {
                    values.add(String.valueOf(value));
                }
            }
            return values;
        }

        if (rawValue instanceof String && !String.isBlank((String) rawValue)) {
            String value = ((String) rawValue).trim();
            if (value.startsWith('[') && value.endsWith(']')) {
                value = value.substring(1, value.length() - 1);
                for (String item : value.split(',')) {
                    item = item.trim();
                    if (!String.isBlank(item)) {
                        values.add(item);
                    }
                }
            } else {
                values.add(value);
            }
        }
        
        return values;
    }
    
    public static String getString(
        Map<String, Object> requestMap,
        String key
    ) {
        Object value = requestMap.get(key);
        return value == null ? null : String.valueOf(value);
    }
    
    public static Boolean getBoolean(
        Map<String, Object> requestMap,
        String key,
        Boolean defaultValue
    ) {
        Object value = requestMap.get(key);
        return value == null ? defaultValue : Boolean.valueOf(String.valueOf(value));
    }
    
    public static Integer getInteger(
        Map<String, Object> requestMap,
        String key
    ) {
        Object value = requestMap.get(key);
        return value == null ? null : Integer.valueOf(String.valueOf(value));
    }
    public class DateRange {
        public Date startDate;
        public Date endDate;
        
        public DateRange(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }
    private class RequestException extends Exception {
    }
}