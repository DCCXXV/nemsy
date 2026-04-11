// Configuración del documento

// información del TFG
#let titulo = "Nemsy, una plataforma web colaborativa para compartir y acceder a recursos académicos"
#let titulo-en = "Nemsy, a collaborative web platform for sharing and accessing academic resources"
#let autor = "Marco Antonio Pérez Neira"
#let director = "Ramón González del Campo Rodríguez Barbero"
#let convocatoria = "Junio" // Febrero/Junio/Septiembre
#let año = 2025

// tipo de documento
#let tipo-documento = "Trabajo de Fin de Grado"
#let grado = "Ingeniería de Software"
#let institucion = [
  Grado en #grado\
  Facultad de Informática\
  Universidad Complutense de Madrid
]

// resumen
#let resumen = [
  Hasta hace relativamente poco, en España no existían plataformas bien integradas donde compartir apuntes, exámenes u otros recursos académicos; los estudiantes dependían de intercambios en persona o de grupos de mensajería sin persistencia real. En 2015 se lanzó Wuolah, una plataforma que sí se integraba con los centros educativos y permitía subir apuntes vinculados específicamente a una asignatura de un grado concreto. Sin embargo, esta plataforma presenta limitaciones significativas de rendimiento y un modelo de monetización basado en publicidad intensiva que deteriora la experiencia del usuario.

  Este Trabajo de Fin de Grado describe el diseño e implementación de una aplicación web alternativa que permite a estudiantes compartir, buscar y descargar apuntes sin interferencias, con un énfasis en la rapidez y la ligereza desde el inicio. La plataforma está diseñada para integrarse con las asignaturas, estudios y centros educativos tanto de España como del extranjero. Debido a las limitaciones de tiempo y al carácter tedioso del proceso más que dificultad técnica, la integración completa solo se ha realizado sobre la UCM, aunque la arquitectura está preparada para su expansión a otros centros: únicamente sería necesario desarrollar un _web crawler_ adaptado a la página de cada uno.

  Para ello se ha utilizado una combinación de _web scraping_ y el desarrollo de un _script_ que utiliza Jetbrains SWOT, una lista de dominios de correo académicos, para conseguir todos los centros educativos y sus dominios. Los usuarios que completan el proceso de _onboarding_ podrán ver todas las asignaturas de su grado separadas por año y ver los apuntes que otros usuarios han compartido. Además podrán buscar globalmente entre todos los apuntes de la plataforma gracias a la utilización de _Full Text Search_ permitiendo que la búsqueda sea instantánea aun con millones de apuntes.

  La plataforma está construida siguiendo una arquitectura cliente-servidor: un backend desarrollado en Go, elegido por su rendimiento y la solidez de su ecosistema para la construcción de APIs, un frontend en SvelteKit que proporciona una interfaz limpia y responsiva y PostgreSQL como base de datos lo que facilita ciertas funcionalidades.
]

#let palabras-clave = (
  "Aplicación Web",
  "Plataforma Colaborativa",
  "Recursos Académicos",
  "Go",
  "SvelteKit",
  "PostgreSQL",
  "OAuth2",
  "Docker",
)

// abstract
#let abstract-en = [
  Until relatively recently, there were no well-integrated platforms in Spain where students could share notes, exams or other academic resources; they relied on in-person exchanges or messaging groups with no real persistence. In 2015 Wuolah was launched, a platform that did integrate with educational institutions and allowed users to upload notes linked specifically to a subject within a degree programme at their university. However, this platform suffers from significant performance limitations and an advertising-heavy monetisation model that degrades the user experience.

  This Bachelor's Thesis describes the design and implementation of an alternative web application that allows students to share, search and download notes without interference, with an emphasis on speed and lightness from the outset. The platform is designed to integrate with subjects, degree programmes and educational institutions both in Spain and abroad. Due to time constraints and the tedious nature of the process rather than technical difficulty, full integration has only been completed for the UCM, although the architecture is ready for expansion to other institutions: only a _web crawler_ adapted to each institution's website would be needed.

  To achieve this, a combination of _web scraping_ and the development of a script that uses JetBrains SWOT, a list of academic email domains, was used to obtain all educational institutions and their domains. Users who complete the onboarding process can see all the subjects in their degree organised by year and access notes shared by other students. They can also search globally across all notes on the platform thanks to _Full Text Search_, allowing searches to remain instant even with millions of resources.

  The platform is built following a client-server architecture: a backend developed in Go, chosen for its performance and the robustness of its ecosystem for building APIs, a frontend in SvelteKit that provides a clean and responsive interface, and PostgreSQL as the database which facilitates certain functionalities.
]

#let keywords-en = (
  "Web Application",
  "Collaborative Platform",
  "Academic Resources",
  "Go",
  "SvelteKit",
  "PostgreSQL",
  "OAuth2",
  "Docker",
)
