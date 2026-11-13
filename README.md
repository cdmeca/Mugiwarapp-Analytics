# Mugiwarapp Analytics | One Piece TCG

Base de datos relacional en **MySQL / MariaDB** para analizar el metajuego de *One Piece Card Game*: catálogo de cartas, mazos de usuario, resultados de torneos asiáticos y reglas del reglamento aplicadas en el propio motor.

> Todos los datos de usuarios y jugadores de este repositorio son **ficticios o anonimizados**. Las cartas y el catálogo son datos públicos del juego.

## Contenido del repositorio

| Archivo | Qué contiene |
|---|---|
| `01_schema_creation.sql` | Crea la base `mugiwarapp` (utf8mb4) y 20 tablas: catálogo, usuarios, mazos, metajuego e histórico. |
| `02_seed_catalog.sql` | Catálogo de cartas (1.801 filas, incluida la carta marcadora `99999`), colores, tipos, rarezas, rotaciones, estados legales y torneos. |
| `03_seed_sample_data.sql` | Datos de ejemplo anonimizados: 6 usuarios, 15 mazos, 218 mazos ganadores y 1.600 registros de victorias. |
| `04_triggers.sql` | 10 triggers: reglas del reglamento (copias, 51 cartas, colores del líder) en INSERT y UPDATE, y auditoría de mazos. |
| `05_views.sql` | 8 vistas: ranking de líderes y jugadores, mazos ganadores, colección por usuario y documentación de la propia base. |
| `06_functions_procedures_events.sql` | 2 funciones (`impact_ratio`, `complete_collection_ratio`), 2 procedimientos (`deck_validator`, `backup_maintenance`) y 1 evento diario. |
| `07_queries_examples.sql` | Consultas de ejemplo de solo lectura (ranking, mazos listos para imprimir, stock frente a mazo, rotación). |
| `erd_diagram.png` | Diagrama entidad-relación. **Procede de una versión anterior** del esquema y puede no coincidir con los nombres y tipos actuales. |

## Requisitos

- MySQL 8.0+ o MariaDB 10.5+ (se han probado los scripts con MariaDB 10.11).
- Un usuario con permisos para crear bases de datos, triggers, funciones, procedimientos y eventos.

## Instalación

Ejecuta los scripts **en este orden**. Usa un cliente que soporte `DELIMITER`, como `mysql` o `mariadb`:

```bash
mysql -u <usuario> -p < 01_schema_creation.sql
mysql -u <usuario> -p < 02_seed_catalog.sql
mysql -u <usuario> -p < 03_seed_sample_data.sql
mysql -u <usuario> -p < 04_triggers.sql
mysql -u <usuario> -p < 05_views.sql
mysql -u <usuario> -p < 06_functions_procedures_events.sql
mysql -u <usuario> -p < 07_queries_examples.sql      # opcional
```

Los datos se cargan **antes** de los triggers a propósito, para que la carga inicial no quede bloqueada por las reglas. Si cambias datos después, los triggers se aplican igualmente.

**Limpieza diaria del histórico:** el evento `backup_maintenance_event` necesita el planificador activo:

```sql
SET GLOBAL event_scheduler = ON;
```

**Reconstruir desde cero:** el esquema no borra nada. Si quieres empezar de nuevo, ejecuta antes `DROP DATABASE IF EXISTS mugiwarapp;` tú mismo.

## Reglas de negocio (triggers)

| Regla | Dónde | Comportamiento |
|---|---|---|
| Máximo de copias | `max4copies`, `max4copies_upd` | Legal: 4 · Restricted: 1 · Banned: 0 · Unlimited/unknown: sin límite. |
| Máximo 51 cartas | `user_deck_plus_51`, `user_deck_plus_51_upd` | El total del mazo no puede superar 51. |
| Color del líder | `trg_check_card_color_match`, `_upd` | La carta debe compartir al menos un color con el líder. |
| Auditoría | `before_user_deck_insert`, `user_deck_header_backup`, `deck_detail_backup`, `deck_detail_delete_backup` | Fecha de creación y copias del mazo antes de modificar o borrar. |

Las reglas se aplican en INSERT y en UPDATE. Las restricciones de copias y de color se evalúan con el estado legal y los colores de la carta, no con IDs fijos.

## Funciones y procedimientos

- **`impact_ratio(carta)`**: porcentaje (0-100) de mazos ganadores que incluyen la carta.
- **`complete_collection_ratio(usuario)`**: porcentaje (0-100) de playsets completos del catálogo. Cada carta necesita 1 copia si es Leader y 4 en el resto; el valor suma el mínimo entre lo poseído y lo necesario.
- **`deck_validator(mazo)`**: devuelve una fila con tres comprobaciones: 51 cartas, cartas `Banned` y cartas de rotaciones caducadas. Lanza error si el mazo no existe.
- **`backup_maintenance()`**: borra el histórico con más de 32 días.

Ejemplo:

```sql
CALL deck_validator(6);
SELECT impact_ratio(1361) AS presencia_pct;
```

## Vistas principales

- **`top_leaders`**: top 10 de líderes por puntos de torneo (puntos del torneo por cada victoria).
- **`top_players`**: top 25 de jugadores por puntos, sin equipos genéricos.
- **`top_decks_view`**: hasta 5 mazos ganadores por cada uno de los 10 líderes principales.
- **`collection_user_view`**: cartas poseídas frente a playset necesario por usuario.
- **`leader_list`**, **`INFOTABLAS`**, **`REGISTROSTABLAS`**, **`estructurabbdd`**: catálogo de líderes y documentación de la base.

## Seguridad

- **No hay usuarios ni contraseñas en el repositorio.** Los roles y cuentas de MySQL se gestionan fuera del repo.
- Las contraseñas de `user_table` deben guardarse como hash (bcrypt o argon2, generado por la aplicación). Los datos de ejemplo usan hashes SHA-256 de cadenas demo (`demo-only-<id>`): no son válidos en producción.
- Los nombres de jugadores de torneo están sustituidos por pseudónimos (`Player 001`…).

## Pruebas

Para comprobar la instalación, ejecuta:

```sql
SELECT * FROM top_leaders LIMIT 5;
CALL deck_validator(1);       -- debería devolver OK en las 51 cartas
```

Se han verificado estos casos en una base limpia:

- El ranking de líderes coincide con la suma real de puntos de sus victorias.
- `impact_ratio` y `complete_collection_ratio` devuelven valores entre 0 y 100.
- `deck_validator` valida el mazo que recibe.
- Un UPDATE que supera 4 copias, 51 cartas o los colores del líder se rechaza.
- Una carta con dos colores basta con que comparta uno con el líder para poder añadirse.
- Borrar un mazo funciona aunque tenga histórico, y el histórico se guarda con precisión de microsegundos.

## Cambios respecto a la versión anterior

- `impact_ratio` era una suma de cantidades dividida entre filas (los valores sumaban ~317%); ahora es el porcentaje de mazos que contienen la carta.
- `top_leaders` multiplicaba el ID del torneo por sus puntos; ahora suma los puntos de cada victoria.
- `complete_collection_ratio` estaba invertido (necesarias/poseídas); ahora mide playsets completos y queda acotado a 0-100.
- `deck_validator` validaba un mazo arbitrario; ahora valida el mazo que recibe.
- Los triggers de regla solo funcionaban en INSERT; ahora también en UPDATE.
- La regla de color comparaba solo el primer color de la carta; ahora basta con que coincida uno.
- La regla de copias aplica también Restricted (1 copia) y Banned (0).
- Un histórico de mazo con FK a la tabla viva impedía borrar mazos durante 32 días; ahora es independiente.
- La validación de email rechazaba `nombre.apellido@dominio.com`.
- La base usa utf8mb4, necesaria para nombres con kanji y emojis.
- Se ha eliminado la columna `full_type`, que daba NULL en casi todas las cartas.

## Pendiente

- Regenerar el diagrama entidad-relación con el esquema actual.
- Revisar los 3 registros de mazos de ejemplo que contienen cartas `Banned` (los datos se cargaron antes de aplicar las reglas).
- Valorar si `winner_name` debe ser una tabla de jugadores aparte.
- Conectar Power BI por ODBC y automatizar la ingesta de torneos con Python.

---
*Autor: Chaim D. Medina Castilla*
*Portfolio de Data Analytics*
