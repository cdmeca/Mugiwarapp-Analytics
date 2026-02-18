# Mugiwarapp-Analytics
# 🏴‍☠️ Mugiwarapp Analytics | One Piece TCG

**Una plataforma de análisis de datos e inteligencia competitiva para el juego de cartas One Piece TCG, enfocada en la predicción de tendencias mediante datos del metajuego asiático.**

---

## Descripción del Proyecto

**Mugiwarapp-Analytics** es una solución de datos diseñada para resolver una necesidad crítica en el ecosistema competitivo de *One Piece Card Game*: la brecha de información.

Dado que el metajuego asiático va **3 meses por delante** del lanzamiento global, los jugadores occidentales necesitan analizar esos datos para anticipar qué mazos y cartas dominarán los torneos futuros. Este proyecto ingesta, normaliza y analiza datos de torneos para ofrecer estadísticas que facilitan la toma de decisiones estratégicas y la gestión de colecciones.

## Tecnologías Utilizadas

El núcleo del proyecto está construido sobre una base de datos relacional robusta con lógica de negocio integrada:

* **MySQL (8.0+)**: Motor de base de datos principal.
* **Advanced SQL Scripting**:
    * **Triggers Complejos**: Implementación de reglas oficiales del juego (validación de colores líder-mazo, límites de copias) directamente en el motor de base de datos.
    * **Vistas Analíticas**: Tablas virtuales pre-calculadas para rankings y estadísticas de uso.
    * **Stored Constraints**: Validaciones de integridad de datos a nivel de esquema.
* **Data Modeling**: Modelo relacional normalizado (3NF) con más de 20 tablas interconectadas.

## Dataset y Estructura

El sistema gestiona un volumen considerable de datos históricos y transaccionales:

* **Volumen de Datos**:
    * Más de **1.400 cartas** únicas detalladas con atributos, rareza y efectos.
    * Más de **1.200 registros** de victorias en torneos competitivos (Meta Asiático).
    * Miles de relaciones entre mazos y cartas (`winner_deck_details`).
* **Modelo de Datos**:
    * Tablas dimensionales para atributos de cartas (`card_colour`, `card_type`, `card_rarity`).
    * Tablas de hechos para resultados de torneos (`meta_winners`, `winner_decks`).
    * Tablas transaccionales de usuario (`user_deck`, `user_stock`).

## Lógica de Negocio y Automatización (SQL)

A diferencia de una base de datos pasiva, este proyecto actúa como un motor de reglas activo.

### 1. Validación de Reglas del Juego (Triggers)
Se programaron *triggers* para impedir la creación de mazos ilegales según el reglamento oficial de Bandai:
* `trg_check_card_color_match`: Verifica dinámicamente si el color de una carta añadida coincide con la identidad de color del Líder del mazo (e.g., impide añadir una carta Roja en un mazo puramente Azul).
* `max4copies`: Impide insertar más de 4 copias de la misma carta, respetando las excepciones de cartas "Unlimited".
* `user_deck_plus_51`: Controla el límite estricto de cartas permitidas por mazo.

### 2. Analítica e Insights (Vistas)
* **`top_leaders_view`**: Genera un ranking dinámico de los líderes con mejor desempeño basado en puntos de torneo ponderados.
* **`top_players`**: Identifica a los jugadores más consistentes del circuito asiático.
* **`leader_view`**: Agrega atributos complejos para facilitar el filtrado en el frontend o dashboards.

## Instalación y Reproducción

1.  Clonar el repositorio.
2.  Importar el archivo `mugiwarapp_structure.sql` en tu servidor MySQL para crear el esquema, las vistas y los triggers.
3.  (Opcional) Ejecutar los scripts de carga de datos `mugiwarapp_data.sql` para poblar la base de datos con las cartas del bloque OP-01 a OP-08 y EB-01.
4.  Ejecutar las consultas de prueba en `queries_examples.sql` para ver las métricas.

## Futuras Implementaciones

* **Conexión con Power BI**: Desarrollo de un Dashboard interactivo mediante conexión ODBC para visualizar el *Win Rate* por color y evolución del precio de las cartas (aprovechando mis habilidades en DAX y modelado de datos).
* **Pipeline ETL con Python**: Automatizar la ingesta de nuevos resultados de torneos mediante *web scraping* de fuentes asiáticas.
* **Machine Learning**: Modelo predictivo para estimar la probabilidad de victoria de un mazo basado en su composición.

---
*Autor: Chaim D. Medina Castilla*
*Portfolio de Data Analytics*
