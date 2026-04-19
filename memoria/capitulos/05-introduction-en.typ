= Introduction

#counter(figure).update(0)

#block(
  fill: rgb("#f0f0f0"),
  inset: 1em,
  below: 1.5em,
)[
  *Abstract:* This chapter presents the motivation behind the project, the objectives pursued and the structure of the document.
]

#pad(left: 3em)[
  #quote(attribution: [Grady Booch], block: true)[
    The quality of a system is not determined by the power of its individual components, but by how they are chosen and assembled to meet the needs.
  ]
]

== Motivation

As a software engineering student I use a large amount of different software in my day to day life; some work well and some are frustrating. It is precisely one of the latter that motivated me to undertake this Bachelor's Thesis.

Before Wuolah, the alternatives were limited to generic platforms such as Docsity or StudyLib, which had not been targeted at the Spanish market and therefore had very little or practically no content depending on the platform, and which also did not integrate with specific educational institutions, or to informal solutions such as messaging groups and shared drives.

Wuolah, the best known and most integrated platform for sharing notes, solved a real problem by recognising the need for students to have a place to share and find relevant notes for their specific subjects, in their degree programme and educational institution. Despite its popularity, its current model presents a series of problems that harm both the user experience and the quality of information exchange.

Its main problem is performance. By analysing the platform using Lighthouse, an open source Google tool that audits the performance, accessibility, best practices and SEO of any website (@fig:lighthouse-en), some fairly conclusive results are obtained.

#figure(
  image("../imagenes/lighthouse_wuolah.png", width: 75%),
  caption: [Performance analysis of wuolah.com with Google Lighthouse.],
  supplement: [Figure],
) <fig:lighthouse-en>

The platform achieves a performance score of 32 out of 100, a result that reveals a major optimisation problem and explains the slowness felt when using it. This low score can be explained by the use of a heavy client-side architecture and the large number of advertisements loaded on it. This significantly worsens the user experience and demonstrates the need for a more efficient design approach.

Furthermore, its business model based on intensive advertising also harms the experience. While it is understandable that the platform needs to monetise itself, the current implementation excessively penalises the free user with long waiting times to download each resource, unless a monthly subscription is paid.

On the other hand, the micropayments per download offered by Wuolah present another fundamental problem. When an economic reward is introduced, especially when it is minimal, there is a risk of transforming users' motivation; the genuine desire to help is replaced by a transactional interest of low value. This approach has been shown to be potentially counterproductive. Research on motivation has demonstrated that external rewards can diminish intrinsic interest in performing a task, an effect known as "Motivational Displacement" @Deci1999 @Frey2001.

Furthermore, this incentive model has another negative consequence for technical degrees. By limiting rewards to PDF files, since these are the ones in which advertisements can be embedded, it discourages students from sharing information in other formats more suitable for certain areas such as code, thus impoverishing the variety and usefulness of the resources available on the platform.

Finally, it is also worth mentioning how the current interface reflects a common problem in platforms that receive a significant percentage of usage from mobile devices: to facilitate responsiveness, the desktop experience has been degraded. As can be seen in @fig:ssw1-en, with a standard laptop resolution of 1920×1080 at 100% zoom, barely half of the screen is devoted to content, leaving the remaining side bars for advertisements. Of that half, slightly more than a third is occupied by a sidebar with low value information, leaving barely a fraction of the total screen width for what the user actually wants to see.

#figure(
  image("../imagenes/screenshot_wuolah1.png", width: 100%),
  caption: [Screenshot of wuolah.com showing the current interface.],
  supplement: [Figure],
) <fig:ssw1-en>

This work seeks to solve all these problems and aims to design and develop a prototype of an alternative platform. The proposed solution improves performance using a lightweight and efficient architecture with a Go backend and a SvelteKit frontend. To reduce maintenance costs, virtual private servers (VPS) are used instead of cloud platforms such as AWS. Intrusive advertising and monetary incentives are eliminated to foster genuine collaboration and the sharing of resources in multiple formats.

== Objectives

The main objective of this project is to create and deploy a prototype of an application for sharing academic resources such as notes and solved exercises, among others. To achieve this, the following objectives have been defined:

+ Design and implement a REST API in Go that manages users, resources and subjects.
+ Develop a web interface with SvelteKit that offers a fast, advertisement free experience.
+ Integrate authentication with Google OAuth2 as the sole access method, automatically detecting the user's educational institution from their email domain.
+ Automatically retrieve educational institutions and their subjects through web scraping and JetBrains SWOT.
+ Use S3-compatible object storage to manage files uploaded by users.
+ Implement global search using PostgreSQL Full Text Search.
+ Deploy the platform in a portable manner using Docker Compose on a VPS.

== Work Plan

The development of the project was carried out following an iterative and incremental approach with an API-first methodology: for each feature, the backend endpoint was implemented first, followed by the corresponding interface. For task management, a Kanban board on Taiga was used. The main development phases were as follows:

+ *Initial prototyping (September -- October 2025).* Technology selection, implementation of Google OAuth2 authentication, first iterations of the interface design and initial configuration of the database and the onboarding flow.

+ *Architecture design and implementation of core features (January -- February 2026).* Definition of the REST API, replacing an initial GraphQL approach that proved unnecessary for the project. Development of the UCM scraper, implementation of resource uploading, downloading and preview, support for multiple files per resource, and design of the view system.

+ *Advanced features and refinement (March 2026).* User profiles, global search with Full Text Search, university integration via JetBrains SWOT and web scraping, and general interface improvements.

+ *Testing, deployment and documentation (April 2026).* Backend unit tests, frontend unit and end to end tests with Playwright, Docker and Docker Compose configuration, VPS deployment and writing of the thesis report.

== Document Structure

This document is structured as follows:

- *Chapter 2. State of the Art:* Existing platforms for sharing academic resources are analysed.
- *Chapter 3. Work Description:* The technological decisions are justified and the architecture, design and implementation of the platform are described in detail.
- *Chapter 4. Conclusions and Future Work:* Conclusions and possible lines of improvement are presented.
