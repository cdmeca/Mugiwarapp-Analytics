USE mugiwarapp_local_test;

-- LOCAL DEMO ACCOUNTS ONLY. Replace every 'CHANGE_ME_*' password before running this file
-- on any server other than a throw-away local instance.
-- SEC 10 USERS AND ROLES
	-- SEC 10.1 SYSTEM_ADMIN_ROLES
		-- super_admin con derechos a todo.
		CREATE ROLE IF NOT EXISTS super_admin;
			GRANT ALL ON mugiwarapp_local_test.* TO super_admin;
	
		-- card_master con derechos de insert, read y update (no delete) para la sección de cartas.
		CREATE ROLE IF NOT EXISTS card_master;
			grant SELECT, INSERT, UPDATE ON mugiwarapp_local_test.card_attribute to card_master;
			grant SELECT, INSERT, UPDATE ON mugiwarapp_local_test.card_colour to card_master;
			grant SELECT, INSERT, UPDATE ON mugiwarapp_local_test.card_legal_status to card_master;
			grant SELECT, INSERT, UPDATE ON mugiwarapp_local_test.card_rarity to card_master;
			grant SELECT, INSERT, UPDATE ON mugiwarapp_local_test.card_rotation to card_master;
			grant SELECT, INSERT, UPDATE ON mugiwarapp_local_test.card_type to card_master;
			grant SELECT, INSERT, UPDATE ON mugiwarapp_local_test.card_typeb to card_master;
			grant SELECT, INSERT, UPDATE ON mugiwarapp_local_test.cardlist to card_master;
			
        
        -- meta_reporter con derechos de insert, read, update y delete para la seccion de 
        -- meta (tournaments, meta_winners, winner decks, etc.).
        CREATE ROLE IF NOT EXISTS meta_reporter; 
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.format_game to meta_reporter;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.meta_winners to meta_reporter;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.tournaments to meta_reporter;	
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.winner_deck_detail to meta_reporter;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.winner_decks to meta_reporter;
        
        
        -- analyst solo select en todas las secciones a excepcion de aquellas de contenido user
        -- (viva la RGDP).
        CREATE ROLE IF NOT EXISTS analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.card_attribute to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.card_colour to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.card_legal_status to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.card_rarity to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.card_rotation to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.card_type to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.card_typeb to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.cardlist to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.format_game to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.leader_list to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.meta_winners to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.top_decks_view to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.top_leaders to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.top_players to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.tournaments to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.user_deck to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.user_deck_detail to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.winner_deck_detail to analyst;
			grant SELECT, INSERT, UPDATE, DELETE ON mugiwarapp_local_test.winner_decks to analyst;
            
            -- SEC 10.2 CREATE USERS
            
			-- FIRST DROP IF THEY EXISTS
				DROP USER IF EXISTS 'Kcho'@'localhost'; 
				DROP USER IF EXISTS 'demo_admin2'@'localhost';
				DROP USER IF EXISTS 'demo_admin3'@'localhost';
				DROP USER IF EXISTS 'demo_meta'@'localhost';
				DROP USER IF EXISTS 'demo_analyst'@'localhost';
				DROP USER IF EXISTS 'demo_cards'@'localhost';
            -- NOW CREATE AGAIN    
		CREATE USER IF NOT EXISTS 'Kcho'@'localhost' IDENTIFIED BY 'CHANGE_ME_Kcho';
		CREATE USER IF NOT EXISTS 'demo_admin2'@'localhost' IDENTIFIED BY 'CHANGE_ME_demo_admin2';
		CREATE USER IF NOT EXISTS 'demo_admin3'@'localhost' IDENTIFIED BY 'CHANGE_ME_demo_admin3';
		CREATE USER IF NOT EXISTS 'demo_meta'@'localhost' IDENTIFIED BY 'CHANGE_ME_demo_meta';
		CREATE USER IF NOT EXISTS 'demo_analyst'@'localhost' IDENTIFIED BY 'CHANGE_ME_demo_analyst';
		CREATE USER IF NOT EXISTS 'demo_cards'@'localhost' IDENTIFIED BY 'CHANGE_ME_demo_cards';
        
			-- SEC 10.3 GRANT ROLES TO USERS
            
		GRANT super_admin TO 'Kcho'@'localhost';
		GRANT super_admin TO 'demo_admin2'@'localhost';
		GRANT super_admin TO 'demo_admin3'@'localhost';
		GRANT meta_reporter TO 'demo_meta'@'localhost';
		GRANT analyst TO 'demo_analyst'@'localhost';
		GRANT card_master TO 'demo_cards'@'localhost';
        






