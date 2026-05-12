#import "../template.typ": epigraph

= Estado de la Cuestión

#block(
  fill: rgb("#f0f0f0"),
  inset: 1em,
  below: 1.5em,
)[
  *Resumen:* Este capítulo analiza el estado del arte de las plataformas colaborativas para compartir recursos académicos.
]

#epigraph(
  [Adapta lo que sea útil, rechaza lo que sea inútil y añade lo que sea específicamente tuyo.],
  [Bruce Lee],
)

== Plataformas existentes

A continuación, se analizan las tres plataformas más relevantes para compartir recursos académicos, evaluando su integración con centros educativos, su modelo de monetización y la experiencia de usuario que ofrecen.

=== Wuolah

Wuolah es una plataforma española que ha sabido integrar las asignaturas, cursos y centros educativos para que sus usuarios puedan compartir y acceder a apuntes y exámenes verdaderamente relevantes para ellos. No se centra únicamente en estudios universitarios, también ofrece soporte para E.S.O, Bachillerato, EBAU, Ciclos y Oposiciones. Además, es la única de las plataformas analizadas que ofrece una compensación monetaria a los usuarios que publican sus apuntes, un aspecto cuyas implicaciones ya se han discutido en la motivación de este trabajo.

El proceso de registro es sencillo para lo que cubre la plataforma ya que intenta abarcar mucho más que solo estudios universitarios. Se puede iniciar sesión con correo y contraseña o mediante OAuth2, tras lo cual se selecciona el país, el tipo de estudio, el estudio concreto y el centro educativo. Sin embargo, el último paso requiere aceptar su política de privacidad, cuya presentación incluye patrones oscuros como lenguaje emocional y apelaciones a la urgencia del estudiante (@fig:wuolah-gdpr). Además, junto a la política se solicita consentimiento para recibir publicidad de empresas de sectores ajenos a la educación.

#figure(
  image("../imagenes/wuolah_gdpr.png", width: 100%),
  caption: [Pantalla de aceptación de la política de privacidad de Wuolah.],
) <fig:wuolah-gdpr>

Esto va acompañado de los problemas anteriormente mencionados como el exceso de publicidad que interfiere con el uso de la plataforma, tiempos de espera de hasta medio minuto para que un usuario gratuito pueda descargar un apunte, y una interfaz de escritorio poco eficiente para facilitar la responsividad en móvil. A esto se suma una barra de navegación con demasiada información: si un usuario ya ha indicado que cursa un grado universitario, de poco le sirve tener acceso directo a los apartados de E.S.O, Bachillerato o EBAU (@fig:wuolah-navbar).

#figure(
  image("../imagenes/wuolah_navbar.png", width: 100%),
  caption: [Barra de navegación de Wuolah.],
) <fig:wuolah-navbar>

En conclusión, Wuolah es la plataforma que mejor ha resuelto el flujo de usuario para compartir recursos académicos y, con diferencia, la que mayor volumen de contenido tiene para universidades españolas. Sin embargo, sus defectos han ido acumulándose con el tiempo a medida que la plataforma ha crecido en funcionalidades y ha intensificado su modelo de monetización.

=== Studocu

Studocu es una plataforma fundada en 2013 en los Países Bajos que ha crecido hasta convertirse en la mayor plataforma de apuntes a nivel global. También ofrece integración con centros educativos, aunque algo más superficial que la de Wuolah, permite seleccionar universidad y asignaturas, pero no grado, por lo que asignaturas de mismo nombre compartidas entre grados se agrupan aunque puedan tener un temario diferente. Dejando ese detalle de lado, como se puede ver en la @fig:studocu, la interfaz de escritorio es excelente, aprovecha bien el ancho de la pantalla y tiene una buena densidad de información. Sin embargo, al no ser tan popular en España, muchas asignaturas de grados como Ingeniería de Software no aparecen, y las que sí lo hacen tienen varias veces menos contenido que en Wuolah.

#figure(
  image("../imagenes/screenshot_studocu.png", width: 100%),
  caption: [Captura de pantalla de Studocu.],
) <fig:studocu>

Por último, aunque lejos del alcance de este TFG, cabe destacar que Studocu cuenta con una gran implementación de inteligencia artificial que recopila automáticamente la información de la asignatura y ayuda al estudiante a repasar con ese contexto. Wuolah también ofrece una funcionalidad similar, aunque todavía en fase beta y más limitada, siendo un _chatbot_ al que se le pueden adjuntar apuntes concretos.

=== Docsity

Docsity es una plataforma italiana lanzada en 2010 que se abrió al mercado internacional en 2012. Ofrece una integración con centros educativos que incluye universidad, área de estudio, asignaturas y carrera, aunque al igual que Studocu no hay segregación de asignaturas por grado, por lo que la selección de carrera no tiene un efecto real en el contenido que se muestra.

La plataforma utiliza un sistema de puntos. Para incentivar las contribuciones los usuarios obtienen puntos al subir documentos o responder preguntas, y los gastan al descargar contenido de otros. Si bien evita la publicidad tan agresiva de Wuolah, este sistema de puntos puede resultar frustrante cuando un usuario quiere acceder a un recurso puntual y no tiene saldo suficiente.

En cuanto a presencia en España, Docsity cuenta con un volumen notable de contenido para algunas universidades como la UCM, aunque su distribución es desigual, carreras técnicas como Ingeniería de Software apenas tienen recursos disponibles, concentrándose la mayoría del contenido en áreas como periodismo, derecho o historia.

La interfaz (@fig:docsity) es limpia pero algo más confusa que las de Wuolah o Studocu ya que dentro de una asignatura solo los documentos populares muestran una miniatura, mientras que el resto se presenta en una lista sin previsualización, y la disposición general resulta menos intuitiva.

#figure(
  image("../imagenes/screenshot_docsity.png", width: 100%),
  caption: [Captura de pantalla de Docsity para la UCM.],
) <fig:docsity>

=== Conclusiones

Las tres plataformas analizadas comparten un objetivo común pero presentan carencias distintas. Wuolah ofrece la mejor integración con centros educativos españoles pero a costa del rendimiento y la experiencia de usuario. Studocu destaca por su interfaz y su alcance global, aunque su integración es más superficial y su contenido en España es limitado. Docsity, por su parte, tiene un modelo de incentivos menos intrusivo pero una organización del contenido poco precisa. Ninguna de las tres combina una integración completa con centros educativos, un buen rendimiento y una experiencia de usuario libre de publicidad o restricciones artificiales, lo que justifica la propuesta desarrollada en este trabajo.
