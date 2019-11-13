import "localhost/sol/common.sol";
import "localhost/sol/BokkyPooBahsDateTimeLibrary.sol";
import "localhost/sol/Ownable.sol";

//контракт по билинговым операциям
contract BillingContract is Ownable{

    //иан по ид счётчика на мап по год*12+месяц на данные билинга в этом месяце
    mapping(bytes16=>mapping(uint32=>Common.BillingData)) public billing;

    //возвращает из б/ч инфо по билингу на заданную дату по заданному счётчику
    function get_billing_data(bytes16 _sensor_id, uint date) public view 
        returns(uint total_month_amount, uint estimated_month_amount, uint total_month_costs, uint estimated_month_costs){

        uint _now = date;

        uint8 _month = uint8(BokkyPooBahsDateTimeLibrary.getMonth(_now));
        
        uint16 _year = uint16(BokkyPooBahsDateTimeLibrary.getYear(_now));
        
        uint8 _day = uint8(BokkyPooBahsDateTimeLibrary.getDay(_now));
        
        uint32 ymindex = uint32(_year*12+_month);


        return (
                billing[_sensor_id][ymindex].total_month_amount,
                billing[_sensor_id][ymindex].estimated_month_amount,
                billing[_sensor_id][ymindex].total_month_costs,
                billing[_sensor_id][ymindex].estimated_month_costs
                );    
    }
    //создаёт или обновляет данные по билингу в б/ч по счётчику, структуре год*12+месяц, месяцу, году, потреблению и стоимости за текущий месяц
    function update_billing(bytes16 sensor_id,  uint32 ymindex, uint8 _month, uint16 _year, 
        uint month_amount, 
        uint estimated_month_amount,
        uint estimated_costs, 
        uint total_costs) public onlyOwner(){
        //если нет данных по билингу за месяц то создаём их
        if(!billing[sensor_id][ymindex].exists)
        {
            billing[sensor_id][ymindex] = 
            Common.BillingData({
                sensor_id:sensor_id,
                exists:true,
                is_pre_invoice_needed:true,
                is_final_invoice_needed:true,
                is_pre_invoice_ready:false,
                is_final_invoice_ready:false,
                is_invoice_payed:false,
                month:_month,
                year:_year,
                total_month_amount:month_amount,
                estimated_month_amount:estimated_month_amount,
                estimated_month_costs:estimated_costs,
                total_month_costs:total_costs,
                final_invoice_payed_on:0
                });
        }
	//иначе обновляем	
        else{
            billing[sensor_id][ymindex].total_month_amount=month_amount;
            billing[sensor_id][ymindex].estimated_month_costs=estimated_costs;
            billing[sensor_id][ymindex].estimated_month_amount=estimated_month_amount;
            billing[sensor_id][ymindex].total_month_costs=total_costs;
        }
    }

    
    
    
}    