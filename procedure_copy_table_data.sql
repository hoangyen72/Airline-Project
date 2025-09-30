-- Tạo Procedure đổ dữ liệu từ CSDL cũ sang CSDL mới:
DELIMITER //

CREATE PROCEDURE copy_table_data()
BEGIN
    SET @sql = CONCAT('INSERT INTO ', airportdb_new, '.', table_name, ' (', columns_list, ') SELECT ', columns_list, ' FROM ', airportdb, '.', table_name);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //

DELIMITER ;

-- Sao chép y hệt
DELIMITER //CREATE PROCEDURE copy_airline() 
BEGIN 
        SET @sql = CONCAT('INSERT INTO airportdb_new.airline (airline_id, iata, airlinename, base_airport) SELECT airline_id, iata, airlinename, base_airport FROM airportdb.airline');
        PREPARE stmt FROM @sql; 
        EXECUTE stmt; 
        DEALLOCATE PREPARE stmt; 
        END //DELIMITER ;
CALL copy_airline();

-- Sao chép một phần
DELIMITER //
CREATE PROCEDURE copy_weatherdata2(specific_date DATE)
BEGIN
    SET @sql = CONCAT('INSERT INTO airportdb_new.weatherdata (log_date, time, station, temp, humidity, airpressure, wind, weather, winddirection) SELECT log_date, time, station, temp, humidity, airpressure, wind, weather, winddirection FROM airportdb.weatherdata WHERE log_date >= ?');
    PREPARE stmt FROM @sql;
    EXECUTE stmt USING specific_date;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;
CALL copy_weatherdata2('2015-12-29');
