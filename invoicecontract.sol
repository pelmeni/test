import "localhost/sol/common.sol";
import "localhost/sol/Ownable.sol";
//контракт по операциям со счетами
contract InvoiceContract is Ownable{

    //мап от банковский счёт на мап от типа счёта на мап на структуру год*12+месяц на счёт в этом месяце
    //bank_account_id=>_type=>_year*12+_month=>invoice
    mapping (uint32=>mapping(uint8=>mapping(uint32=>Common.Invoice))) invoices;

    //функция возвращает счёт из б/ч по банковскому счёту, году, месяцу и типу
    function get_invoice(uint32 _bank_account_id, uint16 _year, uint8 _month, uint8 _type) public view 
        returns (uint created, uint total_month_amount, uint estimated_month_amount, uint total_month_costs, uint estimated_month_costs, bool is_completed){

        uint32 ymindex=(_year*12)+_month;
        
        Common.Invoice memory inv =invoices[_bank_account_id][_type][ymindex];
        
        Common.BillingData memory bd = inv.billing_data;
        //если счёт создан и готов к выставлению, возвращаем данные по этому счёту
        if(inv.exists && inv.is_ready){
            created = inv.created;
            total_month_amount = bd.total_month_amount;
            estimated_month_amount = bd.estimated_month_amount;
            total_month_costs = bd.total_month_costs;
            estimated_month_costs = bd.estimated_month_costs;
            is_completed = inv.is_completed;
        }
    }
    //завершает счёт в б/ч. т.е. после факта банковской оплаты вне блокчейна переносит эту информацию в б/ч. это главный признак факта завершения договора
    //в функцию передаётся ид банковской транзакции во внешней системе, котораой оплачивался выставленный счёт
    function complete_invoice(uint32 _bank_account_id, uint16 _year, uint8 _month, bytes16 _txid) onlyOwner() public{

        uint32 ymindex=(_year*12)+_month;
        //3-финальный счёт
        Common.Invoice memory inv =invoices[_bank_account_id][3][ymindex];
        //проставляем флаги завершения
        inv.completed_on = now;
        inv.bank_tx_id = _txid;
        inv.is_completed = true;
        
        
        
    }
}