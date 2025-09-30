CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdatePassenger`
(  IN p_passenger_id INT,  IN p_passportno CHAR(9),
    IN p_firstname VARCHAR(100),     IN p_lastname VARCHAR(100))
BEGIN
    UPDATE passenger
    SET passportno = p_passportno, firstname = p_firstname, lastname = p_lastname
    WHERE passenger_id = p_passenger_id;
END
