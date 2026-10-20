USE mugiwarapp_local_test;

-- SEC 2.2 VIEWS

-- SEC 2.2.1 LEADER VIEW (OVERALL VIEW OF LEADERS WITH HIS COLOUR, FEEDING COLOR TRIGGER

CREATE VIEW leader_list AS
	SELECT 
		c.pk_card,
		c.card_name, 
		col.colour1,
		col.colour2,
		col.colour_complete
	FROM 
		cardlist AS c 
	JOIN 
		card_colour AS col ON c.fk_color = col.pk_colour
	JOIN 
		card_type AS t ON c.fk_card_type = t.pk_card_type
	WHERE 
			t.card_type_name = "Leader";


  -- SEC 2.2.2 TOP LEADERS VIEW ( A TOP TEN OF THE BEST LEADERS, WITH COLOR, NAME, TOURNAMENTS AND POINTS
CREATE VIEW  top_leaders AS
	SELECT 
		ROW_NUMBER() OVER (ORDER BY SUM(t.points_by_tournament) DESC) AS rank_number,
		cl.pk_card, 
		cl.card_code, 
		ll.colour_complete, 
		cl.card_name, 
		count(mw.fk_tournament) as wins_report, 
		sum(t.points_by_tournament) as points
	FROM 
		meta_winners AS mw 
	JOIN 
		cardlist AS cl ON cl.pk_card =  mw.fk_card
	JOIN 
		tournaments AS t ON t.pk_tournament = mw.fk_tournament
	JOIN 
		leader_list AS ll ON ll.pk_card = mw.fk_card
	GROUP BY 
		cl.pk_card,
        cl.card_code,
        ll.colour_complete, 
        cl.card_name 
	ORDER BY 
		points DESC LIMIT 10;

  -- SEC 2.2.3 TOP PLAYERS (ASIAN WINNERS WITH WIN POINTS, REMOVED USERS 'JAPAN FLAGSHIPS', ETC. 
  -- AS THEY ARE UNKNOWN USERS)
DROP VIEW IF EXISTS top_players;
CREATE VIEW top_players AS 
	SELECT 
		mw.winner_name, 
        count(mw.fk_tournament) AS wins_report, 
		sum(t.points_by_tournament) AS points
	FROM 
		meta_winners AS mw 
	JOIN 
		tournaments AS t ON t.pk_tournament = mw.fk_tournament
	WHERE  
		mw.winner_name NOT IN ('Japan Flagships','Japan Flagship','SEA Flagships')
	GROUP BY 
		mw.winner_name 
	ORDER BY  
		points DESC LIMIT 25
;




-- SEC 2.2.4 TOP DECKS VIEW (FOR EVERY LEADER IN TOP10, FIVE DECKS FROM BEST PLAYERS, ORDER BY DATE ADDED)
DROP VIEW IF EXISTS top_decks_view;

CREATE VIEW top_decks_view AS 
(
	SELECT 
		vtl.pk_card, 
        vtl.colour_complete, 
        vtl.card_name, 
        wdd.fk_winner_deck, 
        wd.winner_name, 
        vtp.points, 
        wd.winner_date
	FROM 
		top_leaders AS vtl 
    JOIN 
		winner_deck_detail AS wdd ON vtl.pk_card = wdd.fk_card
	JOIN
		winner_decks AS wd ON wd.pk_winner_deck = wdd.fk_winner_deck
	LEFT JOIN 
		top_players AS vtp ON wd.winner_name = vtp.winner_name
	WHERE 
		vtl.pk_card = 
        (
			SELECT  
				pk_card 
            FROM top_leaders 
            WHERE  
				rank_number = 1
		) 
	ORDER BY 
		vtp.points DESC, 
        wd.winner_date DESC LIMIT 5
)

UNION

(
	SELECT 
		vtl.pk_card, 
        vtl.colour_complete, 
        vtl.card_name, 
        wdd.fk_winner_deck, 
        wd.winner_name, 
        vtp.points, 
        wd.winner_date
	FROM 
		top_leaders AS vtl 
	JOIN 
		winner_deck_detail AS wdd ON vtl.pk_card = wdd.fk_card
	JOIN 
		winner_decks AS wd ON wd.pk_winner_deck = wdd.fk_winner_deck
	LEFT JOIN 
		top_players AS vtp ON wd.winner_name = vtp.winner_name
	WHERE  	
		vtl.pk_card = 
        (
			SELECT 
				pk_card 
			FROM 
				top_leaders 
			WHERE 
				rank_number = 2
		) 
	ORDER BY 
		vtp.points DESC, 
        wd.winner_date DESC LIMIT 5
)
UNION

(
	SELECT 
		vtl.pk_card, 
		vtl.colour_complete, 
        vtl.card_name, 
        wdd.fk_winner_deck, 
        wd.winner_name, 
        vtp.points, 
        wd.winner_date
	FROM 
		top_leaders AS vtl 
    JOIN 
		winner_deck_detail AS wdd ON vtl.pk_card = wdd.fk_card
	JOIN 
		winner_decks AS  wd ON wd.pk_winner_deck = wdd.fk_winner_deck
	LEFT JOIN 
		top_players AS vtp ON  wd.winner_name = vtp.winner_name
	WHERE 
		vtl.pk_card = 
        (
			SELECT 
				pk_card 
			FROM 
				top_leaders 
			WHERE 
				rank_number = 3
		) 
	ORDER BY 
		vtp.points DESC, 
        wd.winner_date DESC LIMIT 5
)

UNION

(
	SELECT 
		vtl.pk_card, 
        vtl.colour_complete, 
        vtl.card_name, 
        wdd.fk_winner_deck, 
        wd.winner_name, 
        vtp.points, 
        wd.winner_date
	FROM 
		top_leaders AS vtl 
    JOIN 
		winner_deck_detail AS wdd ON vtl.pk_card = wdd.fk_card
	JOIN 
		winner_decks AS wd ON wd.pk_winner_deck = wdd.fk_winner_deck
	LEFT JOIN 
		top_players AS vtp ON wd.winner_name = vtp.winner_name
	WHERE 
		vtl.pk_card = 
        (
			SELECT 
				pk_card 
                FROM 
					top_leaders 
				WHERE 
					rank_number = 4
		) 
	ORDER BY 
		vtp.points DESC, 
        wd.winner_date DESC LIMIT 5
)

UNION

(
	SELECT 
		vtl.pk_card, 
        vtl.colour_complete, 
        vtl.card_name, 
        wdd.fk_winner_deck, 
        wd.winner_name, 
        vtp.points, 
        wd.winner_date
	FROM 
		top_leaders AS vtl 
    JOIN 
		winner_deck_detail AS wdd ON vtl.pk_card = wdd.fk_card
	JOIN 
		winner_decks AS wd ON wd.pk_winner_deck = wdd.fk_winner_deck
	LEFT JOIN 
		top_players AS vtp ON wd.winner_name = vtp.winner_name
	WHERE 
		vtl.pk_card = 
        (
			SELECT 
				pk_card 
			FROM 
				top_leaders 
			WHERE 
				rank_number = 5
		) 
	ORDER BY 
		vtp.points DESC, 
        wd.winner_date DESC LIMIT 5
)

UNION

(
	SELECT 
		vtl.pk_card, 
		vtl.colour_complete, 
        vtl.card_name, 
        wdd.fk_winner_deck, 
        wd.winner_name, 
        vtp.points, 
        wd.winner_date
	FROM 
		top_leaders AS vtl 
    JOIN 
		winner_deck_detail AS wdd ON vtl.pk_card = wdd.fk_card
	JOIN 
		winner_decks AS wd ON wd.pk_winner_deck = wdd.fk_winner_deck
	LEFT JOIN 
		top_players AS vtp ON wd.winner_name = vtp.winner_name
	WHERE 
		vtl.pk_card = 
        (
			SELECT 
				pk_card 
			FROM 
				top_leaders 
			WHERE 
				rank_number = 6
		) 
	ORDER BY 
		vtp.points DESC, 
        wd.winner_date DESC LIMIT 5
)

UNION

(
	SELECT 
		vtl.pk_card, 
        vtl.colour_complete, 
        vtl.card_name, 
        wdd.fk_winner_deck, 
        wd.winner_name, 
        vtp.points, 
        wd.winner_date
	FROM 
		top_leaders AS vtl 
    JOIN 
		winner_deck_detail AS wdd ON vtl.pk_card = wdd.fk_card
	JOIN 
		winner_decks AS wd ON wd.pk_winner_deck = wdd.fk_winner_deck
	LEFT JOIN 
		top_players AS vtp ON wd.winner_name = vtp.winner_name
	WHERE 
		vtl.pk_card = 
        (
			SELECT 
				pk_card 
			FROM 
				top_leaders 
			WHERE rank_number = 7
		) 
	ORDER BY 
		vtp.points DESC, 
        wd.winner_date DESC LIMIT 5
)

UNION

(
	SELECT 
		vtl.pk_card, 
		vtl.colour_complete, 
        vtl.card_name, 
        wdd.fk_winner_deck, 
        wd.winner_name, 
        vtp.points, 
        wd.winner_date
	FROM top_leaders AS vtl 
    JOIN 
		winner_deck_detail AS wdd ON vtl.pk_card = wdd.fk_card
	JOIN 
		winner_decks AS wd ON wd.pk_winner_deck = wdd.fk_winner_deck
	LEFT JOIN 
		top_players AS vtp ON wd.winner_name = vtp.winner_name
	WHERE 
		vtl.pk_card = 
        (
			SELECT 
				pk_card 
			FROM 
				top_leaders 
			WHERE 
				rank_number = 8
		) 
	ORDER BY 
		vtp.points DESC, 
        wd.winner_date DESC LIMIT 5
)

UNION

(
	SELECT 
		vtl.pk_card, 
        vtl.colour_complete, 
        vtl.card_name, 
        wdd.fk_winner_deck, 
        wd.winner_name, 
        vtp.points, 
        wd.winner_date
	FROM 
		top_leaders AS vtl 
    JOIN 
		winner_deck_detail AS wdd ON vtl.pk_card = wdd.fk_card
	JOIN 
		winner_decks AS wd ON wd.pk_winner_deck = wdd.fk_winner_deck
	LEFT JOIN 
		top_players AS vtp ON wd.winner_name = vtp.winner_name
	WHERE 
		vtl.pk_card = 
        (
			SELECT 
				pk_card 
			FROM 
				top_leaders 
			WHERE rank_number = 9
		) 
	ORDER BY 
		vtp.points DESC, 
        wd.winner_date DESC LIMIT 5
)

UNION

(
	SELECT 
		vtl.pk_card, 
        vtl.colour_complete, 
        vtl.card_name, 
        wdd.fk_winner_deck, 
        wd.winner_name, 
        vtp.points, 
        wd.winner_date
	FROM 
		top_leaders AS vtl 
    JOIN 
		winner_deck_detail AS wdd ON vtl.pk_card = wdd.fk_card
	JOIN 
		winner_decks AS wd ON wd.pk_winner_deck = wdd.fk_winner_deck
	LEFT JOIN 
		top_players AS vtp ON wd.winner_name = vtp.winner_name
	WHERE 
		vtl.pk_card = 
        (
			SELECT  
				pk_card 
			FROM 
            top_leaders 
            WHERE 
				rank_number = 10
		) 
	ORDER BY 
		vtp.points DESC, 
        wd.winner_date DESC LIMIT 5
);

-- SEC 2.2.5 CARD COLLECTION BY USER VIEW
CREATE VIEW collection_user_view
as
select cl.pk_card, cl.card_code,ct.card_type_name, cl.card_name,us.fk_user,us.fk_card,us.stock_amount,
-- Check if card is Leader, if it is then will need only one card instead of 4.
	if (ct.card_type_name = 'Leader',1,4) as 'Cards needed for playset', 

		if(if (ct.card_type_name = 'Leader',1,4)-us.stock_amount<0,0,
			if (ct.card_type_name = 'Leader',1,4)-us.stock_amount) as 'Remaining cards need',
				if(if (ct.card_type_name = 'Leader',1,4)-us.stock_amount<=0,'Complete','Missing cards') 
					as 'Collection Status'
from cardlist as cl 
left join user_stock as us on cl.pk_card = us.fk_card
left join card_type as ct on cl.fk_card_type = ct.pk_card_type 
where pk_card != 99999
order by fk_user
;



-- ============ DOCUMENTATION VIEWS ============
-- SEC 9.2 INFOTABLAS Y ESTRUCTURA BBDD
-- SEC 9.2.1 Guardar la siguiente consulta como una vista llamada INFOTABLAS a modo de 
-- documentación
CREATE VIEW infotablas AS
SELECT  
TABLE_NAME AS 'Tabla', 
COLUMN_NAME AS 'Campo', 
DATA_TYPE AS 'Tipo', 
CHARACTER_MAXIMUM_LENGTH AS 'Tamaño', 
COLUMN_KEY AS 'Claves', 
COLUMN_COMMENT AS 'Comentarios del campo' 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'mugiwarapp_local_test'; 

-- SEC 9.2.2 Crear una vista que, haciendo uso de consultas de UNION muestre el 
-- nombre y el número de registros de cada tabla. Darle como nombre a esta vista 
-- REGISTROSTABLAS. 

CREATE VIEW registrostablas AS 
SELECT 'backup_user_deck' AS tabla, COUNT(*) as registros from backup_user_deck
UNION 
SELECT 'backup_user_deck_detail' , COUNT(*) FROM backup_user_deck_detail
UNION 
SELECT 'card_attribute' , COUNT(*) FROM card_attribute
UNION 
SELECT 'card_colour' , COUNT(*) FROM card_colour
UNION 
SELECT 'card_legal_status' , COUNT(*) FROM card_legal_status
UNION 
SELECT 'card_rarity' , COUNT(*) FROM card_rarity
UNION 
SELECT 'card_rotation' , COUNT(*) FROM card_rotation
UNION 
SELECT 'card_type' , COUNT(*) FROM card_type
UNION 
SELECT 'card_typeb' , COUNT(*) FROM card_typeb
UNION 
SELECT 'cardlist' , COUNT(*) FROM cardlist
UNION 
SELECT 'format_game' , COUNT(*) FROM format_game
UNION 
SELECT 'meta_winners' , COUNT(*) FROM meta_winners
UNION 
SELECT 'tournaments' , COUNT(*) FROM tournaments
UNION 
SELECT 'user_deck' , COUNT(*) FROM user_deck
UNION 
SELECT 'user_deck_detail' , COUNT(*) FROM user_deck_detail
UNION 
SELECT 'user_stock' , COUNT(*) FROM user_stock
UNION 
SELECT 'user_table' , COUNT(*) FROM user_table
UNION 
SELECT 'user_types' , COUNT(*) FROM user_types
UNION 
SELECT 'winner_deck_detail' , COUNT(*) FROM winner_deck_detail
UNION 
SELECT 'winner_decks' , COUNT(*) FROM winner_decks
;

-- SEC 9.2.3 Guardar la siguiente consulta como una vista llamada ESTRUCTURABBDD a modo de
-- documentación 

create view estructurabbdd as
SELECT TABLE_NAME AS 'Objeto', TABLE_TYPE AS 'Tipo' 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'mugiwarapp_local_test'  
UNION 
SELECT EVENT_OBJECT_TABLE AS 'Tabla', TRIGGER_NAME AS 'Trigger'  
FROM information_schema.TRIGGERS  
WHERE TRIGGER_SCHEMA = 'mugiwarapp_local_test' 

UNION 
SELECT ROUTINE_NAME AS 'Objeto', ROUTINE_TYPE AS 'Tipo' 
FROM information_schema.ROUTINES  
WHERE ROUTINE_SCHEMA = 'mugiwarapp_local_test' 
;


