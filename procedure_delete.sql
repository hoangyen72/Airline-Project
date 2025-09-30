CREATE DEFINER =`root`@`localhost` PROCEDURE `DeletePassenger`
    (IN p_passenger_id INT)
BEGIN
    DELETE FROM passenger WHERE passenger_id = p_passenger_id;    
END
