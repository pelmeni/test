library Common
{
    //Данные биллинга 
    struct BillingData
    {
        //id счётчика
        bytes16 sensor_id;
        //флаг инициализации
        bool exists;
        
        bool is_pre_invoice_needed;
        bool is_final_invoice_needed;
        bool is_pre_invoice_ready;
        bool is_final_invoice_ready;
        bool is_invoice_payed;
        //месяц билинга
        uint8 month;
        //год биллинга
        uint16 year;
        //общее потребление за месяц
        uint total_month_amount;
        //расчётное потребление за месяц
        uint estimated_month_amount;
        //расчётная стоимость за месяц
        uint estimated_month_costs;
        //фактическая стоимость за месяц
        uint total_month_costs;
        
        uint final_invoice_payed_on;
    }
    //данные выставленного счёта на оплату
    struct Invoice
    {
        //флаг инициализации
        bool exists;
        //биллинг за месяц по которому выставляется счёт
        BillingData billing_data;
        //банковский счёт на который выставлять счёт
        uint32 user_account_id;
        //бата создания счёта
        uint created;
        //тип счёта - предварительный 1,2 и финальный
        uint8 _type; //1 - pre1, 2- pre2, 3 - final;
        //флаг готовности счёта в блокчейне
        bool is_ready;
        //флаг завершения счёта(оплачен)
        bool is_completed;
        //дата завершения счёта
        uint completed_on;
        //номер банковской транзакции которой был оплачен фактический счёт
        bytes16 bank_tx_id;
    }
    //Даннае настройки контракта
    struct Settings
    {
        //флаг инициализации
        bool exists;
        //дата выставления финального счёта
        uint final_invoice_date;
        //дата выставления предварительного счёта №1
        uint pre1_invoice_date;
        //дата выставления предварительного счёта №2
        uint pre2_invoice_date;
    }
    //Данные о тарифах
    struct TariffZone
    {
        //тарифная зона
        uint8 zone_id;
        //курс в у.е. на 1000 потреблённых единиц энергии
        uint32 rate_per_1000;
        //флаг инициализации
        bool exists;
    }
    //Данные о банковском счётк
    struct BankAccount
    {
        //ид банковского счёта
        uint32 user_account_id;
        //ид счётчика привязанного к банковскому счёту для автооплаты
        bytes16 autopay_sensor_id;
        //флаг инициализации
        bool exists;
    }
    //данный счётчиков потреблённой энергии
    struct SensorData
    {
        //индекс в массиве
        uint256 index; 
        //ид счётчика
        bytes16 sensor_id;
        //показания
        uint64 counter;
        //дата показаний
        uint256 created;
        //месяц снятия показаний
        uint8 month;
        //год снятия показаний
        uint16 year;
        //тарифная зона
        uint8 zone_id;
    }
    //данные показания в спец формате
    struct MSensorData
    {
        //мап от год*12+месяц на массив показаний в этом месяце
        mapping(uint=>SensorData[]) mdata;
        //мап от год*12+месяц на последние показания в этом месяце
        mapping(uint=>SensorData) last_data;
        //мап от год*12+месяц на последние показания в прошлом месяце(отсечка)(для получания кол-ва потребления за текущий месяц)
        mapping(uint=>uint) offset;
        //мап от год*12+месяц на потребление в текущем месяце
        mapping(uint=>uint) amount;
    }    
}