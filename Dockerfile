FROM debian:jessie

MAINTAINER Andrew Neff <andrew.neff@visionsystemsinc.com>

ARG TINI_VERSION=v0.10.0
ARG GOSU_VERSION=1.9
RUN build_deps='curl ca-certificates' && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${build_deps} && \
    curl -Lo /tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini && \
    curl -Lo /tini.asc https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc && \
    chmod +x /tini && \
    curl -Lo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" && \
    curl -Lo /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 0527A9B7 && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --batch --verify /tini.asc /tini && \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
    rm -r "$GNUPGHOME" /tini.asc /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
    DEBIAN_FRONTEND=noninteractive apt-get purge -y --auto-remove ${build_deps} && \
    rm -r /var/lib/apt/lists/*


RUN build_deps="curl ca-certificates" && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${build_deps} \
        #Undocumented vscode dependencies 
        libgtk2.0 libatk1.0 libpango1.0 libpangocairo-1.0 libcairo2 libfreetype6 \
        libfontconfig1 libdbus-1-3 libxi6 libxcursor1 libxdamage1 libxrandr2 \
        libxcomposite1 libxext6 libxfixes3 libxrender1 libxtst6 libgconf-2-4 \
        libasound2 libcups2 libexpat1 libxss1 libxkbfile1 && \
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > \
        /etc/apt/trusted.gpg.d/microsoft.gpg && \
    echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" > \
        /etc/apt/sources.list.d/vscode.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends code && \
    #curl -L https://go.microsoft.com/fwlink/?LinkID=760868 -o /code.deb && \
    #dpkg -i /code.deb; \
    #DEBIAN_FRONTEND=noninteractive apt-get install -y -f --no-install-recommends && \
    DEBIAN_FRONTEND=noninteractive apt-get purge -y --auto-remove ${build_deps} && \
    rm -rf /var/lib/apt/lists/* /code.deb /tmp/* /home/user/.vscode/extensions/v0.9.2-3.tar.gz

RUN build_deps="curl ca-certificates unzip" && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${build_deps} \
        gdb && \
    useradd user --create-home --home-dir /home/user && \
    gosu user code --install-extension PeterJausovec.vscode-docker && \
    gosu user code --install-extension ms-vscode.cpptools && \
    cd /home/user/.vscode/extensions/ms-vscode.cpptools* && \
#    gosu user npm install && \
    for link in $(grep -E "description.*\(Linux\)|description.*\(Linux / x86_64\)|Mono Framework Assemblies" -A 1 \
                  ~user/.vscode/extensions/ms-vscode.cpptools*/package.json | grep "url" | \
                  sed -r 's| *"url": "(.*)".*|\1|'); do \
      curl -L "${link}" -o tmp.zip && \
      gosu user unzip -o tmp.zip && \
      echo "$link"; \
    done && \
    touch install.lock && \
    chmod 755 debugAdapters/mono.linux-x86_64 \
              bin/Microsoft.VSCode.CPP.Extension.linux \
              LLVM/bin/clang-format && \
    DEBIAN_FRONTEND=noninteractive apt-get purge -y --auto-remove ${build_deps} && \
    rm -rf /var/lib/apt/lists/* /code.deb /tmp/* /home/user/.vscode/extensions/v0.9.2-3.tar.gz tmp.zip

ADD code_entrypoint.bsh /

ENV USER_ID=1000 GROUP_ID=1000

LABEL dustify.runargs="-v /tmp/.X11-unix:/tmp/.X11-unix \
                       -e DISPLAY \
                       -e USER_ID=%DUSTIFY_USER_ID% \
                       -e GROUP_ID=%DUSTIFY_GROUP_ID%"

ENTRYPOINT ["/tini", "--", "/code_entrypoint.bsh"]

CMD ["code"]