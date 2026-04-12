= Introducción

#block(
  fill: rgb("#f0f0f0"),
  inset: 1em,
  below: 1.5em,
)[
  *Resumen:* En este capítulo se presenta la motivación del proyecto, los objetivos que se persiguen y la estructura del documento.
]

#pad(left: 3em)[
  #quote(attribution: [Grady Booch], block: true)[
    La calidad de un sistema no está determinada por el poder de sus componentes individuales, sino por cómo se eligen y se ensamblan para satisfacer las necesidades.
  ]
]

== Motivación

Como estudiante de ingeniería de software utilizo una gran cantidad de software distinto en mi día a día; algunos funcionan mejor y otros resultan frustrantes. Es precisamente uno de los segundos lo que me motivó a realizar este Trabajo de Fin de Grado.

Antes de Wuolah, las alternativas se limitaban a plataformas genéricas como Docsity o StudyLib, que no se habían publicitado en España por lo que la cantidad de contenido era casi inexistente, y que tampoco se integraban con centros educativos concretos, o a soluciones informales como grupos de mensajería y drives compartidos.

Wuolah, la plataforma para compartir apuntes mejor integrada y más conocida, solucionó un problema real al ver la necesidad de los estudiantes de tener un lugar donde compartir y encontrar apuntes relevantes para sus asignaturas concretas, de su grado o estudio, en su centro educativo. A pesar de su popularidad el modelo actual que sigue presenta una serie de problemas que perjudican tanto la experiencia de usuario como la calidad del intercambio de información.

Su principal problema es el rendimiento. Al realizar un análisis de la plataforma utilizando Lighthouse, una herramienta de código abierto de Google que audita el rendimiento, la accesibilidad, mejores prácticas y el SEO de cualquier página web (@fig:lighthouse), se observan unos resultados bastante concluyentes.

#figure(
  image("../imagenes/lighthouse_wuolah.png", width: 100%),
  caption: [Análisis del rendimiento de wuolah.com con Google Lighthouse.],
) <fig:lighthouse>

La plataforma obtiene una puntuación de rendimiento de 22 sobre 100, un resultado que muestra un gran problema de optimización y explica la lentitud que se siente al usarla. Esta baja puntuación se puede explicar por el uso de una arquitectura pesada en el lado del cliente y la gran cantidad de anuncios que se cargan en este. Esto empeora significativamente la experiencia del usuario y demuestra la necesidad de un enfoque de diseño más eficiente.

Además, su modelo de negocio basado en publicidad intensiva también perjudica la experiencia. Si bien es comprensible que la plataforma necesite monetizarse, la implementación actual penaliza en exceso al usuario gratuito con largos tiempos de espera para descargar cada recurso, a menos que se pague una suscripción mensual.

Por otro lado los micropagos por descarga que ofrece Wuolah presentan otro problema fundamental. Cuando se introduce una recompensa económica, especialmente cuando es mínima, se corre el riesgo de transformar la motivación de los usuarios; el deseo genuino de ayudar es reemplazado por un interés transaccional de bajo valor. Este enfoque ha sido demostrado como algo que puede llegar a ser contraproducente. La investigación sobre la motivación ha demostrado que las recompensas externas pueden disminuir el interés propio por realizar una tarea, un efecto conocido como "Desplazamiento Motivacional" @Deci1999 @Frey2001.

Además, este modelo de incentivos tiene otra consecuencia negativa para las carreras técnicas. Al limitar las recompensas a los archivos PDF, ya que en estos es en los que se puede incrustar anuncios, se desincentiva a que los estudiantes compartan información en otros formatos más adecuados para ciertas áreas como puede ser en el caso de código, empobreciendo así la variedad y utilidad de los recursos disponibles en la plataforma.

Por último, cabe mencionar también cómo la interfaz actual refleja un problema común en plataformas que reciben un porcentaje significativo de uso desde dispositivos móviles: para facilitar la responsividad, la experiencia en escritorio se ha visto degradada. Como se puede observar en la @fig:ssw1, con una resolución estándar de portátil de 1920x1080 al 100% de zoom, apenas la mitad de la pantalla se dedica al contenido, dejando las barras laterales sobrantes para anuncios. De esa mitad usada, algo más de un tercio está ocupado por una barra lateral con información de poco valor, dejando apenas una fracción del ancho total de la pantalla para lo que el usuario realmente quiere ver.

#figure(
  image("../imagenes/screenshot_wuolah1.png", width: 100%),
  caption: [Captura de pantalla de wuolah.com mostrando la interfaz actual.],
) <fig:ssw1>

Este trabajo busca solucionar todos estos problemas y tiene como objetivo el diseño y desarrollo de un prototipo de plataforma alternativa. La solución propuesta mejorará el rendimiento usando una arquitectura ligera y eficiente con un backend en Go y un frontend con SvelteKit. Para reducir los costes de mantenimiento se usarán servidores privados virtuales (VPS) en vez de plataformas en la nube como AWS. Y se eliminará la publicidad invasiva y los incentivos monetarios para fomentar la colaboración genuina y la compartición de recursos en múltiples formatos.

== Objetivos

El objetivo principal de este proyecto es crear y desplegar un prototipo de una aplicación para compartir recursos académicos como apuntes y ejercicios resueltos entre otros. Para realizarlo se han definido los siguientes objetivos:

+ Diseñar e implementar una API REST en Go que gestione usuarios, recursos y asignaturas.
+ Desarrollar una interfaz web con SvelteKit que ofrezca una experiencia rápida y sin publicidad.
+ Integrar autenticación con Google OAuth2 como método único de acceso, detectando automáticamente el centro educativo del usuario a partir de su dominio de correo.
+ Obtener automáticamente centros educativos y sus asignaturas mediante _web scraping_ y JetBrains SWOT.
+ Utilizar almacenamiento de objetos compatible con S3 para gestionar los archivos subidos por los usuarios.
+ Implementar búsqueda global mediante _Full Text Search_ de PostgreSQL.
+ Desplegar la plataforma de forma portable usando Docker Compose en un VPS.

== Plan de trabajo

El desarrollo del proyecto se ha llevado a cabo siguiendo un enfoque iterativo e incremental con una metodología API-first: para cada funcionalidad se implementaba primero el endpoint en el backend y después la interfaz correspondiente. Para la gestión de tareas se utilizó un tablero Kanban en Taiga. Las fases principales del desarrollo fueron las siguientes:

+ *Prototipado inicial (septiembre - octubre 2025).* Elección de tecnologías, implementación de la autenticación con Google OAuth2, primeras iteraciones del diseño de la interfaz y configuración inicial de la base de datos y el flujo de onboarding.

+ *Diseño de la arquitectura e implementación de las funcionalidades principales (enero - febrero 2026).* Definición de la API REST, sustituyendo un enfoque inicial con GraphQL que resultó innecesario para el proyecto. Desarrollo del scraper de la UCM, implementación de la subida, descarga y previsualización de recursos, soporte para múltiples archivos por recurso y diseño del sistema de vistas.

+ *Funcionalidades avanzadas y refinamiento (marzo 2026).* Perfiles de usuario, búsqueda global con Full Text Search, integración de universidades mediante JetBrains SWOT y web scraping, y mejoras generales de la interfaz.

+ *Pruebas, despliegue y documentación (abril 2026).* Tests unitarios del backend, tests unitarios y end to end del frontend con Playwright, configuración de Docker y Docker Compose, despliegue en VPS y redacción de la memoria.

== Estructura del documento

Este documento está estructurado de la siguiente manera:

- *Capítulo 2. Estado de la Cuestión:* Se analizan las plataformas existentes y las tecnologías evaluadas para el desarrollo del proyecto.
- *Capítulo 3. Descripción del Trabajo:* Se describe en detalle la arquitectura, el diseño y la implementación de la plataforma.
- *Capítulo 4. Conclusiones y Trabajo Futuro:* Se presentan las conclusiones y las posibles líneas de mejora.
