# 🏴‍☠️ Mugiwarapp Analytics · One Piece TCG

**Base de datos relacional en MySQL para analizar el metajuego competitivo de One Piece Card Game y gestionar colecciones y mazos, con reglas del juego aplicadas directamente en la base de datos.**

---

## Descripción del proyecto

Mugiwarapp nace para que los jugadores de One Piece TCG puedan llevar el control de su colección de cartas y preparar sus mazos con información del metajuego asiático.

El metajuego asiático va unos 3 meses por delante del occidental, así que sus resultados sirven para anticipar qué líderes y mazos tendrán peso en los próximos torneos de todo el mundo. Además, los premios de los torneos (cartas y playmats) alcanzan valores de venta muy altos en plataformas como Cardmarket, lo que hace aún más útil saber qué cartas se necesitan.

El proyecto integra, normaliza y analiza resultados de torneos y ofrece estadísticas (líderes con mejor rendimiento, mejores jugadores, mazos ganadores recientes, estado de la colección de cada usuario) además de validar mazos según el reglamento.

## Contenido del repositorio

```
.
├── sql/
│   ├── 01_schema.sql                      # BBDD, 20 tablas, claves y restricciones (¡borra y recrea la BBDD!)
│   ├── 02_views.sql                       # 8 vistas (analíticas y de documentación)
│   ├── 03_triggers.sql                    # 6 triggers (backups y validación de mazos)
│   ├── 04_functions_procedures_event.sql  # 2 funciones, 2 procedimientos y 1 evento programado
│   ├── 05_data_cards.sql                  # Catálogo de cartas y tablas maestras
│   ├── 06_data_asian_meta.sql             # Torneos, mazos ganadores y victorias del meta asiático
│   ├── 07_data_demo_users.sql             # Usuarios, colecciones y mazos de demostración
│   ├── 08_roles_users.sql                 # Roles y usuarios de MySQL (cambiar contraseñas)
│   ├── 09_queries_examples.sql            # Consultas de ejemplo
│   └── tests/test_backup_maintenance.sql  # Prueba del procedimiento de mantenimiento de backups
└── docs/
    ├── Presentacion_Mugiwarapp.pdf        # Documentación detallada de cada tabla, trigger y consulta
    └── erd_diagram.png                    # Diagrama entidad-relación
```

## Qué incluye

| Objeto | Cantidad |
|---|---|
| Tablas | 20 |
| Vistas | 8 |
| Triggers | 6 |
| Funciones | 2 |
| Procedimientos almacenados | 2 |
| Eventos programados | 1 |
| Roles | 4 |

**Datos**

- **1.800 cartas** (sets OP-01 a OP-11, EB-01 y EB-02, mazos de inicio ST-01 a ST-14 y promocionales) con color, tipo, rareza, coste, poder, contador, tipos, estado legal y rotación.
- **1.600 victorias de líderes** y **218 mazos ganadores** con su lista de cartas (**3.504** líneas de detalle) en torneos asiáticos entre el 1 de marzo y el 20 de abril de 2025.
- **8 tipos de torneo**, cada uno con su peso en puntos.
- Datos de demostración: 6 usuarios ficticios, sus colecciones y 15 mazos.

**Modelo de datos**

- Tablas maestras de atributos de cartas: `card_colour`, `card_type`, `card_rarity`, `card_attribute`, `card_typeb`, `card_rotation`, `card_legal_status`.
- Tablas de metajuego: `tournaments`, `format_game`, `meta_winners`, `winner_decks`, `winner_deck_detail`.
- Tablas de usuario: `user_table`, `user_types`, `user_stock`, `user_deck`, `user_deck_detail`.
- Tablas de copia de seguridad: `backup_user_deck`, `backup_user_deck_detail`.

## Lógica de negocio en SQL

La base de datos no es solo almacenamiento: aplica reglas del juego y se mantiene sola.

### Triggers

| Trigger | Qué hace |
|---|---|
| `max4copies` | Impide más de 4 copias de una carta en un mazo, salvo cartas con estado legal "Unlimited" o desconocido. |
| `user_deck_plus_51` | Impide que un mazo supere las 51 cartas (líder incluido). |
| `trg_check_card_color_match` | Una carta solo entra en un mazo si comparte al menos un color con el líder. |
| `before_user_deck_insert` | Registra la fecha de creación del mazo. |
| `deck_detail_backup` / `deck_detail_delete_backup` | Guardan una copia del detalle del mazo antes de modificarlo o borrarlo. |

Los tres primeros se desarrollaron con ayuda de ChatGPT; los de backup y fecha de creación son propios.

### Vistas

- `leader_list`: líderes con sus colores (alimenta el trigger de color).
- `top_leaders`: top 10 de líderes por puntos de torneo, con `ROW_NUMBER()` como función de ventana.
- `top_players`: top 25 de jugadores del circuito asiático (excluye cuentas genéricas como "Japan Flagships").
- `top_decks_view`: para los líderes del top, cinco mazos de los mejores jugadores, ordenados por puntos y fecha.
- `collection_user_view`: estado de la colección de cada usuario (copias necesarias, que faltan y si está completa).
- `infotablas`, `registrostablas`, `estructurabbdd`: documentación automática del esquema.

### Funciones, procedimientos y evento

- `impact_ratio(carta)`: porcentaje de aparición de una carta en los mazos ganadores.
- `complete_collection_ratio(usuario)`: porcentaje de la colección completada (1 copia por líder, 4 por el resto).
- `deck_validator(mazo)`: comprueba que el mazo tenga 51 cartas, ninguna prohibida y ninguna fuera de rotación.
- `backup_maintenance()`: borra copias de seguridad de más de 32 días dentro de una transacción.
- `backup_maintenance_event`: ejecuta el procedimiento anterior cada noche.

### Roles

`super_admin`, `card_master` (cartas), `meta_reporter` (torneos y mazos ganadores) y `analyst` (analítica).

### Limitaciones conocidas

- Los triggers de validación se ejecutan en `INSERT`; las modificaciones posteriores de un mazo no se vuelven a validar.
- Las cartas prohibidas (Banned) y la rotación se comprueban con `deck_validator`, no al insertar la carta.

## Instalación

**Requisitos:** MySQL 8.0 o superior (desarrollado en MySQL; la carga completa también se ha probado en MariaDB 10.11) y un usuario con permisos para crear bases de datos, triggers y eventos.

> ⚠️ `sql/01_schema.sql` ejecuta `DROP DATABASE IF EXISTS mugiwarapp_local_test` y la recrea. No lo ejecutes en un servidor donde exista una base de datos con ese nombre que quieras conservar.

1. Clona el repositorio.
2. Ejecuta los scripts de `sql/` en orden, del `01` al `07`:
   ```bash
   for f in sql/0[1-7]_*.sql; do
     mysql -u root -p --default-character-set=utf8mb4 < "$f"
   done
   ```
   También puedes abrirlos en orden desde MySQL Workbench. Es importante usar `utf8mb4`: los nombres de jugadores incluyen kanji y emojis.
3. Después ejecuta `08_roles_users.sql`, pero antes sustituye las contraseñas `CHANGE_ME_*` por otras tuyas. El script crea usuarios de MySQL y activa el planificador de eventos (`SET GLOBAL event_scheduler = ON`), por lo que requiere privilegios de administrador.
4. Prueba las consultas de `sql/09_queries_examples.sql` y, si quieres, `sql/tests/test_backup_maintenance.sql`.

## Consultas de ejemplo

```sql
USE mugiwarapp_local_test;

-- Top 10 de líderes por puntos de torneo
SELECT rank_number, card_code, colour_complete, card_name, wins_report, points
FROM top_leaders;

-- Estado de la colección de un usuario
SELECT card_code, card_name, stock_amount, `Remaining cards need`
FROM collection_user_view
WHERE fk_user = 1;

-- ¿Es válido el mazo 1 para torneo?
CALL deck_validator(1);
```

## Documentación

- [`docs/Presentacion_Mugiwarapp.pdf`](docs/Presentacion_Mugiwarapp.pdf): objetivo, estructura y restricciones de cada tabla, triggers y consultas.
- [`docs/erd_diagram.png`](docs/erd_diagram.png): diagrama entidad-relación.

## Futuras implementaciones

- **Panel en Power BI** conectado por ODBC para visualizar el win rate por color y la evolución del precio de las cartas, apoyado en modelado de datos y DAX.
- **Pipeline ETL en Python** para automatizar la carga de nuevos resultados de torneos mediante web scraping de fuentes asiáticas.
- **Machine Learning** para estimar la probabilidad de victoria de un mazo según su composición.

## Créditos y aviso legal

- Los datos del metajuego asiático proceden del trabajo de **Waffles_the_asian_yenbear** ([@TheAsianYenbear en X](https://x.com/TheAsianYenbear)), que los cedió para este proyecto. ¡Gracias!
- Proyecto de aficionado sin ninguna afiliación con Bandai, Shueisha ni Toei Animation. *One Piece Card Game*, sus cartas y nombres pertenecen a sus respectivos titulares.

---

*Autor: Chaim D. Medina Castilla · Portfolio de Data Analytics*
