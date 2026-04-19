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
      chronos._seq("api", "nav", comment: "302 → accounts.google.com", dashed: true)
      chronos._seq("nav", "google", comment: "solicitud de autorización")
      chronos._seq("google", "nav", comment: "pantalla de autenticación", dashed: true)
      chronos._seq("nav", "google", comment: "credenciales del usuario")
      chronos._seq("google", "api", comment: "GET /auth/callback?code=...")
      chronos._seq("api", "google", comment: "intercambio código → token")
      chronos._seq("google", "api", comment: "access token + perfil de usuario", dashed: true)
      chronos._seq("api", "db", comment: "upsert usuario")
      chronos._seq("db", "api", comment: "ok", dashed: true)
      chronos._seq("api", "nav", comment: "Set-Cookie JWT + 302 → /", dashed: true)
    }))
  },
  caption: [Diagrama de secuencia del flujo de autenticación con Google OAuth2.],
) <fig:oauth-sequence>

Una vez completado el flujo, las rutas protegidas pasan por el middleware `AuthMiddleware`, que valida la cookie JWT en cada petición. La detección del centro educativo se realiza a partir del dominio del correo, si el usuario se autentica con una cuenta `@ucm.es`, se asocia automáticamente a la Universidad Complutense de Madrid sin necesidad de seleccionarla manualmente.

Esta separación se refleja directamente en la estructura del router ya que Chi permite anidar grupos de rutas con middlewares independientes, de forma que las rutas públicas de autenticación, las rutas protegidas por JWT y las rutas exclusivas de administración quedan aisladas entre sí.

== Diseño de la base de datos

Explicación del esquema de base de datos...

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
