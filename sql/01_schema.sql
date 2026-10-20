-- WARNING: this script DROPS the database `mugiwarapp_local_test` and rebuilds it from scratch.
-- USE THIS COMMANDS TO DELETE AND REBUILD THE DATABASE

drop database if exists mugiwarapp_local_test;
  create database mugiwarapp_local_test
    character set utf8mb4 collate utf8mb4_unicode_ci;
  use mugiwarapp_local_test;

-- SECTION 1 BASIC STRUCTURE ////////////////////////////////////////////////////////////////////////////////////////////
-- SEC 1.1 FORMAT GAME
CREATE TABLE 
  format_game (
    pk_format   INT PRIMARY KEY,
    format_name VARCHAR(45)
);

-- SEC 1.2 TOURNAMENTS
CREATE TABLE 
  tournaments (
    pk_tournament         INT PRIMARY KEY,
    name_tournament       VARCHAR(45),
    points_by_tournament  INT
);

-- SEC 1.3 USER TYPES (USER, ADMIN, ETC)
CREATE TABLE 
  user_types (
    pk_user_type    INT PRIMARY KEY,
    user_type_name  VARCHAR (45) NOT NULL
);

-- SEC 1.4 CARD RARITY
CREATE TABLE 
  card_rarity (
    pk_rarity   INT PRIMARY KEY,
    rarity_name VARCHAR (45) NOT NULL
);

-- SEC 1.1.5 CARD TYPES
CREATE TABLE 
  card_type (
    pk_card_type    INT PRIMARY KEY,
    card_type_name  VARCHAR (45) NOT NULL
);

-- SEC 1.1.6 CARD COLOUR
CREATE TABLE 
  card_colour (
    pk_colour INT PRIMARY KEY,
    colour1   VARCHAR (45) NOT NULL,
    colour2   VARCHAR (45) NOT NULL
);

ALTER TABLE card_colour
ADD COLUMN colour_complete varchar (93)
 generated always as (concat(colour1,"/",colour2)) STORED
;

-- SEC 1.1.7 CARD ATTRIBUTE
CREATE TABLE 
  card_attribute(
    pk_attribute    INT PRIMARY KEY,
    attribute_name  VARCHAR (45) NOT NULL
);



-- SEC 1.1.8 TYPEB (relates with tag types inside the card: Strawhats, Supernovas, etc...)
CREATE TABLE 
  card_typeb(
    pk_typeb    INT PRIMARY KEY,
    type2_name  VARCHAR (45) NOT NULL
);

-- SEC 1.1.9 CARD ROTATION
CREATE TABLE 
  card_rotation (
    pk_rotation         INT PRIMARY KEY,
    card_rotation_name  VARCHAR (45) NOT NULL,
    rotation_final_day  date
);

-- SEC 1.10 CARD LEGAL STATUS
CREATE TABLE 
  card_legal_status (
    pk_status   INT PRIMARY KEY,
    status_name VARCHAR (45)
);

-- SEC 1.11 CARD LIST TABLE WITH FOREIGN KEYS
CREATE TABLE 
  cardlist (
    pk_card       INT primary key,
-- Card code
    card_code     VARCHAR (50) UNIQUE NOT NULL,
    fk_color      INT NOT NULL,
    card_name     VARCHAR (100) NOT NULL,
    fk_card_type  INT NOT NULL,
    counter       ENUM('0','1000','2000') NOT NULL,
    cost          DECIMAL (2,0) NOT NULL,
    power         DECIMAL (5,0),
    fk_attribute  INT ,
    fk_typeb1     INT NOT NULL,
    fk_typeb2     INT ,
    fk_typeb3     INT ,
    fk_legal_status INT NOT NULL,
    fk_rarity     INT NOT NULL,
  fk_rotation     INT NOT NULL,
  leader_life     INT
);

ALTER TABLE cardlist  
ADD CONSTRAINT fk_colour
        FOREIGN KEY (fk_color) 
			REFERENCES card_colour(pk_colour)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

ALTER TABLE cardlist
ADD CONSTRAINT fk_card_type
        FOREIGN KEY (fk_card_type) 
			REFERENCES card_type(pk_card_type)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

ALTER TABLE cardlist
	ADD CONSTRAINT fk_attribute
        FOREIGN KEY (fk_attribute) 
			REFERENCES card_attribute(pk_attribute)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

ALTER TABLE cardlist
	ADD CONSTRAINT fk_typeB1
		FOREIGN KEY (fk_typeb1) 
			REFERENCES card_typeb(pk_typeb)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT 
;

ALTER TABLE cardlist
	ADD CONSTRAINT fk_typeB2
		FOREIGN KEY (fk_typeb2) 
			REFERENCES card_typeb(pk_typeb)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

ALTER TABLE cardlist
	ADD CONSTRAINT fk_typeB3
		FOREIGN KEY (fk_typeb3) 
			REFERENCES card_typeb(pk_typeb)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

ALTER TABLE cardlist
	ADD CONSTRAINT fk_legal_status
		FOREIGN KEY (fk_legal_status) 
			REFERENCES card_legal_status(pk_status)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

ALTER TABLE cardlist
	ADD CONSTRAINT fk_rarity
		FOREIGN KEY (fk_rarity) 
			REFERENCES card_rarity(pk_rarity)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT 
;

ALTER TABLE cardlist
	ADD CONSTRAINT fk_rotation
		FOREIGN KEY (fk_rotation) 
			REFERENCES card_rotation(pk_rotation)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

ALTER TABLE cardlist 
  ADD COLUMN full_type VARCHAR (150)
  GENERATED ALWAYS AS (CONCAT_WS('/', fk_typeb1, fk_typeb2, fk_typeb3))
  VIRTUAL
;

-- SEC 1.12 USER TABLE
CREATE TABLE user_table (
  pk_user 		INT PRIMARY KEY AUTO_INCREMENT,
  user_name 	VARCHAR (45) NOT NULL,
  user_surname1 VARCHAR (45) NOT NULL,
  user_surname2 VARCHAR (45),
  nickname 		VARCHAR (45) UNIQUE NOT NULL,
  user_email 	VARCHAR (90) UNIQUE NOT NULL,
  User_password VARCHAR (255) NOT NULL,
  reg_date_time Datetime NOT NULL,
  fk_user_type 	INT NOT NULL
);

ALTER TABLE user_table 
	ADD CONSTRAINT user_table_type
		FOREIGN KEY (fk_user_type) 
			REFERENCES user_types(pk_user_type)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

ALTER TABLE user_table
	ADD CONSTRAINT email_validator
		CHECK (
		INSTR(user_email, '@') > 1 AND
		INSTR(user_email, '.') > INSTR(user_email, '@') + 1
);

-- SEC 1.13 META WINNERS (DECKS REPORTED AS WINNERS IN ASIAN COMPETITION
CREATE TABLE meta_winners (
  pk_champion 	INT PRIMARY KEY,
  fk_tournament INT NOT NULL,
  winner_name 	VARCHAR (45),
  winner_date 	date,
-- we put the leader here because usually we don´t have the full deck, 
-- but only the leader.
  fk_card 		INT
);

ALTER TABLE meta_winners 
	ADD CONSTRAINT fk_winner_tournament_meta_winners
		FOREIGN KEY (fk_tournament) 
			REFERENCES tournaments(pk_tournament)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

ALTER TABLE meta_winners 
	ADD CONSTRAINT fk_leader_card
		FOREIGN KEY (fk_card) 
			REFERENCES cardlist(pk_card)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

-- SEC 1.14 WINNER DECKS (DETAILED DECKS REPORTED THAT WON ANY TOURNAMENT)
CREATE TABLE winner_decks (
  pk_winner_deck 	INT PRIMARY KEY,
  fk_format 		INT NOT NULL,
  winner_date 		DATE,
  fk_tournament 	INT NOT NULL,
-- Asian winner names can include kanji and emoji, and the player is sometimes unknown,
-- so this column is left nullable. (Requires utf8mb4, set on the database below.)
  winner_name 		VARCHAR (45)
);

ALTER TABLE winner_decks
	ADD CONSTRAINT fk_winner_tournament_winner_decks
		FOREIGN KEY (fk_tournament) 
			REFERENCES tournaments(pk_tournament)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

ALTER TABLE winner_decks
	ADD CONSTRAINT fk_winner_format
		FOREIGN KEY (fk_format) 
			REFERENCES format_game(pk_format)
			ON UPDATE CASCADE 
			ON DELETE RESTRICT
;

-- SEC 1.15 USER STOCK (TABLE WHERE USERS WILL ADD/EDIT HIS PERSONAL COLLECTION OF CARDS)
CREATE TABLE user_stock (
	fk_user 		INT,
	fk_card 		INT,
	stock_amount 	INT,
	PRIMARY KEY (fk_user, fk_card),
	FOREIGN KEY (fk_user) 
		REFERENCES user_table(pk_user)
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	FOREIGN KEY (fk_card) 
		REFERENCES cardlist(pk_card)
		ON DELETE CASCADE 
		ON UPDATE CASCADE
);

-- SEC 1.16 USER DECK (TO SAVE THE DECKS 
CREATE TABLE user_deck (
	pk_user_deck 	INT PRIMARY KEY,
	fk_user 		INT NOT NULL,
	deck_name 		VARCHAR(45) NOT NULL,
	fk_leader_card 	INT NOT NULL,
	creation_date 	DATETIME,
	FOREIGN KEY (fk_user) 
		REFERENCES user_table(pk_user)
		ON DELETE CASCADE 
        ON UPDATE CASCADE,
	FOREIGN KEY (fk_leader_card) 
		REFERENCES cardlist(pk_card)
		ON DELETE RESTRICT 
        ON UPDATE CASCADE
);

-- SEC 1.17 USER DECK DETAIL (DETAILLED TABLE FOR DECKS)
CREATE TABLE user_deck_detail (
	fk_user_deck 	INT,
	fk_card 		INT,
	deck_amount 	DECIMAL (3,0),
	PRIMARY KEY (fk_user_deck, fk_card),
		FOREIGN KEY (fk_user_deck) 
			REFERENCES user_deck(pk_user_deck)
			ON DELETE RESTRICT 
			ON UPDATE CASCADE,
		FOREIGN KEY (fk_card) 
			REFERENCES cardlist(pk_card)
			ON DELETE RESTRICT 
			ON UPDATE CASCADE
);

-- SEC 1.18 WINNER DECK DETAIL (SAME AS USER DECKS, BUT FOR WINNERS)
CREATE TABLE winner_deck_detail (
	fk_winner_deck 	INT,
	fk_card 		INT,
	amount 			INT NOT NULL,
	PRIMARY KEY (fk_winner_deck, fk_card),
	FOREIGN KEY (fk_winner_deck) 
		REFERENCES winner_decks(pk_winner_deck)
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	FOREIGN KEY (fk_card) 
		REFERENCES cardlist(pk_card)
		ON DELETE RESTRICT 
        ON UPDATE CASCADE
);



-- SECTION 2 BACKUPS, TRIGGERS, VIEWS, CONSULTS///////////////////////////////////////////////////////////////////////////

-- SEC 2.1 BACKUP TABLES 

-- drop table if exists backup_user_deck;
-- drop table if exists backup_user_deck_detail;

-- SEC 2.1.1 BACKUP USER DECK
CREATE TABLE backup_user_deck (
	pk_user_deck 	INT,
	fk_user 		INT NOT NULL,
	deck_name 		VARCHAR(45) NOT NULL,
	fk_leader_card 	INT NOT NULL,
	backup_time 	DATETIME,
	PRIMARY KEY ( pk_user_deck, backup_time),
	FOREIGN KEY (fk_user) 
		REFERENCES user_table(pk_user)
		ON DELETE CASCADE 
        ON UPDATE CASCADE,
	FOREIGN KEY (fk_leader_card) 
		REFERENCES cardlist(pk_card)
		ON DELETE RESTRICT 
        ON UPDATE CASCADE
);

-- SEC 2.1.2 BACKUP USER DECK DETAILS
CREATE TABLE backup_user_deck_detail (
	fk_user_deck 	INT,
	fk_card 		INT,
	deck_amount 	DECIMAL (3,0),
	backup_time 	DATETIME,
	PRIMARY KEY (fk_user_deck, fk_card, backup_time),
	FOREIGN KEY (fk_user_deck) 
		REFERENCES user_deck(pk_user_deck)
		ON DELETE RESTRICT 
        ON UPDATE CASCADE,
	FOREIGN KEY (fk_card) 
		REFERENCES cardlist(pk_card)
		ON DELETE RESTRICT 
        ON UPDATE CASCADE
);

