USE mugiwarapp_local_test;

-- SEC 2.4 FUNCTIONS
	-- SEC 2.4.1 IMPACT_RATIO_FUNCTION
DELIMITER //
CREATE FUNCTION 
	impact_ratio (pk_card INT)
	RETURNS DECIMAL (5,2)
	DETERMINISTIC
	BEGIN
	DECLARE 
		total_in_decks 			INT;
	DECLARE 
		total_amount_of_cards 	INT default 1;
		SELECT 
			ifnull(sum(amount),0) INTO total_in_decks
		FROM 
			winner_deck_detail AS wdd
		WHERE 
			wdd.fk_card = pk_card;

		SELECT
			count(*) INTO total_amount_of_cards
		FROM 
			winner_deck_detail;

		IF total_amount_of_cards = 0 THEN RETURN 0.00;
	END IF;

	RETURN ROUND(  (total_in_decks / total_amount_of_cards)*100  ,5);
END //
DELIMITER ;

	-- SEC 2.4.2 COLLECTION COMPLETION RATIO
    -- Created to check how much completed is the collection for every user. It takes into account that 
    -- leader cards only need 1, and all the others need at leat a playset of 4.
    
delimiter //
create function complete_collection_ratio (userid INT)
returns decimal (5,2)
deterministic
begin
declare user_stock INT;
declare cards_needed INT;
declare completion_deck decimal (5,2);

select sum(stock_amount) into user_stock 
	from collection_user_view
	where collection_user_view.fk_user = userid;
select sum(if (collection_user_view.card_type_name = 'Leader',1,4)) into cards_needed
	from collection_user_view
    where collection_user_view.fk_user = userid;

if cards_needed = 0 then 
set completion_deck = 0;
else 
	set completion_deck = (cards_needed/user_stock)*100;
end if;
return completion_deck;
end //
delimiter ;


-- SEC 2.5 STORED PROCEDURES
-- SEC 2.5.1 DECK VALIDATOR
-- THIS PROCEDURE ASSURES THAT A USER DECK BUILT IS VALID FOR ANY TOURNAMENT 
-- (51 CARDS, NO BANNED CARDS, NO CARDS OUT OF ROTATION).

DELIMITER //
CREATE PROCEDURE 
	deck_validator (in pk_user_deck INT)
	BEGIN
-- the deck that we will check
	DECLARE deckcheck 	INT;
-- the card check for 51 cards
	DECLARE cards51 	INT DEFAULT 0;
	DECLARE checknumber VARCHAR (100);

-- to check the pk_code that contains Banned in the text, and a counter of banned cards.
	DECLARE banstatus 	INT;
	DECLARE bancheck 	INT;
	DECLARE checkalarm 	VARCHAR (100);

-- we will need also the rotation
	DECLARE rotationstatus 	INT;
	DECLARE rotationcount 	INT;
	DECLARE rotation_alarm 	VARCHAR (100);


-- Lets check if the deck has 51 cards:
		SET deckcheck = 
        (
			SELECT 
            pk_user_deck 
            FROM 
            user_deck LIMIT 1
		)
        ;
		SET cards51 =
        (
			SELECT 
				sum(deck_amount) 
			FROM 
				user_deck_detail 
                WHERE 
					fk_user_deck = deckcheck
		)
        ;
-- Lets set up cards51 and Checknumber message.
			IF cards51 = 51 THEN 
				SET checknumber = 'OK'; 
					ELSE SET checknumber =Concat('The deck misses ', 51-cards51,'Cards');

			END IF;

-- check what is the pk_status that represents a banned card
		SET banstatus = 
        (
			SELECT 
				pk_status 
			FROM 
				card_legal_status 
			WHERE 
				status_name = 'Banned'
		)
        ;

-- count from the deck all the cards that has a banned card
		SET bancheck = 
        (
			SELECT 
				count(*) 
			FROM 
				cardlist AS cl
			JOIN 
				user_deck_detail AS udd ON cl.pk_card = udd.fk_card
			WHERE 
				udd.fk_user_deck = pk_user_deck
				AND cl.fk_legal_status = banstatus);

	IF bancheck = 0 
		THEN SET checkalarm = 'OK';
			ELSE SET checkalarm = 'The deck contains 1 or more Banned cards ';
	END IF;

-- rotation check 
-- Check the highest rotation number that is forbidden for today
	SET rotationstatus = 
    (
		SELECT 
			max(pk_rotation) 
		FROM 
			card_rotation 
		WHERE 
			rotation_final_day < curdate()
	);
		IF  rotationstatus IS NULL THEN SET rotationstatus = 0;
	END IF;

-- count the forbidden cards
	SET rotationcount = 
		(
        Select 
        count(*) 
        FROM 
			cardlist AS cl
		JOIN 
			user_deck_detail AS udd ON cl.pk_card = udd.fk_card
		WHERE 
			udd.fk_user_deck = pk_user_deck
			AND cl.fk_rotation <= rotationstatus
		);

	IF rotationcount = 0 THEN SET rotation_alarm = 'OK';
		ELSE SET rotation_alarm = 'The deck contains cards with past rotations';
	END IF;

	SELECT 
		checknumber AS '51 cards Check', 
        checkalarm AS 'Banned Cards Check', 
		rotation_alarm AS 'Rotation Cards Ceck';
END //
DELIMITER ;


-- SEC 2.5.2 BACKUP MAINTENANCE
-- Created to delete backups from user decks after 32 days.
drop procedure if exists backup_maintenance;
delimiter // 
create procedure backup_maintenance ()
begin
-- select the data limit of 32 days 
declare deletedate datetime;
-- Total rows from backup_user_deck that exceeds data limit.
declare backup_user_deck_count INT;
-- Total rows from backup_user_deck_detail that exceeds data limit.
declare delete_user_deck_detail_count INT;
-- sum of both rows.
declare total_rows INT;

-- set the data
set deletedate = CURRENT_DATE - INTERVAL 32 DAY;
	
-- Start Transaction
		start transaction;

-- lets check how many inserts we have in the backup
select count(*) into backup_user_deck_count
	from backup_user_deck where backup_time < deletedate;
select count(*) into delete_user_deck_detail_count
	from backup_user_deck_detail where backup_time < deletedate;
		
        set total_rows = backup_user_deck_count+delete_user_deck_detail_count;
 -- WHILE FUNCTION because we will limit delete results at 1 row at time.
 
while total_rows > 0 do 

-- Delete rows exceeding deletedate
	delete from backup_user_deck_detail where backup_time < deletedate limit 1;
		delete from backup_user_deck where backup_time < deletedate limit 1;

-- lets check how many inserts we have in the backup
select count(*) into backup_user_deck_count
	from backup_user_deck where backup_time < deletedate;
select count(*) into delete_user_deck_detail_count
	from backup_user_deck_detail where backup_time < deletedate;
		set total_rows = backup_user_deck_count+delete_user_deck_detail_count;
 end while;
 
 COMMIT;

end //
delimiter ;

-- SEC 2.6 EVENTS
-- SEC 2.6.1 BACKUP EVENT SCHEDULER

SET GLOBAL event_scheduler = ON;

CREATE EVENT IF NOT EXISTS backup_maintenance_event
ON SCHEDULE EVERY 1 DAY
STARTS '2025-05-27 00:00:00'
DO
CALL backup_maintenance;


