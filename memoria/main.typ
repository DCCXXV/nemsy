#import "template.typ": *
#import "config.typ": *

// aplicar plantilla
#show: ucm-tfg.with(
  titulo: titulo,
  titulo-en: titulo-en,
  autor: autor,
  director: director,
  // codirector: codirector,
  convocatoria: convocatoria,
  año: año,
  tipo-documento: tipo-documento,
  grado: grado,
  institucion: institucion,
  resumen: resumen,
  palabras-clave: palabras-clave,
  abstract-en: abstract-en,
  keywords-en: keywords-en,
)

// CAPÍTULOS
#include "capitulos/01-introduccion.typ"
#set text(lang: "en")
#counter(heading).update(0)
#include "capitulos/05-introduction-en.typ"
#set text(lang: "es")
#counter(heading).update(1)
#counter(figure).update(2)

#include "capitulos/02-estado-cuestion.typ"
#include "capitulos/03-descripcion-trabajo.typ"
#include "capitulos/04-conclusiones.typ"

#pagebreak()
#bibliography("referencias.bib", title: "Bibliografía", style: "ieee")

// APENDICES
#pagebreak()
#set heading(numbering: (..nums) => {
  if nums.pos().len() == 1 {
    "Apéndice " + numbering("A", ..nums)
  } else {
    numbering("A.1", ..nums)
  }
})
#counter(heading).update(0)

// Apéndice A
// #include "apendices/a-manual-usuario.typ"

// Apéndice B
// #include "apendices/b-instalacion.typ"
