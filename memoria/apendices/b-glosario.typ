= Glosario y acrónimos

#table(
  columns: (auto, 1fr),
  align: left,
  stroke: 0.5pt,
  table.header([*Término*], [*Definición*]),
  [API],
  [_Application Programming Interface_. Conjunto de _endpoints_ HTTP que el _backend_ expone para que el _frontend_ y otros clientes consuman.],

  [CORS],
  [_Cross-Origin Resource Sharing_. Mecanismo del navegador que controla qué orígenes pueden hacer peticiones a un dominio distinto.],

  [DTO], [_Data Transfer Object_. Estructura de datos que se serializa entre cliente y servidor.],

  [FAB], [_Floating Action Button_. Botón de acción flotante típico en interfaces móviles.],

  [FTS],
  [_Full Text Search_. Búsqueda de texto completo, en este proyecto resuelta con `tsvector`/`tsquery` de PostgreSQL.],

  [GIN],
  [_Generalized Inverted Index_. Tipo de índice invertido genérico de PostgreSQL, adecuado para valores compuestos como arrays, JSONB y `tsvector`. En Nemsy se utiliza para indexar las columnas `tsvector` que sostienen la búsqueda de texto completo.],

  [JWT],
  [_JSON Web Token_. Estándar para representar afirmaciones (_claims_) firmadas, utilizado para las cookies de sesión.],

  [OAuth2],
  [Estándar de autorización delegada. En Nemsy se usa el flujo _authorization code_ con Google como proveedor.],

  [ORM],
  [_Object-Relational Mapping_. Capa que traduce entre objetos del lenguaje y filas de la base de datos. En este proyecto se ha evitado a favor de sqlc.],

  [PWA], [_Progressive Web App_. Aplicación web instalable con capacidades cercanas a las nativas.],

  [REST], [_Representational State Transfer_. Estilo arquitectónico para APIs HTTP basado en recursos y verbos.],

  [RUNE],
  [Construcción de Svelte 5 (`$state`, `$derived`, `$props`, `$effect`) que declara reactividad de forma explícita.],

  [S3],
  [_Simple Storage Service_. API de almacenamiento de objetos popularizada por Amazon. En Nemsy se utiliza Hetzner Object Storage como proveedor compatible con esta API.],

  [Saga],
  [Patrón de coordinación de operaciones distribuidas mediante pasos compensables, aplicado en la creación de recursos.],

  [SGBD], [_Sistema Gestor de Bases de Datos_.],

  [SPA],
  [_Single Page Application_. Aplicación web que se carga una sola vez y reemplaza el contenido en cliente al navegar.],

  [sqlc], [Herramienta que genera código Go fuertemente tipado a partir de consultas SQL escritas a mano.],

  [SSR], [_Server-Side Rendering_. Renderizado de la página en el servidor antes de enviarla al cliente.],

  [SWOT],
  [_Student Webmail Origin Tracker_, lista mantenida por JetBrains que asocia dominios de correo a centros educativos.],

  [TFG], [_Trabajo de Fin de Grado_.],

  [tsquery / tsvector], [Tipos de PostgreSQL para consulta y representación tokenizada de texto en búsquedas FTS.],

  [VPS],
  [_Virtual Private Server_. Servidor virtualizado contratado a un proveedor de _hosting_, donde está desplegado Nemsy.],

  [VU], [_Virtual User_. Usuario simulado por k6 durante una prueba de carga.],
)
