CREATE DEFINER =`root`@`localhost` PROCEDURE `InsertPassenger`
    (IN p_passportno CHAR(9), IN p_firstname VARCHAR(100), 
     IN p_lastname VARCHAR(100))
BEGIN
    INSERT INTO passenger (passportno, firstname, lastname)
    VALUES (p_passportno, p_firstname, p_lastname);
END
