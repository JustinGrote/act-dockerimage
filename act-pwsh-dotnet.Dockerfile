FROM ghcr.io/justingrote/act-pwsh

#Dotnet version based on Ubuntu available packages. Possible are 2.1, 3.1, 5.0
ARG DOTNET_VERSION=5.0

SHELL [ "/bin/bash", "-c" ]

# Install DotNet SDK
RUN set -Eeuxo pipefail \
    && wget -q https://packages.microsoft.com/config/ubuntu/20.10/packages-microsoft-prod.deb \
    && sudo dpkg -i packages-microsoft-prod.deb \
    && sudo apt-get update \
    && sudo apt-get install -y dotnet-sdk-${DOTNET_VERSION} \
    && printf "Cleaning image\n" \
    && apt-get clean \
    && rm -rf /var/cache/* \
    && rm -rf /var/log/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && printf "Cleaned up image\n"