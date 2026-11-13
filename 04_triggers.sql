-- =============================================================================
-- Mugiwarapp Analytics | 04 · Triggers
-- Reglas de negocio del reglamento de One Piece TCG y auditoría de mazos.
-- Se ejecuta después de cargar datos (02 y 03) para no bloquear la carga inicial.
--
-- Cada regla existe en dos variantes: INSERT y UPDATE. Antes solo existía INSERT,
-- así que un UPDATE podía saltarse todas las reglas (p. ej. pasar a 9 copias).
-- =============================================================================
USE mugiwarapp;

DELIMITER //

-- -----------------------------------------------------------------------------
-- Auditoría: fecha de creación del mazo
-- -----------------------------------------------------------------------------
CREATE TRIGGER before_user_deck_insert
BEFORE INSERT ON user_deck
FOR EACH ROW
BEGIN
    SET NEW.creation_date = NOW();
END//

-- Histórico de la cabecera del mazo al borrarlo (los detalles se borran antes,
-- porque user_deck_detail tiene ON DELETE RESTRICT)
CREATE TRIGGER user_deck_header_backup
BEFORE DELETE ON user_deck
FOR EACH ROW
BEGIN
    INSERT INTO backup_user_deck (pk_user_deck, fk_user, deck_name, fk_leader_card, backup_time)
    VALUES (OLD.pk_user_deck, OLD.fk_user, OLD.deck_name, OLD.fk_leader_card, NOW(6));
END//

-- Histórico de detalle: guarda la versión ANTERIOR de la línea al modificarla
CREATE TRIGGER deck_detail_backup
AFTER UPDATE ON user_deck_detail
FOR EACH ROW
BEGIN
    INSERT INTO backup_user_deck_detail (fk_user_deck, fk_card, deck_amount, backup_time)
    VALUES (OLD.fk_user_deck, OLD.fk_card, OLD.deck_amount, NOW(6));
END//

-- Histórico de detalle al borrar una línea
CREATE TRIGGER deck_detail_delete_backup
BEFORE DELETE ON user_deck_detail
FOR EACH ROW
BEGIN
    INSERT INTO backup_user_deck_detail (fk_user_deck, fk_card, deck_amount, backup_time)
    VALUES (OLD.fk_user_deck, OLD.fk_card, OLD.deck_amount, NOW(6));
END//

-- -----------------------------------------------------------------------------
-- Regla 1: máximo de copias según estado legal de la carta
--   Banned     -> 0 copias
--   Restricted -> 1 copia
--   Unlimited / unknown -> sin límite
--   Resto (Legal) -> 4 copias
-- -----------------------------------------------------------------------------
CREATE TRIGGER max4copies
BEFORE INSERT ON user_deck_detail
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(45);
    DECLARE v_limit  INT;

    SELECT s.status_name INTO v_status
    FROM cardlist c
    JOIN card_legal_status s ON s.pk_status = c.fk_legal_status
    WHERE c.pk_card = NEW.fk_card;

    SET v_limit = CASE v_status
                    WHEN 'Banned'     THEN 0
                    WHEN 'Restricted' THEN 1
                    WHEN 'Unlimited'  THEN NULL
                    WHEN 'unknown'    THEN NULL
                    ELSE 4
                  END;

    IF v_limit IS NOT NULL AND NEW.deck_amount > v_limit THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Copy limit exceeded for this card legal status';
    END IF;
END//

CREATE TRIGGER max4copies_upd
BEFORE UPDATE ON user_deck_detail
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(45);
    DECLARE v_limit  INT;

    SELECT s.status_name INTO v_status
    FROM cardlist c
    JOIN card_legal_status s ON s.pk_status = c.fk_legal_status
    WHERE c.pk_card = NEW.fk_card;

    SET v_limit = CASE v_status
                    WHEN 'Banned'     THEN 0
                    WHEN 'Restricted' THEN 1
                    WHEN 'Unlimited'  THEN NULL
                    WHEN 'unknown'    THEN NULL
                    ELSE 4
                  END;

    IF v_limit IS NOT NULL AND NEW.deck_amount > v_limit THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Copy limit exceeded for this card legal status';
    END IF;
END//

-- -----------------------------------------------------------------------------
-- Regla 2: máximo de 51 cartas por mazo
--   En UPDATE se excluye la línea que se modifica para no contarla dos veces.
-- -----------------------------------------------------------------------------
CREATE TRIGGER user_deck_plus_51
BEFORE INSERT ON user_deck_detail
FOR EACH ROW
BEGIN
    DECLARE v_total INT;

    SELECT IFNULL(SUM(deck_amount), 0) INTO v_total
    FROM user_deck_detail
    WHERE fk_user_deck = NEW.fk_user_deck;

    IF v_total + NEW.deck_amount > 51 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Deck cannot contain more than 51 cards';
    END IF;
END//

CREATE TRIGGER user_deck_plus_51_upd
BEFORE UPDATE ON user_deck_detail
FOR EACH ROW
BEGIN
    DECLARE v_total INT;

    SELECT IFNULL(SUM(deck_amount), 0) INTO v_total
    FROM user_deck_detail
    WHERE fk_user_deck = NEW.fk_user_deck
      AND fk_card <> NEW.fk_card;

    IF v_total + NEW.deck_amount > 51 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Deck cannot contain more than 51 cards';
    END IF;
END//

-- -----------------------------------------------------------------------------
-- Regla 3: la carta debe compartir al menos un color con el líder.
--   Corrección: antes solo se comparaba el primer color de la carta, así que una
--   carta roja/verde se rechazaba en un mazo azul/verde aunque sí comparte verde.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_check_card_color_match
BEFORE INSERT ON user_deck_detail
FOR EACH ROW
BEGIN
    DECLARE l1 VARCHAR(45);
    DECLARE l2 VARCHAR(45);
    DECLARE c1 VARCHAR(45);
    DECLARE c2 VARCHAR(45);

    SELECT LOWER(lc.colour1), LOWER(lc.colour2) INTO l1, l2
    FROM user_deck ud
    JOIN cardlist lcard     ON lcard.pk_card = ud.fk_leader_card
    JOIN card_colour lc     ON lc.pk_colour = lcard.fk_color
    WHERE ud.pk_user_deck = NEW.fk_user_deck;

    SELECT LOWER(cc.colour1), LOWER(cc.colour2) INTO c1, c2
    FROM cardlist c
    JOIN card_colour cc ON cc.pk_colour = c.fk_color
    WHERE c.pk_card = NEW.fk_card;

    IF NOT (c1 IN (l1, l2) OR c2 IN (l1, l2)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Card colour does not match the leader colour(s)';
    END IF;
END//

CREATE TRIGGER trg_check_card_color_match_upd
BEFORE UPDATE ON user_deck_detail
FOR EACH ROW
BEGIN
    DECLARE l1 VARCHAR(45);
    DECLARE l2 VARCHAR(45);
    DECLARE c1 VARCHAR(45);
    DECLARE c2 VARCHAR(45);

    SELECT LOWER(lc.colour1), LOWER(lc.colour2) INTO l1, l2
    FROM user_deck ud
    JOIN cardlist lcard     ON lcard.pk_card = ud.fk_leader_card
    JOIN card_colour lc     ON lc.pk_colour = lcard.fk_color
    WHERE ud.pk_user_deck = NEW.fk_user_deck;

    SELECT LOWER(cc.colour1), LOWER(cc.colour2) INTO c1, c2
    FROM cardlist c
    JOIN card_colour cc ON cc.pk_colour = c.fk_color
    WHERE c.pk_card = NEW.fk_card;

    IF NOT (c1 IN (l1, l2) OR c2 IN (l1, l2)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Card colour does not match the leader colour(s)';
    END IF;
END//

DELIMITER ;
