USE mugiwarapp_local_test;

-- SEC 9 EXERCISES //////////////////////////////////////////////////////////////////////////////////////////////////
-- SEC 9.1 REQUISITOS DE 10 CONSULTAS:
-- Deberán diseñarse al menos 10 consultas que tendrán todas las características estudiadas
-- en clase.

-- SEC 9.1.1 LEADER CARDS
-- Muestra todas las cartas de tipo "Leader" ordenadas por poder de forma descendente

SELECT 
card_name, 
power, 
cost 
FROM cardlist 
WHERE fk_card_type = 1 
ORDER BY power DESC
;

-- SEC 9.1.2 WINNER DECKS
-- Muestra los mazos ganadores con su nombre y fecha
SELECT 
	pk_winner_deck, 
	winner_name AS 'Nombre del ganador', 
  	winner_date AS 'Fecha cuando gano', 
    	fk_tournament AS 'Torneo'
FROM winner_decks
ORDER BY winner_date DESC
;

-- SEC 9.1.3 RARE CARDS
-- Para identificar cartas raras 
SELECT 
*
FROM cardlist c
JOIN card_rarity cr ON c.fk_rarity = cr.pk_rarity
WHERE cr.rarity_name IN ('Rare', 'Super Rare', 'Secret Rare') 
ORDER BY POWER DESC
;

-- SEC 9.1.4 WINNER DECKS WITH DATA
-- Muestra los mazos ganadores con su líder, torneo, formato y fecha
SELECT 
wd.pk_winner_deck, 
wd.winner_name, 
cl.card_name AS leader_name, 
t.name_tournament, 
fg.format_name, 
wd.winner_date
FROM winner_decks wd
JOIN winner_deck_detail wdd ON wd.pk_winner_deck = wdd.fk_winner_deck
JOIN cardlist cl ON wdd.fk_card = cl.pk_card
JOIN tournaments t ON wd.fk_tournament = t.pk_tournament
JOIN format_game fg ON wd.fk_format = fg.pk_format
JOIN card_type ct ON cl.fk_card_type = ct.pk_card_type
WHERE ct.card_type_name = 'Leader'
ORDER BY wd.winner_date DESC
;

  -- SEC 9.1.5 USER / DECKS VIEW 
  -- Muestra el listado de los usuarios y sus decks junto con el nombre del deck, 
  -- el nombre de la carta y su cantidad
select ut.nickname,ud.deck_name, cl.card_code, cl.card_name, udd.deck_amount 
from user_deck_detail as udd join user_deck as ud on udd.fk_user_deck = ud.pk_user_deck
join cardlist as cl on udd.fk_card = cl.pk_card
join user_table as ut on ut.pk_user = ud.fk_user;

-- SEC 9.1.6 POINTS BY LEADER / WEEK
-- Muestra un listado con los puntos acumulados por líder por semana.

Select cl.card_code, ll.colour_complete, cl.card_name, week(mw.winner_date) as 'Week Period',
sum(tu.points_by_tournament) as 'Total points by week' 
	from meta_winners as mw join tournaments as tu on mw.fk_tournament = tu.pk_tournament
	join cardlist as cl on mw.fk_card = cl.pk_card
	join leader_list as ll on ll.pk_card = mw.fk_card
		group by mw.fk_card, week(mw.winner_date)
			order by week(mw.winner_date), sum(tu.points_by_tournament) desc;
            
-- SEC 9.1.7 TOP 5 CARDS BY COLOR
-- Muestra las cartas más utilizadas de cada color.
select * from (
	select cc.colour1, cl.card_code, cl.card_name, sum(wdd.amount) as 'Total Cards',cls.status_name
	from winner_deck_detail as wdd join cardlist as cl on wdd.fk_card = cl.pk_card
	join card_colour as cc on cl.fk_color = cc.pk_colour
    join card_legal_status as cls on cls.pk_status = cl.fk_legal_status
		where cc.colour1 = 'Black'
			group by cl.card_code, cl.card_name
			order by  cc.colour1 asc, sum(wdd.amount) desc limit 5
            ) as Black
UNION ALL

select * from (
	select cc.colour1, cl.card_code, cl.card_name, sum(wdd.amount) as 'Total Cards',cls.status_name
	from winner_deck_detail as wdd join cardlist as cl on wdd.fk_card = cl.pk_card
	join card_colour as cc on cl.fk_color = cc.pk_colour
    join card_legal_status as cls on cls.pk_status = cl.fk_legal_status
		where cc.colour1 = 'Red'
			group by cl.card_code, cl.card_name
			order by  cc.colour1 asc, sum(wdd.amount) desc limit 5
			) as Red
            
UNION ALL

select * from (
	select cc.colour1, cl.card_code, cl.card_name, sum(wdd.amount) as 'Total Cards',cls.status_name
	from winner_deck_detail as wdd join cardlist as cl on wdd.fk_card = cl.pk_card
	join card_colour as cc on cl.fk_color = cc.pk_colour
    join card_legal_status as cls on cls.pk_status = cl.fk_legal_status
		where cc.colour1 = 'Green'
			group by cl.card_code, cl.card_name
			order by  cc.colour1 asc, sum(wdd.amount) desc limit 5
			) as Green

UNION ALL

select * from (
	select cc.colour1, cl.card_code, cl.card_name, sum(wdd.amount) as 'Total Cards',cls.status_name
	from winner_deck_detail as wdd join cardlist as cl on wdd.fk_card = cl.pk_card
	join card_colour as cc on cl.fk_color = cc.pk_colour
    join card_legal_status as cls on cls.pk_status = cl.fk_legal_status
		where cc.colour1 = 'Yellow'
			group by cl.card_code, cl.card_name
			order by  cc.colour1 asc, sum(wdd.amount) desc limit 5
			) as Yellow

UNION ALL

select * from (
	select cc.colour1, cl.card_code, cl.card_name, sum(wdd.amount) as 'Total Cards',cls.status_name
	from winner_deck_detail as wdd join cardlist as cl on wdd.fk_card = cl.pk_card
	join card_colour as cc on cl.fk_color = cc.pk_colour
    join card_legal_status as cls on cls.pk_status = cl.fk_legal_status
		where cc.colour1 = 'Purple'
			group by cl.card_code, cl.card_name
			order by  cc.colour1 asc, sum(wdd.amount) desc limit 5
			) as Purple;

 -- SEC 9.1.8 LIST OF LEADERS, NUMBER OF TOURNAMENTS WON, TOTAL POINTS WON AND
 -- THE RATIO BETWEEN POINTS WON / TOURNAMENTS WON
 -- Lista de líderes, torneos ganados, puntos totales y el ratio entre puntos ganados y torneos.
 -- Ideal para identificar un ratio de líder más sólido.
 
select ll.colour_complete, ll.card_name, count(mw.fk_card) as times_played, tl.points, 
round( tl.points /count(mw.fk_card) ,2) AS ratio
from leader_list as ll 
join meta_winners as mw on mw.fk_card = ll.pk_card
join top_leaders as tl on tl.pk_card = ll.pk_card
group by ll.colour_complete, ll.card_name, tl.points
order by ratio desc, times_played desc;

-- SEC 9.1.9 IMPACT RATIO FUNCTION
-- Con esta consulta usamos la función impact ratio para ver las cartas más usadas en la mayoría de decks
-- (Baneen la chancla...)
select card_code, card_name, impact_ratio(pk_card) as 'Presence Ratio' from cardlist
order by impact_ratio(pk_card) desc limit 50;

-- SEC 9.1.10 USER DECK VS STOCK CONSULT
-- Con esta consulta podemos ver los decks que ha montado cada usuario y comparar las cartas necesarias para montar
-- el propio deck con las cartas que tiene cada usuario en su colección. Con estos datos el usuario podrá
-- saber qué cartas necesita comprar.

Select udd.fk_user_deck as 'Deck n.',ut.nickname as 'User Nickname',
ud.deck_name as 'Deck Name',cl.card_code as 'Card Code',
cl.card_name as 'Card Name',udd.deck_amount as 'Needed Cards', 
ifnull(us.stock_amount,0) as stock,
if(udd.deck_amount-ifnull(us.stock_amount,0)<0,0,udd.deck_amount-ifnull(us.stock_amount,0)) as Needed
from user_deck_detail as udd 
join user_deck as ud on udd.fk_user_deck = ud.pk_user_deck
join user_table as ut on ut.pk_user = ud.fk_user
join cardlist as cl on udd.fk_card = cl.pk_card
left join user_stock as us on us.fk_user = udd.fk_user_deck and us.fk_card = udd.fk_card
order by udd.fk_user_deck;


-- SEC 9.1.11 DECK READY TO PRINT
-- Aunque esta puede ser una de las consultas más simples es una de las más usadas en el entorno competitivo
-- de One Piece TCG. Aquí seleccionas un deck y te devuelve un listado completamente compatible con otros programas como
-- el simulador online o la propia aplicación de Bandai a la que envías el listado de tu deck a la hora de 
-- participar en cualquiera de sus torneos.

Select concat(udd.deck_amount,"x",cl.card_code) as 'List to copy'
from user_deck_detail as udd join 
cardlist as cl on udd.fk_card = cl.pk_card

where udd.fk_user_deck = 2
;

-- SEC 9.1.12 REMAINING DAYS FOR CARD ROTATION
-- Con esta función sabremos los días que tienen las cartas segun su rotación.
select cl.card_code, cl.fk_color, cl.card_name, cr.card_rotation_name, 
datediff(cr.rotation_final_day,curdate()) as 'Remaining days'
from cardlist as cl join card_rotation as cr on pk_rotation = cl.fk_rotation
where datediff(cr.rotation_final_day,curdate()) is not null;


