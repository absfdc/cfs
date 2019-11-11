public class DFSIContactMatching {
@testvisible    
    public static Contact DFSIContactCheck(String SuppliedName,String SuppliedEmail,String SuppliedPhone){
        Contact con = new Contact();
        system.debug('SuppliedName '+SuppliedName);
        if(String.isNotEmpty(SuppliedName) ){
            system.debug('SuppliedName is not empty');
            if(SuppliedName.contains(' ')){
                con.FirstName = SuppliedName.split(' ')[0];  
                con.LastName = SuppliedName.split(' ')[1];
            }
            else{
                con.LastName = SuppliedName;
            }
        }        
        con.Email = SuppliedEmail;
        
        con.Phone = SuppliedPhone;
        
        system.debug('con is '+con);
        return con; 
    }
    
}