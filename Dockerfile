FROM debian:buster-slim
#  $ docker build . -t juliapython:latest 

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG JULIA_VERSION

# 修改源地址
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
    && sed -i 's|security.debian.org/debian-security|mirrors.ustc.edu.cn/debian-security|g' /etc/apt/sources.list \
    && apt-get update --fix-missing && apt-get install -y wget curl bzip2 libglib2.0-0 libxext6 libsm6 libxrender1 git mercurial subversion ca-certificates apt-utils
# Configure apt, install packages and tools


ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

RUN wget --quiet https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    #wget --quiet https://repo.anaconda.com/miniconda/Miniconda2-4.5.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc \
    #
    && echo "channels:" >> ~/.condarc \
    && echo "  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free" >> ~/.condarc \
    && echo "  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/pro" >> ~/.condarc \
    && echo "  - defaults" >> ~/.condarc \
    && echo "show_channel_urls: true" >> ~/.condarc \
    && echo "custom_channels:" >> ~/.condarc \
    && echo "  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud" >> ~/.condarc \
#
#-------------------------------------安装jupyter lab----------------------------------------------------------------------
&& conda install -y -c conda-forge jupyterlab \
&& conda clean -y --all \
&& apt-get clean 
#&& 	rm -rf /var/lib/apt/lists/* 
    #NOTE: If you are using Docker 1.13 or greater, Tini is included in Docker itself. This includes all versions of Docker CE. To enable Tini, just pass the --init flag to docker run.
    #TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    #curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    ##curl -L "https://github.com/krallin/tini/releases/download/v0.19.0/tini_0.19.0.deb   tini.deb && \
    #dpkg -i tini.deb && \
    #rm tini.deb && \
    #apt-get clean \

#conda install --yes jupyterlab
#-------------------------------------安装Julia-----------------------------------------------------------------------


ENV JULIA_PATH /usr/local/julia
ENV PATH $JULIA_PATH/bin:$PATH

# https://julialang.org/juliareleases.asc
# Julia (Binary signing key) <buildbot@julialang.org>
ENV JULIA_GPG 3673DF529D9049477F76B37566E3C7DC03D6E495

# https://julialang.org/downloads/
# ENV JULIA_VERSION 1.5.0-rc1

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	if ! command -v gpg > /dev/null; then \
		apt-get update; \
		apt-get install -y --no-install-recommends \
			gnupg \
			dirmngr \
		; \
		rm -rf /var/lib/apt/lists/*; \
	fi; \
	\
# https://julialang.org/downloads/#julia-command-line-version
# https://julialang-s3.julialang.org/bin/checksums/julia-1.5.0-rc1.sha256
# this "case" statement is generated via "update.sh"
	dpkgArch="$(dpkg --print-architecture)"; \
	case "${dpkgArch##*-}" in \
# amd64
		#--build-arg="JULIA_VERSION=1.5.0-rc1"
		#amd64) tarArch='x86_64'; dirArch='x64'; sha256='a4ea36aa86269116992393067e5afc182707cb4f26eac9fddda08e04a9c7b94d' ;; \
		#--build-arg="JULIA_VERSION=1.4.2"
		amd64) tarArch='x86_64'; dirArch='x64'; sha256='d77311be23260710e89700d0b1113eecf421d6cf31a9cebad3f6bdd606165c28' ;; \
# arm64v8
		arm64) tarArch='aarch64'; dirArch='aarch64'; sha256='7e9f3fac46264a2c861c542adce9d6b47276976dab40cbe19ca7ed2c97a82b66' ;; \
# i386
		i386) tarArch='i686'; dirArch='x86'; sha256='ebc76bc879f722375e658a2c3cd43304ee8b05035fa46b8ad7c5c8eef1091a42' ;; \
		*) echo >&2 "error: current architecture ($dpkgArch) does not have a corresponding Julia binary release"; exit 1 ;; \
	esac; \
	\
	folder="$(echo "$JULIA_VERSION" | cut -d. -f1-2)"; \
	#curl -fL -o julia.tar.gz.asc "https://julialang-s3.julialang.org/bin/linux/${dirArch}/${folder}/julia-${JULIA_VERSION}-linux-${tarArch}.tar.gz.asc"; \
	curl -fL -o julia.tar.gz.asc "https://mirrors.bfsu.edu.cn/julia-releases/bin/linux/${dirArch}/${folder}/julia-${JULIA_VERSION}-linux-${tarArch}.tar.gz.asc"; \
	#curl -fL -o julia.tar.gz     "https://julialang-s3.julialang.org/bin/linux/${dirArch}/${folder}/julia-${JULIA_VERSION}-linux-${tarArch}.tar.gz"; \
	curl -fL -o julia.tar.gz     "https://mirrors.bfsu.edu.cn/julia-releases/bin/linux/${dirArch}/${folder}/julia-${JULIA_VERSION}-linux-${tarArch}.tar.gz"; \
	\
	echo "${sha256} *julia.tar.gz" | sha256sum -c -; \
	\
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$JULIA_GPG"; \
	gpg --batch --verify julia.tar.gz.asc julia.tar.gz; \
	command -v gpgconf > /dev/null && gpgconf --kill all; \
	rm -rf "$GNUPGHOME" julia.tar.gz.asc; \
	\
	mkdir "$JULIA_PATH"; \
	tar -xzf julia.tar.gz -C "$JULIA_PATH" --strip-components 1; \
	rm julia.tar.gz; \
	\
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
	echo "export JULIA_PKG_SERVER=https://mirrors.bfsu.edu.cn/julia/static" >> ~/.bashrc \
	; \
# smoke test
	julia -e 'using Pkg;Pkg.add("IJulia")'

EXPOSE 8888
CMD [ "/bin/bash" ]
