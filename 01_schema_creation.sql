-- =============================================================================
-- Mugiwarapp Analytics | 01 · Esquema (tablas, claves y restricciones)
-- Orden de ejecución: 01 -> 02 -> 03 -> 04 -> 05 -> 06 (07 opcional, consultas)
--
-- Requisitos: MySQL 8.0+ / MariaDB 10.5+ (columnas generadas y ventanas).
-- Este script NO borra ninguna base de datos. Si quieres reconstruirla desde cero,
-- hazlo a mano antes de ejecutarlo:   DROP DATABASE IF EXISTS mugiwarapp;
-- =============================================================================

CREATE DATABASE IF NOT EXISTS mugiwarapp
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE mugiwarapp;

-- -----------------------------------------------------------------------------
-- 1. Tablas de catálogo (dimensiones)
-- -----------------------------------------------------------------------------
CREATE TABLE format_game (
    pk_format   INT PRIMARY KEY,
    format_name VARCHAR(45)
);

CREATE TABLE tournaments (
    pk_tournament        INT PRIMARY KEY,
    name_tournament      VARCHAR(45),
    points_by_tournament INT
);

CREATE TABLE user_types (
    pk_user_type   INT PRIMARY KEY,
    user_type_name VARCHAR(45) NOT NULL
);

CREATE TABLE card_rarity (
    pk_rarity   INT PRIMARY KEY,
    rarity_name VARCHAR(45) NOT NULL
);

CREATE TABLE card_type (
    pk_card_type   INT PRIMARY KEY,
    card_type_name VARCHAR(45) NOT NULL
);

CREATE TABLE card_colour (
    pk_colour INT PRIMARY KEY,
    colour1   VARCHAR(45) NOT NULL,
    colour2   VARCHAR(45) NOT NULL,
    colour_complete VARCHAR(93)
        GENERATED ALWAYS AS (CONCAT(colour1, '/', colour2)) STORED
);

CREATE TABLE card_attribute (
    pk_attribute   INT PRIMARY KEY,
    attribute_name VARCHAR(45) NOT NULL
);

CREATE TABLE card_typeb (
    pk_typeb   INT PRIMARY KEY,
    type2_name VARCHAR(45) NOT NULL
);

CREATE TABLE card_rotation (
    pk_rotation        INT PRIMARY KEY,
    card_rotation_name VARCHAR(45) NOT NULL,
    rotation_final_day DATE
);

CREATE TABLE card_legal_status (
    pk_status   INT PRIMARY KEY,
    status_name VARCHAR(45)
);

-- -----------------------------------------------------------------------------
-- 2. Catálogo de cartas
--    (la columna full_type del borrador anterior se ha eliminado: concatenaba IDs
--     y devolvía NULL en casi todas las cartas)
-- -----------------------------------------------------------------------------
CREATE TABLE cardlist (
    pk_card        INT PRIMARY KEY,
    card_code      VARCHAR(50) UNIQUE NOT NULL,
    fk_color       INT NOT NULL,
    card_name      VARCHAR(100) NOT NULL,
    fk_card_type   INT NOT NULL,
    counter        ENUM('0','1000','2000') NOT NULL,
    cost           DECIMAL(2,0) NOT NULL,
    power          DECIMAL(5,0),
    fk_attribute   INT,
    fk_typeb1      INT NOT NULL,
    fk_typeb2      INT,
    fk_typeb3      INT,
    fk_legal_status INT NOT NULL,
    fk_rarity      INT NOT NULL,
    fk_rotation    INT NOT NULL,
    leader_life    INT,
    CONSTRAINT fk_colour       FOREIGN KEY (fk_color)        REFERENCES card_colour(pk_colour)       ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_card_type    FOREIGN KEY (fk_card_type)    REFERENCES card_type(pk_card_type)      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_attribute    FOREIGN KEY (fk_attribute)    REFERENCES card_attribute(pk_attribute) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_typeb1       FOREIGN KEY (fk_typeb1)       REFERENCES card_typeb(pk_typeb)         ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_typeb2       FOREIGN KEY (fk_typeb2)       REFERENCES card_typeb(pk_typeb)         ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_typeb3       FOREIGN KEY (fk_typeb3)       REFERENCES card_typeb(pk_typeb)         ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_legal_status FOREIGN KEY (fk_legal_status) REFERENCES card_legal_status(pk_status) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_rarity       FOREIGN KEY (fk_rarity)       REFERENCES card_rarity(pk_rarity)       ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_rotation     FOREIGN KEY (fk_rotation)     REFERENCES card_rotation(pk_rotation)   ON UPDATE CASCADE ON DELETE RESTRICT
);

-- -----------------------------------------------------------------------------
-- 3. Usuarios (datos transaccionales; en el repo solo hay datos ANONIMIZADOS)
--    La contraseña debe guardarse como hash (p. ej. bcrypt/argon2 desde la app),
--    nunca en texto plano.
-- -----------------------------------------------------------------------------
CREATE TABLE user_table (
    pk_user       INT PRIMARY KEY AUTO_INCREMENT,
    user_name     VARCHAR(45) NOT NULL,
    user_surname1 VARCHAR(45) NOT NULL,
    user_surname2 VARCHAR(45),
    nickname      VARCHAR(45) UNIQUE NOT NULL,
    user_email    VARCHAR(90) UNIQUE NOT NULL,
    user_password VARCHAR(255) NOT NULL,        -- hash, nunca texto plano
    reg_date_time DATETIME NOT NULL,
    fk_user_type  INT NOT NULL,
    CONSTRAINT user_table_type FOREIGN KEY (fk_user_type) REFERENCES user_types(pk_user_type)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    -- Antes: INSTR(...,'.') > INSTR(...,'@')+1 rechazaba "nombre.apellido@dominio.com".
    CONSTRAINT email_validator CHECK (user_email LIKE '_%@_%._%')
);

CREATE TABLE user_stock (
    fk_user      INT,
    fk_card      INT,
    stock_amount INT,
    PRIMARY KEY (fk_user, fk_card),
    CONSTRAINT fk_stock_user FOREIGN KEY (fk_user) REFERENCES user_table(pk_user)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_stock_card FOREIGN KEY (fk_card) REFERENCES cardlist(pk_card)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE user_deck (
    pk_user_deck    INT PRIMARY KEY,
    fk_user         INT NOT NULL,
    deck_name       VARCHAR(45) NOT NULL,
    fk_leader_card  INT NOT NULL,
    creation_date   DATETIME,
    CONSTRAINT fk_deck_user   FOREIGN KEY (fk_user)        REFERENCES user_table(pk_user)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_deck_leader FOREIGN KEY (fk_leader_card) REFERENCES cardlist(pk_card)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE user_deck_detail (
    fk_user_deck INT,
    fk_card      INT,
    deck_amount  DECIMAL(3,0),
    PRIMARY KEY (fk_user_deck, fk_card),
    CONSTRAINT fk_udd_deck FOREIGN KEY (fk_user_deck) REFERENCES user_deck(pk_user_deck)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_udd_card FOREIGN KEY (fk_card)      REFERENCES cardlist(pk_card)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- -----------------------------------------------------------------------------
-- 4. Datos de metajuego (torneos asiáticos)
--    Los nombres pueden contener kanji y emojis: por eso la base es utf8mb4.
-- -----------------------------------------------------------------------------
CREATE TABLE meta_winners (
    pk_champion   INT PRIMARY KEY,
    fk_tournament INT NOT NULL,
    winner_name   VARCHAR(100),
    winner_date   DATE,
    fk_card       INT,                          -- líder del mazo ganador
    CONSTRAINT fk_winner_tournament_meta FOREIGN KEY (fk_tournament) REFERENCES tournaments(pk_tournament)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_leader_card_meta       FOREIGN KEY (fk_card)       REFERENCES cardlist(pk_card)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE winner_decks (
    pk_winner_deck INT PRIMARY KEY,
    fk_format      INT NOT NULL,
    winner_date    DATE,
    fk_tournament  INT NOT NULL,
    winner_name    VARCHAR(100),                -- opcional (antes el comentario decía NOT NULL)
    CONSTRAINT fk_winner_tournament_decks FOREIGN KEY (fk_tournament) REFERENCES tournaments(pk_tournament)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_winner_format           FOREIGN KEY (fk_format)     REFERENCES format_game(pk_format)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE winner_deck_detail (
    fk_winner_deck INT,
    fk_card        INT,
    amount         INT NOT NULL,
    PRIMARY KEY (fk_winner_deck, fk_card),
    CONSTRAINT fk_wdd_deck FOREIGN KEY (fk_winner_deck) REFERENCES winner_decks(pk_winner_deck)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_wdd_card FOREIGN KEY (fk_card)        REFERENCES cardlist(pk_card)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- -----------------------------------------------------------------------------
-- 5. Histórico de mazos (lo rellenan los triggers de 04_triggers.sql)
--    Antes: backup_user_deck_detail referenciaba user_deck (tabla viva) con
--    ON DELETE RESTRICT, lo que impedía borrar un mazo durante 32 días.
--    Ahora el histórico es independiente y se limpia con backup_maintenance.
--    backup_time usa precisión de microsegundos para evitar colisiones de PK.
-- -----------------------------------------------------------------------------
CREATE TABLE backup_user_deck (
    pk_user_deck   INT,
    fk_user        INT NOT NULL,
    deck_name      VARCHAR(45) NOT NULL,
    fk_leader_card INT NOT NULL,
    backup_time    DATETIME(6),
    PRIMARY KEY (pk_user_deck, backup_time),
    CONSTRAINT fk_bud_user   FOREIGN KEY (fk_user)        REFERENCES user_table(pk_user)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bud_leader FOREIGN KEY (fk_leader_card) REFERENCES cardlist(pk_card)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE backup_user_deck_detail (
    fk_user_deck INT,
    fk_card      INT,
    deck_amount  DECIMAL(3,0),
    backup_time  DATETIME(6),
    PRIMARY KEY (fk_user_deck, fk_card, backup_time),
    CONSTRAINT fk_budd_card FOREIGN KEY (fk_card) REFERENCES cardlist(pk_card)
        ON DELETE RESTRICT ON UPDATE CASCADE
);
