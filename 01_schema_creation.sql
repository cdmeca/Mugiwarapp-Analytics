-- mugiwarapp structured query
-- USE THIS COMMANDS TO DELETE AND REBUILD THE DATABASE

drop database if exists mugiwarapp_local_test;
create database mugiwarapp_local_test;
use mugiwarapp_local_test;

-- SECTION 1 BASIC STRUCTURE ////////////////////////////////////////////////////////////////////////////////////////////
CREATE TABLE format_game (
pk_format INT PRIMARY KEY,
format_name VARCHAR(45)
);

CREATE TABLE tournaments (
pk_tournament INT PRIMARY KEY,
name_tournament VARCHAR(45),
points_by_tournament INT
);

create table user_types (
pk_user_type INT PRIMARY KEY,
user_type_name VARCHAR (45) NOT NULL);


create table card_rarity (
pk_rarity INT PRIMARY KEY,
rarity_name VARCHAR (45) NOT NULL
);

create table card_type (
pk_card_type INT PRIMARY KEY,
card_type_name VARCHAR (45) NOT NULL
);


create table card_colour (
pk_colour INT PRIMARY KEY,
colour1 VARCHAR (45) NOT NULL,
colour2 VARCHAR (45) NOT NULL
);
alter table card_colour
add column colour_complete varchar (93)
generated always as (concat(colour1,"/",colour2)) STORED;


create table card_attribute(
pk_attribute INT PRIMARY KEY,
attribute_name VARCHAR (45) NOT NULL
);


create table card_typeb(
pk_typeb INT PRIMARY KEY,
type2_name VARCHAR (45) NOT NULL
);

create table card_rotation (
pk_rotation INT PRIMARY KEY,
card_rotation_name VARCHAR (45)
);

create table card_legal_status (
pk_status INT PRIMARY KEY,
status_name VARCHAR (45)
);

create table cardlist (
pk_card INT primary key,
-- Card code
card_code VARCHAR (50) UNIQUE NOT NULL,
fk_color INT NOT NULL,
card_name VARCHAR (100) NOT NULL,
fk_card_type INT NOT NULL,
counter ENUM('0','1000','2000') NOT NULL,
cost DECIMAL (2,0) NOT NULL,
power DECIMAL (5,0),
fk_attribute INT ,
fk_typeb1 INT NOT NULL,
fk_typeb2 INT ,
fk_typeb3 INT ,
fk_legal_status INT NOT NULL,
fk_rarity INT NOT NULL,
fk_rotation INT NOT NULL,
leader_life INT
);

ALTER TABLE cardlist
ADD CONSTRAINT fk_colour
FOREIGN KEY (fk_color) REFERENCES card_colour(pk_colour)
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE cardlist
ADD CONSTRAINT fk_card_type
FOREIGN KEY (fk_card_type) REFERENCES card_type(pk_card_type)
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE cardlist
ADD CONSTRAINT fk_attribute
FOREIGN KEY (fk_attribute) REFERENCES card_attribute(pk_attribute)
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE cardlist
ADD CONSTRAINT fk_typeB1
FOREIGN KEY (fk_typeb1) REFERENCES card_typeb(pk_typeb)
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE cardlist
ADD CONSTRAINT fk_typeB2
FOREIGN KEY (fk_typeb2) REFERENCES card_typeb(pk_typeb)
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE cardlist
ADD CONSTRAINT fk_typeB3
FOREIGN KEY (fk_typeb3) REFERENCES card_typeb(pk_typeb)
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE cardlist
ADD CONSTRAINT fk_legal_status
FOREIGN KEY (fk_legal_status) REFERENCES card_legal_status(pk_status)
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE cardlist
ADD CONSTRAINT fk_rarity
FOREIGN KEY (fk_rarity) REFERENCES card_rarity(pk_rarity)
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE cardlist
ADD CONSTRAINT fk_rotation
FOREIGN KEY (fk_rotation) REFERENCES card_rotation(pk_rotation)
ON UPDATE CASCADE ON DELETE RESTRICT;

alter table cardlist 
add column full_type VARCHAR (150)
GENERATED ALWAYS AS (CONCAT(fk_typeb1,"/",fk_typeb2,"/",fk_typeb3))
VIRTUAL;


create table user_table (
pk_user INT PRIMARY KEY,
user_name VARCHAR (45) NOT NULL,
user_surname1 VARCHAR (45) NOT NULL,
user_surname2 VARCHAR (45),
nickname VARCHAR (45) UNIQUE NOT NULL,
user_email VARCHAR (90) UNIQUE NOT NULL,
User_password VARCHAR (255) NOT NULL,
reg_date_time Datetime NOT NULL,
fk_user_type INT NOT NULL
);

ALTER TABLE user_table 
ADD CONSTRAINT user_table_type
FOREIGN KEY (fk_user_type) REFERENCES user_types(pk_user_type)
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE user_table
ADD CONSTRAINT email_validator
CHECK (
    INSTR(user_email, '@') > 1 AND
    INSTR(user_email, '.') > INSTR(user_email, '@') + 1
);

create table meta_winners (
pk_champion INT PRIMARY KEY,
fk_tournament INT NOT NULL,
winner_name VARCHAR (45),
-- we put the leader here because usually we don´t have the full deck, 
-- but only the leader.
fk_card INT
);

ALTER TABLE meta_winners 
ADD CONSTRAINT fk_winner_tournament_meta_winners
FOREIGN KEY (fk_tournament) REFERENCES tournaments(pk_tournament)
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE meta_winners 
ADD CONSTRAINT fk_leader_card
FOREIGN KEY (fk_card) REFERENCES cardlist(pk_card)
ON UPDATE CASCADE ON DELETE RESTRICT;

create TABLE winner_decks (
pk_winner_deck INT PRIMARY KEY,
fk_format INT NOT NULL,
winner_date DATE,
fk_tournament INT NOT NULL,
-- Because asian winners can include Kanjis and emojis, we will 
-- left following column as NOT NULL. 
winner_name VARCHAR (45)
);

ALTER TABLE winner_decks
ADD CONSTRAINT fk_winner_tournament_winner_decks
FOREIGN KEY (fk_tournament) REFERENCES tournaments(pk_tournament)
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE winner_decks
ADD CONSTRAINT fk_winner_format
FOREIGN KEY (fk_format) REFERENCES format_game(pk_format)
ON UPDATE CASCADE ON DELETE RESTRICT;


CREATE TABLE user_stock (
fk_user INT,
fk_card INT,
stock_amount INT,
PRIMARY KEY (fk_user, fk_card),
FOREIGN KEY (fk_user) REFERENCES user_table(pk_user)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (fk_card) REFERENCES cardlist(pk_card)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE user_deck (
pk_user_deck INT PRIMARY KEY,
fk_user INT NOT NULL,
deck_name VARCHAR(45) NOT NULL,
fk_leader_card INT NOT NULL,
creation_date datetime,
FOREIGN KEY (fk_user) REFERENCES user_table(pk_user)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (fk_leader_card) REFERENCES cardlist(pk_card)
ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE user_deck_detail (
  fk_user_deck INT,
  fk_card INT,
  deck_amount decimal (3,0),
  PRIMARY KEY (fk_user_deck, fk_card),
  FOREIGN KEY (fk_user_deck) REFERENCES user_deck(pk_user_deck)
  ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (fk_card) REFERENCES cardlist(pk_card)
  ON DELETE RESTRICT ON UPDATE CASCADE
);


CREATE TABLE winner_deck_detail (
fk_winner_deck INT,
fk_card INT,
amount INT NOT NULL,
PRIMARY KEY (fk_winner_deck, fk_card),
FOREIGN KEY (fk_winner_deck) REFERENCES winner_decks(pk_winner_deck)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (fk_card) REFERENCES cardlist(pk_card)
ON DELETE RESTRICT ON UPDATE CASCADE);


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