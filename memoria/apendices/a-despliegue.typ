= Guía de despliegue

Este apéndice describe los pasos necesarios para desplegar Nemsy en una máquina con Docker desde cero. Se asume un sistema GNU/Linux con `git`, `docker` y `docker compose` instalados, una cuenta de Google Cloud Platform para crear las credenciales OAuth2 y un proveedor de almacenamiento compatible con S3, en este caso Hetzner Object Storage.

== Requisitos previos

El despliegue de producción corre sobre una instancia _CAX11_ de Hetzner Cloud con procesador Ampere Altra (2 vCPU ARM64 con núcleos Neoverse-N1), 4 GB de RAM y 40 GB de disco, utilizando la imagen oficial de Fedora Linux 42 con Docker Engine y Docker Compose v2. La máquina debe disponer de al menos 1 GB de memoria RAM libre y unos 5 GB de almacenamiento para las imágenes Docker, la base de datos y un margen razonable para los archivos subidos al inicio, y exponer los puertos 80 y 443 al exterior si se va a publicar bajo un dominio propio.

Para la autenticación es necesario crear unas credenciales OAuth2 en Google Cloud Platform. En la consola, dentro del menú _APIs and Services_, se crea un nuevo proyecto, se habilita la _Google People API_ y se generan unas credenciales de tipo _OAuth client ID_ con la URL de retorno `https://<dominio>/api/auth/google/callback` (o `http://localhost:8080/api/auth/google/callback` para pruebas locales).

== Configuración

Toda la configuración del sistema se concentra en un único fichero `.env` que `docker compose` lee al levantar el _stack_. La @cod:env-deploy reproduce las variables que es necesario definir.

#figure(
  ```bash
  DB_PASSWORD=<contraseña_aleatoria>

  GOOGLE_CLIENT_ID=<id_obtenido_en_GCP>
  GOOGLE_CLIENT_SECRET=<secreto_obtenido_en_GCP>
  GOOGLE_REDIRECT_URL=https://<dominio>/api/auth/google/callback

  JWT_SECRET=<cadena_aleatoria_de_32+_caracteres>
  ALLOWED_ORIGIN=https://<dominio>

  S3_ENDPOINT=<endpoint_de_hetzner_object_storage>
  S3_ACCESS_KEY=<access_key_del_bucket>
  S3_SECRET_KEY=<secret_key_del_bucket>
  S3_BUCKET=nemsy
  S3_USE_SSL=true

  PUBLIC_API_BASE_URL=https://<dominio>
  ```,
  caption: [Variables de entorno necesarias para el despliegue.],
  supplement: [Código],
) <cod:env-deploy>

Las contraseñas y claves deben generarse con un mecanismo criptográficamente seguro, por ejemplo `openssl rand -hex 32` para `JWT_SECRET` y `openssl rand -base64 24` para las contraseñas de servicio.

== Levantamiento del _stack_

Una vez configurado el `.env`, basta con clonar el repositorio y levantar el _stack_ con un único comando.

#figure(
  ```bash
  git clone https://github.com/DCCXXV/nemsy.git
  cd nemsy
  cp .env.example .env
  # editar .env con los valores reales (vi .env)
  docker compose up -d
  ```,
  caption: [Comandos para clonar y arrancar Nemsy.],
  supplement: [Código],
) <cod:deploy-up>

`docker compose` levanta tres servicios en una red privada, el contenedor del _backend_ Go, el del _frontend_ SvelteKit servido como SSR Node y el de PostgreSQL con persistencia en un volumen llamado `pgdata`. El almacenamiento de archivos no se levanta como contenedor, sino que se delega externamente en un _bucket_ de Hetzner Object Storage al que el _backend_ accede mediante la librería `minio-go`, lo que evita ocupar espacio del VPS con los archivos subidos por los usuarios. Las migraciones de base de datos se aplican automáticamente al arrancar el _backend_ mediante `golang-migrate`.

== Carga inicial del catálogo

Tras el primer arranque, la base de datos está vacía de universidades y estudios. La imagen Docker del _backend_ solo incluye el binario del servidor, así que los _seeders_ se ejecutan directamente desde el código fuente clonado, aprovechando que el contenedor de PostgreSQL expone el puerto `5432` en `127.0.0.1:5433` para conexiones desde el _host_.

#figure(
  ```bash
  cd backend
  export DATABASE_URL="postgres://nemsy:$DB_PASSWORD@127.0.0.1:5433/nemsy?sslmode=disable"
  go run ./cmd/seed-universities
  go run ./cmd/seed-studies
  ```,
  caption: [Comandos para cargar el catálogo inicial de universidades y estudios.],
  supplement: [Código],
) <cod:seed>

El primer comando importa el catálogo mundial de centros desde JetBrains SWOT, y el segundo ejecuta el _scraper_ de la UCM para poblar los grados y asignaturas. Ambos son idempotentes y pueden volver a ejecutarse para refrescar los datos. Esto requiere tener Go instalado en el _host_, requisito que se cumple sin esfuerzo en Fedora con `dnf install golang`.

== Promoción de un usuario a administrador

El rol de administrador no se asigna desde la interfaz, sino directamente en la base de datos. Una vez que el usuario ha iniciado sesión por primera vez con Google, basta con actualizar su fila como muestra la @cod:promote.

#figure(
  ```bash
  docker compose exec -e PGPASSWORD=$DB_PASSWORD db \
      psql -U nemsy -d nemsy \
      -c "UPDATE users SET role = 'admin' WHERE email = '<correo>';"
  ```,
  caption: [Promoción de un usuario a administrador.],
  supplement: [Código],
) <cod:promote>
