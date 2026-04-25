#import "@preview/fletcher:0.5.8": diagram, edge, node
#import "@preview/chronos:0.3.0" as chronos
#import "@preview/codly:1.3.0": *
#show: codly-init.with()

= Descripción del Trabajo

#block(
  fill: rgb("#f0f0f0"),
  inset: 1em,
)[
  *Resumen:* En este capítulo se justifican las decisiones tecnológicas y se describe en detalle el desarrollo de la plataforma Nemsy.
]

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

La autenticación se delega completamente a Google OAuth2 por lo que el usuario no crea credenciales propias en Nemsy, sino que inicia sesión con su cuenta de Google. El flujo completo se ilustra en la @fig:oauth-sequence.

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

Una vez completado el flujo, las rutas protegidas pasan por el middleware `AuthMiddleware`, que valida la cookie JWT en cada petición. La detección del centro educativo se realiza a partir del dominio del correo, si el usuario se autentica con una cuenta `@ucm.es`, se asocia automáticamente a la Universidad Complutense de Madrid sin necesidad de seleccionarla manualmente.

Esta separación se refleja directamente en la estructura del router ya que Chi permite anidar grupos de rutas con middlewares independientes, de forma que las rutas públicas de autenticación, las rutas protegidas por JWT y las rutas exclusivas de administración quedan aisladas entre sí.

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

Los tres servicios comparten una red interna gestionada por Docker, de forma que se comunican entre sí mediante el nombre del servicio (`db`, `backend`) sin exponer esos puertos al exterior. Los puertos del backend y la base de datos se publican únicamente en la interfaz de _loopback_ (`127.0.0.1:8081` y `127.0.0.1:5433`), accesibles desde el propio VPS para tareas de administración pero no desde Internet. El tráfico HTTPS público llega al frontend a través de Caddy @caddy-docs, un reverse proxy instalado en el host que termina TLS y reenvía las peticiones al contenedor correspondiente. Caddy se eligió frente a alternativas como Nginx por su gestión automática de certificados TLS mediante Let's Encrypt sin configuración adicional, lo que permite renovar los certificados de forma transparente sin intervención manual.

El estado persistente de PostgreSQL se almacena en un volumen nombrado (`pgdata`), desacoplado del ciclo de vida del contenedor, de forma que se pueden recrear los contenedores sin perder los datos. Los archivos subidos por los usuarios no se guardan en el VPS, sino en Hetzner Object Storage a través de la librería `minio-go`, lo que mantiene la máquina prácticamente sin estado.

Toda la configuración sensible (credenciales de base de datos, secreto JWT, claves OAuth2 y S3) se inyecta a los contenedores mediante variables de entorno definidas en un fichero `.env` presente únicamente en el servidor. De este modo, el mismo `docker-compose.yml` sirve tanto para desarrollo local como para producción, cambiando solo el contenido del `.env`, y el entorno resulta reproducible con un único comando.

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
  caption: [Interfaz actual de Nemsy en modo desplegado (arriba) y compacto (abajo).],
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
        align(bottom + center, text(size: 7.5pt, fill: fg, font: "Courier New")[#label]),
      )
    }

    stack(
      spacing: 2em,
      {
        text(size: 12pt, fill: rgb("#3f3f46"))[Acento]
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
      [Catálogo de universidades con su dominio de correo (`ucm.es`, `upm.es`, …), usado para asociar automáticamente al usuario al iniciar sesión con Google.],

      [`studies`],
      [Grados o titulaciones ofertados por una universidad. Cada estudio pertenece a una universidad mediante `university_id`.],

      [`subjects`], [Asignaturas que componen un estudio, junto con el curso (`year`) al que pertenecen.],
      [`users`],
      [Usuarios autenticados vía Google. Se almacena `google_sub` como identificador estable, el `email`, el `hd` (_hosted domain_) del que se deduce la universidad, un `username` único generado a partir del correo y un campo `role` para distinguir administradores.],

      [`resources`],
      [Publicaciones subidas por los usuarios. Cada recurso agrupa uno o varios archivos bajo un mismo `title` y `description`, y mantiene un contador `download_count` y un `search_vector` para la búsqueda de texto completo.],

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

Todas las claves foráneas se declaran con `ON DELETE CASCADE`, de forma que al eliminar un usuario se borran en cascada sus recursos, archivos, denuncias y asignaturas fijadas, sin dejar filas huérfanas ni necesidad de lógica de limpieza en el backend.

=== Evolución mediante migraciones

El esquema no se definió en un único fichero monolítico, sino que se construyó de forma incremental a medida que crecieron los requisitos de la plataforma. Para gestionar esta evolución se utilizó `golang-migrate` @golang-migrate, una herramienta que aplica migraciones SQL numeradas y mantiene una tabla `schema_migrations` interna para saber qué versión está activa. Cada migración consta de dos ficheros, `NNN_nombre.up.sql` para aplicar el cambio y `NNN_nombre.down.sql` para revertirlo, lo que permite volver a una versión anterior sin intervención manual sobre la base de datos.

La @tab:migraciones recoge el historial completo de migraciones del proyecto, que refleja la evolución natural del esquema desde la versión inicial hasta el estado actual.

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

Detalles de implementación del backend en Go...

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
  caption: [Estructura de grupos de rutas en Chi con middlewares anidados.],
  supplement: [Código],
) <cod:chi-routes>

== Implementación del frontend

Detalles de implementación del frontend en SvelteKit...

== Pruebas y validación

Para garantizar la corrección y el rendimiento de la plataforma se aplicaron tres niveles de pruebas complementarios, cubriendo los tests unitarios del backend con el paquete `testing` de Go, los tests unitarios y _end to end_ del frontend con Vitest y Playwright, y una prueba de carga con k6 sobre la API desplegada en producción. Esta última no solo valida que el sistema no falla bajo carga, sino que sirve como demostración empírica del rendimiento de la plataforma, aportando los datos que respaldan uno de sus objetivos centrales, ofrecer una experiencia rápida como alternativa a Wuolah.

=== Tests unitarios del backend

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

La acción `clickOutside` detecta clics fuera de un elemento del DOM y emite un evento `outclick`, usado para cerrar menús desplegables. Sus tests verifican que el evento se dispara al hacer clic fuera del nodo, que no se dispara al hacer clic dentro, y que deja de escuchar tras llamar a `destroy`.

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

El principal reto de los tests E2E en Nemsy es que la autenticación delega en Google OAuth2, cuyo flujo no puede automatizarse en un entorno de pruebas. La solución adoptada es inyectar directamente una cookie `session_token` con un JWT firmado antes de cada test, usando un helper `generateTestJWT` implementado en TypeScript con la API de criptografía de Node.js. De este modo, los tests arrancan ya autenticados sin pasar por el flujo de Google.

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

==== Prueba de carga con k6

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

El modelo de rendimiento RAIL de Google @google-rail establece que las respuestas del servidor deben llegar en menos de 100 ms para que el usuario perciba la interacción como inmediata. Como se puede observar en la @fig:k6-run y en la @tab:k6, la API de Nemsy obtiene un p95 global de 3,45 ms bajo 100 VUs concurrentes, casi treinta veces por debajo de ese umbral, con una tasa de error del 0 %. Cabe destacar que estas latencias corresponden exclusivamente al servidor, el tiempo que percibe el usuario final incluye además la red, el renderizado del navegador y la ejecución del JavaScript del frontend.

El script de prueba se encuentra en `tests/k6/stress-test.js`. Para ejecutar las rutas protegidas, se incluyó un generador de tokens JWT en `backend/cmd/gen-token/main.go` que firma un token con el mismo secreto que el servidor, evitando la necesidad de pasar por el flujo de Google OAuth2 durante la prueba.

==== Análisis con Lighthouse

Para medir el rendimiento desde la perspectiva del usuario se utilizó Google Lighthouse, ejecutando la auditoría en las mismas condiciones para ambas plataformas mediante Helium @helium-browser, un fork ligero de Chromium sin extensiones instaladas y en modo incógnito, accediendo a la página de inicio tras iniciar sesión. El resultado se recoge en la @fig:lighthouse-comparison.

#figure(
  grid(
    columns: 2,
    column-gutter: 0.5em,
    image("../imagenes/lighthouse_wuolah.png"), image("../imagenes/lighthouse_nemsy.png"),
  ),
  caption: [Comparativa de puntuaciones Lighthouse entre Wuolah (izquierda) y Nemsy (derecha).],
) <fig:lighthouse-comparison>

Nemsy obtiene una puntuación de rendimiento de 100 sobre 100, frente al 32 de Wuolah. La diferencia responde principalmente a la ausencia de publicidad y scripts de terceros, que en Wuolah son la principal fuente de bloqueo del hilo principal del navegador, a un bundle de JavaScript mínimo gracias a que Svelte compila los componentes a JavaScript puro sin necesidad de ningún framework en tiempo de ejecución, y a una API en Go que, como demuestran los resultados de la sección anterior, responde en menos de 4 ms en el percentil 95 independientemente de la carga concurrente.
