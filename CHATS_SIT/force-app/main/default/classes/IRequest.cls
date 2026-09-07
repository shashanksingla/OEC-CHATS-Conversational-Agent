/**
 * @author DELOITTE
 * 
 * @verison 1.0
 * 
 * Interface to define service contract for processing requests
 * 
 * @Change History
 */
public interface IRequest {
    /**
     * Processes the request and resturns JSON response
     * 
     * @param methodName - Name of the method
     * @param jsonParam - JSON parameter to be de-serialized
     * 
     * @return JsonResponse - Response holding status, data & errors as part of request processed
     */
    Object processRequest(String methodName, String jsonParam);
}