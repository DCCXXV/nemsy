#import "../template.typ": epigraph

= Conclusions and Future Work

#block(
  fill: rgb("#f0f0f0"),
  inset: 1em,
  below: 1.5em,
)[
  *Abstract:* This chapter presents the conclusions drawn from the project and the future lines of work.
]

#epigraph(
  [Perfection is achieved, not when there is nothing more to add, but when there is nothing left to take away.],
  [Antoine de Saint-Exupéry],
)

== Conclusions

The result of the project is a functional platform, deployed in production at #link("https://nemsy.org")[nemsy.org] and demonstrably solid, that covers the proposed use case, namely sharing and consulting university notes between students, without the advertising and paywall concessions that limit the alternatives analysed in the State of the Art chapter. The implementation combines a Go backend with sqlc and PostgreSQL and a SvelteKit frontend with Svelte 5, two choices that have proven to be sound both in terms of productivity during development and in performance measured during the validation phase.

The data gathered during the k6 load test and the Lighthouse analysis show that the system behaves stably under sustained concurrency and obtains scores noticeably higher than Wuolah across the four dimensions Lighthouse measures. This empirically validates one of the central goals of the project, offering a fast experience as a differentiating factor against the existing alternatives. Beyond the figures, the resulting architecture is deliberately simple, well delimited by layers and built on widely adopted standards (HTTP, JWT, S3, OAuth2), which makes both maintenance and the addition of new features easy without structural rewrites.

It is worth emphasising that what has been built is a prototype in the strict sense of the word, a complete and operational system that covers the happy path and the main alternative paths, but that does not yet aim to compete in feature breadth with platforms that have been on the market for years. That said, the foundation it sits on is solid enough to scale, since the backend is stateless and can be replicated horizontally behind a load balancer, the object storage is abstracted behind a façade and the provider can be swapped without touching domain logic, PostgreSQL supports partitioning and read replicas when the time comes, and the frontend is served as static content with targeted SSR. In other words, the decisions taken do not compromise future growth and allow incorporating both more users and more features at minimal cost.

== Objectives Achieved

The seven objectives listed in the Introduction chapter have been fully met. The Go REST API is implemented and deployed in production, exposing the endpoints documented throughout the Work Description chapter and validated both by unit tests and by the load test described in the testing section. The SvelteKit web interface covers the entire user flow, from onboarding to uploading and consulting resources, with two navigation layouts adapted to desktop and mobile. Google OAuth2 authentication works as the sole access mechanism, with automatic detection of the educational institution from the email domain when it is registered in the universities table. The catalogue of institutions and subjects has been populated entirely automatically, combining JetBrains SWOT data for universities with a UCM-specific scraper for degrees and subjects, and is loaded during the initial deployment via the `cmd/seed-universities` and `cmd/seed-studies` binaries. File storage is delegated to a Hetzner Object Storage bucket accessed through the `minio-go` library, which makes it possible to migrate to any other S3-compatible provider without code changes. Global search is resolved with PostgreSQL native Full Text Search, with per field weighting and accent support via the `unaccent` extension. Finally, the platform has been deployed in a portable way using Docker Compose on a VPS, with a single `docker compose up` capable of bringing up the entire stack on any machine with Docker installed.

== Future Work

Several lines of evolution have been identified from the delivered prototype, all of them feasible without structural rewrites thanks to the architecture described in the Work Description chapter.

The most immediate extension is the addition of new file viewers in the frontend. The current architecture delegates previewing to Svelte components specialised by type (`PdfViewer`, `ImageViewer`, `MarkdownViewer`), selected from the file extension. Adding support for source code with syntax highlighting, audio via `<audio>`, video via `<video>` or office documents via prior conversion to PDF reduces to creating a new component and registering it in the dispatch table of the generic viewer, without touching the backend.

A second, more ambitious line is to broaden the concept of resource so that it is not limited to a set of files. At least three new variants can be envisaged. The first is _links_, resources pointing to an external URL, useful for sharing YouTube videos, forums or official documentation without having to download anything. The second is _text resources_, with a Markdown based rich editor that allows writing summaries and notes directly on the platform, without going through an uploaded file. The third, the most interesting from a didactic point of view, is _quizzes_ in the style of Moodle tests, with questions, correct answers and a self-assessment mode that could be enriched with aggregated metrics. The current structure of the `resources` table admits this extension by adding a discriminating `kind` column and auxiliary tables per type, without altering the rest of the model.

Another natural evolution, in line with the platforms analysed in the State of the Art chapter, is the integration of artificial intelligence features. Some are immediately useful, such as automatically generating a summary of the resource from text extracted from the PDF, suggesting tags or the most likely subject during upload, or automatic detection of inappropriate content to complement the manual reporting system. Others require more design, such as a chatbot that answers questions about the user's notes or the generation of quizzes from an existing resource, similar to those already offered by Studocu and Docsity. The architecture allows incorporating them as an additional service consumed by the backend, without coupling them to the core domain.

Finally, there are more operational lines of work that do not introduce new features but extend the scope of the prototype. The most obvious one is to complete the catalogue beyond UCM, writing scrapers for other Spanish universities and taking advantage of the fact that the `universities` table already contains institutions worldwide thanks to JetBrains SWOT. Other possibilities are implementing a per resource comments and ratings system, introducing realtime notifications via WebSockets when a user resource is reported or downloaded, a native mobile application that reuses the existing API, and migrating the current single VPS deployment to an infrastructure with a load balancer and replicas when traffic volume justifies it. All these extensions fit cleanly with the design decisions taken, which confirms that the prototype not only meets the proposed objectives but also constitutes a foundation on which to keep building.
