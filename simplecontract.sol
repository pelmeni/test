pragma solidity ^0.5.0;

//pragma experimental ABIEncoderV2;
import "localhost/sol/common.sol";
import "localhost/sol/InvoiceContract.sol";
import "localhost/sol/BankContract.sol";
import "localhost/sol/BillingContract.sol";
import "localhost/sol/SettingsContract.sol";
import "localhost/sol/TariffZoneContract.sol";
import "localhost/sol/BokkyPooBahsDateTimeLibrary.sol";
import "localhost/sol/Ownable.sol";

//основной рабочий контракт 
contract SimpleContract is Ownable, SettingsContract, BillingContract, InvoiceContract, BankContract, TariffZoneContract {

     
    //absolute sensor counter value
    mapping(bytes16=>mapping(uint32=>uint64)) private cnt_data;
    //sensor monthly counters amount
    //mapping(bytes16=>mapping(uint32=>uint64)) private amount_data;
    //last sensor data
    //reserved
    mapping(bytes16=>mapping(uint32=>uint64)) private last_costs;
    //last sensor counters value
    
    //sensor last month last counters value(used to calculate current month amount)
    //mapping(bytes16=>uint64) private offset;

    
    //sensor avarage daily consumption in value amount
        mapping(bytes16=>Common.SensorData[]) public data;
    
    mapping(bytes16=>Common.MSensorData) private datas;
    
    mapping(bytes16=>Common.SensorData) private last_data;
    
    mapping(bytes16=>uint64) private last_value;
    
    event eAddSensorData(bytes16 sensor, uint year, uint month);   // declaring event
    //записывает данные со счётчиков э/э в б/ч 
    function add_data(bytes16 _sensor_id, uint8 _zone_id, uint64 _counter, uint256 _created) onlyOwner() public
    {
        Common.SensorData[] memory d=data[_sensor_id];

        uint8 _month = uint8(BokkyPooBahsDateTimeLibrary.getMonth(_created));
        
        uint16 _year = uint16(BokkyPooBahsDateTimeLibrary.getYear(_created));

        
        emit eAddSensorData(_sensor_id, _year, _month);

        uint256 len = d.length;
        
        Common.SensorData memory sd = Common.SensorData({index:d.length+1,sensor_id:_sensor_id,counter:_counter, created:_created, month:_month, year:_year, zone_id:_zone_id });
            
        data[_sensor_id].push(sd);

        uint ymindex = (_year*12)+_month;        
        
        datas[_sensor_id].mdata[ymindex].push(sd);

        datas[_sensor_id].last_data[ymindex] = sd;

	//если начался новый месяц, запоминаем последние полученные данные со счётчика
        if(datas[_sensor_id].mdata[ymindex].length==0){
            datas[_sensor_id].offset[ymindex] = last_value[_sensor_id];
        }
        //потребление за месяц как разница текущих показаний с последними за прошлый месяц
	datas[_sensor_id].amount[ymindex] = _counter - datas[_sensor_id].offset[ymindex];
        //перезаписываем последние показания
        last_value[_sensor_id] = _counter;
    
    }
    //возвращает данные по передныых показаниях из б/ч
    function get_data(bytes16 sensor_id, uint16 year, uint8 month, uint256 index) public view returns (uint value){
        value=datas[sensor_id].mdata[(year*12)+month][index].year;
    }
    //возвращает данные о количестве показаний со счётчиков из б/ч
    function get_data_len(bytes16 sensor_id, uint16 year, uint8 month) public view returns (uint256 value){
        value=datas[sensor_id].mdata[(year*12)+month].length;
    }
    //возвращает данные о потреблении из б/ч
    function get_amount(bytes16 sensor_id, uint16 year, uint8 month) public view returns (uint value){
        value=datas[sensor_id].amount[(year*12)+month];
    }
    //возвращает данные о последних показаниях из б/ч
    function get_last_data(bytes16 _sensor_id, uint16 _year, uint8 _month) public view returns (uint index, bytes16 sensor_id, uint64 counter, uint created, uint16 year, uint8 month){
         Common.SensorData memory sd = datas[sensor_id].last_data[(year*12)+month];
         return (sd.index, sd.sensor_id, sd.counter, sd.created, sd.year, sd.month);
    }
    //процессинг билинга потреблённой э/э
    function process_billing(bytes16 sensor_id) onlyOwner() public 
    {
        uint256 _now = now;
        
        uint8 _month = uint8(BokkyPooBahsDateTimeLibrary.getMonth(_now));
        
        uint16 _year = uint16(BokkyPooBahsDateTimeLibrary.getYear(_now));
        
        uint8 day = uint8(BokkyPooBahsDateTimeLibrary.getDay(_now));
        
        uint32 ymindex = uint32(_year*12+_month);
        //потреблениев месяце
        uint month_amount = datas[sensor_id].amount[ymindex];
        //среднее потребление в день
        uint daily_avg_amount = month_amount/uint8(day);
        //кол-во дней в месяце
        uint8 days_total=uint8(BokkyPooBahsDateTimeLibrary.getDaysInMonth(_now));
        //расчётное потребление в месяце как фактическое на дату и расчётное на остаток месяца
        uint estimated_month_amount = (days_total - day) * daily_avg_amount + month_amount;
        //последние переданные показания в месяце
        Common.SensorData memory last_data = datas[sensor_id].last_data[ymindex];
        //считаем стоимость с учётом тарифа по фактическим показаниям
        uint total_costs = month_amount*tariff_zone[last_data.zone_id].rate_per_1000;
        //считаем стоимость с учётом тарифа по расчётному потреблению
        uint estimated_costs = estimated_month_amount*tariff_zone[last_data.zone_id].rate_per_1000;
        
        
        // if(!billing[sensor_id][ymindex].exists)
        // {
        //     billing[sensor_id][ymindex] = 
        //     Common.BillingData({
        //         sensor_id:sensor_id,
        //         exists:true,
        //         is_pre_invoice_needed:true,
        //         is_final_invoice_needed:true,
        //         is_pre_invoice_ready:false,
        //         is_final_invoice_ready:false,
        //         is_invoice_payed:false,
        //         month:_month,
        //         year:_year,
        //         total_month_amount:month_amount,
        //         estimated_month_amount:estimated_month_amount,
        //         estimated_month_costs:estimated_costs,
        //         total_month_costs:total_costs,
        //         final_invoice_payed_on:0
        //         });
        // }
        // else{
        //     billing[sensor_id][ymindex].total_month_amount=month_amount;
        //     billing[sensor_id][ymindex].estimated_month_costs=estimated_costs;
        //     billing[sensor_id][ymindex].estimated_month_amount=estimated_month_amount;
        //     billing[sensor_id][ymindex].total_month_costs=total_costs;
        // }
        //на основе посчитанных данных создаём срез данных по билингу в б/ч
	update_billing(sensor_id, ymindex, _month, _year, month_amount,  estimated_month_amount, estimated_costs,  total_costs);
        //процессинг выставления счетов
        process_invoices(sensor_id, _year, _month);
        
        
    }
    //ф-я производит выставление и подготовку счетов на оплату
    function process_invoices(bytes16 _sensor_id, uint16 _year, uint8 _month) onlyOwner() public{
        
        uint32 ymindex=(_year*12)+_month;
        //достаём данные по билингу из б/ч
        Common.BillingData memory bd = billing[_sensor_id][ymindex];
        //получаем банковский счёт для выставления счёта на оплату
        uint32 bank_account_id = get_sensor_bank_account(bd.sensor_id);
        
        uint _now = now;
        
        if(!settings.exists)
            return;
        if(bd.total_month_amount==0)
        return;
        
        //условия на выставления предварительного счёта №1
        if(_now>settings.pre1_invoice_date 
            && BokkyPooBahsDateTimeLibrary.getDay(_now) >= BokkyPooBahsDateTimeLibrary.getDay(settings.pre1_invoice_date)){
                //смотрим есть ли уже счёт
                Common.Invoice memory inv =invoices[bank_account_id][uint8(1)][(_year*12)+_month];
                //если нет то создаём
                if(!inv.exists){
                    // Common.Invoice memory inv = Common.Invoice({
                    //     billing_data:bd,exists:true, 
                    //     created:_now, 
                    //     is_ready:true, 
                    //     user_account_id:bank_account_id, 
                    //     _type:1,
                    //     is_completed:false,
                    //     completed_on:0,
                    //     bank_tx_id:0
                    //});
                    Common.Invoice memory inv;
                    inv.billing_data = bd;
                    inv.exists = true;
                    inv.created = _now; 
                    inv.is_ready = true;
                    inv.user_account_id = bank_account_id;
                    inv._type = 1; //предварительный счёт
                    inv.is_completed = false;
                    //сохраняем подготовленный счёт на оплату в б/ч
                    invoices[bank_account_id][uint8(1)][(_year*12)+_month] = inv;
                }
		//если счёт есть, но не готов к выставлению
                else if(!inv.is_ready){
                    //Common.Invoice memory inv = Common.Invoice({billing_data:bd,exists:true, created:_now, is_ready:true, user_account_id:bank_account_id, _type:1});
                    Common.Invoice memory inv;
                    inv.billing_data = bd;
                    inv.exists = true;
                    inv.created = _now; 
                    inv.is_ready = true;
                    inv.user_account_id = bank_account_id;
                    inv._type = 1;
                    inv.is_completed = false;
                    //сохраняем подготовленный счёт на оплату в б/ч
                    invoices[bank_account_id][uint8(1)][(_year*12)+_month] = inv;
                }
                
        }
	//логика формирования аналогична
        if(_now>settings.pre2_invoice_date 
            && BokkyPooBahsDateTimeLibrary.getDay(_now) >= BokkyPooBahsDateTimeLibrary.getDay(settings.pre2_invoice_date)){

                Common.Invoice memory inv =invoices[bank_account_id][uint8(2)][(_year*12)+_month];

                if(!inv.exists){
                    //Common.Invoice memory inv = Common.Invoice({billing_data:bd,exists:true, created:_now, is_ready:true, user_account_id:bank_account_id, _type:2});
                    Common.Invoice memory inv;
                    inv.billing_data = bd;
                    inv.exists = true;
                    inv.created = _now; 
                    inv.is_ready = true;
                    inv.user_account_id = bank_account_id;
                    inv._type = 2;
                    inv.is_completed = false;

                    invoices[bank_account_id][uint8(2)][(_year*12)+_month] = inv;
                }
                else if(!inv.is_ready){
                    //Common.Invoice memory inv = Common.Invoice({billing_data:bd,exists:true, created:_now, is_ready:true, user_account_id:bank_account_id, _type:2});
                                        Common.Invoice memory inv;
                    inv.billing_data = bd;
                    inv.exists = true;
                    inv.created = _now; 
                    inv.is_ready = true;
                    inv.user_account_id = bank_account_id;
                    inv._type = 2;
                    inv.is_completed = false;

                    invoices[bank_account_id][uint8(2)][(_year*12)+_month] = inv;
                }
        }
        //условия для формирования финального счёта на оплату
        if(_now>settings.final_invoice_date
            && BokkyPooBahsDateTimeLibrary.getDay(_now) >= BokkyPooBahsDateTimeLibrary.getDay(settings.final_invoice_date)){
                //смотрим счет за предыдущий месяц
                Common.Invoice memory inv =invoices[bank_account_id][uint8(3)][(_year*12)+_month-1]; //looking for prev month invoice
                //и билинг за предыдущий месяц
                bd = billing[_sensor_id][ymindex - 1]; //take prev month billing
                //далее всё аналогично
                if(!inv.exists){
                    //Common.Invoice memory inv = Common.Invoice({billing_data:bd,exists:true, created:_now, is_ready:true, user_account_id:bank_account_id, _type:3});
                    Common.Invoice memory inv;
                    inv.billing_data = bd;
                    inv.exists = true;
                    inv.created = _now; 
                    inv.is_ready = true;
                    inv.user_account_id = bank_account_id;
                    inv._type = 3; //фактический счёт на оплату
                    inv.is_completed = false;

                    invoices[bank_account_id][uint8(3)][(_year*12)+_month-1] = inv;
                }
                else if(!inv.is_ready){
                    //Common.Invoice memory inv = Common.Invoice({billing_data:bd,exists:true, created:_now, is_ready:true, user_account_id:bank_account_id, _type:3});
                    Common.Invoice memory inv;
                    inv.billing_data = bd;
                    inv.exists = true;
                    inv.created = _now; 
                    inv.is_ready = true;
                    inv.user_account_id = bank_account_id;
                    inv._type = 3; //фактический счёт на оплату
                    inv.is_completed = false;

                    invoices[bank_account_id][uint8(3)][(_year*12)+_month-1] = inv; //save final invoice in prev month invoices
                }
        }                
        
        

    }
        
    
    struct Sensor{
        bytes16 sensorId;
        uint8 zone_id;
        bool exists;
        int64 sensor_data_hash;
        //SensorData[] data;
        mapping(bytes16=>Common.SensorData)data;
        bytes16[] sensor_data_keys;
        int64 sensor_hash;
    }
    
    mapping(bytes16=>Sensor) private sensors;
    mapping(bytes16=>Common.SensorData) private lastCounters;
    
    bytes16[]sensor_keys;
    
    constructor() public{
        

    }
    
    
   /* 
    function getCurrentInvoice(uint32 _user_account_id) public view returns (uint32 user_account_id, uint64 value){
        
        
        
        if(bank_accounts[_user_account_id].exists){
            bytes16 sensor_id = bank_accounts[_user_account_id].autopay_sensor_id;
            
            if(lastCounters[sensor_id].key!=0){
                
                uint64 counters = lastCounters[sensor_id].counter;
                
                uint8 zone_id = sensors[sensor_id].zone_id;
                
                uint32 rate_per_1000 = tariff_zone[zone_id].rate_per_1000;
                
                user_account_id = _user_account_id;
                
                value = rate_per_1000*counters;
                
                
            }
        }
    }
    */

    

/*
    function insertSensor(bytes16 _sensorId) public{
        
        if(!sensors[_sensorId].exists){
                sensor_keys.push(_sensorId);
        }
        
        sensors[_sensorId]=Sensor({sensorId:_sensorId, sensor_data_hash:0, zone_id:1, exists:true,  sensor_data_keys:new bytes16[](0),sensor_hash:0 });
    }
    function getSensor(bytes16 _sensorId) public view returns(bytes16 _sensor_id, uint8 _zone_id, int64 _sensor_data_hash){
        
        if(sensors[_sensorId].exists){
                return (_sensorId, sensors[_sensorId].zone_id, sensors[_sensorId].sensor_data_hash);
        }
    }
    function insertLastSensorCounters(bytes16 _sensorId,bytes16 _sensorDataId, uint64 _lastCountersValue, uint256 _lastCountersDateTime) public{
        //if(sensors[_sensorId].exists)
            lastCounters[_sensorId]=SensorData({key:_sensorDataId, counter:_lastCountersValue, lastCounterSyncDate:_lastCountersDateTime});
    }
    function getLastSensorCounters(bytes16 _sensorId) public view returns (bytes16 _sensorDataId, uint64 _lastCountersValue, uint256 _lastCountersDateTime){
        _sensorDataId=lastCounters[_sensorId].key;
        _lastCountersValue=lastCounters[_sensorId].counter;
        _lastCountersDateTime=lastCounters[_sensorId].lastCounterSyncDate;
        
    }
    
    function getSensorHash(bytes16 _sensorId) public view returns (int64){
        
       // if(sensors[_sensorId].exists)
            return sensors[_sensorId].sensor_hash;
        //else
            //return 0;
    }
    function setSensorHash(bytes16 _sensorId, int64 hash) public{
        
        if(sensors[_sensorId].exists)
            sensors[_sensorId].sensor_hash=hash;
    }    
    function getSensorDataHash(bytes16 _sensorId) public view returns (int64){
        
        if(sensors[_sensorId].exists)
            return sensors[_sensorId].sensor_data_hash;
        else
            return 0;
    }
    function setSensorDataHash(bytes16 _sensorId, int64 hash) public{
        
        if(sensors[_sensorId].exists)
            sensors[_sensorId].sensor_data_hash=hash;
    }

    function insertSensorData(bytes16 _sensorId, bytes16 _sensorDataId, uint64 _counter) public{

        if(sensors[_sensorId].exists){
            sensors[_sensorId].data[_sensorDataId]=SensorData({key:_sensorDataId,counter: _counter,lastCounterSyncDate:now });
        }
    }
    
    function getSensorData(bytes16 _sensorId, bytes16 _sensorDataId) public view returns(bytes16, uint64, uint256 ){
        //if(sensors[_sensorId].exists){
           return (
            sensors[_sensorId].data[_sensorDataId].key,
            sensors[_sensorId].data[_sensorDataId].counter, 
            sensors[_sensorId].data[_sensorDataId].lastCounterSyncDate
            );
       // }
    }
    
    
    struct UserData{
        string email;
        uint age;
        uint index;
    }
    mapping(address => UserData) private userData;
    
    address[] private userIndex;
    
    function bytes32ToString(bytes32 x) public returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint8 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    function insertUser(address userAddress, bytes32 email, uint age) public returns(uint index)
    {
        //if(isUser(userAddress)) throw; 
        
        userData[userAddress].email = bytes32ToString(email);
        userData[userAddress].age   = age;
        userData[userAddress].index = userIndex.push(userAddress)-1;

        return userIndex.length-1;
    }
    function getUser(address userAddress) public view returns(string memory userEmail, uint userAge, uint index)
    {
    //if(!isUser(userAddress)) throw; 
    return(
      userData[userAddress].email, 
      userData[userAddress].age, 
      userData[userAddress].index);
    }
    */
}
    
