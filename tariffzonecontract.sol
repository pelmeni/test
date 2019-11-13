import "localhost/sol/common.sol";
import "localhost/sol/Ownable.sol";

//контракт по операциям с тарифами
contract TariffZoneContract is Ownable{
    //мап от зоны тарифа на тариф
    mapping(uint8=>Common.TariffZone) public tariff_zone;
    //зоны тарифа
    uint8[] private tariff_zones_keys;
    //контрольная сумма тарифа
    int64 tariff_zone_chksum;
    
    
    bool tariff_loaded = false;
    
    uint32 private tariff_zones;

    constructor() public{
        
        tariff_loaded=false;
        
        tariff_zones=0;
        
        tariff_zone_chksum=0;
    }


    //возвращает кол-во тарифныех зон
    function getTariffZones() public view returns (uint32) {
        return tariff_zones;
    }
    //загружает инфо из тарифа по зоне
    function loadTariffZone(uint8 _zone_id, uint32 _rate_per_1000) onlyOwner() public {

        if(!tariff_zone[_zone_id].exists)
        {
            tariff_zones_keys.push(_zone_id);
            
            tariff_zones+=1;
        
            tariff_loaded=true;
        }
        
        tariff_zone[_zone_id]= Common.TariffZone(_zone_id,  _rate_per_1000, true);
        
    }
    //возвращает инфо о тарифной зоне из б/ч
    function getTariffZoneByZoneId(uint8 zone_id) public view returns (uint32){
        
        return tariff_zone[zone_id].rate_per_1000;
    }
    //возвращает инфо о контрольной сумме тарифа в б/ч(используется для перезаписи тарифов в случае изменения файла с тарифами во вне)
    function getTariffZoneChkSum() public view returns (int64){
        
        return tariff_zone_chksum;
    }
    //устанавливает контрольную сумму для тарифа
    function setTariffZoneChkSum(int64 chksum) onlyOwner() public{
        
        tariff_zone_chksum=chksum;
    }
        
    function emptyTariffZoneChkSum() onlyOwner() public{
        
        tariff_zone_chksum=0;
        
        tariff_zones=0;
        
        delete tariff_zones;
        
        delete tariff_zones_keys;

    }     

   
}