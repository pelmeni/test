import "localhost/sol/common.sol";
import "localhost/sol/Ownable.sol";

//контракт для работы с потоками банковского сервиса
contract BankContract is Ownable{

    //мап от ид банковского счёта на данные по тему
    mapping(uint32=>Common.BankAccount) private bank_accounts;
    //массив банковских счётов
    uint32[] private bank_account_keys;
        //возвращает банковский счёт к кототому привязан заданный счётчик
    function get_sensor_bank_account(bytes16 _sensor_id) public view returns(uint32 bank_account_id){

        bank_account_id = 0;
    
        for(uint i=0;i<bank_account_keys.length;i++){
            
            uint32 key = bank_account_keys[i];
            
            if(bank_accounts[key].exists && bank_accounts[key].autopay_sensor_id==_sensor_id){
                bank_account_id = key;
               break;
            }
        }
    }
    //передаёт инфо по банковскому счёту в блокчейн
    function insertBankAccount(uint32 _user_account_id, bytes16 _autopay_sensor_id) onlyOwner() public{
         if(!bank_accounts[_user_account_id].exists){
             bank_account_keys.push(_user_account_id);
         }
        bank_accounts[_user_account_id]=Common.BankAccount({user_account_id:_user_account_id,autopay_sensor_id:_autopay_sensor_id,exists:true });
    }
    //возвращает инфо по банковскому счёту из блокчейна
    function getBankAccount(uint32 _user_account_id) public view returns(uint32 user_account_id, bytes16 autopay_sensor_id){
        user_account_id=bank_accounts[_user_account_id].user_account_id;
        autopay_sensor_id=bank_accounts[_user_account_id].autopay_sensor_id;    
    }    

    
    
}    