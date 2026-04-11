// Plantilla UCM FDI para TFG
// Basada en la plantilla TeXiS

#let ucm-tfg(
  titulo: "",
  titulo-en: "",
  autor: "",
  director: "",
  codirector: none,
  convocatoria: "",
  año: none,
  calificacion: none,
  tipo-documento: "",
  grado: "",
  institucion: [],
  resumen: [],
  palabras-clave: (),
  abstract-en: [],
  keywords-en: (),
  body,
) = {
  // configuración del documento
  set document(
    title: titulo,
    author: autor,
    date: datetime.today(),
  )

  // configuración de página
  set page(
    paper: "a4",
    margin: (
      top: 2.5cm,
      bottom: 2.5cm,
      left: 3cm,
      right: 2.5cm,
    ),
    numbering: "1",
    number-align: center,
  )

  // configuración de texto
  set text(
    font: "New Computer Modern",
    size: 12pt,
    lang: "es",
    hyphenate: true,
  )

  // configuración de párrafos
  set par(
    justify: true,
    leading: 0.65em,
    first-line-indent: 1.5em,
  )

  // sangría
  show heading: it => {
    it
    par()[#text(size: 0pt)[#h(0pt)]]
  }

  // encabezados
  set heading(numbering: "1.1")

  // estilo de capítulos (heading niv 1)
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(2cm)
    block(
      text(size: 22pt, weight: "bold")[
        #if it.numbering != none [
          Capítulo #counter(heading).display()
        ]
        #it.body
      ],
    )
    v(1.5cm)
  }

  // estilo de secciones (heading niv 2)
  show heading.where(level: 2): it => {
    v(1cm)
    block(
      text(size: 16pt, weight: "bold")[
        #if it.numbering != none [
          #counter(heading).display() #h(0.5em)
        ]
        #it.body
      ],
    )
    v(0.5cm)
  }

  // estilo de subsecciones (heading niv 3)
  show heading.where(level: 3): it => {
    v(0.7cm)
    block(
      text(size: 14pt, weight: "bold")[
        #if it.numbering != none [
          #counter(heading).display() #h(0.5em)
        ]
        #it.body
      ],
    )
    v(0.3cm)
  }

  // enlaces
  show link: set text(fill: blue)

  // PORTADA
  page(
    margin: 2.5cm,
    numbering: none,
  )[
    #set align(center)
    #set par(justify: false)

    #v(1cm)

    // línea superior
    #line(length: 100%, stroke: 1pt)

    #v(0.4cm)

    // título en español
    #text(size: 15pt, weight: "bold")[
      #titulo
    ]

    #v(0.4cm)

    // título en inglés
    #text(size: 15pt, weight: "bold")[
      #titulo-en
    ]

    #v(0.4cm)

    // línea inferior
    #line(length: 100%, stroke: 1pt)

    #v(1cm)

    // logo UCM
    #if type(read("imagenes/escudoUCMcolor.png", encoding: none)) != none {
      image("imagenes/escudoUCMcolor.png", width: 25%)
    }

    #v(1cm)

    // tipo de documento
    #text(size: 13pt)[
      #tipo-documento
    ]

    #v(0.2cm)

    // curso
    #text(size: 13pt)[
      Curso #año–#(año + 1)
    ]

    #v(1cm)

    // autor
    #text(size: 12pt, weight: "bold")[
      Autor
    ]
    #v(0.15cm)
    #text(size: 12pt)[
      #autor
    ]

    #v(0.7cm)

    // director
    #text(size: 12pt, weight: "bold")[
      Director
    ]
    #v(0.15cm)
    #text(size: 12pt)[
      #director
    ]

    #if codirector != none [
      #v(0.7cm)
      #text(size: 12pt, weight: "bold")[
        Codirector
      ]
      #v(0.15cm)
      #text(size: 12pt)[
        #codirector
      ]
    ]

    #v(1fr)

    // institución
    #text(size: 11pt)[
      #grado\
      Facultad de Informática\
      Universidad Complutense de Madrid
    ]

    #v(0.5cm)
  ]


  // DEDICATORIA
  // page(numbering: none)[
  //   TODO
  // ]

  // AGRADECIMIENTOS
  // page(numbering: none)[
  //   TODO
  // ]

  // RESUMEN
  page(numbering: none)[
    #set align(left)

    #heading(level: 1, numbering: none)[Resumen]

    #heading(level: 2, numbering: none)[#titulo]

    #resumen

    #v(1cm)

    #heading(level: 2, numbering: none)[Palabras clave]

    #par(first-line-indent: 0pt)[
      #text(style: "italic")[
        #palabras-clave.join(", ").
      ]
    ]
  ]

  // ABSTRACT
  page(numbering: none)[
    #set align(left)
    #set text(lang: "en")

    #heading(level: 1, numbering: none)[Abstract]

    #heading(level: 2, numbering: none)[#titulo-en]

    #abstract-en

    #v(1cm)

    #heading(level: 2, numbering: none)[Keywords]

    #par(first-line-indent: 0pt)[
      #text(style: "italic")[
        #keywords-en.join(", ").
      ]
    ]
  ]

  // ÍNDICE
  page(numbering: none)[
    #heading(level: 1, numbering: none, outlined: false)[Índice general]
    #v(1cm)
    #outline(
      title: none,
      indent: 2em,
      depth: 3,
    )
  ]


  // CONTENIDO PRINCIPAL
  counter(page).update(1)

  // configurar encabezados
  set page(
    header: context {
      let elems = query(heading).filter(h => h.level == 1 and h.location().page() <= here().page())

      if elems != () {
        let current = elems.last()
        align(center)[
          #text(size: 10pt, style: "italic")[
            #if current.numbering != none [
              Capítulo #counter(heading).at(current.location()).first():
            ]
            #current.body
          ]
          #line(length: 100%, stroke: 0.5pt)
        ]
      }
    },
    numbering: "1",
  )

  body
}

// función auxiliar para figuras
#let figura(
  path,
  caption: [],
  label: none,
  width: auto,
) = {
  figure(
    image(path, width: width),
    caption: caption,
  )
  if label != none {
    label(label)
  }
}
