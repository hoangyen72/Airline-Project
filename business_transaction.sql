-- Kịch bản: Một hành khách muốn tìm chuyến bay từ Mỹ đến Đà Lạt, Việt Nam
/* 1. Tìm chuyến bay từ thành phố North Pole, Mỹ đến thành phố Đà Lạt, Việt Nam. 
- Nếu có thì hiển thị ra chuyến bay. 
- Nếu không có thì rollback và đưa ra yêu cầu nhập thành phố khác. */

DELIMITER //

CREATE PROCEDURE FindFlights(IN from_city VARCHAR(50), IN to_city VARCHAR(50))
BEGIN
    DECLARE rollback_message VARCHAR(255) DEFAULT 'There are no flights. Please add new departure or arrival.'; 
    DECLARE found BOOLEAN DEFAULT FALSE;

    START TRANSACTION;
    SELECT COUNT(*) INTO found FROM flight f
    JOIN airport_geo dep_airport ON f.`from` = dep_airport.airport_id
    JOIN airport_geo arr_airport ON f.`to` = arr_airport.airport_id
    WHERE dep_airport.city = from_city AND arr_airport.city = to_city ;

IF found THEN
     SELECT f.flight_id, f.flightno, f.departure, f.arrival, dep_airport.city departure_city, arr_airport.city arrival_city FROM flight f
    JOIN airport_geo dep_airport ON f.`from` = dep_airport.airport_id
    JOIN airport_geo arr_airport ON f.`to` = arr_airport.airport_id
    WHERE dep_airport.city = from_city 
	AND arr_airport.city = to_city 
	AND f.departure='2015-08-15';
        COMMIT;
    ELSE
        ROLLBACK;
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = rollback_message;
    END IF;
END //   DELIMITER ;

CALL FindFlight('NORTHPOLE','DALAT')
CALL FindFlight('FAIRBANKS','DALAT')

/*2. Thêm thông tin hành khách vào bảng
- Nếu chưa tồn tại thì thêm thông tin vào và đưa ra thông báo thực hiện thành công.
- Nếu đã tồn tại khách hàng thì rollback và đưa ra thông báo lỗi.
 */
DELIMITER //
CREATE PROCEDURE AddNewPassenger(IN p_passportno CHAR(9), IN p_firstname VARCHAR(100), IN p_lastname VARCHAR(100))
BEGIN
   DECLARE rollback_message VARCHAR(255) DEFAULT 'This customer already exists.';
   DECLARE commit_message VARCHAR(255) DEFAULT 'Add new passenger successfully.';
   DECLARE found BOOLEAN DEFAULT FALSE;
  
    START TRANSACTION ;
    SELECT COUNT(*) INTO found FROM passenger WHERE passportno = p_passportno;
    IF found THEN ROLLBACK;
         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = rollback_message;
    ELSE CALL InsertPassenger(p_passportno, p_firstname, p_lastname);
             COMMIT; SELECT commit_message as 'Results';
    END IF;
  END //
  DELIMITER ;

CALL AddNewPassenger('A123123','Williams','David')
CALL AddNewPassenger('B123123','Jolie','Serena') 

/*3. Đăng ký ghế ngồi cho khách hàng.
- Nếu ghế đó chưa có ai đặt thêm thông tin và thông báo giao dịch thành  công.
- Nếu đã có người đặt thì rollback và đưa ra thông báo lỗi.
*/
DELIMITER // 
CREATE PROCEDURE SeatBooking(IN p_flight_id INT, IN p_seat CHAR(4),IN p_passenger_id INT, IN
    p_price DECIMAL(10,2))
BEGIN
   DECLARE rollback_message VARCHAR(255) DEFAULT 'This seat is taken. Please add new seat';
   DECLARE commit_message VARCHAR(255) DEFAULT 'Added seat successfully.'    
   DECLARE found BOOLEAN DEFAULT FALSE;
   START TRANSACTION;
   SELECT COUNT(*) INTO found FROM booking
   WHERE flight_id = p_flight_id AND seat  = p_seat ;
   IF found THEN ROLLBACK;
       SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = rollback_message;
    ELSE CALL InsertBooking(p_flight_id, p_seat,p_passenger_id, p_price);
         COMMIT;
         SELECT commit_message AS 'RESULTS';
    END IF;
    END //
    DELIMITER ;
CALL SeatBooking('43232','A01','36113','100.00')
CALL SeatBooking('43232','C01','36113','80.00')

/*4. Khách hàng muốn đổi ngày bay vào ngày 16-8-2015.
- Nếu tồn tại chuyến bay thì update thông tin và tăng giá vé 1.5 lần.
- Nếu không tồn tại thì rollback và thông báo lỗi không tồn tại chuyến vào ngày đó.
*/
DELIMITER //
CREATE PROCEDURE UpdateScheduleOfPassenger(IN updateday DATETIME )
BEGIN
    DECLARE rollback_message VARCHAR(255) DEFAULT 'Does not exist this date. Please add a new date.';
    DECLARE commit_message VARCHAR(255) DEFAULT 'Information changed successfully.';
    DECLARE count_found INT DEFAULT 0;
    DECLARE p_flight_id INT;

    START TRANSACTION;
    SELECT COUNT(*), flight_id INTO count_found,p_flight_id
    FROM flight f JOIN airport_geo dep_airport ON f.`from` = dep_airport.airport_id
    JOIN airport_geo arr_airport ON f.`to` = arr_airport.airport_id
    WHERE dep_airport.city = 'FAIRBANKS' AND arr_airport.city = 'DALAT' AND
       DATE(f.departure) = DATE(updateday);

  IF count_found > 0 THEN 
	UPDATE booking SET price = price * 1.5 WHERE booking_id = 55099804;
         UPDATE booking SET flight_id=p_flight_id
      COMMIT;
      SELECT commit_message AS 'Results';
    ELSE
      ROLLBACK;
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = rollback_message;
    END IF;
END //
DELIMITER ;

CALL UpdateScheduleOfPassenger('2015-08-16');
--Khách hàng quyết định lùi đến ngày 18-08-2015.
CALL UpdateScheduleOfPassenger('2015-08-18'); 

/*5. Đến ngày bay, David muốn hủy vé. Hãng hàng không chỉ cho phép hành khách hủy vé và được hoàn tiền do thời tiết xấu.
- Nếu thời tiết xấu thì update lịch bay lùi 2 tiếng và xoá booking của David.
- Nếu thời tiết đủ điều kiện thì rollback đưa ra thông báo lỗi không thể hủy.
*/
DELIMITER //
CREATE PROCEDURE TicketCancellation(IN Wlog_date DATE, IN Wtime TIME, IN Wstation INT)
BEGIN
    DECLARE rollback_message VARCHAR(255) DEFAULT 'Stable weather conditions. Flights cannot be cancelled.';
    DECLARE commit_message VARCHAR(255) DEFAULT 'Ticket successfully canceled.';
    DECLARE found BOOLEAN DEFAULT FALSE; DECLARE Wtemp DECIMAL(3,1);
    DECLARE Whumidity DECIMAL(4,1); DECLARE Wairpressure DECIMAL(10,2);
    DECLARE Wwind DECIMAL(5,2); DECLARE Wwinddirection SMALLINT;

    START TRANSACTION;
    SELECT temp,humidity,airpressure,wind INTO Wtemp,Whumidity, Wairpressure,Wwind
    FROM weatherdata
         WHERE log_date = Wlog_date AND `time`= Wtime AND station= Wstation;
IF Wtemp < 0 AND Wtemp > 40 OR Whumidity < 20 OR Wairpressure < 950 OR Wwind > 50 
OR Wwinddirection > 150 THEN
     UPDATE flight SET departure = DATE_ADD(departure, INTERVAL 2 HOUR)
     		WHERE flightno = 'JO5430' AND departure LIKE '%2015-08-18%';
     UPDATE flight SET arrival = DATE_ADD(arrival, INTERVAL 2 HOUR)
     		WHERE flightno = 'JO5430' AND departure LIKE '%2015-08-18%';   
     CALL DeleteBooking(55099804);
     COMMIT;
     SELECT commit_message AS 'RESULTS';
     ELSE
ROLLBACK;
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = rollback_message;
    END IF;
END //
  DELIMITER ;
CALL TicketCancellation('2015-08-18','11:45:00',1)
CALL TicketCancellation('2015-08-18','14:45:00',1)

/*6. Do chuyến bay bị hủy nên cần kiểm tra lại thông tin hành khách.
- Nếu kiểm tra không còn booking nào của David thì xóa thông tin của David trong bảng passenger và passengerdetails.
- Nếu còn booking của David thì rollback đưa ra thông báo lỗi.
*/
DELIMITER //
CREATE PROCEDURE CheckInfoAgain(IN passenger_id INT)
BEGIN
 DECLARE rollback_message VARCHAR(255) DEFAULT 'Ticket booking information exists. Customer information cannot be deleted.';
 DECLARE commit_message VARCHAR(255) DEFAULT 'Deleted customer information successfully.';
 DECLARE count_found INT DEFAULT 0;
 START TRANSACTION;
    SELECT COUNT(*) INTO count_found FROM booking WHERE passenger_id = passengerid;
    IF count_found > 0 THEN ROLLBACK;
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = rollback_message;
    ELSE  DELETE FROM passengerdetails WHERE passenger_id = passengerid;
          DELETE FROM passenger WHERE passenger_id = passengerid; COMMIT;
    	SELECT commit_message AS 'Results';
    END IF;
    END //
DELIMITER ;
CALL CheckInfoAgain(36113);


