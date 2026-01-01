# Docker PHP Repository

## Overview

This is a custom PHP Docker image builder repository that creates and maintains Docker images for various PHP versions. The images are built with common PHP extensions and tools needed for web development, and are automatically published to both GitHub Container Registry (GHCR) and Docker Hub.

**Repository**: [fduarte42/docker-php](https://github.com/fduarte42/docker-php)  
**Container Registries**:
- GHCR: `ghcr.io/fduarte42/docker-php`
- Docker Hub: `docker.io/fduarte42/docker-php`

## Supported PHP Versions

The automated CI/CD pipeline builds and publishes Docker images for the following PHP versions:
- **7.4**
- **8.2**
- **8.3**
- **8.4**
- **8.5**

Legacy versions (5.3, 5.5, 5.6, 7.0, 7.1, 7.2, 7.3, 7.4) are available in the `unsupported/` directory as reference.

## Directory Structure

```
docker-php/
├── build/                          # Main build files
│   ├── Dockerfile                  # Primary Dockerfile
│   ├── Dockerfile-slim             # Slim variant
│   ├── Dockerfile-debug            # Debug variant
│   ├── Dockerfile-chartdirector    # ChartDirector extension variant
│   ├── Dockerfile-oci              # Oracle OCI variant
│   ├── Dockerfile-sourceguardian   # SourceGuardian variant
│   ├── build.sh                    # Main build script
│   ├── build-slim.sh               # Slim build script
│   ├── add-*.sh                    # Extension addition scripts
│   ├── config/                     # Configuration files
│   ├── driver/                     # Database drivers
│   ├── extension/                  # PHP extensions
│   ├── packages/                   # Pre-built packages
│   └── scripts/                    # Build and runtime scripts
├── unsupported/                    # Legacy PHP versions (5.3-8.1)
├── .github/workflows/              # CI/CD workflows
│   └── docker-build.yml            # Automated build workflow
├── build-all.sh                    # Main orchestration script
└── Readme.md                       # Quick README

```

## Build System

### Main Build Script: `build-all.sh`

The `build-all.sh` script is the primary orchestration script that:
- Determines the build environment (GitHub Actions vs. local)
- Sets appropriate Docker registry tags
- Handles PHP version-specific builds

**Usage**:
```bash
./build-all.sh <PHP_VERSION>
```

### Docker Build Process

The Dockerfile-based build process:
1. **Base Image**: Debian Trixie Slim
2. **Configuration Setup**: Keyboard, Bash, PHP-FPM reload script
3. **Build Step**: Executes `build.sh` to install PHP and extensions
4. **Post-Build Setup**: Supervisor configuration, Docker initialization script
5. **Entry Point**: Supervisord for process management

### Docker Variants

1. **Standard** (`Dockerfile`): Full-featured PHP image with common extensions
2. **Slim** (`Dockerfile-slim`): Minimal PHP image for smaller deployments
3. **Debug** (`Dockerfile-debug`): Development-focused with debugging tools
4. **ChartDirector** (`Dockerfile-chartdirector`): Includes ChartDirector extension
5. **OCI** (`Dockerfile-oci`): Oracle OCI database driver support
6. **SourceGuardian** (`Dockerfile-sourceguardian`): SourceGuardian extension

## Key Features

### Environment Variables
- **PUPPETEER_SKIP_CHROMIUM_DOWNLOAD**: `true` (optimized for headless operations)
- **COMPOSER_HOME**: `/composer` (Composer configuration directory)
- **COMPOSER_ALLOW_SUPERUSER**: `1` (Allows Composer to run as root)
- **PHP_GC_MAX_LIFETIME**: `1440` (PHP session garbage collection)
- **DOCUMENT_ROOT**: `/` (Web root configuration)

### Pre-installed Components
- PHP-FPM with CLI
- Composer (dependency manager)
- Chromium (for Puppeteer/headless operations)
- Supervisor (process management)
- Common PHP extensions (database drivers, image processing, etc.)
- wkhtmltox (HTML to PDF/Image conversion)

### Working Directory
- **WORKDIR**: `/var/www/html`
- **Exposed Port**: `80` (HTTP)

### Initialization
- Docker entrypoint: `/docker-php-init` script for runtime setup
- Supervisor configuration: `/etc/supervisor/conf.d/supervisord.conf`

## CI/CD Pipeline

### Automated Build Workflow (`.github/workflows/docker-build.yml`)

**Trigger Events**:
- **Schedule**: Weekly (every Thursday at 00:00 UTC)
- **Manual**: Can be triggered manually via `workflow_dispatch`

**Build Matrix**: 5 PHP versions (7.4, 8.2, 8.3, 8.4, 8.5)

**Process**:
1. Checkout repository code
2. Set up Docker Buildx for multi-platform builds
3. Authenticate with GHCR (GitHub Container Registry)
4. Authenticate with Docker Hub
5. Build and push images to both registries with appropriate tags

## Configuration Files

- **`build/config/keyboard`**: Keyboard layout configuration
- **`build/config/supervisord.conf`**: Process supervision configuration
- **`build/scripts/.bashrc`**: Bash environment configuration for root and www-data users
- **`build/scripts/php-fpm-reload.sh`**: PHP-FPM reload utility
- **`build/scripts/cron-foreground`**: Cron daemon in foreground mode
- **`build/scripts/docker-php-init`**: Docker initialization script

## Image Tagging Strategy

**For GitHub Actions builds** (automatic CI/CD):
```
ghcr.io/fduarte42/docker-php:X.Y
docker.io/fduarte42/docker-php:X.Y
```

**For local builds**:
```
fduarte42/docker-php:X.Y
```

Where `X.Y` is the PHP version (e.g., `8.3`, `8.4`)

## Extension Support

The build system supports adding custom extensions via scripts:
- `add-chartdirector.sh`: ChartDirector visualization library
- `add-debug.sh`: Debugging tools
- `add-oci.sh`: Oracle OCI database driver
- `add-sourceguardian.sh`: SourceGuardian encoder protection

## Usage

### Pull Pre-built Image
```bash
docker pull ghcr.io/fduarte42/docker-php:8.4
# or
docker pull fduarte42/docker-php:8.4
```

### Run Container
```bash
docker run -d \
  -p 80:80 \
  -v /path/to/app:/var/www/html \
  fduarte42/docker-php:8.4
```

### Build Locally
```bash
./build-all.sh 8.4
```

## Notes

- Images are automatically rebuilt weekly to ensure security patches are applied
- The repository uses Debian Trixie (cutting-edge but stable) as the base
- Supervisor is used as the main process manager instead of systemd
- The images are optimized for containerized environments
- Composer dependencies are globally available via the `PATH` variable
