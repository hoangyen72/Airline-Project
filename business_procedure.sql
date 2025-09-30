-- 1: Truy xuất và hiển thị thông tin về vé máy bay của các hành khách trên một chuyến bay với số hiệu cụ thể
DELIMITER $$CREATE PROCEDURE get_flight_passengers(IN Vflightno CHAR(8))
BEGIN
    DECLARE done INT DEFAULT FALSE; //  khai báo cờ done dùng để chỉ khi nào con trỏ đã đọc hết các hàng, khi chưa đọc hết các hàng thì mặc định cờ done là FALSE
    DECLARE Vbooking_id INT; DECLARE Vpassenger_id INT; DECLARE Vseat CHAR(4);
    DECLARE Vfirstname VARCHAR(100); DECLARE Vlastname VARCHAR(100);   
        -- Khai báo con trỏ
    DECLARE cur CURSOR FOR
        SELECT b.booking_id, b.passenger_id, p.firstname, p.lastname, b.seat
        FROM booking b
        INNER JOIN flight f ON b.flight_id = f.flight_id
        INNER JOIN passenger p ON p.passenger_id = b.booking_id
        WHERE f.flightno = Vflightno;
– Khai báo trình xử lý khi không tìm thấy hàng nào nữa, sẽ đặt cờ done từ False → True
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DROP TEMPORARY TABLE IF EXISTS temp_results;
    CREATE TEMPORARY TABLE temp_results (PassengerInfo VARCHAR(500));    OPEN cur;  -- Tạo vòng lặp đọc qua các hàng
    read_loop: LOOP
        FETCH cur INTO Vbooking_id, Vpassenger_id, Vfirstname, Vlastname, Vseat;
        IF done THEN LEAVE read_loop; END IF;        -- Xử lý truy xuất thông tin vé máy bay và lưu vào bảng tạm
        INSERT INTO temp_results (PassengerInfo) 
        VALUES (CONCAT('Booking ID: ' , Vbooking_id, ', Passenger ID: ', Vpassenger_id,', First Name: ', Vfirstname, ', Last Name: ', Vlastname, ', Seat Number: ', Vseat));
    END LOOP;    CLOSE cur;

    SELECT * FROM temp_results;
    DROP TEMPORARY TABLE IF EXISTS temp_results;
END$$DELIMITER ;

    -- Gọi thủ tục
   CALL get_flight_passengers('SP4186');
-- 2: Cập nhật loại khách hàng (customer_type) trong bảng passenger dựa trên tổng doanh thu mà khách hàng đó đã chi tiêu.
DELIMITER //

CREATE PROCEDURE UpdateCustomerTypeBasedOnRevenue()
BEGIN
    DECLARE customer_id_var INT;
    DECLARE total_revenue DECIMAL(10, 2);
    -- Lặp qua từng khách hàng
    DECLARE done INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR SELECT passenger_id FROM booking GROUP BY passenger_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO customer_id_var;
        IF done THEN  LEAVE read_loop;  END IF;
    -- Tính tổng doanh thu của khách hàng
        SELECT SUM(price) INTO total_revenue  FROM booking
        WHERE passenger_id = customer_id_var;

        -- Cập nhật loại khách hàng dựa trên tổng doanh thu
        IF total_revenue > 1000 THEN    UPDATE passenger SET customer_type = 'VIP'
            			WHERE passenger_id = customer_id_var;
        ELSE      UPDATE passenger  SET customer_type = 'Normal'
            	WHERE passenger_id = customer_id_var;   END IF;
    END LOOP;
    CLOSE cur;
END //
DELIMITER ;
CALL UpdateCustomerTypeBasedOnRevenue();

