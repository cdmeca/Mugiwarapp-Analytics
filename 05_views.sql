-- =============================================================================
-- Mugiwarapp Analytics | 05 · Vistas analíticas y de documentación
-- =============================================================================
USE mugiwarapp;

-- -----------------------------------------------------------------------------
-- Líderes con su color (base para el resto de vistas)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW leader_list AS
SELECT c.pk_card,
       c.card_name,
       col.colour1,
       col.colour2,
       col.colour_complete
FROM cardlist c
JOIN card_colour col ON col.pk_colour = c.fk_color
JOIN card_type t     ON t.pk_card_type = c.fk_card_type
WHERE t.card_type_name = 'Leader';

-- -----------------------------------------------------------------------------
-- Top 10 líderes por puntos de torneo.
-- Corrección: antes se calculaba SUM(fk_tournament * points), es decir, el ID
-- del torneo multiplicado por sus puntos. Ahora: cada victoria aporta los puntos
-- de su torneo, y wins_report cuenta las victorias.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW top_leaders AS
SELECT
    ROW_NUMBER() OVER (ORDER BY SUM(t.points_by_tournament) DESC) AS rank_number,
    cl.pk_card,
    cl.card_code,
    ll.colour_complete,
    cl.card_name,
    COUNT(*)                         AS wins_report,
    SUM(t.points_by_tournament)      AS points
FROM meta_winners mw
JOIN cardlist cl     ON cl.pk_card = mw.fk_card
JOIN tournaments t   ON t.pk_tournament = mw.fk_tournament
JOIN leader_list ll  ON ll.pk_card = mw.fk_card
GROUP BY cl.pk_card, cl.card_code, ll.colour_complete, cl.card_name
ORDER BY points DESC
LIMIT 10;

-- -----------------------------------------------------------------------------
-- Jugadores con más puntos (sin equipos genéricos)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW top_players AS
SELECT mw.winner_name,
       COUNT(*)                    AS wins_report,
       SUM(t.points_by_tournament) AS points
FROM meta_winners mw
JOIN tournaments t ON t.pk_tournament = mw.fk_tournament
WHERE mw.winner_name NOT IN ('Japan Flagships', 'Japan Flagship', 'SEA Flagships')
GROUP BY mw.winner_name
ORDER BY points DESC
LIMIT 25;

-- -----------------------------------------------------------------------------
-- Mazos ganadores de cada uno de los 10 líderes principales (hasta 5 por líder).
-- Reescrita con ventana: misma salida que las 10 consultas UNION del original.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW top_decks_view AS
SELECT rank_number, pk_card, colour_complete, card_name,
       fk_winner_deck, winner_name, points, winner_date
FROM (
    SELECT vtl.rank_number,
           vtl.pk_card,
           vtl.colour_complete,
           vtl.card_name,
           wdd.fk_winner_deck,
           wd.winner_name,
           vtp.points,
           wd.winner_date,
           ROW_NUMBER() OVER (PARTITION BY vtl.pk_card
                              ORDER BY vtp.points DESC, wd.winner_date DESC) AS rn
    FROM top_leaders vtl
    JOIN winner_deck_detail wdd ON wdd.fk_card = vtl.pk_card
    JOIN winner_decks wd        ON wd.pk_winner_deck = wdd.fk_winner_deck
    LEFT JOIN top_players vtp   ON vtp.winner_name = wd.winner_name
) x
WHERE rn <= 5;

-- -----------------------------------------------------------------------------
-- Colección por usuario (cartas poseídas frente a playset necesario)
-- Se excluye la carta marcadora 99999 (carta desconocida).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW collection_user_view AS
SELECT cl.pk_card,
       cl.card_code,
       ct.card_type_name,
       cl.card_name,
       us.fk_user,
       us.fk_card,
       us.stock_amount,
       IF(ct.card_type_name = 'Leader', 1, 4)                         AS `Cards needed for playset`,
       GREATEST(IF(ct.card_type_name = 'Leader', 1, 4) - us.stock_amount, 0) AS `Remaining cards need`,
       IF(us.stock_amount >= IF(ct.card_type_name = 'Leader', 1, 4), 'Complete', 'Missing cards') AS `Collection Status`
FROM cardlist cl
LEFT JOIN user_stock us ON us.fk_card = cl.pk_card
LEFT JOIN card_type ct  ON ct.pk_card_type = cl.fk_card_type
WHERE cl.pk_card <> 99999;

-- -----------------------------------------------------------------------------
-- Documentación de la propia base de datos
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW INFOTABLAS AS
SELECT TABLE_NAME       AS `Tabla`,
       COLUMN_NAME      AS `Campo`,
       DATA_TYPE        AS `Tipo`,
       CHARACTER_MAXIMUM_LENGTH AS `Tamaño`,
       COLUMN_KEY       AS `Claves`,
       COLUMN_COMMENT   AS `Comentarios del campo`
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE();

CREATE OR REPLACE VIEW REGISTROSTABLAS AS
SELECT 'backup_user_deck' AS tabla, COUNT(*) AS registros FROM backup_user_deck
UNION SELECT 'backup_user_deck_detail', COUNT(*) FROM backup_user_deck_detail
UNION SELECT 'card_attribute',          COUNT(*) FROM card_attribute
UNION SELECT 'card_colour',             COUNT(*) FROM card_colour
UNION SELECT 'card_legal_status',       COUNT(*) FROM card_legal_status
UNION SELECT 'card_rarity',             COUNT(*) FROM card_rarity
UNION SELECT 'card_rotation',           COUNT(*) FROM card_rotation
UNION SELECT 'card_type',               COUNT(*) FROM card_type
UNION SELECT 'card_typeb',              COUNT(*) FROM card_typeb
UNION SELECT 'cardlist',                COUNT(*) FROM cardlist
UNION SELECT 'format_game',             COUNT(*) FROM format_game
UNION SELECT 'meta_winners',            COUNT(*) FROM meta_winners
UNION SELECT 'tournaments',             COUNT(*) FROM tournaments
UNION SELECT 'user_deck',               COUNT(*) FROM user_deck
UNION SELECT 'user_deck_detail',        COUNT(*) FROM user_deck_detail
UNION SELECT 'user_stock',              COUNT(*) FROM user_stock
UNION SELECT 'user_table',              COUNT(*) FROM user_table
UNION SELECT 'user_types',              COUNT(*) FROM user_types
UNION SELECT 'winner_deck_detail',      COUNT(*) FROM winner_deck_detail
UNION SELECT 'winner_decks',            COUNT(*) FROM winner_decks;

CREATE OR REPLACE VIEW estructurabbdd AS
SELECT TABLE_NAME AS `Objeto`, TABLE_TYPE AS `Tipo`
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
UNION
SELECT EVENT_OBJECT_TABLE, TRIGGER_NAME
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
UNION
SELECT ROUTINE_NAME, ROUTINE_TYPE
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = DATABASE();
