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

Descripción de la arquitectura...

== Diseño de la base de datos

Explicación del esquema de base de datos...

== Implementación del backend

Detalles de implementación del backend en Go...

== Implementación del frontend

Detalles de implementación del frontend en SvelteKit...

== Pruebas y validación

Estrategia de testing...
