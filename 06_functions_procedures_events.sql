-- =============================================================================
-- Mugiwarapp Analytics | 06 · Funciones, procedimientos y eventos
-- =============================================================================
USE mugiwarapp;

DELIMITER //

-- -----------------------------------------------------------------------------
-- impact_ratio(carta) -> % de mazos ganadores que incluyen la carta (0-100)
-- Corrección: antes sumaba cantidades y dividía entre el número de filas, así que
-- los valores por carta sumaban ~317% y no eran una proporción.
-- Marcada READS SQL DATA (no DETERMINISTIC): depende de datos que cambian.
-- -----------------------------------------------------------------------------
CREATE FUNCTION impact_ratio (p_card INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_with  INT DEFAULT 0;
    DECLARE v_total INT DEFAULT 0;

    SELECT COUNT(DISTINCT fk_winner_deck) INTO v_total
    FROM winner_deck_detail
    WHERE amount > 0;

    SELECT COUNT(DISTINCT fk_winner_deck) INTO v_with
    FROM winner_deck_detail
    WHERE fk_card = p_card AND amount > 0;

    IF v_total = 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND(100 * v_with / v_total, 2);
END//

-- -----------------------------------------------------------------------------
-- complete_collection_ratio(usuario) -> % de playsets completos del catálogo
--   Necesario por carta: 1 si es Leader, 4 en el resto.
--   Poseído útil: MIN(necesario, stock). Así el resultado está entre 0 y 100.
-- Corrección: antes devolvía necesarias / poseídas * 100 (invertido y sin tope).
-- -----------------------------------------------------------------------------
CREATE FUNCTION complete_collection_ratio (p_user INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_needed INT DEFAULT 0;
    DECLARE v_owned  INT DEFAULT 0;

    SELECT SUM(IF(ct.card_type_name = 'Leader', 1, 4)) INTO v_needed
    FROM cardlist c
    JOIN card_type ct ON ct.pk_card_type = c.fk_card_type
    WHERE c.pk_card <> 99999;

    SELECT SUM(LEAST(IF(ct.card_type_name = 'Leader', 1, 4), IFNULL(us.stock_amount, 0))) INTO v_owned
    FROM cardlist c
    JOIN card_type ct ON ct.pk_card_type = c.fk_card_type
    LEFT JOIN user_stock us ON us.fk_card = c.pk_card AND us.fk_user = p_user
    WHERE c.pk_card <> 99999;

    IF v_needed IS NULL OR v_needed = 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND(100 * IFNULL(v_owned, 0) / v_needed, 2);
END//

-- -----------------------------------------------------------------------------
-- deck_validator(mazo) -> comprueba 51 cartas, cartas prohibidas y rotación
-- Corrección: antes usaba SELECT pk_user_deck FROM user_deck LIMIT 1 para el
-- conteo de 51 cartas, así que validaba un mazo arbitrario y no el recibido.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE deck_validator (IN p_deck INT)
BEGIN
    DECLARE v_exists   INT DEFAULT 0;
    DECLARE v_total    INT DEFAULT 0;
    DECLARE v_banned   INT DEFAULT 0;
    DECLARE v_cutoff   INT DEFAULT 0;
    DECLARE v_rotated  INT DEFAULT 0;
    DECLARE v_51_msg   VARCHAR(100);
    DECLARE v_ban_msg  VARCHAR(100);
    DECLARE v_rot_msg  VARCHAR(100);

    SELECT COUNT(*) INTO v_exists FROM user_deck WHERE pk_user_deck = p_deck;
    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Deck not found';
    END IF;

    -- 1) Número de cartas
    SELECT IFNULL(SUM(deck_amount), 0) INTO v_total
    FROM user_deck_detail
    WHERE fk_user_deck = p_deck;

    IF v_total = 51 THEN
        SET v_51_msg = 'OK';
    ELSEIF v_total < 51 THEN
        SET v_51_msg = CONCAT('The deck misses ', 51 - v_total, ' cards');
    ELSE
        SET v_51_msg = CONCAT('The deck has ', v_total - 51, ' cards too many');
    END IF;

    -- 2) Cartas con estado Banned
    SELECT COUNT(*) INTO v_banned
    FROM user_deck_detail udd
    JOIN cardlist c            ON c.pk_card = udd.fk_card
    JOIN card_legal_status s   ON s.pk_status = c.fk_legal_status
    WHERE udd.fk_user_deck = p_deck
      AND s.status_name = 'Banned';

    SET v_ban_msg = IF(v_banned = 0, 'OK', 'The deck contains banned cards');

    -- 3) Rotación: la rotación más alta ya caducada (fecha final < hoy)
    SELECT IFNULL(MAX(pk_rotation), 0) INTO v_cutoff
    FROM card_rotation
    WHERE rotation_final_day < CURDATE();

    SELECT COUNT(*) INTO v_rotated
    FROM user_deck_detail udd
    JOIN cardlist c ON c.pk_card = udd.fk_card
    WHERE udd.fk_user_deck = p_deck
      AND v_cutoff > 0
      AND c.fk_rotation <= v_cutoff;

    SET v_rot_msg = IF(v_rotated = 0, 'OK', 'The deck contains cards from rotated sets');

    SELECT p_deck       AS deck,
           v_51_msg     AS `51 cards check`,
           v_ban_msg    AS `Banned cards check`,
           v_rot_msg    AS `Rotation check`;
END//

-- -----------------------------------------------------------------------------
-- backup_maintenance() -> borra el histórico de mazos con más de 32 días
-- Sin FKs entre tablas de histórico, un DELETE por tabla basta (antes era un
-- bucle fila a fila dentro de una transacción).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE backup_maintenance ()
BEGIN
    DECLARE v_cutoff DATETIME DEFAULT NOW() - INTERVAL 32 DAY;

    START TRANSACTION;
    DELETE FROM backup_user_deck_detail WHERE backup_time < v_cutoff;
    DELETE FROM backup_user_deck        WHERE backup_time < v_cutoff;
    COMMIT;
END//

DELIMITER ;

-- Evento diario de limpieza.
-- Requiere event_scheduler activo (ver README: SET GLOBAL event_scheduler = ON;).
CREATE EVENT IF NOT EXISTS backup_maintenance_event
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO
    CALL backup_maintenance();
