USE mugiwarapp_local_test;

-- SEC 2.3 TRIGGERS
-- SEC 2.3.1 PERSONAL TRIGGERS (TRIGGERS CREATED BY US WITH NO HELP FROM CHAT-GPT)

-- SEC 2.3.1.2 TRIGGER TO SAVE DECKLISTS AFTER UPDATE
DELIMITER //
CREATE TRIGGER deck_detail_backup
	AFTER UPDATE ON user_deck_detail
	FOR EACH ROW
	BEGIN 
	INSERT INTO backup_user_deck_detail (fk_user_deck,fk_card,deck_amount,backup_time) 
	VALUES
	(OLD.fk_user_deck,OLD.fk_card,OLD.deck_amount,now());
END //
DELIMITER ;

-- SEC 2.3.1.2.2 TRIGGER TO REGISTER DECK CREATION

DELIMITER //
CREATE TRIGGER before_user_deck_insert
	BEFORE INSERT ON user_deck
	FOR EACH ROW
	BEGIN
    SET NEW.creation_date = NOW();
END //
DELIMITER ;

-- SEC 2.3.1.2.3 TRIGGER TO BACKUP DECK DETAILS BEFORE DELETE
-- IT DOESN´T HAS ISSUES DUE BACKUP_TIME COLUMN ALSO IS PK.
DROP TRIGGER IF EXISTS  deck_detail_delete_backup;
DELIMITER //
CREATE TRIGGER deck_detail_delete_backup
	BEFORE DELETE ON user_deck_detail
	FOR EACH ROW
	BEGIN 
	INSERT INTO backup_user_deck_detail (fk_user_deck,fk_card,deck_amount,backup_time) 
	VALUES
	(OLD.fk_user_deck,OLD.fk_card,OLD.deck_amount,now());
END //
DELIMITER ;

-- SEC 2.3.2 CHATGPT TRIGGERS (THESE TRIGGERS WERE CREATED WITH THE HELP OF CHATGPT
-- THEY WERE NEEDED TO BE CREATED IN ORDER OF CORRECT PERFORMANCE OF THE DDBB, BUT THE SKILL REQUIRED EXCEEDED
-- OURS AT THE MOMENT OF CREATION

-- SEC 2.3.2.1 -- MAXIMUM 4 COPIES OF EACH CARD WHEN ADDED INTO USER-DECK-DETAIL
DELIMITER //
CREATE TRIGGER max4copies
	BEFORE INSERT ON user_deck_detail
	FOR EACH ROW
	BEGIN
	DECLARE card_status_id INT DEFAULT 0;

    SELECT 
		fk_legal_status
    INTO card_status_id
    FROM 
		cardlist
    WHERE 
		pk_card = NEW.fk_card;


  -- legal status 4 = 'Unlimited', 9 = 'unknown' (see SEC 3.7): no 4-copy limit for them
  IF card_status_id not in (4,9) AND NEW.deck_amount > 4 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot insert more than 4 copies of a single card';
    END IF;
END //

DELIMITER ;

-- SEC 2.3.2.2 TRIGGER TO CHECK THAT THE TOTAL AMOUNT OF CARDS DOES NOT EXCEED 51.

DELIMITER $$
CREATE TRIGGER user_deck_plus_51
	BEFORE INSERT ON user_deck_detail
	FOR EACH ROW
	BEGIN
    DECLARE 
		total_cards INT;
	SELECT 
		IFNULL(SUM(deck_amount), 0)
    INTO total_cards
    FROM 
		user_deck_detail
    WHERE 
		fk_user_deck = NEW.fk_user_deck;
	SET total_cards = total_cards + NEW.deck_amount;
	IF total_cards > 51 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Deck cannot contain more than 51 cards';
    END IF;
END$$

DELIMITER ;

-- SEC 2.3.2.2 TRIGGER TO VERIFY THAT THE CARDS MATCH WITH THE LEADER COLOR(S)

DELIMITER //

CREATE TRIGGER trg_check_card_color_match
	BEFORE INSERT ON user_deck_detail
	FOR EACH ROW
	BEGIN
    -- Rule: a card is legal in a deck when it shares at least one colour with the leader.
    -- Leader and card can each have two colours (colour1/colour2; equal when single-colour).
    DECLARE leader_colour1 	VARCHAR(45);
    DECLARE leader_colour2 	VARCHAR(45);
    DECLARE card_colour1 	VARCHAR(45);
    DECLARE card_colour2 	VARCHAR(45);
    DECLARE err_msg 		TEXT;

    SELECT
		LOWER(TRIM(l.colour1)), LOWER(TRIM(l.colour2))
	INTO
		leader_colour1, leader_colour2
    FROM
		user_deck AS d
    JOIN
		leader_list AS l ON d.fk_leader_card = l.pk_card
    WHERE
		d.pk_user_deck = NEW.fk_user_deck;

    SELECT
		LOWER(TRIM(cc.colour1)), LOWER(TRIM(cc.colour2))
	INTO
		card_colour1, card_colour2
    FROM
		cardlist AS c
    JOIN
		card_colour AS cc ON c.fk_color = cc.pk_colour
    WHERE
		c.pk_card = NEW.fk_card;

    IF card_colour1 NOT IN (leader_colour1, leader_colour2)
       AND card_colour2 NOT IN (leader_colour1, leader_colour2) THEN
        SET err_msg = CONCAT('Card colour "', card_colour1, '/', card_colour2,
							 '" does not match leader colours: ', leader_colour1, '/', leader_colour2);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
    END IF;

END//

DELIMITER ;

