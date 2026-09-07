public class DMLResult {
	public Database.SaveResult saveResult;
    public CRUDPermissionException crudPermissionException;
    public DMLResult(Database.SaveResult saveResult, CRUDPermissionException crudPermissionException){
        this.saveResult = saveResult;
        this.crudPermissionException = crudPermissionException;
    }
}