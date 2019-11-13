import "localhost/sol/common.sol";
import "localhost/sol/Ownable.sol";

//контракт по работе с настройками рабочего контракта
contract SettingsContract is Ownable{

        Common.Settings public settings;

   function set_settings(uint _final_invoice_date, uint _pre1_invoice_date, uint _pre2_invoice_date ) onlyOwner() public 
    {
        settings.final_invoice_date = _final_invoice_date;
        
        settings.pre1_invoice_date = _pre1_invoice_date;
        
        settings.pre2_invoice_date = _pre2_invoice_date;
        
        settings.exists = true;
    }
    function get_settings() public view returns (uint final_invoice_date, uint pre1_invoice_date, uint pre2_invoice_date ) 
    {
        final_invoice_date = settings.final_invoice_date;
        
        pre1_invoice_date = settings.pre1_invoice_date;
        
        pre2_invoice_date = settings.pre2_invoice_date;
    }
    
}