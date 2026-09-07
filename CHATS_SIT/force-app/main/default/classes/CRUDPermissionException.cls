public class CRUDPermissionException extends Exception {
    public String errorMessage;
    public CRUDPermissionException(String objectName, String dmlOperation){
        this.errorMessage = UserInfo.getName()+'('+UserInfo.getProfileId()+') does not have '+dmlOperation+' access on '+objectName;  
    }

    public override String getMessage(){
        return errorMessage;
    }
    
    public static CRUDPermissionException getCRUDPermissionException(List<CRUDPermissionException> crudPermissionExceptions){
        CRUDPermissionException crudPermissionException = new CRUDPermissionException();
        String message = '';
        for(CRUDPermissionException eachCRUDPermissionException:crudPermissionExceptions){
            if(!message.contains(eachCRUDPermissionException.getMessage())){
	            message+=eachCRUDPermissionException.getMessage()+Label.SEPARATOR_COMMA;
            }
        }
        crudPermissionException.errorMessage = message.removeEnd(Label.SEPARATOR_COMMA);
        return crudPermissionException;
    }
}