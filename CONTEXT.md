# docker-php

Published PHP-FPM + Apache container images, one set per PHP version, for consuming projects to run on.

## Language

**Variant**:
Which Debian-built base an image starts from: **full** (everything) or **slim** (full without the browser, PDF rendering and font packages). Chosen once at the base; every flavor inherits it.
_Avoid_: non-slim (legacy alias for full, still used as a CI matrix label), edition

**Flavor**:
An add-on layered on top of an already tagged image (debug, oci, sourceguardian, chartdirector). Flavors stack, e.g. `-oci-debug`.
_Avoid_: variant (for add-ons)
