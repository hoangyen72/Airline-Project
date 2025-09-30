-- 1. Một doanh nhân tên John Stax thường xuyên phải đi công tác nước ngoài nên di chuyển bằng máy bay liên tục. Vào ngày công tác, anh muốn tra cứu lại thông tin chuyến bay. Biết anh đã đặt vé và có số hộ chiếu là “P106000”.
SELECT p.passenger_id, CONCAT(firstname,' ',lastname) passengerName, seat, flightno, DATE(departure) departure_date, a1.name depart_airport, a2.name arrive_airport FROM flight f 	
	INNER JOIN airport a1 ON f.`from` = a1.airport_id
	JOIN airport a2 ON f.`to` = a2.airport_id
	JOIN booking b ON f.flight_id = b.flight_id
	JOIN passenger p ON p.passenger_id = b.passenger_id
WHERE passportno = 'P106000' AND DATE(f.departure) = '2015-12-24';

-- 2. Anh muốn đến một nơi gần chỗ công tác du lịch nhưng giá vé lại hơi đắt. Kiểm tra anh đang ở xếp hạng hành khách nào để xem có thể được giảm giá không.
DELIMITER $$
CREATE FUNCTION passengerType(passportNum CHAR(9)) RETURNS VARCHAR(20)
DETERMINISTIC 
BEGIN 
   DECLARE passengerType VARCHAR(20); DECLARE total_flight INT;   
   SET total_flight = 
          (SELECT COUNT(flight_id) FROM booking b
           INNER JOIN passenger p ON p.passenger_id = b. passenger_id 
           WHERE passportno = passportNum);
   CASE WHEN (total_flight <= 20) THEN SET passengerType  = 'New';
       WHEN (total_flight BETWEEN 20 AND 50) THEN SET passengerType = 'Silver';
       WHEN (total_flight BETWEEN 50 AND 100) THEN SET passengerType = 'Gold';
       ELSE SET passengerType = 'Platinum';
   END CASE;
   RETURN (passengerType);
END $$
DELIMITER ;

SELECT CONCAT(firstname,' ',lastname) fullname, passportno,  	passengerType(passportno) passengerType
FROM passenger
WHERE passportno = 'P106000'

-- 3. Chính phủ Việt Nam đang tìm cách cải thiện doanh thu ngành hàng không. Trước tiên, tìm các hãng hàng không có trụ sở ở Việt Nam để có báo báo doanh thu của hãng.
SELECT airline_id, airlinename FROM airline a
WHERE EXISTS 
  (SELECT * FROM airport_geo apg
   WHERE apg.airport_id = a.base_airport 
         AND apg.country = 'VIETNAM');

-- 4.  Thống kê doanh thu các chuyến bay của Vietnam Airlines, xếp hạng theo từng tháng. Chỉ lấy 5 chuyến bay có doanh thu lớn nhất mỗi tháng.
SELECT * 
FROM (SELECT flight_id, MONTH(departure) `month`, SUM(price) flightRevenue, 
      DENSE_RANK() OVER (PARTITION BY MONTH(departure) ORDER BY SUM(price) DESC) AS revenueRank   
      FROM flight f JOIN booking b ON f.flight_id = b. f.flight_id
      JOIN airline a USING f.airline_id = a.airline_id 
      WHERE airlinename = "Vietnam Airlines"
      GROUP BY flight_id, `month`) tbl
HAVING revenueRank <= 5;

-- 5. Tính doanh thu theo theo từng tháng của hãng hàng không Vietnam Airlines và hiển thị tổng doanh thu theo năm.
SELECT  MONTH(departure) AS `month`, SUM(price) monthRevenue FROM flight f
INNER JOIN booking b ON f.flight_id = b.flight_id
INNER JOIN airline a ON f.airline_id = a.airline_id
WHERE airlinename = 'Vietnam Airlines' 
GROUP BY `month` WITH ROLLUP;

-- 6. So sánh doanh thu các tháng với tháng trước đó (tỷ lệ % tăng/giảm doanh  thu) 
WITH MonthlyRevenue AS (
SELECT MONTH(departure) `month`, SUM(price) monthRevenue
FROM flight f INNER JOIN booking b ON f.flight_id = b.flight_id
INNER JOIN airline a ON f.airline_id = a.airline_id
WHERE airlinename = 'Vietnam Airlines' GROUP BY `month`)
SELECT 
    `month` thisMonth, monthRevenue AS thisMonthRevenue, (`month`-1) lastMonth, 
    LAG(monthRevenue,1,0) OVER(ORDER BY `month`) lastMonthRevenue,
    ROUND((monthRevenue - LAG(monthRevenue, 1 , 0) OVER 
	(ORDER BY `month`))/monthRevenue * 100, 2) AS `monthlyGrowth (%)`
FROM MonthlyRevenue

-- 7. Tìm 10 hãng hàng không chưa có chuyến bay nào từ Việt Nam để mời hợp tác.
SELECT airline_id, airlinename 
FROM airline
WHERE airline_id != ALL (
    SELECT DISTINCT airline_id
    FROM flightschedule fs JOIN airport_geo ag 
    ON fs.`from` = ag.airport_id
    WHERE country = 'VIETNAM')
LIMIT 10;

-- 8. Vào ngày 01/06/2015, Chính phủ Việt Nam muốn tìm thông tin liên lạc của tất cả các hành khách từng đi đến Việt Nam (đến một trong các sân bay ở VN) để quảng bá thông tin du lịch đến họ.
SELECT emailaddress, telephoneno FROM passengerdetails 
WHERE passenger_id = ANY (
	SELECT passenger_id FROM airport_geo ag
         INNER JOIN flight f ON f.`to` = ag.airport_id
         INNER JOIN booking b ON f.flight_id = b.flight_id
    	WHERE country = 'VIETNAM' AND DATE(departure) <= "2015-06-01");

-- 9. Với những người đã được gửi thông tin quảng bá du lịch, tìm xem thời gian họ quay lại Việt Nam là bao lâu.
-- Danh sách hành khách đến Việt Nam trước   
'2015-06-01' đã gửi mail và tin nhắn
DROP VIEW IF EXISTS sentList;
CREATE VIEW sentList AS
SELECT passenger_id, MAX(DATE(departure)) `lastCameBefore_1/6`
    FROM airport_geo ag
    INNER JOIN flight f ON f.`to` = ag.airport_id
    INNER JOIN booking ON (flight_id)
    WHERE country = 'VIETNAM' 
	AND DATE(departure) <= '2015-06-01'
GROUP BY passenger_id;

SELECT * FROM sentList;

-- Danh sách hành khách đến Việt Nam sau '2015-06-01' 
DROP VIEW IF EXISTS afterSentList;
CREATE VIEW afterSentList AS
SELECT passenger_id, MIN(DATE(departure)) `firstCameAfter_1/6`
    FROM airport_geo ag
    INNER JOIN flight f ON f.`to` = ag.airport_id
    INNER JOIN booking ON (flight_id)
    WHERE country = 'VIETNAM' 
	AND DATE(departure)> '2015-06-01'
GROUP BY passenger_id;

SELECT * FROM afterSentList;

-- Với người quay lại, tìm xem thời gian họ quay lại VN là bao lâu. Nếu không quay lại ghi “No Return” và thời gian quay lại là -1. 
SELECT s.passenger_id, `lastCameBefore_1/6`,
       IFNULL(`firstCameAfter_1/6`, 'No Return') `firstCameAfter_1/6`,
       IFNULL(DATEDIFF(`firstCameAfter_1/6`, `lastCameBefore_1/6`), -1) returnTime
FROM sentList s LEFT JOIN aftersentlist ON s.passenger_id = a.passenger_id
-- Lọc ra hành khách không quay lại Việt Nam bằng HAVING
HAVING returnTime = -1;

-- 10. Cuối 2015, Chính phủ tìm thông tin liên lạc của tất cả các hành khách nước ngoài từng đến VN và các hành khách người Việt (kể cả hành khách chưa từng bay với Vietnam Airlines) để khảo sát về chất lượng hàng không.
SELECT emailaddress, telephoneno, 'Nội địa' AS passengerType 
FROM passengerdetails WHERE country = 'VIETNAM' 
UNION 
SELECT emailaddress, telephoneno, 'Nước ngoài' AS passengerType
FROM passengerdetails WHERE country != 'VIETNAM' AND passenger_id IN 
	(SELECT passenger_id FROM sentList UNION
	 SELECT passenger_id FROM afterSentList);
