#import "../template.typ": epigraph
#import "@preview/fletcher:0.5.8": diagram, edge, node
#import "@preview/chronos:0.3.0" as chronos
#import "@preview/codly:1.3.0": *
#import "@preview/ansi-render:0.8.0": ansi-render, terminal-themes
#show: codly-init.with()

#show figure.where(kind: table): set block(breakable: true)

#let placeholder(height: 7cm, label: "captura pendiente") = rect(
  width: 100%,
  height: height,
  stroke: 1pt + rgb("#a1a1aa"),
  fill: rgb("#fafafa"),
  align(center + horizon)[#text(fill: rgb("#71717a"), style: "italic")[TODO: #label]],
)

= Descripción del Trabajo

#block(
  fill: rgb("#f0f0f0"),
  inset: 1em,
  below: 1.5em,
)[
  *Resumen:* En este capítulo se justifican las decisiones tecnológicas y se describe en detalle el desarrollo de la plataforma Nemsy.
]

#epigraph(
  [La calidad de un sistema no está determinada por el poder de sus componentes individuales, sino por cómo se eligen y se ensamblan para satisfacer las necesidades.],
  [Grady Booch],
)

== Tecnologías evaluadas

En esta sección se justifican las principales decisiones tecnológicas del proyecto, comparando las opciones consideradas para cada componente de la arquitectura.

=== Backend

Para el backend se evaluaron tres alternativas con las que ya tenía experiencia: Node.js con Express, Spring Boot (Java) y Go con Chi, siendo esta última con la que más cómodo me sentía. Dos de ellas figuran entre los frameworks web más utilizados según la encuesta anual de Stack Overflow a desarrolladores @stackoverflow-survey-2025, como se puede observar en la @fig:stackoverflow-frameworks.

#figure(
  image("../imagenes/stackoverflow_frameworks.png", width: 75%),
  caption: [Frameworks y tecnologías web más populares según la encuesta de Stack Overflow 2025 @stackoverflow-survey-2025.],
) <fig:stackoverflow-frameworks>

==== Node.js (Express)

Express es un framework web minimalista escrito sobre Node.js. Como refleja la @fig:stackoverflow-frameworks, se sitúa entre los frameworks web más utilizados a nivel global, lo que se traduce en un ecosistema muy maduro y una gran cantidad de recursos disponibles. Además, es el framework utilizado en la asignatura de Aplicaciones Web del grado, por lo que ya se contaba con experiencia previa en su uso.

En cuanto a la experiencia de desarrollo, Express es excelente, es directo y sencillo, y su principal punto fuerte es la velocidad con la que se puede construir un servicio. Sin embargo, el objetivo de este proyecto no es maximizar la velocidad de desarrollo, sino ofrecer una plataforma que se sienta rápida para el usuario final, y Node.js, al ser interpretado y basarse en un único hilo de ejecución, no es la opción más adecuada para ello. Es por ello que fue descartada.

==== Spring Boot

Spring Boot es el framework más popular del ecosistema Java y también aparece en la @fig:stackoverflow-frameworks con una presencia notable. Proporciona un entorno muy completo con inyección de dependencias, ORM integrado y una amplia cobertura para aplicaciones empresariales. Este es el framework utilizado en la asignatura de Ingeniería Web del grado, por lo que también se contaba con experiencia previa en su uso.

Su experiencia de desarrollo también es destacable una vez superado el boilerplate inicial, aunque con un matiz. La filosofía del ecosistema Java se apoya en múltiples capas de abstracción, lo cual puede dificultar la depuración cuando algo falla. Además, para un proyecto de este tamaño, contar con ORM e inyección de dependencias resulta más una carga que una ventaja. A esto se suma el elevado consumo de memoria de la JVM, un factor relevante al desplegar en un VPS con recursos limitados. Por todo ello, también fue descartada.


==== Go (Chi)

Go es un lenguaje de programación creado por Google, compilado y con un fuerte enfoque en servicios web y cloud @go-website. Su librería estándar incluye el módulo `net/http`, lo suficientemente sólido como para construir un servidor HTTP sin dependencias externas. Chi es una extensión ligera sobre este módulo que añade utilidades como el enrutamiento con parámetros y middlewares encadenables @chi-docs. Además, Go cuenta con un sistema de testing integrado en el propio lenguaje y un tooling moderno que cubre desde el formateo de código hasta la gestión de dependencias.

Frente a la filosofía de Java, donde las abstracciones ocultan los detalles de implementación, el ecosistema de Go apuesta por la generación de código y la transparencia. Herramientas como sqlc generan código Go a partir de consultas SQL escritas a mano, de forma que el desarrollador mantiene el control total sobre las queries sin depender de un ORM. Esto resulta especialmente relevante cuando se quieren aprovechar funcionalidades específicas del motor de base de datos elegido, algo que un ORM tiende a dificultar y cuya importancia se detallará en la sección de base de datos.

==== Comparativa

#figure(
  {
    set par(justify: false)
    set text(size: 10pt)
    table(
      columns: 4,
      [*Criterio*],
      [ *Node.js* #image("../imagenes/logo_nodejs.png", height: 1cm, fit: "contain") ],
      [ *Spring Boot* #image("../imagenes/logo_springboot.png", height: 1cm, fit: "contain")],
      [ *Go* #image("../imagenes/logo_go.png", height: 1cm, fit: "contain")],

      [Rendimiento], [Medio (V8, single-thread)], [Alto (JVM, JIT)], [Alto (compilado, nativo)],
      [Concurrencia], [Event loop, un hilo], [Threads del SO], [Goroutines (ligeras)],
      [Consumo de recursos], [Medio], [Alto (JVM)], [Bajo (binario único)],
      [Ecosistema HTTP], [Muy amplio (Express)], [Muy amplio (Spring MVC)], [Sólido (net/http, Chi)],
      [Despliegue], [Requiere Node + node\_modules], [Requiere JVM + JAR], [Binario único],
      [Curva de aprendizaje], [Ya conocido], [Ya conocido], [Ya conocido],
    )
  },
  caption: [Comparativa de tecnologías para el backend.],
) <tab:backend>

Como se resume en la @tab:backend, Go destaca frente a las otras dos alternativas en consumo de recursos y despliegue, al compilar a un binario único sin dependencias externas. Además, su modelo de concurrencia basado en goroutines permite manejar operaciones simultáneas como descargas de archivos de forma nativa, sin configuración adicional. Dado que el foco de este TFG está muy ligado a la velocidad y el bajo consumo de recursos de la plataforma, Go resultó la opción más adecuada.

=== Frontend

Para el frontend se consideraron tres enfoques con filosofías distintas: un framework completo con React (Next.js), un framework ligero con Svelte (SvelteKit), y el enfoque clásico de servidor con templating y Bootstrap, utilizado en varias asignaturas del grado como Aplicaciones Web (EJS) e Ingeniería Web (Thymeleaf).

==== Servidor con templating + Bootstrap

El enfoque más directo y el más familiar por las asignaturas del grado. Con motores como EJS o Thymeleaf, el HTML se renderiza en el servidor y se envía completo al navegador, mientras que Bootstrap proporciona estilos predefinidos y componentes básicos. Es sencillo de entender y desplegar, pero presenta limitaciones claras para una aplicación interactiva: cada acción del usuario requiere una recarga completa de la página, la experiencia resulta lenta y poco fluida, y la personalización visual está limitada por los estilos de Bootstrap. Para una plataforma que aspira a competir en experiencia de usuario con aplicaciones modernas, este enfoque resulta insuficiente.

==== Next.js (React)

Next.js es el meta framework más popular del ecosistema React y uno de los más utilizados en la industria, como refleja la @fig:stackoverflow-frameworks. Ofrece renderizado del lado del servidor (SSR), generación estática, enrutamiento basado en ficheros y un ecosistema de componentes y librerías enorme. Sin embargo, React se basa en un virtual DOM que añade una capa de abstracción entre el código y el navegador @react-docs, lo que resulta en un bundle más pesado. Además, no tenía experiencia previa con React, lo que habría añadido una curva de aprendizaje significativa al proyecto.

==== SvelteKit (Svelte)

SvelteKit es un meta-framework construido sobre Svelte, un compilador que transforma los componentes a JavaScript vanilla durante el build, eliminando la necesidad de un virtual DOM en tiempo de ejecución @svelte-docs. Esto resulta en bundles significativamente más pequeños y un mejor rendimiento en el navegador. Ya tenía experiencia con Svelte y SvelteKit, y además Svelte 5 introduce las runes, un sistema de reactividad más explícito y eficiente que el de versiones anteriores.

SvelteKit ofrece las mismas capacidades que Next.js (SSR, enrutamiento basado en ficheros, layouts anidados) pero con un enfoque más ligero. Al igual que con Go en el backend, la elección se alinea con el objetivo del proyecto de ofrecer una experiencia rápida y eficiente.

==== Comparativa

#figure(
  {
    set par(justify: false)
    set text(size: 10pt)
    table(
      columns: 4,
      [*Criterio*],
      table.cell(
        align: bottom + center,
      )[*Templating + Bootstrap* \ #image("../imagenes/logo_bootstrap.png", height: 1cm, fit: "contain")],
      table.cell(
        align: bottom + center,
      )[*Next.js (React)* \ #image("../imagenes/logo_react.png", height: 1cm, fit: "contain")],
      table.cell(
        align: bottom + center,
      )[*SvelteKit (Svelte)* \ #image("../imagenes/logo_svelte.png", height: 1cm, fit: "contain")],

      [Rendimiento], [Bajo (recarga completa)], [Medio (virtual DOM)], [Alto (compilado, sin virtual DOM)],
      [Interactividad], [Mínima (MPA)], [Alta (SPA/SSR)], [Alta (SPA/SSR)],
      [Tamaño del bundle], [Bajo (sin framework de JS)], [Alto], [Muy bajo],
      [Personalización IU], [Limitada (Bootstrap)], [Total], [Total],
      [Ecosistema], [Maduro pero limitado], [Muy amplio], [Creciente],
      [Curva de aprendizaje], [Ya conocido], [Nuevo], [Ya conocido],
    )
  },
  caption: [Comparativa de tecnologías para el frontend.],
) <tab:frontend>

Se eligió SvelteKit por su combinación de rendimiento, tamaño de bundle reducido y mi familiaridad con el framework. Al compilar a JavaScript vanilla, se alinea directamente con el objetivo del proyecto de ofrecer una plataforma ligera y rápida.

=== Base de datos

Los datos de Nemsy son inherentemente relacionales. Los usuarios, universidades, asignaturas, recursos y archivos están interconectados mediante claves foráneas. Por ello, la decisión entre modelos de datos se inclinó desde el inicio hacia un sistema relacional, pero se evaluaron igualmente las alternativas con las que se tenía experiencia.

==== MySQL

MySQL es el SGBD relacional de código abierto más extendido y el utilizado en asignaturas del grado como Modelado de Software y Aplicaciones Web. Es robusto, bien documentado y cuenta con un ecosistema enorme @mysql-docs. Sin embargo, su soporte de búsqueda de texto completo (`FULLTEXT`) es limitado, no permite asignar pesos a distintos campos, carece de un sistema de ranking comparable a `ts_rank`, y no dispone de un mecanismo nativo para ignorar acentos, algo imprescindible en una plataforma en español. Para conseguir una experiencia de búsqueda equivalente habría sido necesario recurrir a un servicio externo como Elasticsearch, añadiendo complejidad al despliegue.

==== MongoDB

MongoDB es una base de datos documental NoSQL que almacena los datos en formato BSON (similar a JSON). Es una opción popular para prototipos rápidos y esquemas que cambian con frecuencia @mongodb-docs, y fue uno de los SGBD utilizado en la asignatura de Ampliación de Bases de Datos del grado. Sin embargo, el modelo de datos de Nemsy se basa en relaciones claras entre entidades, algo que MongoDB no gestiona de forma nativa, las consultas que implican joins requieren múltiples peticiones o desnormalizar los datos, lo que complica el mantenimiento y compromete la consistencia. Además, sqlc, la herramienta de generación de código elegida para el backend, solo soporta bases de datos SQL.

==== PostgreSQL

PostgreSQL es un SGBD relacional de código abierto con una licencia permisiva (PostgreSQL License), con el que ya contaba con experiencia por proyectos personales. Su principal ventaja frente a MySQL para este proyecto es el sistema de búsqueda de texto completo integrado @postgresql-docs. Mediante columnas de tipo `tsvector`, índices GIN y la función `ts_rank`, PostgreSQL permite construir búsquedas con pesos por campo y ranking de relevancia sin dependencias externas. Además, la extensión `unaccent` permite ignorar tildes en las consultas, algo fundamental para texto en español. Estas funcionalidades se integran directamente en el esquema mediante columnas generadas, de forma que el índice de búsqueda se actualiza automáticamente con cada inserción o modificación.

==== Comparativa

#figure(
  {
    set par(justify: false)
    set text(size: 10pt)
    table(
      columns: 4,
      [*Criterio*],
      table.cell(
        align: bottom + center,
      )[*MySQL* \ #image("../imagenes/logo_mysql.png", height: 1cm, fit: "contain")],
      table.cell(
        align: bottom + center,
      )[*MongoDB* \ #image("../imagenes/logo_mongodb.png", height: 1cm, fit: "contain")],
      table.cell(
        align: bottom + center,
      )[*PostgreSQL* \ #image("../imagenes/logo_postgresql.png", height: 1cm, fit: "contain")],

      [Modelo de datos], [Relacional], [Documental (NoSQL)], [Relacional],
      [Licencia], [GPL], [SSPL], [PostgreSQL (permisiva)],
      [Full-text search], [Básico (FULLTEXT)], [Básico], [Avanzado (tsvector, ts\_rank)],
      [Soporte de acentos], [No nativo], [No nativo], [Sí (unaccent)],
      [Soporte en sqlc], [Sí], [No], [Sí (nativo)],
      [Curva de aprendizaje], [Ya conocido], [Ya conocido], [Ya conocido],
    )
  },
  caption: [Comparativa de sistemas de gestión de bases de datos.],
) <tab:database>

Como se resume en la @tab:database, PostgreSQL fue la elección natural. Es el único que resuelve la búsqueda de texto en español de forma nativa, sin añadir servicios externos al despliegue, y su compatibilidad con sqlc encaja directamente con la arquitectura del backend.

=== Almacenamiento

El almacenamiento de archivos es una pieza central en una plataforma como Nemsy, donde los usuarios suben y descargan documentos de forma continua. Se evaluaron dos enfoques para gestionar estos archivos.

La opción más simple es almacenar los archivos directamente en el sistema de ficheros del VPS. Es inmediata de implementar y no introduce dependencias externas, pero presenta limitaciones importantes,  el espacio en disco de un VPS es limitado y caro por gigabyte, y más importante, los ficheros quedan ligados a una sola máquina y cualquier migración implica mover manualmente todo el contenido.

El almacenamiento de objetos es el enfoque estándar en la industria para este tipo de casos. AWS S3 es el servicio de referencia y su API se ha convertido en estándar de facto, pero su modelo de precios incluye costes de egreso que pueden resultar en facturas impredecibles en una plataforma orientada a descargas. Hetzner Object Storage ofrece la misma API compatible con S3 y un modelo de precios más predecible, con un coste fijo mensual por TB almacenado que incluye tráfico sin cargos adicionales por egreso. Al estar ubicado en centros de datos europeos, facilita además el cumplimiento del RGPD, un aspecto relevante para una plataforma que almacena documentos de usuarios de la Unión Europea.

La integración se realiza a través de la librería `minio-go`, que implementa el protocolo S3 de forma genérica y permite conectar con cualquier proveedor compatible mediante variables de entorno, sin cambios en el código.

=== Despliegue

La plataforma se despliega en un VPS con recursos limitados, por lo que la solución de despliegue debía ser ligera, reproducible y fácil de mantener por una sola persona.

Una alternativa habría sido desplegar los servicios manualmente, instalando Go, Node.js y PostgreSQL directamente en el sistema operativo del servidor y gestionando los procesos con `systemd`. Es el enfoque más simple en términos de herramientas, pero también el más frágil, ya que el entorno del servidor se convierte en un estado implícito difícil de reproducir y actualizar una dependencia puede romper el resto.

Kubernetes es la solución estándar para orquestación de contenedores a escala, pero introduce una complejidad operativa desproporcionada para un proyecto de este tamaño. Requiere un clúster, recursos considerables y conocimientos específicos de administración, aspectos que no se justifican cuando la plataforma corre en una sola máquina, pero que sí serían valiosos si en el futuro fuese necesario escalar a múltiples máquinas.

Docker Compose permite definir todos los servicios de la aplicación (backend, frontend y base de datos) en un único fichero `docker-compose.yml`, levantarlos con un solo comando y garantizar que el entorno es idéntico en local y en producción. Cada servicio corre en su propio contenedor aislado, las variables de entorno se gestionan mediante un fichero `.env`, y el estado persistente de PostgreSQL se mantiene en un volumen nombrado. Es la opción que mejor equilibra reproducibilidad y simplicidad en el contexto de este proyecto.

== Arquitectura del sistema

Nemsy sigue una arquitectura cliente-servidor de tres capas. El frontend es una _Single Page Application_ (SPA) desarrollada con SvelteKit que se comunica con el backend exclusivamente a través de una API REST. El backend, implementado en Go con el router Chi, actúa como única puerta de entrada al sistema gestionando la autenticación, la lógica de negocio y el acceso a los dos sistemas de persistencia, PostgreSQL y un almacenamiento de objetos compatible con S3. El conjunto se despliega mediante Docker Compose en un VPS, de forma que el entorno de producción es reproducible e idéntico al de desarrollo local.

#figure(
  {
    diagram(
      node-stroke: .7pt,
      node-corner-radius: 4pt,
      node-inset: 8pt,
      spacing: (-1cm, 2cm),
      node((0, 0), align(center)[*SvelteKit SPA*], name: <spa>, fill: rgb("#dbeafe")),
      node((0, 2), align(center)[*Go / Chi* \ _(API REST)_], name: <api>, fill: rgb("#dcfce7")),
      node((2, 1), align(center)[*Google OAuth2*], name: <google>, fill: rgb("#fef9c3"), stroke: (
        dash: "dashed",
      )),
      node((-1, 4), align(center)[*PostgreSQL*], name: <db>, fill: rgb("#dcfce7")),
      node((1, 4), align(center)[*Hetzner S3* \ _(Object Storage)_], name: <s3>, fill: rgb("#fef9c3"), stroke: (
        dash: "dashed",
      )),
      edge(<spa>, <api>, "<->", [REST / JSON \ Cookie JWT], label-side: right, label-sep: 6pt),
      edge(<spa>, <google>, "->", [redirect], label-side: left, label-sep: 6pt),
      edge(<google>, <api>, "->", [callback], label-side: left, label-sep: 6pt),
      edge(<api>, <db>, "->", [pgx / sqlc], label-side: right, label-sep: 6pt),
      edge(<api>, <s3>, "->", [minio-go], label-side: left, label-sep: 6pt),
    )
    v(0.8em)
    align(center, grid(
      columns: 3,
      column-gutter: 1.5em,
      row-gutter: 0.4em,
      box(fill: rgb("#dbeafe"), stroke: .7pt, radius: 2pt, width: 0.75em, height: 0.75em),
      box(fill: rgb("#dcfce7"), stroke: .7pt, radius: 2pt, width: 0.75em, height: 0.75em),
      box(fill: rgb("#fef9c3"), stroke: (dash: "dashed", thickness: .7pt), radius: 2pt, width: 0.75em, height: 0.75em),

      text(size: 8pt)[Navegador], text(size: 8pt)[VPS], text(size: 8pt)[Servicio externo],
    ))
  },
  caption: [Diagrama de componentes de la arquitectura de Nemsy.],
) <fig:arquitectura>

=== Frontend

El frontend está construido con SvelteKit, que organiza la aplicación en torno a un sistema de enrutamiento basado en el sistema de ficheros: cada carpeta dentro de `src/routes/` define una ruta, y los ficheros con nombres especiales (`+page.svelte`, `+layout.svelte`, `+page.server.ts`) tienen roles concretos dentro del ciclo de vida de la página. La @tab:rutas recoge las rutas de la aplicación.

#figure(
  {
    set par(justify: false)
    table(
      columns: (auto, 1fr),
      align: left,
      table.header([*Ruta*], [*Descripción*]),
      [`/`],
      [Página de inicio: _hero_ de bienvenida para usuarios no autenticados; lista de asignaturas y recursos para usuarios autenticados.],

      [`/search`], [Búsqueda global de recursos mediante Full Text Search.],
      [`/create`], [Formulario de subida de un nuevo recurso con sus archivos.],
      [`/user/[slug]`], [Perfil público de un usuario y sus recursos compartidos.],
      [`/auth`], [Pantalla de inicio de sesión con Google OAuth2.],
      [`/admin`], [Panel de administración para gestionar reportes (solo administradores).],
    )
  },
  caption: [Rutas de la aplicación frontend.],
) <tab:rutas>

El fichero `+layout.svelte` de la raíz actúa como _shell_ de toda la aplicación y define dos disposiciones de navegación completamente distintas según el dispositivo. En escritorio se muestra una barra de navegación superior clásica con los enlaces principales centrados y el perfil de usuario a la derecha. En móvil esta barra desaparece y es sustituida por una barra de navegación fija en la parte inferior de la pantalla, siguiendo el patrón habitual en aplicaciones móviles, acompañada de un botón de acción flotante (FAB) para subir un recurso. Esta separación es un cambio de paradigma de navegación adaptado a cada contexto de uso. La interfaz también se adapta en función del estado de autenticación expuesto por `data.me`. La ruta `/auth` queda excluida de este shell mediante su propio `+layout.svelte` independiente, de forma que la pantalla de inicio de sesión se renderiza sin navegación.

Las páginas que necesitan datos del backend utilizan un fichero `+page.server.ts` con una función `load`, que SvelteKit ejecuta en el servidor antes de renderizar la página. La función accede a las cookies de sesión y al resultado del `load` del layout padre mediante `parent()`, evitando repetir la llamada de autenticación en cada página y garantizando que la primera carga llegue al navegador ya con los datos.

=== Backend

El backend es un servidor HTTP escrito en Go que expone la API REST en el puerto 8080. Está organizado en paquetes por dominio funcional, cada uno con su propio _handler_. Todos los _handlers_ reciben una instancia del struct `App`, que agrupa las tres dependencias compartidas del sistema: el cliente de base de datos (`Queries`, generado por sqlc), el _pool_ de conexiones a PostgreSQL (`DB`, para transacciones) y el cliente S3 (`Storage`). Este patrón evita la necesidad de un framework de inyección de dependencias, manteniendo el control explícito sobre las dependencias sin añadir capas de abstracción innecesarias.

#figure(
  ```go
  type App struct {
      DB      *pgxpool.Pool
      Queries QuerierWithTx
      Storage *storage.S3Client
  }
  ```,
  caption: [Struct `App` que agrupa las dependencias compartidas del backend.],
  supplement: [Código],
) <cod:app-struct>


Los paquetes del backend son los siguientes:

#figure(
  {
    set par(justify: false)
    table(
      columns: (auto, 1fr),
      align: left,
      table.header([*Paquete*], [*Descripción*]),
      [`auth`],
      [Implementa el flujo OAuth2 con Google, la generación y validación de tokens JWT y el middleware de autenticación. También expone el middleware `AdminOnly` para restringir el acceso a rutas administrativas.],

      [`resources`],
      [Gestiona el ciclo de vida completo de los recursos: creación con subida de archivos a S3, consulta, descarga (tanto del paquete completo como de ficheros individuales), eliminación y sistema de reportes.],

      [`users`],
      [Expone el perfil del usuario autenticado y permite actualizar su universidad, estudio y asignaturas fijadas.],

      [`studies`\ `universities`],
      [Proporcionan endpoints de consulta y búsqueda por texto sobre estudios y universidades.],

      [`admin`],
      [Rutas protegidas exclusivamente para administradores que permiten revisar y gestionar los reportes de recursos.],

      [`storage`],
      [Encapsula el cliente `minio-go` para interactuar con cualquier proveedor S3-compatible, configurable mediante variables de entorno.],

      [`db/generated`],
      [Código Go generado automáticamente por sqlc a partir de las consultas SQL escritas a mano en el esquema.],
    )
  },
  caption: [Paquetes del backend y su responsabilidad.],
) <tab:paquetes>

=== Autenticación

La autenticación se delega completamente a Google OAuth2, por lo que el usuario no gestiona credenciales propias en Nemsy, sino que inicia sesión con su cuenta de Google. Una vez autenticado, el backend mantiene la sesión mediante un JSON Web Token firmado y almacenado en una _cookie_ del navegador, que se valida en cada petición por el _middleware_ `AuthMiddleware`. Las rutas administrativas pasan además por un segundo _middleware_ `AdminOnly` que comprueba el rol del usuario. Los detalles internos del flujo (anti-CSRF, validación del _ID Token_, estructura del JWT y cadena de _middlewares_) se desarrollan en @sec:auth-internals.

=== Despliegue

El diagrama de la @fig:arquitectura describe la arquitectura lógica del sistema, pero no cómo se materializa en el servidor. En producción, los tres componentes alojados en el VPS (frontend, backend y base de datos) corren cada uno en su propio contenedor Docker, orquestados por un único fichero `docker-compose.yml`. La @fig:despliegue ilustra esta disposición.

#figure(
  {
    diagram(
      node-stroke: .7pt,
      node-corner-radius: 4pt,
      node-inset: 8pt,
      spacing: (1.4cm, 1cm),

      node((-1, 0), align(center)[*Caddy* \ _reverse proxy + TLS_ \ `:443`], name: <caddy>, fill: rgb("#ede9fe")),
      node((0, 0), align(center)[*frontend* \ _SvelteKit (Node)_ \ `:3000`], name: <fe>, fill: rgb("#dcfce7")),
      node((0, 1), align(center)[*backend* \ _Go / Chi_ \ `127.0.0.1:8081`], name: <be>, fill: rgb("#dcfce7")),
      node((0, 2), align(center)[*db* \ _PostgreSQL 17_ \ `127.0.0.1:5433`], name: <pg>, fill: rgb("#dcfce7")),
      node((-1, 2), align(center)[volumen \ `pgdata`], name: <vol>, fill: rgb("#f5f5f5")),

      node(
        (-1, -0.7),
        box(fill: white, inset: (x: 5pt, y: 1pt), text(
          size: 10pt,
          tracking: 0.4pt,
        )[VPS Hetzner (2 vCPU, 4 GB RAM)]),
        name: <vpslabel>,
        stroke: none,
        fill: none,
        inset: 0pt,
      ),
      node(
        enclose: (<vpslabel>, <caddy>, <fe>, <be>, <pg>, <vol>),
        stroke: (dash: "dotted", thickness: .8pt),
        inset: 14pt,
        corner-radius: 6pt,
      ),

      node((1, 1), align(center)[*Hetzner S3* \ _Object Storage_], name: <s3ext>, fill: rgb("#fef9c3"), stroke: (
        dash: "dashed",
      )),

      edge(<caddy>, <fe>, "->", [HTTP], label-side: left, label-sep: 4pt),
      edge(<fe>, <be>, "->", [HTTP interno], label-side: right, label-sep: 4pt),
      edge(<be>, <pg>, "->", [pgx], label-side: right, label-sep: 4pt),
      edge(<pg>, <vol>, "-", label-side: left, label-sep: 4pt),
      edge(<be>, <s3ext>, "->", [minio-go], label-side: left, label-sep: 4pt),
    )
    v(0.8em)
    align(center, grid(
      columns: 4,
      column-gutter: 1.2em,
      row-gutter: 0.4em,
      box(fill: rgb("#dcfce7"), stroke: .7pt, radius: 2pt, width: 0.75em, height: 0.75em),
      box(fill: rgb("#ede9fe"), stroke: .7pt, radius: 2pt, width: 0.75em, height: 0.75em),
      box(fill: rgb("#f5f5f5"), stroke: .7pt, radius: 2pt, width: 0.75em, height: 0.75em),
      box(fill: rgb("#fef9c3"), stroke: (dash: "dashed", thickness: .7pt), radius: 2pt, width: 0.75em, height: 0.75em),

      text(size: 8pt)[Contenedor en VPS],
      text(size: 8pt)[Proceso en el host],
      text(size: 8pt)[Volumen persistente],
      text(size: 8pt)[Servicio externo],
    ))
  },
  caption: [Arquitectura de despliegue en el VPS con Docker Compose.],
) <fig:despliegue>

Los tres servicios comparten una red interna gestionada por Docker, de forma que se comunican entre sí mediante el nombre del servicio (`db`, `backend`) sin exponer esos puertos al exterior. Los puertos del backend y la base de datos se publican únicamente en la interfaz de _loopback_ (`127.0.0.1:8081` y `127.0.0.1:5433`), accesibles desde el propio VPS para tareas de administración pero no desde Internet. El tráfico HTTPS público llega al frontend a través de Caddy @caddy-docs, un reverse proxy instalado en el host que termina TLS y reenvía las peticiones al contenedor correspondiente. Caddy fue elegido ante  alternativas como Nginx por su gestión automática de certificados TLS mediante Let's Encrypt sin configuración adicional, de esta forma se consiguen renovar los certificados sin necesidad de intervención manual.

El estado persistente de PostgreSQL se almacena en un volumen nombrado `pgdata`, fuera del ciclo de vida del contenedor, permitiendo poder reemplazar los contenedores sin perder los datos. Los archivos subidos por los usuarios no se guardan en el VPS, sino en Hetzner Object Storage a través de la librería `minio-go`. Esto mantiene la máquina prácticamente sin estado.

Toda la configuración sensible como los credenciales de base de datos, el secreto JWT, o las claves de OAuth2 y S3, se inyectan a los contenedores mediante variables de entorno definidas en un fichero `.env` presente únicamente en el servidor. De este modo, el mismo `docker-compose.yml` sirve tanto para desarrollo local como para producción, cambiando solo el contenido del `.env`, y el entorno resulta reproducible con un único comando.

#figure(
  ```yaml
  services:
    db:
      image: postgres:17-alpine
      restart: unless-stopped
      environment:
        POSTGRES_USER: nemsy
        POSTGRES_PASSWORD: ${DB_PASSWORD}
        POSTGRES_DB: nemsy
      volumes:
        - pgdata:/var/lib/postgresql/data
      ports:
        - "127.0.0.1:5433:5432"

    backend:
      build: ./backend
      restart: unless-stopped
      depends_on: [db]
      environment:
        DATABASE_URL: postgresql://nemsy:${DB_PASSWORD}@db:5432/nemsy?sslmode=disable
        JWT_SECRET: ${JWT_SECRET}
        # ... OAuth2 y credenciales S3
      ports:
        - "127.0.0.1:8081:8080"

    frontend:
      build:
        context: ./frontend
        args:
          PUBLIC_API_BASE_URL: ${PUBLIC_API_BASE_URL}
      restart: unless-stopped
      depends_on: [backend]
      ports:
        - "3000:3000"

  volumes:
    pgdata:
  ```,
  caption: [Fragmento del `docker-compose.yml` de Nemsy.],
  supplement: [Código],
) <cod:docker-compose>

== Diseño de la interfaz de usuario

La interfaz de Nemsy se ha diseñado en paralelo al desarrollo del backend, partiendo de una primera versión funcional pero poco refinada que ha ido madurando hasta el lenguaje visual actual. En esta sección se recoge esa evolución y los tres pilares que sostienen el diseño final, el sistema de componentes, la tipografía y la paleta de color, que en conjunto buscan ofrecer una interfaz sobria pero no fría, alineada con el objetivo de competir en experiencia de usuario con plataformas como Wuolah.

=== Evolución del diseño

El diseño de Nemsy evolucionó de forma iterativa a lo largo del desarrollo. La primera versión, visible en la @fig:nemsy-v1, ya establecía la estructura que se mantiene hoy, con islas blancas sobre fondo de color y retícula de tres columnas, pero el lenguaje visual era más informal, con bordes negros gruesos, esquinas redondeadas y fondo azul pálido. A medida que se añadían nuevas pantallas, el diseño fue derivando hacia una estética más sobria, sustituyendo los bordes gruesos por líneas finas, las esquinas redondeadas por rectas y el azul pálido por un gris neutro. La @fig:nemsy-modos muestra el estado actual en los dos modos de visualización disponibles.

#figure(
  image("../imagenes/nemsy_v1.png", width: 100%),
  caption: [Primera versión de la interfaz de Nemsy (enero 2026).],
) <fig:nemsy-v1>

#figure(
  grid(
    columns: 1,
    row-gutter: 0.5em,
    image("../imagenes/nemsy_desplegado.png"),
    image("../imagenes/nemsy_compacto.png"),
  ),
  caption: [Interfaz actual de Nemsy en modo desplegado y modo compacto.],
) <fig:nemsy-modos>

=== Sistema de diseño

La interfaz organiza el contenido en islas blancas sobre un fondo gris claro, con esquinas rectas y bordes finos, buscando transmitir una sensación más ordenada y sobria que la primera versión. El logotipo, mostrado en la @fig:logo, es el elemento visualmente más llamativo y resume la identidad visual de la plataforma: seis cuadrados de colores dispuestos sobre una retícula de $3 times 3$ que forman una escalera ascendente junto al nombre. Esos seis colores no se quedan en el logotipo, sino que se reutilizan como acentos a lo largo de toda la interfaz, lo que evita que la rigidez de la cuadrícula y los bordes rectos resulten monótonos.

#figure(
  image("../imagenes/nemsy_logo.svg", width: 4cm),
  caption: [Logotipo de Nemsy.],
) <fig:logo>

=== Tipografía

La tipografía es _Google Sans Flex_, una fuente variable cargada desde Google Fonts que cubre todos los pesos y tamaños ópticos en un único fichero, evitando así la carga de múltiples variantes. Se eligió por su buena legibilidad a tamaños pequeños y porque sus formas ligeramente redondeadas contrastan con la rectitud de los componentes sin que la interfaz resulte fría.

=== Paleta de color

La paleta se divide en dos grupos. Por un lado, los colores base, una escala neutra de grises (`zinc` de Tailwind CSS) que estructura el fondo, las islas de contenido, los bordes y la jerarquía tipográfica. Por otro, los seis colores de acento heredados directamente del logotipo, también tomados de la paleta de Tailwind, que se aplican en pequeños detalles como fondos de elementos seleccionados, botones de acción e iconos de tipo de archivo. A diferencia del enfoque habitual de elegir un único color de acento, este reparto multicolor consigue que la interfaz, pese a su rigidez geométrica y su sobriedad, mantenga el suficiente contraste cromático como para no resultar aburrida de mirar ni de usar. La @fig:nemsy-busqueda ilustra esta paleta en la página de búsqueda global.

#figure(
  {
    let cell(color, label) = {
      let lum = color.components().at(0)
      let fg = if lum > 55% { rgb("#374151") } else { rgb("#f9fafb") }
      box(
        fill: color,
        stroke: 0.5pt + rgb("#cccccc"),
        width: 100%,
        height: 3.6em,
        inset: 5pt,
        align(bottom + center, text(size: 7.5pt, fill: fg)[#label]),
      )
    }

    stack(
      spacing: 2em,
      {
        text(size: 12pt, fill: rgb("#3f3f46"))[Acentos]
        grid(
          columns: 6,
          column-gutter: 3pt,
          cell(rgb("#93c5fd"), "blue-300"),
          cell(rgb("#d9f99d"), "lime-200"),
          cell(rgb("#fca5a5"), "red-300"),
          cell(rgb("#fde68a"), "amber-200"),
          cell(rgb("#c4b5fd"), "violet-300"),
          cell(rgb("#fdba74"), "orange-300"),
        )
      },
      {
        text(size: 12pt, fill: rgb("#3f3f46"))[Base]
        grid(
          columns: 7,
          column-gutter: 3pt,
          cell(rgb("#ffffff"), "white"),
          cell(rgb("#fafafa"), "zinc-50"),
          cell(rgb("#f4f4f5"), "zinc-100"),
          cell(rgb("#e4e4e7"), "zinc-200"),
          cell(rgb("#d4d4d8"), "zinc-300"),
          cell(rgb("#71717a"), "zinc-500"),
          cell(rgb("#3f3f46"), "zinc-700"),
        )
      },
    )
  },
  caption: [Paleta de color de Nemsy basada en colores por defecto de Tailwind CSS.],
) <fig:paleta>

#figure(
  image("../imagenes/nemsy_busqueda.png", width: 100%),
  caption: [Página de búsqueda global de Nemsy.],
) <fig:nemsy-busqueda>

#figure(
  image("../imagenes/nemsy_hero.png", width: 100%),
  caption: [Página de inicio para usuarios no autenticados.],
) <fig:nemsy-hero>

#figure(
  image("../imagenes/nemsy_onboarding.png", width: 100%),
  caption: [Selección manual de universidad durante el _onboarding_.],
) <fig:nemsy-onboarding>

#figure(
  grid(
    columns: 3,
    column-gutter: 0.5em,
    image("../imagenes/nemsy_movil_inicio.png", width: 100%),
    image("../imagenes/nemsy_movil_busqueda.png", width: 100%),
    image("../imagenes/nemsy_movil_perfil.png", width: 100%),
  ),
  caption: [Vistas móviles: listado de recursos, búsqueda global y perfil de usuario.],
) <fig:nemsy-movil>

== Diseño de la base de datos

El esquema de Nemsy se apoya en nueve tablas relacionales que modelan las entidades principales de la plataforma y las relaciones entre ellas. El diseño sigue la tercera forma normal en lo que respecta a la información de dominio, pero introduce de forma deliberada dos columnas desnormalizadas (`download_count` y `search_vector`) para evitar cálculos repetidos en cada consulta. La @fig:er recoge el modelo entidad-relación resultante.

#figure(
  {
    diagram(
      node-stroke: .7pt,
      node-corner-radius: 4pt,
      node-inset: 6pt,
      spacing: (2cm, 2cm),
      node((0, 0), align(center)[*universities*], name: <uni>, fill: rgb("#fef9c3")),
      node((-1, 1), align(center)[*studies*], name: <stu>, fill: rgb("#fef9c3")),
      node((0, 1), align(center)[*users*], name: <usr>, fill: rgb("#dbeafe")),
      node((-1, 2), align(center)[*subjects*], name: <sub>, fill: rgb("#fef9c3")),
      node((0, 2), align(center)[*resources*], name: <res>, fill: rgb("#dcfce7")),
      node((1, 2), align(center)[*reports*], name: <rep>, fill: rgb("#fee2e2")),
      node((-1, 3), align(center)[*pinned\_subjects*], name: <pin>, fill: rgb("#f5f5f5")),
      node((0, 3), align(center)[*resource\_files*], name: <rf>, fill: rgb("#dcfce7")),

      edge(<uni>, <stu>, "-|>", [1..N], label-side: left, label-sep: 3pt),
      edge(<uni>, <usr>, "-|>", [1..N], label-side: right, label-sep: 3pt),
      edge(<stu>, <sub>, "-|>", [1..N], label-side: left, label-sep: 3pt),
      edge(<stu>, <usr>, "-|>", [1..N], label-side: right, label-sep: 3pt),
      edge(<usr>, <res>, "-|>", [1..N], label-side: right, label-sep: 3pt),
      edge(<sub>, <res>, "-|>", [1..N], label-side: left, label-sep: 3pt),
      edge(<res>, <rf>, "-|>", [1..N], label-side: right, label-sep: 3pt),
      edge(<usr>, <pin>, "-|>", [1..N], label-pos: 0.7, label-side: right, label-sep: 3pt),
      edge(<sub>, <pin>, "-|>", [1..N], label-side: left, label-sep: 3pt),
      edge(<res>, <rep>, "-|>", [1..N], label-side: right, label-sep: 3pt),
      edge(<usr>, <rep>, "-|>", [1..N], label-side: left, label-sep: 3pt),
    )
    v(0.8em)
    align(center, grid(
      columns: 5,
      column-gutter: 1.2em,
      row-gutter: 0.4em,
      box(fill: rgb("#fef9c3"), stroke: .7pt, radius: 2pt, width: 0.75em, height: 0.75em),
      box(fill: rgb("#dbeafe"), stroke: .7pt, radius: 2pt, width: 0.75em, height: 0.75em),
      box(fill: rgb("#dcfce7"), stroke: .7pt, radius: 2pt, width: 0.75em, height: 0.75em),
      box(fill: rgb("#fee2e2"), stroke: .7pt, radius: 2pt, width: 0.75em, height: 0.75em),
      box(fill: rgb("#f5f5f5"), stroke: .7pt, radius: 2pt, width: 0.75em, height: 0.75em),

      text(size: 8pt)[Jerarquía académica],
      text(size: 8pt)[Usuarios],
      text(size: 8pt)[Contenido],
      text(size: 8pt)[Moderación],
      text(size: 8pt)[Tabla de unión],
    ))
  },
  caption: [Diagrama entidad-relación del esquema de Nemsy.],
) <fig:er>

=== Entidades principales

El esquema se articula en torno al eje educativo `universities` $arrow.r$ `studies` $arrow.r$ `subjects`, que modela la jerarquía académica, y al eje de contenido `users` $arrow.r$ `resources` $arrow.r$ `resource_files`, que modela la autoría y el almacenamiento. La tabla `pinned_subjects` materializa la relación N:M entre usuarios y asignaturas fijadas, y `reports` recoge las denuncias sobre recursos. La @tab:entidades resume el papel de cada tabla.

#figure(
  {
    set par(justify: false)
    set text(size: 10pt)
    table(
      columns: (auto, 1fr),
      align: left,
      table.header([*Tabla*], [*Responsabilidad*]),
      [`universities`],
      [Lista de universidades con su dominio de correo (`ucm.es`, `upm.es`, …), usado para asociar automáticamente al usuario al iniciar sesión con Google.],

      [`studies`],
      [Grados o titulaciones ofertados por una universidad. Cada estudio pertenece a una universidad mediante `university_id`.],

      [`subjects`], [Asignaturas que componen un estudio, junto con el curso (`year`) al que pertenecen.],
      [`users`],
      [Usuarios autenticados vía Google. Se almacena el `google_sub` como identificador, el `email`, el `hd` (_hosted domain_) del que se deduce la universidad, un `username` único generado a partir del correo y un campo `role` para distinguir administradores de usuarios corrientes.],

      [`resources`],
      [Apuntes y demás archivos subidos por los usuarios. Cada recurso agrupa uno o varios archivos bajo un mismo `title` y `description`, y mantiene un contador `download_count` y un `search_vector` para la búsqueda de texto completo.],

      [`resource_files`],
      [Archivos individuales que componen un recurso, con su `s3_key` (clave en Object Storage), nombre original y tamaño.],

      [`pinned_subjects`],
      [Relación N:M entre `users` y `subjects` que representa las asignaturas fijadas por cada usuario en su página de inicio. Su clave primaria compuesta `(user_id, subject_id)` evita duplicados sin un índice adicional.],

      [`reports`],
      [Denuncias sobre recursos. La restricción `UNIQUE(resource_id, reporter_id)` impide que un mismo usuario denuncie dos veces el mismo recurso.],
    )
  },
  caption: [Tablas del esquema y su responsabilidad.],
) <tab:entidades>

Todas las claves foráneas se declaran con `ON DELETE CASCADE`, de forma que al eliminar un usuario se borran en cascada sus recursos, archivos, denuncias y asignaturas fijadas, por lo que no quedan filas huérfanas ni es necesario ninguna lógica de limpieza en el backend.

=== Evolución mediante migraciones

El esquema no se definió en un único fichero monolítico, sino que se construyó de forma incremental a medida que crecieron los requisitos de la plataforma. Para gestionar esta evolución se utilizó `golang-migrate` @golang-migrate, una herramienta que aplica migraciones SQL numeradas y mantiene una tabla `schema_migrations` interna para saber qué versión está activa. Cada migración consta de dos ficheros, `NNN_nombre.up.sql` para aplicar el cambio y `NNN_nombre.down.sql` para revertirlo, lo que permite volver a una versión anterior sin intervención manual sobre la base de datos.

La @tab:migraciones recoge el historial completo de migraciones del proyecto, que refleja la evolución del esquema desde la versión inicial hasta el estado actual con cada nueva funcionalidad que se requería modificar de este.

#figure(
  {
    set par(justify: false)
    set text(size: 10pt)
    table(
      columns: (auto, 1fr),
      align: left,
      table.header([*Migración*], [*Cambio introducido*]),
      [`000001_init`], [Esquema inicial con `studies`, `users`, `subjects` y `resources`.],
      [`000002_multi_files`],
      [Extrae los archivos de `resources` a la tabla `resource_files` para permitir varios ficheros por recurso.],

      [`000003_pinned_subjects`], [Tabla `pinned_subjects` para asignaturas fijadas por cada usuario.],
      [`000004_username`], [Sustituye `full_name` y `pfp` por un `username` único generado del correo.],
      [`000005_download_count`], [Añade `download_count` a `resources` para evitar `COUNT(*)` en cada consulta.],
      [`000006_search_vector`], [Añade la columna generada `search_vector` e índice GIN para Full Text Search.],
      [`000007_universities`], [Introduce la tabla `universities` y enlaza `studies` y `users` con ella.],
      [`000008_unaccent_search`], [Integra la extensión `unaccent` en los `search_vector` para ignorar tildes.],
      [`000009_user_role`], [Añade el campo `role` a `users` y la tabla `reports`.],
    )
  },
  caption: [Historial de migraciones del esquema.],
) <tab:migraciones>

=== Búsqueda de texto completo

Una de las decisiones de diseño más relevantes es el uso de las capacidades nativas de Full Text Search de PostgreSQL para implementar la búsqueda global de recursos, sin recurrir a servicios externos como Elasticsearch. La búsqueda se apoya en tres piezas que se combinan en el propio esquema: columnas generadas de tipo `tsvector`, la extensión `unaccent` envuelta en una función `IMMUTABLE`, e índices GIN.

La columna `search_vector` de `resources` es una columna generada y almacenada (`GENERATED ALWAYS ... STORED`) que PostgreSQL recalcula automáticamente en cada `INSERT` o `UPDATE`, eliminando la necesidad de triggers o lógica adicional en el backend. Su contenido combina el título y la descripción del recurso con pesos distintos (`'A'` y `'B'`), de forma que una coincidencia en el título pesa más que una en la descripción al calcular el ranking con `ts_rank`.

Un problema importante que surge al tratar con texto en español son las tíldes, que pese a ser frecuentes en el idioma, los usuarios no siempre tienden a escribirlas al buscar pero si esperan que la búsqueda lo encuentre. La extensión `unaccent` de PostgreSQL elimina los diacríticos, pero no puede usarse directamente dentro de una columna generada porque no está marcada como `IMMUTABLE`. La solución, introducida en la migración `000008`, consiste en envolverla en una función SQL propia (`immutable_unaccent`) que sí lo está, tal y como muestra el fragmento de la @cod:search-vector.

#figure(
  ```sql
  CREATE OR REPLACE FUNCTION immutable_unaccent(text)
  RETURNS text AS $$
      SELECT public.unaccent('public.unaccent', $1)
  $$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;

  ALTER TABLE resources ADD COLUMN search_vector tsvector
      GENERATED ALWAYS AS (
          setweight(to_tsvector('spanish',
              immutable_unaccent(coalesce(title, ''))), 'A') ||
          setweight(to_tsvector('spanish',
              immutable_unaccent(coalesce(description, ''))), 'B')
      ) STORED;

  CREATE INDEX idx_resources_search ON resources USING GIN (search_vector);
  ```,
  caption: [Definición del `search_vector` con pesos y `unaccent`.],
  supplement: [Código],
) <cod:search-vector>

Sobre esta columna se construye un índice GIN (_Generalized Inverted Index_), la estructura recomendada por PostgreSQL para datos `tsvector` @postgresql-gin. Un índice GIN indexa cada _lexema_ de forma independiente, de manera que una consulta con el operador `@@` localiza los recursos coincidentes sin necesidad de escanear toda la tabla. La misma técnica se aplica a la tabla `universities`, aunque en su caso se usa la configuración `'simple'` en lugar de `'spanish'`, ya que los nombres propios no deben reducirse a su raíz como sí conviene hacer con el texto en prosa.

=== Índices adicionales

Además del índice GIN para la búsqueda, el esquema define varios índices B-tree sobre las claves foráneas más consultadas. El índice compuesto `idx_resources_subject_created (subject_id, created_at DESC)` es especialmente relevante ya que sirve para la consulta que lista los recursos de una asignatura ordenados por fecha, permitiendo que PostgreSQL resuelva la operación directamente desde el índice sin ordenación posterior. Los índices por `owner_id` y por `resource_id` en `resource_files` garantizan que las eliminaciones en cascada y las consultas de perfil se ejecuten en tiempo logarítmico, sin necesidad de recorrer la tabla completa.

== Implementación del backend

Una vez establecidas la arquitectura general en la @fig:arquitectura y las elecciones tecnológicas, esta sección entra en los detalles de la implementación. Se describen primero la organización del proyecto y el proceso de arranque del servidor, y a continuación los aspectos técnicamente más relevantes: la generación de código a partir de SQL, el tratamiento transaccional de las operaciones multi-paso, la gestión de archivos contra el almacenamiento de objetos, los detalles internos de la autenticación y, por último, el sistema de moderación.

=== Estructura del proyecto

El backend sigue el _layout_ convencional en Go, que separa los puntos de entrada ejecutables del código reutilizable mediante dos directorios de primer nivel, `cmd/`, que contiene un subdirectorio por cada binario producido por el módulo, e `internal/`, que aloja los paquetes de la aplicación. El compilador de Go aplica una restricción especial sobre `internal/`, impidiendo que sus paquetes sean importados desde fuera del módulo @go-internal-packages, lo que garantiza que la API interna del backend no se filtre como dependencia accidental. La @fig:backend-tree muestra el árbol resultante.

La @fig:backend-tree reproduce la salida del comando `tree` ejecutado sobre la raíz del backend, con los directorios resaltados como en una terminal real.

#figure(
  block(
    fill: rgb("#000000"),
    radius: 4pt,
    inset: (x: 12pt, y: 8pt),
    width: 100%,
    {
      set par(leading: 0.45em)
      align(left, ansi-render(
        read("../imagenes/backend-tree.ansi"),
        theme: terminal-themes.vscode,
        font: "DejaVu Sans Mono",
        size: 8.5pt,
      ))
    },
  ),
  caption: [Salida del comando `tree` sobre la raíz del backend.],
  kind: image,
) <fig:backend-tree>

El directorio `cmd/` aloja cuatro binarios independientes. El principal, `cmd/server`, es el servidor HTTP descrito en el apartado @sec:bootstrap. Los dos siguientes, `cmd/seed-universities` y `cmd/seed-studies`, son utilidades de línea de comandos que cargan respectivamente el listado de universidades españolas y los grados ofertados por cada una; se ejecutan una sola vez durante el despliegue inicial. El último, `cmd/gen-token`, genera tokens JWT firmados con el mismo secreto que el servidor para usarlos en las pruebas de carga con k6 descritas en @sec:k6, evitando así depender del flujo OAuth2 durante esas pruebas.

Dentro de `internal/`, los paquetes se organizan por dominio funcional. El paquete `app` define el _struct_ `App` y la interfaz `QuerierWithTx` que comparten todos los _handlers_, ya introducidos en @cod:app-struct. El paquete `auth` concentra el flujo OAuth2 con Google, la generación y validación de tokens JWT y los dos _middlewares_ de la cadena de autenticación, `AuthMiddleware` y `AdminOnly`. Los paquetes `resources`, `users`, `studies`, `universities` y `admin` agrupan los _handlers_ HTTP correspondientes a cada dominio, siendo `resources` el más extenso por concentrar la lógica de creación de recursos con archivos, descargas, búsqueda y reportes.

Los tres paquetes restantes son de infraestructura. El paquete `storage` encapsula el cliente `minio-go` tras una pequeña fachada, lo que permite reemplazar el proveedor S3 sin tocar el resto del código. El paquete `search` aloja la función `PrefixQuery`, que transforma la entrada de usuario en una expresión `tsquery` compatible con el operador `@@` de PostgreSQL. Finalmente, el paquete `db` se subdivide en tres directorios complementarios: `queries/` con las consultas SQL escritas a mano, `migrations/` con las migraciones numeradas que aplica `golang-migrate` (véase @tab:migraciones), y `generated/` con el código Go que sqlc emite a partir de los dos anteriores.

=== Arranque del servidor <sec:bootstrap>

El binario `cmd/server` concentra la totalidad de la inicialización del backend en una única función `main`, siguiendo el principio de _composition root_ @composition-root: todas las dependencias se construyen en el mismo punto y se inyectan explícitamente en los componentes que las necesitan, sin contenedores de inyección de dependencias ni configuración global oculta. La @fig:bootstrap-flow ilustra las cinco fases del arranque.

#figure(
  {
    set text(size: 9pt)
    diagram(
      node-stroke: .7pt,
      node-corner-radius: 4pt,
      node-inset: 6pt,
      spacing: (0.6cm, 0.8cm),
      node((0, 0), align(center)[1. Carga de\ configuración], name: <cfg>, fill: rgb("#f4f4f5")),
      node((1, 0), align(center)[2. Conexión a\ PostgreSQL], name: <pg>, fill: rgb("#dcfce7")),
      node((2, 0), align(center)[3. Cliente S3], name: <s3>, fill: rgb("#fef9c3")),
      node((2, 1), align(center)[4. Ensamblaje\ de `App`], name: <app>, fill: rgb("#dbeafe")),
      node((1, 1), align(center)[5. Router y\ _listen_], name: <r>, fill: rgb("#ede9fe")),
      edge(<cfg>, <pg>, "->"),
      edge(<pg>, <s3>, "->"),
      edge(<s3>, <app>, "->"),
      edge(<app>, <r>, "->"),
    )
  },
  caption: [Fases del arranque del servidor en `cmd/server/main.go`.],
) <fig:bootstrap-flow>

La configuración se inyecta exclusivamente a través de variables de entorno, siguiendo la metodología _twelve-factor_ @twelve-factor que recomienda mantener una separación estricta entre código y configuración. La @tab:env-vars recoge las variables consumidas por el servidor; cualquier variable obligatoria ausente provoca el aborto inmediato del proceso mediante `log.Fatal`, evitando que el servidor arranque en un estado inconsistente.

#figure(
  {
    set par(justify: false)
    set text(size: 10pt)
    table(
      columns: (auto, auto, 1fr),
      align: (left, center, left),
      table.header([*Variable*], [*Obligatoria*], [*Propósito*]),
      [`DATABASE_URL`], [Sí], [Cadena de conexión a PostgreSQL, consumida por `pgxpool`.],
      [`JWT_SECRET`], [Sí], [Clave HMAC para firmar y verificar tokens JWT.],
      [`S3_ENDPOINT`], [Sí], [Endpoint del proveedor de almacenamiento de objetos compatible con S3.],
      [`S3_ACCESS_KEY`, `S3_SECRET_KEY`], [Sí], [Credenciales del bucket de almacenamiento.],
      [`S3_BUCKET`], [Sí], [Nombre del bucket donde se almacenan los archivos de los recursos.],
      [`S3_USE_SSL`], [No], [Habilita TLS contra el endpoint S3. Por defecto activado.],
      [`ALLOWED_ORIGIN`],
      [No],
      [Origen permitido para CORS y _redirect_ tras el _login_. Por defecto `http://localhost:5173` en desarrollo.],

      [`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`], [Sí], [Credenciales del cliente OAuth2 registrado en Google Cloud.],
    )
  },
  caption: [Variables de entorno consumidas por el servidor.],
) <tab:env-vars>

Tras validar la configuración, se inicializa el _pool_ de conexiones a PostgreSQL mediante `pgxpool.New`, que abre y reutiliza un conjunto de conexiones físicas a la base de datos. Sobre este _pool_ se construye el _querier_ generado por sqlc (`db.New(pool)`), que es la implementación concreta de la interfaz `QuerierWithTx` introducida en @cod:app-struct. A continuación se instancia el cliente S3 y, con las tres dependencias disponibles, se ensambla el _struct_ `App` que se inyectará en cada _handler_.

La etapa final construye el _router_ Chi y registra las rutas en tres grupos diferenciados según el _middleware_ que les aplica, como muestra la muestra de @cod:chi-routes. Esta separación se apoya en la capacidad de Chi de anidar grupos de rutas con _middlewares_ independientes, permitiendo que las rutas públicas de autenticación, las rutas protegidas por JWT y las rutas exclusivas de administración convivan en un mismo árbol sin condicionales repetidos en cada _handler_.

#figure(
  ```go
  // rutas públicas (sin autenticación)
  r.Get("/auth/login",    authHandler.LoginHandler)
  r.Get("/auth/callback", authHandler.CallbackHandler)
  r.Post("/auth/logout",  authHandler.LogoutHandler)

  // rutas protegidas (JWT validado en cada petición)
  r.Group(func(r chi.Router) {
      r.Use(mw.Middleware)
      r.Get("/api/me", usersHandler.MeHandler)
      // ...

      // solo administradores
      r.Group(func(r chi.Router) {
          r.Use(auth.AdminOnly)
          r.Get("/api/admin/reports", adminHandler.ListReports)
      })
  })
  ```,
  caption: [Estructura de grupos de rutas en Chi con _middlewares_ anidados.],
  supplement: [Código],
) <cod:chi-routes>

El servidor se lanza en una _goroutine_ independiente para que la _goroutine_ principal pueda quedar bloqueada a la espera de una señal del sistema operativo (`SIGINT` o `SIGTERM`). Al recibirla, el proceso cierra el servidor de forma ordenada antes de devolver el control, evitando interrumpir peticiones en curso y permitiendo que `defer pool.Close()` libere las conexiones a PostgreSQL.

=== Generación de código con sqlc <sec:sqlc>

La capa de persistencia es la que más decisiones de diseño concentra del backend. La elección de sqlc @sqlc-docs frente a un ORM tradicional responde a una preferencia por la transparencia, y a la filosofía de tratar el SQL como fuente de verdad y al código Go como un derivado de este. Este enfoque es bastante más habitual en proyectos Go que en el ecosistema Java, donde el ORM (típicamente JPA) es prácticamente la opción por defecto. La idea es que el desarrollador escriba las consultas como las escribiría en un cliente de PostgreSQL, anotándolas con una directiva especial que indica el nombre y la cardinalidad del resultado y la herramienta las lee y genera funciones Go fuertemente tipadas que las ejecutan, con _structs_ para los parámetros y para las filas devueltas. A diferencia de un _query builder_, que va componiendo el SQL en tiempo de ejecución a partir de llamadas encadenadas, en sqlc el SQL ya está escrito tal cual se envía a PostgreSQL, lo único que se genera automáticamente es el código de pegamento que lo conecta con Go.

#figure(
  grid(
    columns: 2,
    column-gutter: 1em,
    [
      *Entrada* (`queries/resources.sql`):
      ```sql
      -- name: CreateResource :one
      INSERT INTO resources (
          owner_id, subject_id,
          title, description
      ) VALUES (
          $1, $2, $3, $4
      )
      RETURNING id, owner_id, subject_id,
          title, description, created_at,
          download_count;
      ```
    ],
    [
      *Salida* (`generated/resources.sql.go`):
      ```go
      type CreateResourceParams struct {
          OwnerID     int32
          SubjectID   int32
          Title       string
          Description pgtype.Text
      }

      func (q *Queries) CreateResource(
          ctx context.Context,
          arg CreateResourceParams,
      ) (CreateResourceRow, error) { /* ... */ }
      ```
    ],
  ),
  caption: [Consulta SQL anotada con `-- name: ... :one` y código Go generado por sqlc a partir de ella.],
  supplement: [Código],
) <fig:sqlc-codegen>

Este enfoque tiene tres ventajas frente a un ORM. La primera, ya mencionada en @tab:database, es que permite aprovechar funcionalidades específicas de PostgreSQL como `tsvector`, columnas generadas o expresiones de tipos compuestos sin tener que envolverlas en abstracciones genéricas. La segunda es que el SQL queda visible en el repositorio, en lugar de oculto detrás de capas de _builders_ que el desarrollador ha de mentalmente traducir a la consulta real que se ejecuta. La tercera es que cualquier error de sintaxis SQL o de tipos se detecta en el momento de generar el código, no en tiempo de ejecución, desplazando una clase entera de errores del entorno de producción al de desarrollo.

La opción `emit_interface: true` del fichero `sqlc.yaml` instruye a la herramienta para que, además de las funciones, emita la interfaz `Querier` que las agrupa, recogida parcialmente en la @cod:querier. Esta interfaz es el contrato que cumple la implementación generada (`*Queries`) y, fundamentalmente, el que cualquier _mock_ de pruebas debe cumplir también. Esta decisión es la que habilita la estrategia de _testing_ del paquete `auth` y de los _handlers_ HTTP, descrita en @sec:tests-backend.

#figure(
  ```go
  type Querier interface {
      CreateResource(ctx context.Context, arg CreateResourceParams) (CreateResourceRow, error)
      CreateResourceFile(ctx context.Context, arg CreateResourceFileParams) (ResourceFile, error)
      DeleteResource(ctx context.Context, arg DeleteResourceParams) error
      GetResourceWithOwner(ctx context.Context, id int32) (GetResourceWithOwnerRow, error)
      ListResourcesBySubjectWithOwnerPaginated(ctx context.Context,
          arg ListResourcesBySubjectWithOwnerPaginatedParams) ([]ListResourcesBySubjectWithOwnerPaginatedRow, error)
      // ...
  }
  ```,
  caption: [Fragmento de la interfaz `Querier` generada por sqlc.],
  supplement: [Código],
) <cod:querier>

Sobre la interfaz `Querier` generada por sqlc, el paquete `app` define una extensión propia llamada `QuerierWithTx` que añade un único método, `WithTx(tx pgx.Tx) *Queries`, ya introducido en @cod:app-struct. Este método permite obtener una nueva instancia del _querier_ asociada a una transacción concreta, manteniendo la misma API que la versión sin transacción. La utilidad de esta extensión se materializa en el siguiente apartado.

=== Creación de un recurso: transacciones y compensación <sec:create-resource>

La creación de un recurso es la operación más compleja de la API porque atraviesa los dos sistemas de persistencia simultáneamente: PostgreSQL (que almacena los metadatos del recurso y el listado de archivos asociados) y el almacenamiento de objetos S3 (donde residen los bytes de cada archivo). Cualquier fallo a mitad del proceso ha de dejar la plataforma en un estado consistente, sin filas de `resource_files` apuntando a objetos inexistentes ni objetos huérfanos en el _bucket_ que ningún registro referencie.

El problema fundamental es que PostgreSQL y S3 son dos sistemas independientes, sin un coordinador transaccional común que los abarque a ambos. La estrategia adoptada se inspira en el patrón de _saga_ con compensación @saga-pattern: la operación se divide en pasos, y cualquier fallo en un paso intermedio dispara acciones compensatorias que deshacen los pasos previos. La @fig:create-resource-flow ilustra el flujo completo.

#figure(
  {
    set text(size: 9pt)
    pad(x: -0.5cm, chronos.diagram({
      chronos._par("c", display-name: "Cliente")
      chronos._par("h", display-name: "Handler")
      chronos._par("db", display-name: "PostgreSQL")
      chronos._par("s3", display-name: "S3")

      chronos._seq("c", "h", comment: [POST /api/resources \ multipart])
      chronos._seq("h", "db", comment: [BEGIN])
      chronos._seq("h", "db", comment: [INSERT resources])
      chronos._seq("db", "h", comment: [id], dashed: true)
      chronos._loop("por cada archivo", {
        chronos._seq("h", "s3", comment: [PutObject])
        chronos._alt("error S3", {
          chronos._seq("h", "s3", comment: [DeleteMultiple\ (claves previas)])
          chronos._seq("h", "db", comment: [ROLLBACK])
          chronos._seq("h", "c", comment: [500 Internal], dashed: true)
        })
        chronos._seq("h", "db", comment: [INSERT resource_files])
      })
      chronos._seq("h", "db", comment: [COMMIT])
      chronos._seq("h", "c", comment: [201 Created], dashed: true)
    }))
  },
  caption: [Creación de un recurso con varios archivos, mostrando el camino de éxito y la rama de compensación ante un fallo en S3.],
) <fig:create-resource-flow>

El _handler_ comienza abriendo una transacción con `h.app.DB.Begin` y registrando inmediatamente un `defer tx.Rollback`. Esta línea es fundamental: garantiza que, si la función retorna por cualquier camino antes del `Commit`, la transacción se descarta automáticamente. PostgreSQL ignora el `Rollback` posterior si el `Commit` ya se ha ejecutado con éxito, de forma que el `defer` actúa como red de seguridad sin penalizar el camino feliz.

#figure(
  ```go
  tx, err := h.app.DB.Begin(r.Context())
  if err != nil { /* 500 */ }
  defer tx.Rollback(r.Context()) // red de seguridad
  qtx := h.app.Queries.WithTx(tx)

  resource, err := qtx.CreateResource(r.Context(), db.CreateResourceParams{
     // ...
  })
  if err != nil { /* 500 */ }

  var uploadedKeys []string // journal para la compensación
  for _, fh := range files {
      s3Key := fmt.Sprintf("resources/%d/%s", resource.ID, sanitizeFilename(fh.Filename))
      if err := h.app.Storage.Upload(r.Context(), s3Key, f, fh.Size, contentType); err != nil {
          h.cleanupS3(r, uploadedKeys) // compensación
          http.Error(w, "...", http.StatusInternalServerError);
          return
      }
      uploadedKeys = append(uploadedKeys, s3Key)

      if _, err := qtx.CreateResourceFile(r.Context(), db.CreateResourceFileParams{
          // ...
      }); err != nil {
          h.cleanupS3(r, uploadedKeys) // compensación
          http.Error(w, "...", http.StatusInternalServerError);
          return
      }
  }

  if err := tx.Commit(r.Context()); err != nil {
      h.cleanupS3(r, uploadedKeys) // compensación
      http.Error(w, "...", http.StatusInternalServerError);
      return
  }
  ```,
  caption: [Creación de un recurso con compensación en S3 (`internal/resources/handler.go`).],
  supplement: [Código],
) <cod:create-resource>

Sobre esa transacción se construye un _querier_ alternativo mediante `WithTx(tx)`. Todas las consultas ejecutadas a través de `qtx` participan automáticamente en la transacción, mientras que las llamadas que pudieran hacerse contra el _querier_ original seguirían viendo el estado anterior al `Begin`. Este patrón permite escribir el resto del _handler_ sin diferenciar entre operaciones transaccionales y no transaccionales: la API de ambos _queriers_ es exactamente la misma gracias a la interfaz generada por sqlc.

El bucle de archivos alterna inserciones en S3 y en la base de datos. Cada subida a S3 que tiene éxito se registra en la lista local `uploadedKeys`, que actúa como _journal_ de las acciones que requerirían compensación si algo fallase a partir de ese punto. La función auxiliar `cleanupS3` invoca `Storage.DeleteMultiple` con esa lista, aprovechando el endpoint _bulk_ de la API S3 para borrar todos los objetos huérfanos en una única petición. Es importante destacar que el `Rollback` automático de PostgreSQL es suficiente para limpiar las filas de `resource_files` insertadas con `qtx`, pero no afecta a S3, motivo por el cual la compensación explícita es necesaria.

Existe una ventana muy pequeña en la que el sistema podría quedar inconsistente: si el `Commit` final tiene éxito en PostgreSQL pero la respuesta no llega al cliente, el cliente reintentará la operación y se crearán archivos duplicados con el mismo contenido pero distinta `s3_key`. Esta posibilidad se acepta como _trade-off_ frente a la complejidad de implementar idempotencia mediante claves de cliente, decisión razonable dado que el coste de un duplicado ocasional es bajo y el usuario puede borrarlo manualmente.

=== Descarga de archivos con redirección y empaquetado en _streaming_ <sec:download>

La descarga es la operación dual a la creación y plantea un problema distinto, ya que los recursos pueden contener un único fichero o varios y los ficheros pueden llegar a pesar 100 MB, por lo que volcar todos los bytes en memoria del backend antes de enviarlos al cliente sería tanto un desperdicio de RAM como un cuello de botella de latencia, sobre todo en un VPS con 4 GB compartidos entre todos los servicios. Por ello, los dos endpoints de descarga (`/api/resources/{id}/download` para el paquete completo y `/api/resources/{id}/files/{fileId}/download` para un único archivo) se implementan con dos estrategias complementarias que evitan en todo momento mantener un fichero entero en memoria.

El primer endpoint adapta su comportamiento al número de ficheros del recurso. Si solo hay uno, no tiene sentido envolverlo en un ZIP, así que el _handler_ genera una URL prefirmada de S3 con 15 minutos de validez y devuelve un `307 Temporary Redirect` apuntando a esa URL. El navegador del usuario sigue la redirección y descarga el fichero directamente desde el _bucket_, sin que el tráfico atraviese el backend. La cabecera `response-content-disposition` incluida en la URL prefirmada (gestionada en `storage/s3.go`) garantiza que el navegador respete el nombre original del fichero al guardarlo, en lugar de la `s3_key` interna.

#figure(
  ```go
  if len(files) == 1 {
      presigned, err := h.app.Storage.GetPresignedURL(
          r.Context(), files[0].S3Key, 15*time.Minute, files[0].FileName,
      )
      if err != nil {
          http.Error(w, "download error", http.StatusInternalServerError)
          return
      }
      http.Redirect(w, r, presigned, http.StatusTemporaryRedirect)
      return
  }
  ```,
  caption: [Descarga de un único fichero mediante URL prefirmada de S3.],
  supplement: [Código],
) <cod:download-single>

Cuando el recurso contiene varios ficheros, no es posible delegar el empaquetado en S3, así que el backend construye un ZIP al vuelo. El _handler_ instancia un `zip.Writer` apuntando directamente al `http.ResponseWriter` y, para cada fichero, abre un _stream_ de lectura contra S3 con `Storage.GetObject` y copia los bytes en bloques de 32 KB hacia la entrada correspondiente del ZIP. De este modo, los datos fluyen de S3 a backend y luego al navegador, sin que el proceso retenga más de un buffer de 32 KB en ningún momento. El método de compresión utilizado es `zip.Store` (sin compresión), porque la mayoría de los ficheros que sube el usuario, principalmente PDF y archivos comprimidos, ya están comprimidos y un segundo pase solo añadiría coste de CPU sin reducir tamaño.

#figure(
  ```go
  zw := zip.NewWriter(w)
  defer zw.Close()

  for _, file := range files {
      obj, _, err := h.app.Storage.GetObject(r.Context(), file.S3Key)
      if err != nil {
          return // abandona el ZIP en mitad del envío
      }
      writer, err := zw.CreateHeader(&zip.FileHeader{
          Name: file.FileName, Method: zip.Store,
      })
      if err != nil {
          obj.Close()
          return
      }

      buf := make([]byte, 32*1024)
      for {
          n, readErr := obj.Read(buf)
          if n > 0 { writer.Write(buf[:n]) }
          if readErr != nil { break }
      }
      obj.Close()
  }
  ```,
  caption: [Empaquetado en ZIP construido al vuelo sobre el `http.ResponseWriter`.],
  supplement: [Código],
  placement: auto,
) <cod:download-zip>

El endpoint de descarga individual (`DownloadFile`) sigue una lógica similar pero más sencilla, ya que tras localizar el fichero por su identificador abre el flujo de S3 y lo copia íntegro al `ResponseWriter` con `io.Copy`, dejando que la implementación de la librería estándar maneje los _buffers_ internos. Es la operación que sirve, por ejemplo, las previsualizaciones de PDF dentro de la propia interfaz, lo que requiere que la cabecera `Content-Disposition` se configure como `inline` en lugar de `attachment` para que el navegador renderice el fichero en lugar de proponer guardarlo.

Una particularidad de este diseño es que el contador `download_count` solo se incrementa en el endpoint del paquete completo, antes de iniciar la transferencia, y no en `DownloadFile`. Esta decisión refleja la intención del modelo, ya que una descarga representa la intención del usuario de obtener todo el material asociado a un recurso, mientras que la apertura individual de un fichero suele formar parte del flujo de previsualización dentro de la propia interfaz, por lo que contarla como descarga inflaría artificialmente las estadísticas mostradas en el perfil del autor.

=== Detalles internos de la autenticación <sec:auth-internals>

La @fig:oauth-sequence representa el flujo completo de autenticación, desde que el usuario pulsa el botón de _login_ hasta que recibe la _cookie_ de sesión, mostrando las cuatro partes que intervienen y la secuencia de mensajes intercambiados.

#figure(
  {
    set text(size: 10pt)
    pad(x: -1cm, chronos.diagram({
      chronos._par("nav", display-name: "Navegador")
      chronos._par("api", display-name: "Backend")
      chronos._par("google", display-name: "Google OAuth2")
      chronos._par("db", display-name: "PostgreSQL")

      chronos._seq("nav", "api", comment: "GET /auth/login")
      chronos._seq("api", "nav", comment: [302 $arrow.r$ accounts.google.com], dashed: true)
      chronos._seq("nav", "google", comment: "solicitud de autorización")
      chronos._seq("google", "nav", comment: "pantalla de autenticación", dashed: true)
      chronos._seq("nav", "google", comment: "credenciales del usuario")
      chronos._seq("google", "api", comment: "GET /auth/callback?code=...")
      chronos._seq("api", "google", comment: [intercambio código $arrow.r$ token])
      chronos._seq("google", "api", comment: "access token + perfil de usuario", dashed: true)
      chronos._seq("api", "db", comment: "upsert usuario")
      chronos._seq("db", "api", comment: "ok", dashed: true)
      chronos._seq("api", "nav", comment: [Set-Cookie JWT + 302 $arrow.r$ /], dashed: true)
    }))
  },
  caption: [Diagrama de secuencia del flujo de autenticación con Google OAuth2.],
) <fig:oauth-sequence>

Sobre ese flujo, el backend implementa cuatro piezas internas que conviene describir con detalle, ya que cada una resuelve un problema de seguridad concreto. En orden de aparición durante una sesión de usuario son el `StateStore` que protege el flujo OAuth2 frente a ataques CSRF, la generación del token JWT firmado, el `AuthMiddleware` que lo valida en cada petición y el _middleware_ adicional `AdminOnly` que restringe las rutas administrativas.

La primera pieza que entra en juego es el `StateStore`. Cuando el usuario pulsa "iniciar sesión", el `LoginHandler` genera una cadena aleatoria de 16 bytes codificada en base64 y la registra en el almacén con un TTL de cinco minutos antes de redirigir al usuario a la pantalla de Google. Esta cadena viaja como parámetro `state` en la URL de autorización y Google la reenvía intacta al `CallbackHandler` cuando el usuario completa el _login_. El _handler_ comprueba que el `state` recibido estaba en el almacén y lo elimina inmediatamente, por lo que un atacante no podría inducir a un usuario autenticado a ejecutar una autorización maliciosa simplemente enviándole una URL de _callback_ falsa, ya que sin un `state` válido emitido por nosotros la petición se rechaza con `401 Unauthorized` @oauth2-csrf. La implementación del almacén es deliberadamente sencilla, un `map[string]time.Time` protegido por un `sync.Mutex`, suficiente para una sola instancia del backend y sin las complicaciones de un servicio externo como Redis.

#figure(
  ```go
  type StateStore struct {
      m   map[string]time.Time
      mu  sync.Mutex
      ttl time.Duration
  }

  func (s *StateStore) Put(state string) {
      s.mu.Lock()
      defer s.mu.Unlock()
      s.m[state] = time.Now().Add(s.ttl)
  }

  func (s *StateStore) Check(state string) bool {
      s.mu.Lock()
      defer s.mu.Unlock()
      exp, ok := s.m[state]
      if !ok {
          return false
      }
      delete(s.m, state)
      return time.Now().Before(exp)
  }
  ```,
  caption: [Almacén de _state_ OAuth2 con TTL en `internal/auth/statestore.go`.],
  supplement: [Código],
) <cod:statestore>

Una vez verificado el `state`, el `CallbackHandler` intercambia el código de autorización por un _ID Token_ con Google, lo valida criptográficamente con la librería `idtoken` que descarga las claves públicas del servidor de Google, comprueba la firma RS256 y extrae la información del usuario del _payload_. Si es la primera vez que ese correo aparece en la base de datos se crea un nuevo registro intentando un `username` derivado del correo, con sufijos numéricos crecientes en caso de colisión hasta encontrar uno libre. La universidad del usuario se asocia automáticamente buscando el dominio del correo en la tabla `universities`, lo que en la práctica reconoce a un estudiante de `@ucm.es` como miembro de la Complutense sin que tenga que seleccionarla manualmente.

A partir de ese punto la autenticación deja de depender de Google y se pasa a una sesión propia mediante un JSON Web Token @jwt-rfc firmado con HMAC-SHA256, almacenado en una _cookie_ del navegador. Al usar JWT frente a un esquema de sesiones en servidor se mantiene un backend sin estado, ya que cualquier nodo puede validar el token sin necesidad de consultar una base de datos compartida, lo que simplifica la posibilidad de escalar horizontalmente en el futuro. La @tab:jwt-claims recoge los _claims_ que se incrustan en el token.

#figure(
  {
    set par(justify: false)
    set text(size: 10pt)
    table(
      columns: (auto, auto, auto, 1fr),
      align: left,
      table.header([*Claim*], [*Tipo*], [*Origen*], [*Propósito*]),
      [`sub`], [string], [ID Token], [Identificador estable del usuario en Google, no cambia aunque cambie el correo.],
      [`email`], [string], [ID Token], [Correo electrónico del usuario.],
      [`hd`],
      [string],
      [ID Token],
      [_Hosted domain_ del correo (`ucm.es`, `upm.es`, …), usado para asociar la universidad.],

      [`user_id`],
      [int],
      [Tabla `users`],
      [Identificador interno del usuario en Nemsy, usado por los _handlers_ para sus consultas.],

      [`role`], [string], [Tabla `users`], [Vale `user` o `admin`, controla el acceso a las rutas administrativas.],
      [`exp`],
      [int],
      [Backend (now + 7d)],
      [Marca temporal de expiración del token, comprobada por la librería JWT en cada validación.],
    )
  },
  caption: [_Claims_ incluidos en el JWT de sesión de Nemsy.],
) <tab:jwt-claims>

La _cookie_ que lleva el token se emite con tres atributos defensivos. `HttpOnly` impide que JavaScript lea su contenido, lo que neutraliza el robo de sesiones mediante XSS aunque el atacante consiguiera inyectar código en el frontend. `Secure` obliga a que el navegador la envíe únicamente sobre HTTPS. `SameSite=Lax` la excluye de las peticiones _cross-site_ no navegacionales, mitigando ataques CSRF en los _endpoints_ autenticados @owasp-cookies. El alcance se restringe al dominio `.nemsy.org` y la duración a siete días, tras los cuales el `exp` del propio JWT provoca el rechazo del token aunque la _cookie_ siguiera presente.

En cada petición a una ruta protegida el `AuthMiddleware` extrae la _cookie_, parsea el token, comprueba que el método de firma es HMAC y, si la validación es satisfactoria, inyecta tres valores en el `context.Context` de la petición, el `UserInfo`, el `user_id` numérico y el `role`. La comprobación explícita del método de firma defiende contra el clásico ataque de confusión de algoritmos @jwt-alg-confusion en el que un atacante reenvía un token con cabecera `alg: none` o `alg: RS256` con el objetivo de que la librería lo valide con la clave incorrecta. Los tres valores se propagan a los _handlers_ subsiguientes a través de la cadena de _context_ de Go, que es la forma canónica de transmitir información asociada a una petición sin recurrir a variables globales o parámetros adicionales en cada función.

Por último, el _middleware_ `AdminOnly` se anida dentro del grupo protegido por `AuthMiddleware` y constituye una segunda capa que comprueba que el `role` inyectado en el _context_ es exactamente `admin`. Cualquier otro valor, incluido el caso improbable de que el _claim_ esté ausente, se traduce en un `403 Forbidden`. Los dos _middlewares_ actúan en cascada porque responden a preguntas distintas, una de autenticación (quién es el usuario) y otra de autorización (qué puede hacer en cada operación), por lo que tiene sentido mantenerlas como piezas separadas en lugar de mezclarlas en una sola comprobación.

=== Sistema de reportes y moderación <sec:reports>

Cualquier plataforma que aloja contenido subido por usuarios necesita un mecanismo de moderación, tanto por motivos legales como por la propia experiencia de uso, ya que el material académico puede contener errores graves, infringir derechos de autor o incluso, en el peor escenario, aparecer subido como gancho para distribuir un binario malicioso disfrazado de PDF. Nemsy implementa un sistema deliberadamente sencillo en el que cualquier usuario autenticado puede reportar un recurso sospechoso y un grupo reducido de administradores revisa los reportes acumulados, decidiendo en cada caso si descartarlos como falso positivo o eliminar el recurso reportado.

El endpoint `POST /api/resources/{id}/report` recibe un cuerpo JSON con un único campo `reason` que el _frontend_ obtiene de un formulario, lo valida (no puede estar vacío) e inserta una fila en la tabla `reports` con el identificador del recurso, el del usuario que reporta y el motivo. La integridad del sistema se apoya en una restricción `UNIQUE(resource_id, reporter_id)` definida en el esquema, que impide que un mismo usuario reporte dos veces el mismo recurso. El segundo intento devuelve un error de violación de unicidad de PostgreSQL que se traduce en un `500 Internal Server Error` desde el _handler_, lo que en la práctica funciona como protección frente a campañas de _spam_ de reportes coordinadas, ya que un atacante necesitaría una cuenta distinta por cada reporte y la barrera de entrada (autenticarse con Google) es lo suficientemente alta como para desalentar el abuso.

El paquete `internal/admin` agrupa las tres operaciones disponibles para los administradores. La primera, `ListReports`, devuelve una vista paginada de los reportes pendientes con toda la información que el panel de administración necesita para tomar una decisión sin más consultas, incluyendo el título del recurso reportado, el nombre del autor original y el del usuario que lo ha reportado, y el motivo introducido. Esta agregación se resuelve con una única consulta SQL que une las tablas `reports`, `resources` y `users` (esta última dos veces, una por el reporter y otra por el owner), aprovechando la flexibilidad de sqlc para generar funciones tipadas a partir de _joins_ complejos sin las contorsiones que un ORM impondría sobre la misma consulta. Las otras dos operaciones son `DismissReport`, que descarta un reporte concreto sin afectar al recurso, y `DeleteResource`, que elimina el recurso completo cuando el reporte se confirma como legítimo.

#figure(
  {
    set text(size: 9pt)
    pad(x: -0.5cm, chronos.diagram({
      chronos._par("u", display-name: "Usuario")
      chronos._par("a", display-name: "Admin")
      chronos._par("api", display-name: "Backend")
      chronos._par("db", display-name: "PostgreSQL")
      chronos._par("s3", display-name: "S3")

      chronos._seq("u", "api", comment: [POST /api/resources/{id}/report])
      chronos._seq("api", "db", comment: [INSERT reports])
      chronos._seq("api", "u", comment: [201 Created], dashed: true)

      chronos._seq("a", "api", comment: [GET /api/admin/reports])
      chronos._seq("api", "db", comment: [SELECT con JOIN])
      chronos._seq("db", "api", comment: [filas], dashed: true)
      chronos._seq("api", "a", comment: [200 OK + JSON], dashed: true)

      chronos._alt("falso positivo", {
        chronos._seq("a", "api", comment: [DELETE /api/admin/reports/{id}])
        chronos._seq("api", "db", comment: [DELETE FROM reports])
        chronos._seq("api", "a", comment: [204 No Content], dashed: true)
      })
      chronos._alt("reporte legítimo", {
        chronos._seq("a", "api", comment: [DELETE /api/admin/resources/{id}])
        chronos._seq("api", "db", comment: [SELECT s3_keys])
        chronos._seq("api", "db", comment: [DELETE FROM resources (cascade)])
        chronos._seq("api", "s3", comment: [DeleteMultiple(s3_keys)])
        chronos._seq("api", "a", comment: [204 No Content], dashed: true)
      })
    }))
  },
  caption: [Ciclo de vida de un reporte, desde la denuncia del usuario hasta la resolución por parte de un administrador.],
) <fig:report-flow>

La operación `DeleteResource` del administrador conviene examinarla con detalle porque combina dos mecanismos de limpieza distintos. Antes de borrar la fila de `resources`, el _handler_ consulta la lista de claves S3 asociadas al recurso mediante la consulta `ListS3KeysByResource`, que devuelve todos los `s3_key` registrados en la tabla `resource_files`. A continuación borra el recurso de la base de datos, lo que desencadena automáticamente el `ON DELETE CASCADE` declarado en el esquema y arrastra consigo las filas correspondientes de `resource_files` y `reports`. Por último, llama a `Storage.DeleteMultiple` con la lista previamente obtenida para eliminar los objetos del _bucket_ en una única petición. El orden importa, ya que invertir las dos primeras llamadas dejaría el sistema en un estado en el que `s3_keys` ya no se podría obtener (porque la fila habría sido borrada con todo lo que cuelga de ella) pero los objetos seguirían en S3.

Esta operación es la versión administrativa del patrón de compensación introducido en @sec:create-resource, aunque aquí el compromiso es distinto. Un fallo en `DeleteMultiple` después del `DELETE` de PostgreSQL deja objetos huérfanos en S3 sin afectar al funcionamiento del sistema, ya que ninguna fila los referencia, por lo que el _handler_ se limita a registrar el error en el _log_ y devolver `204 No Content` al administrador. La limpieza tardía de esos objetos podría delegarse en una tarea periódica que enumere el _bucket_ y compare con la base de datos, pero por ahora no se ha implementado, ya que el volumen de borrados es reducido y el coste de almacenamiento de los objetos huérfanos resulta despreciable.

== Implementación del frontend

Tras la descripción del backend, esta sección recoge la otra mitad del sistema. El frontend es una aplicación SvelteKit que se encarga de presentar los datos expuestos por la API, gestionar la sesión del usuario y orquestar las interacciones más complejas, en particular la subida de recursos y la búsqueda. Los apartados siguientes recorren la organización del proyecto, el ciclo de vida de una página, el modelo de reactividad de Svelte 5, la comunicación con el backend, los dos flujos de interfaz más representativos (creación y búsqueda) y, por último, la adaptación a móvil y el sistema de componentes reutilizados.

=== Estructura del proyecto

El proyecto sigue la convención de SvelteKit, que distingue tres ámbitos por la ubicación de los ficheros. El directorio `src/routes/` define el árbol de URL mediante carpetas, donde cada `+page.svelte` es la página renderizada y los `+page.server.ts` que la acompañan ejecutan código exclusivamente en el servidor. El directorio `src/lib/` agrupa todo lo reutilizable entre páginas y es accesible desde cualquier punto mediante el alias `$lib`. Y los ficheros sueltos en la raíz de `src/` son los puntos de entrada de la aplicación: `app.html` es la plantilla HTML base, `app.css` carga Tailwind v4 mediante una sola directiva `@import "tailwindcss"`, y `hooks.server.ts` intercepta cada petición entrante antes de que llegue al _router_. La @fig:frontend-tree reproduce la salida de `tree src -L 4 -I node_modules --dirsfirst` ejecutado sobre la raíz del frontend, con los directorios resaltados como en una terminal real.

#figure(
  block(
    fill: rgb("#000000"),
    radius: 4pt,
    inset: (x: 12pt, y: 8pt),
    width: 100%,
    {
      set par(leading: 0.45em)
      align(left, ansi-render(
        read("../imagenes/frontend-tree.ansi"),
        theme: terminal-themes.vscode,
        font: "DejaVu Sans Mono",
        size: 8.5pt,
      ))
    },
  ),
  caption: [Salida de `tree src -L 4 -I node_modules --dirsfirst` sobre la raíz del frontend.],
  kind: image,
) <fig:frontend-tree>

Dentro de `src/lib/`, los componentes reutilizables se concentran en `components/`, las _custom actions_ de Svelte en `actions/`, las imágenes y otros recursos estáticos en `assets/`, y las definiciones compartidas de tipos en `types.ts`. Estas últimas son interfaces TypeScript que reflejan la forma de los DTO que devuelve la API (`User`, `Resource`, `Subject`, `ResourceFile`), de manera que cada respuesta JSON puede tiparse en el punto de consumo sin duplicar declaraciones. La @tab:directorios-frontend resume la responsabilidad de cada directorio.

#figure(
  {
    set par(justify: false)
    table(
      columns: (auto, 1fr),
      align: left,
      table.header([*Directorio*], [*Responsabilidad*]),
      [`src/routes/`],
      [Páginas y _layouts_ de la aplicación. Cada carpeta define una URL y los ficheros con prefijo `+` tienen un rol asignado por SvelteKit (`+page.svelte`, `+page.server.ts`, `+layout.svelte`, `+layout.server.ts`).],

      [`src/lib/components/`],
      [Componentes Svelte reutilizables: visores de PDF, imagen y Markdown, lista de recursos, menú contextual, _avatar_ de usuario y resaltado de coincidencias en búsqueda.],

      [`src/lib/actions/`],
      [_Custom actions_ aplicables a cualquier elemento mediante `use:`. Actualmente alberga `clickOutside`, usada para cerrar menús al pulsar fuera.],

      [`src/lib/types.ts`], [Interfaces TypeScript compartidas que reflejan los DTO de la API.],
      [`hooks.server.ts`],
      [_Middleware_ ejecutado en cada petición SSR antes del _router_, encargado de poblar `event.locals.user` a partir de la cookie de sesión.],

      [`static/`], [Activos servidos tal cual por el servidor, como el `favicon.svg` y los iconos para PWA.],
    )
  },
  caption: [Directorios principales del frontend y su responsabilidad.],
) <tab:directorios-frontend>

=== Ciclo de vida de una página <sec:lifecycle>

Una de las características que distinguen a SvelteKit de un SPA tradicional es que la primera carga de cualquier página se renderiza en el servidor. El navegador recibe HTML completo con los datos ya inyectados, y solo después se hidrata la aplicación para tomar el control de las navegaciones siguientes en el cliente. La @fig:frontend-lifecycle ilustra las cinco fases de una petición a una ruta cualquiera.

#figure(
  {
    set text(size: 9pt)
    diagram(
      node-stroke: .7pt,
      node-corner-radius: 4pt,
      node-inset: 6pt,
      spacing: (0.6cm, 0.8cm),
      node((0, 0), align(center)[1. `hooks.server.ts`\ (cookie → `locals.user`)], name: <h>, fill: rgb("#f4f4f5")),
      node((1, 0), align(center)[2. `+layout.server.ts`\ `load` raíz], name: <l>, fill: rgb("#dcfce7")),
      node((2, 0), align(center)[3. `+page.server.ts`\ `load` específico], name: <p>, fill: rgb("#fef9c3")),
      node((2, 1), align(center)[4. Render SSR\ HTML + datos], name: <r>, fill: rgb("#dbeafe")),
      node((1, 1), align(center)[5. Hidratación\ y navegación cliente], name: <hy>, fill: rgb("#ede9fe")),
      edge(<h>, <l>, "->"),
      edge(<l>, <p>, "->"),
      edge(<p>, <r>, "->"),
      edge(<r>, <hy>, "->"),
    )
  },
  caption: [Fases de la primera carga de una página y transición a navegación cliente.],
) <fig:frontend-lifecycle>

El primer eslabón es el _hook_ `handle` definido en `hooks.server.ts`, que se ejecuta antes que cualquier `load`. Este _hook_ lee la cookie `session_token` enviada por el navegador y, si existe, la reenvía al backend mediante una llamada interna a `/api/me` para resolver el usuario autenticado. El resultado se deposita en `event.locals.user`, una estructura accesible desde cualquier `load` durante la misma petición. Centralizar esta operación en el _hook_ evita que cada página repita la consulta y, lo que es más importante, garantiza una única fuente de verdad sobre la identidad del usuario para toda la cadena de renderizado.

A continuación se ejecuta el `load` del _layout_ raíz, que es el que ven todas las páginas que no estén bajo `/auth`. Su misión es exponer `data.me` al árbol de componentes y, de paso, redirigir al usuario hacia `/auth` cuando ha completado el _login_ con Google pero todavía no ha elegido estudio. Las páginas hijas obtienen este dato sin volver a pedirlo, gracias al patrón `parent()` de SvelteKit.

#figure(
  ```ts
  // src/routes/+layout.server.ts
  export const load: LayoutServerLoad = async ({ fetch, url }) => {
      let me: User | null = null;
      const res = await fetch(`${PUBLIC_API_BASE_URL}/api/me`, {
          credentials: 'include',
      });
      if (res.ok) me = await res.json();

      const isAuthPage = url.pathname.startsWith('/auth');
      if (me && me.studyId == null && !isAuthPage) {
          redirect(302, '/auth');
      }
      return { me };
  };
  ```,
  caption: [_Load_ del _layout_ raíz, que expone el usuario y fuerza la elección de estudio antes de continuar.],
  supplement: [Código],
) <cod:layout-load>

Las páginas que necesitan datos adicionales declaran su propio `+page.server.ts`. Por ejemplo, `/create` consulta las asignaturas fijadas del usuario para poblar el desplegable del formulario, y aprovecha la llamada a `parent()` para reutilizar el `me` ya resuelto en lugar de pedirlo de nuevo. Si el usuario no está autenticado o no ha elegido estudio, la página redirige antes de renderizar, descargando al cliente de cualquier comprobación.

Concluido el `load`, SvelteKit serializa los datos en el HTML y los envía al navegador. La aplicación se hidrata, los _runes_ se inicializan y, a partir de ese momento, cada navegación interna se resuelve en el cliente reemplazando solo la zona de la página afectada. Esta arquitectura SSR-más-hidratación combina lo mejor de ambos mundos. La primera carga es rápida porque el HTML viaja con los datos ya impresos, y las navegaciones posteriores son instantáneas porque no requieren un viaje completo al servidor.

=== Reactividad con runes de Svelte 5 <sec:runes>

El frontend se construyó sobre Svelte 5, la versión que sustituyó el sistema de reactividad implícito por un modelo explícito basado en _runes_. En lugar de detectar dependencias mediante la reasignación de variables declaradas con `let`, Svelte 5 introduce funciones especiales que el compilador reconoce y traduce en señales reactivas. La @tab:runes resume las cuatro empleadas en el proyecto.

#figure(
  {
    set par(justify: false)
    table(
      columns: (auto, 1fr, 1.4fr),
      align: left,
      table.header([*Rune*], [*Descripción*], [*Ejemplo de uso en Nemsy*]),
      [`$state`],
      [Declara un valor reactivo. Cualquier lectura desde la plantilla o desde un `$derived` se vuelve dependiente.],
      [Estado del formulario `/create`: `title`, `description`, `selectedFiles`.],

      [`$derived`],
      [Define un valor calculado a partir de otros estados. Se recomputa automáticamente cuando cambian sus dependencias.],
      [`filesArray = $derived(Array.from(selectedFiles))` para iterar el `Set` en la plantilla.],

      [`$props`],
      [Recibe las _props_ tipadas que el padre pasa al componente.],
      [`let { data } = $props()` en cada `+page.svelte` para acceder al resultado del `load`.],

      [`$effect`],
      [Ejecuta un bloque cada vez que cambian los estados que lee. Útil para sincronizar estado con APIs externas (DOM, `localStorage`).],
      [Persistencia del modo de vista compacto/comforte en `localStorage`.],
    )
  },
  caption: [Runes de Svelte 5 utilizados en el frontend.],
) <tab:runes>

Un caso particularmente ilustrativo es el del formulario de creación, que combina los cuatro mecanismos en pocas líneas. La selección de archivos se almacena en un `Set<File>` reactivo, del que se deriva un array para iterar y, sobre ese array, otro `$derived` calcula el archivo que se mostrará en la previsualización lateral. El usuario puede forzar manualmente cuál ver con un click, lo que actualiza un tercer estado.

#figure(
  ```svelte
  let selectedFiles = $state<Set<File>>(new Set());
  let manualPreviewFile = $state<File | null>(null);

  const filesArray = $derived(Array.from(selectedFiles));
  const previewFile = $derived(
      filesArray.length === 0
          ? null
          : manualPreviewFile !== null && filesArray.includes(manualPreviewFile)
              ? manualPreviewFile
              : filesArray[0]
  );
  ```,
  caption: [Estado y derivaciones del visor de previsualización en `/create`.],
  supplement: [Código],
) <cod:runes-preview>

La diferencia frente al modelo anterior de Svelte es que aquí no hay magia oculta. El compilador no necesita inferir qué variables son reactivas escaneando reasignaciones, sino que basta con que sigan la convención de los _runes_. Esto facilita razonar sobre el código y permite usar estado reactivo dentro de funciones, _stores_ y módulos sin las restricciones del compilador clásico.

=== Comunicación con el backend <sec:api-client>

La aplicación se comunica con el backend Go por dos caminos distintos según el momento del ciclo de vida de la página. Durante el SSR, las llamadas las realiza la función `fetch` que SvelteKit inyecta en cada `load`, una variante especial que reescribe las URL relativas y reenvía las cookies de la petición original. Tras la hidratación, las llamadas las hace directamente el navegador con la API `fetch` estándar, enviando la cookie `session_token` automáticamente al ser de primer nivel de dominio. El @fig:frontend-request ilustra el camino de una llamada autenticada.

#figure(
  {
    set text(size: 9pt)
    pad(x: -0.5cm, chronos.diagram({
      chronos._par("b", display-name: "Navegador")
      chronos._par("k", display-name: "SvelteKit (SSR)")
      chronos._par("h", display-name: "hooks.server.ts")
      chronos._par("a", display-name: "API Go")

      chronos._seq("b", "k", comment: [GET /create\ Cookie: session_token])
      chronos._seq("k", "h", comment: [handle()])
      chronos._seq("h", "a", comment: [GET /api/me\ con cookie])
      chronos._seq("a", "h", comment: [200 User], dashed: true)
      chronos._seq("k", "a", comment: [GET /api/me/subjects])
      chronos._seq("a", "k", comment: [200 Subject\[\]], dashed: true)
      chronos._seq("k", "b", comment: [HTML + datos], dashed: true)
    }))
  },
  caption: [Camino de una petición SSR autenticada hasta la API.],
) <fig:frontend-request>

El _endpoint_ base se inyecta a través de la variable de entorno `PUBLIC_API_BASE_URL`, que Vite expone tanto al servidor como al cliente con el prefijo `PUBLIC_`. En el cliente apunta al dominio público de la API y en el servidor puede apuntar a una dirección interna de la red de contenedores, lo que evita un salto innecesario por el balanceador en producción. La @tab:endpoints-frontend resume los _endpoints_ que el frontend consume agrupados por dominio.

#figure(
  {
    set par(justify: false)
    table(
      columns: (auto, auto, 1fr),
      align: left,
      table.header([*Dominio*], [*Endpoint*], [*Uso*]),
      table.cell(rowspan: 3, align: horizon)[Identidad],
      [`GET /api/me`], [Resolver el usuario autenticado en `hooks.server.ts` y en el _layout_ raíz.],
      [`PATCH /api/me`], [Actualizar universidad, estudio o asignaturas fijadas desde la pantalla de perfil.],
      [`GET /api/me/subjects`], [Poblar el desplegable de asignaturas en `/create` y la lista lateral en `/`.],
      table.cell(rowspan: 6, align: horizon)[Recursos],
      [`POST /api/resources`], [Crear un recurso con archivos en formato `multipart/form-data`.],
      [`GET /api/subjects/{id}/resources`], [Listar los recursos de una asignatura.],
      [`GET /api/resources/search`], [Búsqueda de texto completo paginada (50 resultados por página).],
      [`GET /api/resources/{id}/download`], [Descargar el recurso completo empaquetado en ZIP.],
      [`GET /api/resources/{id}/files/{fileId}/download`], [Descargar un archivo individual del recurso.],
      [`POST /api/resources/{id}/reports`], [Reportar un recurso desde el menú contextual.],
      table.cell(rowspan: 2, align: horizon)[Búsqueda],
      [`GET /api/universities/search`], [Autocompletado de universidad en `/auth`.],
      [`GET /api/studies/search`], [Autocompletado de estudio tras elegir universidad.],
      table.cell(rowspan: 3, align: horizon)[Admin],
      [`GET /api/admin/reports`], [Listado de reportes en el panel de administración.],
      [`POST /api/admin/reports/{id}/resolve`], [Resolver un reporte sin borrar el recurso.],
      [`DELETE /api/admin/resources/{id}`], [Eliminar un recurso reportado.],
    )
  },
  caption: [Endpoints de la API consumidos desde el frontend.],
) <tab:endpoints-frontend>

=== Subida de recursos: formulario multipaso <sec:upload>

La pantalla `/create` es la más compleja del frontend y la que mejor refleja la combinación de _runes_, componentes de terceros y comunicación con la API. El usuario debe elegir una asignatura, asignar un título, redactar una descripción opcional, seleccionar uno o varios archivos y aceptar la cesión de derechos antes de poder enviar el formulario. Mientras compone el envío, una mitad de la pantalla muestra una previsualización del archivo seleccionado renderizada localmente con `URL.createObjectURL`, sin necesidad de subir nada al servidor todavía.

La selección de asignatura emplea el componente `Combobox` de `bits-ui`, que permite escribir para filtrar y conserva el último valor escogido en `localStorage` bajo la clave `lastSubject`, de modo que las subidas consecutivas a la misma asignatura no exigen volver a buscarla. La selección de archivos utiliza el componente `FileUpload` de `melt` con _drag and drop_ y multiselección, que devuelve un `Set<File>` enlazado al estado reactivo del formulario. La previsualización se delega en tres visores propios alojados en `src/lib/components/`, cada uno especializado en un tipo de archivo, según muestra la @tab:visores.

#figure(
  {
    set par(justify: false)
    table(
      columns: (auto, auto, 1fr),
      align: left,
      table.header([*Componente*], [*Tipos*], [*Tecnología*]),
      [`PdfViewer.svelte`], [`.pdf`], [`pdfjs-dist` con renderizado por página y navegación.],
      [`ImageViewer.svelte`], [`.jpg .png .gif .webp`], [Etiqueta `<img>` con encuadre adaptativo.],
      [`MarkdownViewer.svelte`], [`.md .markdown`], [`marked` con sanitización antes del render.],
    )
  },
  caption: [Visores de previsualización empleados en `/create` y en la consulta de recursos.],
) <tab:visores>

#figure(
  grid(
    columns: (1fr, auto),
    column-gutter: 0.8em,
    align: horizon + center,
    image("../imagenes/nemsy_compartir.png", height: 8cm), image("../imagenes/nemsy_movil_compartir.png", height: 8cm),
  ),
  caption: [Formulario de creación de un recurso en escritorio y en móvil.],
) <fig:create-form>

Cuando el usuario pulsa enviar, el formulario construye un `FormData` con los campos textuales y cada archivo, y lo envía al endpoint `POST /api/resources` con `credentials: 'include'`. La respuesta exitosa devuelve el identificador del recurso recién creado, que se utiliza para redirigir al usuario a su perfil mediante `goto`. Los URL de objeto creados durante la previsualización se liberan en un `onDestroy` con `URL.revokeObjectURL` para no fugar memoria al desmontar la página.

=== Búsqueda con _debounce_ y desplazamiento infinito <sec:search-ui>

La búsqueda global en `/search` es una entrada de texto que dispara consultas al _endpoint_ FTS del backend descrito en @sec:tests-backend. Para no saturar la API mientras el usuario teclea, cada cambio en el _input_ programa una llamada con un retardo de 300 milisegundos, y un nuevo cambio en ese intervalo cancela la programada y arranca otra. Este patrón clásico de _debounce_ se implementa con `setTimeout` y `clearTimeout` sobre una variable suelta del módulo, sin necesidad de _runes_.

#figure(
  ```svelte
  let query = $state('');
  let results = $state<Resource[]>([]);
  let debounceTimer: ReturnType<typeof setTimeout>;

  function onInput() {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(() => search(false), 300);
  }
  ```,
  caption: [Implementación del _debounce_ en el _input_ de búsqueda.],
  supplement: [Código],
) <cod:debounce>

La paginación es de tipo _scroll_ infinito. La función `search` acepta un parámetro `append` que, cuando es cierto, calcula el _offset_ a partir de los resultados ya cargados y concatena los nuevos al estado en lugar de reemplazarlo. Un `IntersectionObserver` montado en `onMount` vigila un elemento centinela colocado al final de la lista, y dispara una nueva llamada con `append = true` cada vez que el centinela entra en el _viewport_, siempre que haya más resultados disponibles y no haya otra petición en curso. Las coincidencias en el título y la descripción se resaltan con el componente `HighlightText`, que parte el texto en torno a los términos buscados y envuelve cada coincidencia en un `<mark>` con clases de Tailwind.

=== Responsividad <sec:responsive>

La interfaz se adapta a dos contextos de uso completamente distintos. En escritorio se prioriza la densidad de información y la navegación con el cursor, mientras que en móvil se busca minimizar los _taps_ y aprovechar los gestos. Esto ya se introdujo brevemente en la @tab:rutas, pero conviene detallar los mecanismos que lo hacen posible. La @tab:breakpoints recoge los _breakpoints_ de Tailwind v4 utilizados en el proyecto.

#figure(
  {
    set par(justify: false)
    table(
      columns: (auto, auto, 1fr),
      align: left,
      table.header([*Prefijo*], [*Mínimo*], [*Uso típico en Nemsy*]),
      [_(default)_], [0 px], [Estilos base, asumidos para móvil.],
      [`md:`], [768 px], [Activación de la barra superior y desactivación de la barra inferior.],
      [`lg:`], [1024 px], [Disposición a dos columnas en `/create` y en la consulta de recursos.],
    )
  },
  caption: [_Breakpoints_ de Tailwind utilizados en el frontend.],
) <tab:breakpoints>

#figure(
  grid(
    columns: 1,
    row-gutter: 0.6em,
    image("../imagenes/nemsy_recurso.png", width: 100%),
    align(center, image("../imagenes/nemsy_movil_recurso.png", height: 8cm)),
  ),
  caption: [Misma vista de recurso en escritorio y en móvil.],
) <fig:responsive>

El `+layout.svelte` raíz aplica este principio en su forma más pura. La barra de navegación superior se envuelve en clases `hidden md:flex`, lo que la oculta por defecto y solo la muestra a partir de 768 píxeles. Una segunda barra fija a la parte inferior, con tres iconos grandes para las acciones principales y un botón de acción flotante centrado para subir un recurso, lleva las clases inversas `flex md:hidden`, de manera que ambas se reemplazan limpiamente sin necesidad de _media queries_ explícitas en CSS. Las páginas internas siguen el mismo patrón. Por ejemplo, en `/create` la previsualización lateral se oculta en pantallas pequeñas y se muestra en una pestaña aparte, y en `/search` la rejilla de resultados pasa de cuatro columnas a una sola.

=== Sistema de componentes

El frontend se apoya en una pequeña selección de bibliotecas de componentes _headless_ que aportan accesibilidad y comportamiento sin imponer estilos, dejando que toda la apariencia se resuelva con utilidades de Tailwind. La @tab:libs-frontend resume cada una y su rol.

#figure(
  {
    set par(justify: false)
    table(
      columns: (auto, 1fr),
      align: left,
      table.header([*Biblioteca*], [*Rol*]),
      [`bits-ui`],
      [Primitivas accesibles de UI: `Combobox`, `Dialog`, `Checkbox`, `DropdownMenu`. Cubren la mayoría de los controles de formulario y los modales.],

      [`melt`],
      [Builders de bajo nivel para casos no cubiertos por `bits-ui`. En el proyecto se usa `FileUpload` por su soporte nativo de _drag and drop_ con `Set<File>`.],

      [`phosphor-svelte`],
      [Iconografía completa con _tree-shaking_ por icono, lo que evita cargar el conjunto entero. Cada vista importa solo los iconos que necesita.],

      [`tailwindcss` (v4)],
      [Sistema de utilidades CSS configurado mediante `@import` en `app.css`, sin fichero `tailwind.config.js`.],
    )
  },
  caption: [Bibliotecas de UI utilizadas en el frontend.],
) <tab:libs-frontend>

Por encima de estas primitivas, el directorio `src/lib/components/` aloja diez componentes propios con responsabilidades concretas. `ResourceList` y `ResourceView` son los más usados, pues aparecen tanto en la página de inicio como en los perfiles de usuario y en los resultados de búsqueda, y encapsulan la presentación de un recurso con sus archivos, autor, fecha y estadísticas. `ResourceMenu` despliega el menú contextual de cada recurso sobre la base de `DropdownMenu` de `bits-ui`, e incorpora la _custom action_ `clickOutside` para cerrarse al pulsar fuera. `UserAvatar` resuelve la imagen de perfil con un fallback a las iniciales del usuario cuando Google no devuelve avatar. Los tres visores ya mencionados (`PdfViewer`, `ImageViewer`, `MarkdownViewer`) y el `PdfThumbnail` que genera la miniatura de la primera página del PDF para los listados completan el listado de componentes propios. Esta separación entre primitivas externas y componentes de dominio mantiene los ficheros de las páginas concentrados en la lógica de la vista, mientras que los detalles de presentación quedan encapsulados y reutilizables.

=== Panel de administración <sec:admin-panel>

La ruta `/admin` da acceso a una vista reservada a los usuarios con rol de administrador, encargada de gestionar los reportes que los usuarios envían sobre los recursos compartidos. La protección se aplica en dos capas. En el frontend, el `+page.server.ts` comprueba `me.role === 'admin'` durante el `load` y redirige a la página de inicio en caso contrario, evitando renderizar la página por completo a usuarios sin permiso. En el backend, el _middleware_ `AdminOnly` introducido en @sec:auth-internals rechaza cualquier llamada a `/api/admin/*` con un `403 Forbidden` cuando el JWT del solicitante no contiene el _claim_ de administrador, de modo que la restricción se sostiene aunque el cliente intentara saltarse la comprobación del frontend.

#figure(
  image("../imagenes/nemsy_admin.png", width: 100%),
  caption: [Panel de administración con la lista de reportes pendientes.],
) <fig:admin-list>

La pantalla muestra una tabla con los reportes ordenados por fecha de creación descendente, indicando para cada uno el recurso reportado, el reportante, el motivo y la antigüedad. Cada fila ofrece dos acciones excluyentes. La primera, _descartar_, marca el reporte como atendido sin tocar el recurso, útil cuando el administrador determina que el contenido es legítimo y el reporte infundado. La segunda, _eliminar_, dispara el `DELETE /api/admin/resources/{id}` descrito en @sec:reports tras una confirmación rápida, que borra el recurso y, en cascada, todos sus archivos en S3 y los reportes asociados.

== Pruebas y validación

Para garantizar la corrección y el rendimiento de la plataforma se aplicaron tres niveles de pruebas complementarios, cubriendo los tests unitarios del backend con el paquete `testing` de Go, los tests unitarios y _end to end_ del frontend con Vitest y Playwright, y una prueba de carga con k6 sobre la API desplegada en producción. Esta última no solo valida que el sistema no falla bajo carga, sino que sirve como demostración empírica del rendimiento de la plataforma, aportando los datos que respaldan uno de sus objetivos centrales, ofrecer una experiencia rápida como alternativa a Wuolah.

=== Tests unitarios del backend <sec:tests-backend>

Los tests unitarios del backend están escritos con el paquete `testing` de la librería estándar de Go y `httptest` para simular peticiones HTTP sin levantar un servidor real. Cada paquete define un `mockQuerier` que implementa la interfaz `QuerierWithTx` generada por sqlc, de forma que los tests son completamente independientes de la base de datos y se ejecutan de forma determinista.

Los tests del paquete `auth` cubren la generación y verificación de tokens JWT, la extracción de claims y el comportamiento del middleware ante distintos escenarios, incluyendo petición sin cookie, token con firma incorrecta y token válido. Este último caso verifica además que el middleware inyecta correctamente la información del usuario en el contexto de la petición.

#figure(
  ```go
  func TestAuthMiddleware_ValidToken(t *testing.T) {
      secret := []byte("testsecret")
      tokenStr, _ := GenerateJWTWithUserID(
          UserInfo{GoogleSub: "123456", Email: "test@example.com"},
          42, "user", secret,
      )

      req := httptest.NewRequest("GET", "/protected", nil)
      req.AddCookie(&http.Cookie{Name: "session_token", Value: tokenStr})
      rr := httptest.NewRecorder()

      mw := &AuthMiddleware{Secret: secret}
      handlerCalled := false

      mw.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
          handlerCalled = true
          w.WriteHeader(http.StatusOK)
      })).ServeHTTP(rr, req)

      if rr.Code != http.StatusOK { t.Errorf("expected 200, got %d", rr.Code) }
      if !handlerCalled { t.Error("protected handler was not called") }
  }
  ```,
  caption: [Test del middleware de autenticación con token válido.],
  supplement: [Código],
) <cod:auth-middleware-test>

Los tests del paquete `search` verifican la función `PrefixQuery`, que transforma la entrada del usuario en una expresión compatible con el operador `@@` de PostgreSQL Full Text Search. Los casos incluyen búsquedas con una o varias palabras, eliminación de tildes y caracteres especiales, espacios extra y entrada vacía.

#figure(
  ```go
  func TestPrefixQuery(t *testing.T) {
      tests := []struct{ name, input, want string }{
          {"single word", "matematicas", "matematicas:*"},
          {"multiple words", "algebra lineal", "algebra:* & lineal:*"},
          {"strips accents", "programación", "programacion:*"},
          {"removes specials", "hello! world?", "hello:* & world:*"},
          {"empty input", "", ""},
          {"extra whitespace", "  fisica cuantica  ", "fisica:* & cuantica:*"},
      }
      for _, tt := range tests {
          t.Run(tt.name, func(t *testing.T) {
              got := PrefixQuery(tt.input)
              if got != tt.want {
                  t.Errorf("PrefixQuery(%q) = %q, want %q", tt.input, got, tt.want)
              }
          })
      }
  }
  ```,
  caption: [Tests de la función `PrefixQuery` para Full Text Search.],
  supplement: [Código],
) <cod:search-test>

Los tests de los _handlers_ siguen el mismo patrón: instancian un `mockQuerier` con funciones anónimas que devuelven datos controlados, construyen una petición HTTP con `httptest.NewRequest`, inyectan el contexto de autenticación manualmente y verifican tanto el código de estado como el cuerpo de la respuesta.

=== Tests unitarios del frontend

Los tests unitarios del frontend se escribieron con Vitest @vitest-docs y se centran en los dos tipos de lógica que pueden probarse de forma aislada, los componentes de interfaz y las acciones de Svelte.

El componente `HighlightText` resalta la subcadena buscada dentro de un texto envolviéndola en un elemento `<mark>`. Sus tests verifican los tres casos posibles, que resalta correctamente ignorando mayúsculas y tildes, que no introduce ningún `<mark>` cuando no hay coincidencia, y que tampoco lo hace con una búsqueda vacía.

#figure(
  ```typescript
  it('highlights the matching substring', async () => {
      render(HighlightText, { text: 'Álgebra Lineal', query: 'lineal' });
      const mark = page.getByRole('mark');
      await expect.element(mark).toHaveTextContent('Lineal');
  });

  it('renders plain text when there is no match', async () => {
      const { container } = render(HighlightText, { text: 'Cálculo', query: 'física' });
      expect(container.querySelectorAll('mark').length).toBe(0);
  });
  ```,
  caption: [Tests unitarios del componente `HighlightText`.],
  supplement: [Código],
) <cod:highlight-test>

La acción `clickOutside` detecta clics fuera de un elemento del DOM y emite un evento `outclick`, usado para cerrar menús desplegables. Los tests verifican tanto que el evento se dispara al hacer clic fuera del nodo, como que no se dispara al hacer clic dentro, y que deja de escuchar tras llamar a `destroy`.

#figure(
  ```typescript
  it('dispatches outclick when clicking outside the node', () => {
      const node = document.createElement('div');
      const outside = document.createElement('div');
      document.body.appendChild(node);
      document.body.appendChild(outside);

      let fired = false;
      node.addEventListener('outclick', () => { fired = true; });

      const action = clickOutside(node);
      outside.click();

      expect(fired).toBe(true);
      action.destroy!();
  });
  ```,
  caption: [Test unitario de la acción `clickOutside`.],
  supplement: [Código],
) <cod:clickoutside-test>

=== Tests end to end con Playwright

Los tests _end to end_ (E2E) verifican los flujos de la aplicación desde el punto de vista del navegador, ejecutando interacciones reales contra el frontend y el backend levantados localmente. Se escribieron con Playwright @playwright-docs, una herramienta de automatización de navegadores que permite controlar Chrome, Firefox y Safari desde código TypeScript.

El principal reto de los tests E2E de Nemsy es que como la autenticación se delega completamente en Google OAuth2, cuyo flujo no puede automatizarse en un entorno de pruebas, es necesario inyectar directamente una cookie `session_token` con un JWT firmado antes de cada test, usando un helper `generateTestJWT` implementado en TypeScript con la API de criptografía de Node.js. Con esta solución, los tests arrancan ya autenticados sin pasar por el flujo de Google.

#figure(
  ```typescript
  test.beforeEach(async ({ context }) => {
      const jwt = generateTestJWT({
          sub: 'e2e-test-sub', email: 'e2e@test.edu',
          hd: 'test.edu',     user_id: 32, role: 'user'
      });
      await context.addCookies([{
          name: 'session_token', value: jwt,
          domain: 'localhost',   path: '/'
      }]);
  });
  ```,
  caption: [Inyección de cookie JWT antes de cada test E2E.],
  supplement: [Código],
) <cod:e2e-auth>

Los tests están organizados en dos grupos. El grupo `logged out` verifica que la página de inicio muestra el _hero_ y el botón de inicio de sesión cuando no hay sesión activa. El grupo `logged in` cubre los flujos principales, verificando que la página de inicio muestra la barra lateral de asignaturas, que la búsqueda global devuelve resultados al escribir, que el formulario de subida muestra todos sus campos y que el perfil de un usuario es accesible.

#figure(
  ```typescript
  test('search returns results', async ({ page }) => {
      await page.goto('/search');
      await page.waitForLoadState('networkidle');

      const input = page.getByPlaceholder('Buscar recursos de toda la plataforma...');
      await input.click();
      await input.pressSequentially('prueba', { delay: 50 });

      await expect(page.getByText('Recurso de prueba')).toBeVisible({ timeout: 10000 });
  });
  ```,
  caption: [Test E2E del flujo de búsqueda global.],
  supplement: [Código],
) <cod:e2e-search>

=== Validación de rendimiento

Más allá de comprobar que el código funciona, conviene medir cómo se comporta la plataforma bajo condiciones realistas y cómo se percibe desde el navegador del usuario. Para cubrir ambos planos se aplicaron dos validaciones complementarias, una prueba de carga con k6 sobre la API en producción que mide la capacidad del servidor frente a tráfico concurrente, y un análisis con Lighthouse que evalúa la experiencia de usuario en métricas de rendimiento, accesibilidad, buenas prácticas y SEO, comparada directamente con la de Wuolah.

==== Prueba de carga con k6 <sec:k6>

Para validar empíricamente el rendimiento de la API bajo condiciones de uso realistas se realizó una prueba de carga con k6 @k6-docs, una herramienta de código abierto orientada a pruebas de rendimiento de APIs HTTP. El escenario simula usuarios virtuales (VUs) navegando por la aplicación, ejecutando en bucle una de tres acciones de forma aleatoria: consultar su perfil y asignaturas, buscar recursos por texto completo o consultar el detalle de un recurso concreto, con pausas de entre 0,5 y 1,5 segundos entre peticiones para simular el tiempo que un usuario real emplea leyendo.

Un VU de k6 no equivale a un usuario real ya que un usuario real hace peticiones de forma esporádica con largos intervalos de inactividad, mientras que un VU las hace de forma continua. Realmente, en la práctica, 100 VUs con pausas de un segundo generan una carga equivalente a varios miles de usuarios activos simultáneamente. La prueba se ejecutó contra la API desplegada en producción en un VPS de Hetzner con 2 vCPU y 4 GB de RAM, aumentando progresivamente la carga desde 10 hasta 100 VUs a lo largo de ocho minutos.

#figure(
  image("../imagenes/k6.png", width: 100%),
  caption: [Ejecución de la prueba de carga con k6 en el VPS de producción.],
) <fig:k6-run>

#figure(
  {
    set par(justify: false)
    set text(size: 10pt)
    table(
      columns: (auto, auto, auto, auto),
      align: (left, right, right, right),
      table.header([*Endpoint*], [*p50*], [*p90*], [*p95*]),
      [`GET /api/me`], [1,72 ms], [2,27 ms], [2,89 ms],
      [`GET /api/me/subjects`], [2,45 ms], [3,48 ms], [4,18 ms],
      [`GET /api/subjects/{id}/resources`], [1,53 ms], [2,22 ms], [2,72 ms],
      [`GET /api/resources/search`], [1,75 ms], [2,44 ms], [2,93 ms],
      [`GET /api/resources/{id}`], [1,96 ms], [2,81 ms], [3,36 ms],
      [*Global*], [*1,83 ms*], [*2,79 ms*], [*3,45 ms*],
    )
  },
  caption: [Latencias por endpoint en la prueba de carga con k6 (100 VUs, 0 % de errores).],
) <tab:k6>

El modelo de rendimiento RAIL de Google @google-rail establece que las respuestas del servidor deben llegar en menos de 100 ms para que el usuario perciba la interacción como inmediata. Como se puede observar en la @fig:k6-run y en la @tab:k6, la API de Nemsy obtiene un p95 global de 3,45 ms bajo 100 VUs concurrentes, casi treinta veces por debajo de ese umbral, con una tasa de error del 0 %. Cabe destacar que estas latencias corresponden exclusivamente al servidor pero el tiempo que percibe el usuario final incluye además la red, el renderizado del navegador y la ejecución del JavaScript del frontend.

El script de prueba se encuentra en `tests/k6/stress-test.js`. Para ejecutar las rutas protegidas, se incluyó un generador de tokens JWT en `backend/cmd/gen-token/main.go` que firma un token con el mismo secreto que el servidor, evitando la necesidad de pasar por el flujo de Google OAuth2 durante la prueba.

==== Análisis con Lighthouse

Para medir el rendimiento desde la perspectiva del usuario se utilizó Google Lighthouse, ejecutando la auditoría en las mismas condiciones para ambas plataformas mediante Helium @helium-browser, un fork ligero de Chromium sin extensiones instaladas y en modo incógnito, accediendo a la página de inicio tras iniciar sesión. El resultado se recoge en la @fig:lighthouse-comparison.

#figure(
  grid(
    columns: 2,
    column-gutter: 0.5em,
    image("../imagenes/lighthouse_wuolah.png"), image("../imagenes/lighthouse_nemsy.png"),
  ),
  caption: [Comparativa de puntuaciones Lighthouse entre Wuolah y Nemsy.],
) <fig:lighthouse-comparison>

Nemsy obtiene una puntuación de rendimiento de 100 sobre 100, frente al 32 de Wuolah. La diferencia responde principalmente a la ausencia de publicidad y scripts de terceros, que en Wuolah son la principal fuente de bloqueo del hilo principal del navegador, a un bundle de JavaScript mínimo gracias a que Svelte compila los componentes a JavaScript puro sin necesidad de ningún framework en tiempo de ejecución, y a una API en Go que, como demuestran los resultados de la sección anterior, responde en menos de 4 ms en el percentil 95 independientemente de la carga concurrente.
