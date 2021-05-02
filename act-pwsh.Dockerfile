#Borrowed with love from catthehacker

ARG DISTRIB_ID=ubuntu
ARG DISTRIB_RELEASE=20.04
FROM ${DISTRIB_ID}:${DISTRIB_RELEASE}

# > ARGs before FROM are not accessible
ARG DISTRIB_ID=ubuntu
ARG DISTRIB_RELEASE=20.04

# > Allow customization of operational paths
ARG AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
ARG DEPLOYMENT_BASEPATH=/opt/runner
ARG RUNNER_USER=runner
ARG RUNNER_HOME=/home/$RUNNER_USER
ARG RUNNER_WORK=$RUNNER_HOME/work
ARG RUNNER_TEMP=$RUNNER_WORK/_temp
ARG RUNNER_TOOL_CACHE=$AGENT_TOOLSDIRECTORY
ARG RUNNER_PERFLOG=$RUNNER_HOME/perflog

# > Prepare basic environment that Github Actions requires
ENV AGENT_TOOLSDIRECTORY=${AGENT_TOOLSDIRECTORY}
ENV RUNNER_HOME=${RUNNER_HOME}
ENV AGENT_TOOLSDIRECTORY=${AGENT_TOOLSDIRECTORY}
ENV RUNNER_TOOL_CACHE=${AGENT_TOOLSDIRECTORY}

# > Node version
ARG NODE_VERSION=12

# > Powershell channel (options are powershell, powershell-lts, and powershell-preview)
ARG POWERSHELL_CHANNEL=powershell

# > Force apt-get to not be interactive/not ask
ARG DEBIAN_FRONTEND=noninteractive

SHELL [ "/bin/bash", "-c" ]

# > setup environment required for GitHub Actions
RUN set -Eeuxo pipefail \
    && printf "Build started\n" \
    && ImageOS=${DISTRIB_ID}$(echo ${DISTRIB_RELEASE} | cut -d'.' -f 1) \
    && echo "IMAGE_OS=$ImageOS" | tee -a /etc/environment \
    && echo "ImageOS=$ImageOS" | tee -a /etc/environment \
    && echo "LSB_RELEASE=${DISTRIB_RELEASE}" | tee -a /etc/environment \
    && AGENT_TOOLSDIRECTORY=${AGENT_TOOLSDIRECTORY}} \
    && echo "AGENT_TOOLSDIRECTORY=$AGENT_TOOLSDIRECTORY" | tee -a /etc/environment \
    && echo "RUNNER_TOOL_CACHE=$AGENT_TOOLSDIRECTORY" | tee -a /etc/environment \
    && echo "DEPLOYMENT_BASEPATH=${DEPLOYMENT_BASEPATH}" | tee -a /etc/environment \
    && echo ". /etc/environment" | tee -a /etc/profile \
    && mkdir -p $AGENT_TOOLSDIRECTORY \
    && chown 1000:1000 $AGENT_TOOLSDIRECTORY \
    && chmod 0777 $AGENT_TOOLSDIRECTORY \
    && mkdir -p /github \
    && chown 1000:1000 /github \
    && chmod 0777 /github \
    && echo "RUNNER_USER=${RUNNER_USER}" | tee -a /etc/environment \
    && echo "RUNNER_TEMP=${RUNNER_TEMP}" | tee -a /etc/environment

# > Install deps
RUN set -Eeuxo pipefail \
    && apt-get -yq update \
    && printf "Updated apt-get lists and upgraded packages\n\n" \
    && apt-get -yq install --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        gawk \
        git \
        gnupg-agent \
        jq \
        libyaml-0-2 \
        lsb-release \
        software-properties-common \
        ssh \
        sudo \
        wget \
        zstd \
        unzip $(apt-cache search libicu | grep -E 'libicu[[:digit:]]+ -' | cut -d " " -f 1) \
    && printf "Installed base utils\nInstalling docker\n" \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
    && add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get -yq update \
    && apt-get -yq install docker-ce-cli \
    && printf "Cleaning image\n" \
    && apt-get clean \
    && rm -rf /var/cache/* \
    && rm -rf /var/log/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && printf "Cleaned up image\n"

# > Create non-root user (requires sudo to be installed which is why this is after deps)
RUN set -Eeuxo pipefail \
    && printf "Creating non-root user ${RUNNER_USER}\n" \
    && groupadd -g 1000 ${RUNNER_USER} \
    && useradd -u 1000 -g ${RUNNER_USER} -d ${RUNNER_HOME} -G sudo -m -s /bin/bash ${RUNNER_USER} \
    && sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' \
    && sed -i /etc/sudoers -re 's/^root.*/root ALL=(ALL:ALL) NOPASSWD: ALL/g' \
    && sed -i /etc/sudoers -re 's/^#includedir.*/## **Removed the include directive** ##"/g' \
    && echo "${RUNNER_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && printf "runner user: $(su - ${RUNNER_USER} -c id)\n" \
    && printf "Created non-root user $(grep ${RUNNER_USER} /etc/passwd)\n"

# > Install Node.JS
RUN set -Eeuxo pipefail \
    printf "Installing Node.JS\n" \
    && curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && DISTRO="$(lsb_release -s -c)" \
    && echo "deb https://deb.nodesource.com/node_${NODE_VERSION}.x $DISTRO main" | tee /etc/apt/sources.list.d/nodesource.list \
    && echo "deb-src https://deb.nodesource.com/node_${NODE_VERSION}.x $DISTRO main" | tee -a /etc/apt/sources.list.d/nodesource.list \
    && apt-get -yq update \
    && apt-get -yq install --no-install-recommends nodejs="${NODE_VERSION}*" \
    && printf "Installed Node.JS $(node -v)\n" \
    && dpkg-query -f '${binary:Package}\n' -W \
    && printf "Cleaning image\n" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && printf "Cleaned up image\n"

# > Install Powershell
RUN set -Eeuxo pipefail \
    && printf "Installing Powershell\n" \
    && wget -q https://packages.microsoft.com/config/${DISTRIB_ID}/${DISTRIB_RELEASE}/packages-microsoft-prod.deb \
    && sudo dpkg -i packages-microsoft-prod.deb \
    && sudo apt-get update \
    && sudo add-apt-repository universe \
    && sudo apt-get install -y ${POWERSHELL_CHANNEL} \
    && sudo apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && printf "Cleaned up image\n"

# > Don't run as root, generally not good idea
USER ${RUNNER_USER}:${RUNNER_USER}

WORKDIR ${RUNNER_HOME}

SHELL [ "/bin/bash", "--login" ]

# > Force bash with environment
ENTRYPOINT [ "/bin/bash", "--login" ]
