#MAINTAINER partcyborg
FROM alpine as gccbuilder
ARG GCC_VERSION=7.4.0
ENV GCC_VERSION=$GCC_VERSION

RUN apk add --quiet --no-cache \
            build-base \
            dejagnu \
            isl-dev \
            make \
            mpc1-dev \
            mpfr-dev \
            texinfo \
            zlib-dev
RUN wget -q https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz && \
    tar -xzf gcc-${GCC_VERSION}.tar.gz && \
    rm -f gcc-${GCC_VERSION}.tar.gz

WORKDIR /gcc-${GCC_VERSION}

RUN ./configure \
        --prefix=/usr/local \
        --build=$(uname -m)-alpine-linux-musl \
        --host=$(uname -m)-alpine-linux-musl \
        --target=$(uname -m)-alpine-linux-musl \
        --with-pkgversion="Alpine ${GCC_VERSION}" \
        --enable-checking=release \
        --disable-fixed-point \
        --disable-libmpx \
        --disable-libmudflap \
        --disable-libsanitizer \
        --disable-libssp \
        --disable-libstdcxx-pch \
        --disable-multilib \
        --disable-nls \
        --disable-symvers \
        --disable-werror \
        --enable-__cxa_atexit \
        --enable-default-pie \
        --enable-languages=c,c++ \
        --enable-shared \
        --enable-threads \
        --enable-tls \
        --with-linker-hash-style=gnu \
        --with-system-zlib
RUN make --silent -j $(nproc)
RUN make --silent -j $(nproc) install-strip
RUN gcc -v



FROM lsiobase/alpine:3.10 as runtime-image

# set version label
ARG BUILD_DATE
ARG VERSION
ARG BUILD_CORES
LABEL build_version="Version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# package version
ARG MEDIAINF_VER="19.07"
ARG CURL_VER="6.65.3"
ARG GEOIP_VER="1.1.1"
ARG RTORRENT_VER="0.9.8"
ARG LIBTORRENT_VER="v0.13.8"

# set env
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
ENV LD_LIBRARY_PATH=/usr/local/lib
ENV CONTEXT_PATH=/
ENV CREATE_SUBDIR_BY_TRACKERS="no"
ENV OPENSSL_VER=1.0.2o
ENV DISABLE_PERMS_CHANGE="no"


RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} && \
 apk add --no-cache \
	bash-completion \
        ca-certificates \
        fcgi \
        ffmpeg \
        geoip \
        geoip-dev \
        gzip \
        logrotate \
        nginx \
        dtach \
        tar \
        unrar \
        unzip \
        sox \
        wget \
        irssi \
        irssi-perl \
        zlib \
        zlib-dev \
        libxml2-dev \
        perl-archive-zip \
        perl-net-ssleay \
        perl-digest-sha1 \
        git \
        binutils \
        findutils \
        zip \
        php7 \
        php7-cgi \
        php7-fpm \
        php7-json  \
        php7-mbstring \
        php7-sockets \
        php7-pear \
        php7-opcache \
        php7-apcu \
        php7-ctype \
        php7-dev \
        php7-phar \
		  php7-zip \
        python \
        python3 && \
# install build packages
 apk add --no-cache --virtual=build-dependencies \
        autoconf \
        automake \
        perl-app-cpanminus \
        cppunit-dev \
        perl-dev \
        file \
        git \
        libtool \
        libcrypto1.1 \
        make \
        ncurses-dev \
        libtool \
        subversion \
        linux-headers \
        libffi-dev \
        python3-dev \
        mpfr \
        go \
        patch \
        dejagnu \
        isl-dev \
        make \
        mpc1-dev \
        mpfr-dev \
        texinfo \
        zlib-dev \
        binutils \
        file \
        make \
        fortify-headers \
        musl-dev 

COPY --from=gccbuilder /usr/local/ /usr/

RUN ln -sf /usr/local/bin/gcc /usr/bin/cc && \
ln -sf /usr/local/bin/g++ /usr/bin/c++ && \
cd /tmp && \
rm -rf openssl-fips-${OPENSSL_FIPS_VER} && \
wget -qO- https://www.openssl.org/source/openssl-$OPENSSL_VER.tar.gz | tar xz && \
cd openssl-$OPENSSL_VER && \
perl ./Configure linux-x86_64 --prefix=/usr \
	--libdir=lib \
	--openssldir=/etc/ssl \
	shared zlib enable-md2  \
	-DOPENSSL_NO_BUF_FREELISTS \
	-Wa,--noexecstack enable-ssl2 && \
make && \
make install_sw && \
cd /tmp && \
rm -rf openssl-${OPENSSL_VER}

# compile curl to fix ssl for rtorrent
RUN cd /tmp && \
mkdir curl && \
cd curl && \
wget -qO- https://curl.haxx.se/download/curl-${CURL_VER}.tar.gz | tar xz --strip 1 && \
./configure --with-ssl && make -j ${NB_CORES} && make install && \
ldconfig /usr/bin && ldconfig /usr/lib && \
# install webui
 mkdir -p \
        /usr/share/webapps/rutorrent \
        /defaults/rutorrent-conf && \
 git clone https://github.com/Novik/ruTorrent.git \
        /usr/share/webapps/rutorrent/ && \
 mv /usr/share/webapps/rutorrent/conf/* \
        /defaults/rutorrent-conf/ && \
 rm -rf \
        /defaults/rutorrent-conf/users && \
 pip3 install CfScrape \
              cloudscraper

# install webui extras
# QuickBox Theme
RUN git clone https://github.com/QuickBox/club-QuickBox /usr/share/webapps/rutorrent/plugins/theme/themes/club-QuickBox && \
git clone https://github.com/Phlooo/ruTorrent-MaterialDesign /usr/share/webapps/rutorrent/plugins/theme/themes/MaterialDesign && \
# ruTorrent plugins
cd /usr/share/webapps/rutorrent/plugins/ && \
git clone https://github.com/orobardet/rutorrent-force_save_session force_save_session && \
git clone https://github.com/AceP1983/ruTorrent-plugins  && \
mv ruTorrent-plugins/* . && \
rm -rf ruTorrent-plugins && \
apk add --no-cache cksfv && \
git clone https://github.com/nelu/rutorrent-thirdparty-plugins.git && \
mv rutorrent-thirdparty-plugins/* . && \
rm -rf rutorrent-thirdparty-plugins && \
cd /usr/share/webapps/rutorrent/ && \
chmod 755 plugins/filemanager/scripts/* && \
rm -rf plugins/fileupload && \
cd /tmp && \
git clone https://github.com/mcrapet/plowshare.git && \
cd plowshare/ && \
make install && \
cd .. && \
rm -rf plowshare* && \
apk add --no-cache unzip bzip2 && \
cd /usr/share/webapps/rutorrent/plugins/ && \
git clone https://github.com/Gyran/rutorrent-pausewebui pausewebui && \
git clone https://github.com/Gyran/rutorrent-ratiocolor ratiocolor && \
sed -i 's/changeWhat = "cell-background";/changeWhat = "font";/g' /usr/share/webapps/rutorrent/plugins/ratiocolor/init.js && \
git clone https://github.com/Gyran/rutorrent-instantsearch instantsearch && \
git clone https://github.com/xombiemp/rutorrentMobile && \
git clone https://github.com/dioltas/AddZip && \
# install autodl-irssi perl modules
 perl -MCPAN -e 'my $c = "CPAN::HandleConfig"; $c->load(doit => 1, autoconfig => 1); $c->edit(prerequisites_policy => "follow"); $c->edit(build_requires_install_policy => "yes"); $c->commit' && \
cpanm -n HTML::Entities XML::LibXML JSON JSON::XS Net::SSLeay && \
# compile xmlrpc-c
cd /tmp && \
svn checkout http://svn.code.sf.net/p/xmlrpc-c/code/stable xmlrpc-c && \
cd /tmp/xmlrpc-c && \
./configure --with-libwww-ssl --disable-wininet-client --disable-curl-client --disable-libwww-client --disable-abyss-server --disable-cgi-server && make -j ${NB_CORES} && make install && \
cd /tmp && \
rm -rf xmlrpc-c

# compile libtorrent
#if [ "$RTORRENT_VER" == "v0.9.4" ] || [ "$RTORRENT_VER" == "v0.9.6" ]; then apk add -X http://dl-cdn.alpinelinux.org/alpine/v3.6/main -U cppunit-dev==1.13.2-r1 cppunit==1.13.2-r1; fi && \
#echo "DEBUG: RTORRENT/LIBTORRENT VERSIONS ARE: $RTORRENT_VER/$LIBTORRENT_VER" && \
#cd /tmp && \
#mkdir libtorrent && \
#cd libtorrent && \
#wget -qO- https://github.com/rakshasa/libtorrent/archive/${LIBTORRENT_VER}.tar.gz | tar xz --strip 1 && \
#./autogen.sh && ./configure && make -j ${NB_CORES} && make install && \

# compile rtorrent-ps
RUN cd /tmp && \
git clone https://github.com/pyroscope/rtorrent-ps && \
cd rtorrent-ps && \
bash -c "INSTALL_ROOT=/usr/local PACKAGE_ROOT=/usr/local/rtorrent BIN_DIR=/usr/local/bin ./build.sh all" && \
cd /tmp && \
rm -rf rtorrent-ps


# compile mediainfo packages
RUN cd /tmp && \
curl -o /tmp/libmediainfo.tar.gz -L \
        "http://mediaarea.net/download/binary/libmediainfo0/${MEDIAINF_VER}/MediaInfo_DLL_${MEDIAINF_VER}_GNU_FromSource.tar.gz" && \
curl -o /tmp/mediainfo.tar.gz -L \
        "http://mediaarea.net/download/binary/mediainfo/${MEDIAINF_VER}/MediaInfo_CLI_${MEDIAINF_VER}_GNU_FromSource.tar.gz" && \
mkdir -p \
        /tmp/libmediainfo \
        /tmp/mediainfo && \
tar xf /tmp/libmediainfo.tar.gz -C \
        /tmp/libmediainfo --strip-components=1 && \
tar xf /tmp/mediainfo.tar.gz -C \
        /tmp/mediainfo --strip-components=1 && \
cd /tmp/libmediainfo && \
        ./SO_Compile.sh && \
cd /tmp/libmediainfo/ZenLib/Project/GNU/Library && \
        make install && \
cd /tmp/libmediainfo/MediaInfoLib/Project/GNU/Library && \
        make install && \
cd /tmp/mediainfo && \
        ./CLI_Compile.sh && \
cd /tmp/mediainfo/MediaInfo/Project/GNU/CLI && \
        make install && \
cd /tmp && \
rm -rf mediainfo && \
# compile and install rtelegram
GOPATH=/usr go get -u github.com/pyed/rtelegram 
#if [ "$RTORRENT_VER" == "v0.9.4" ] || [ "$RTORRENT_VER" == "v0.9.6" ]; then apk del -X http://dl-cdn.alpinelinux.org/alpine/v3.6/main cppunit-dev; fi && \

# install flood webui
RUN  apk add --no-cache \
       python \
       nodejs \
       nodejs-npm && \
     apk add --no-cache --virtual=build-dependencies \
       build-base && \
     mkdir /usr/flood && \
     cd /usr/flood && \
     git clone https://github.com/jfurrow/flood . && \
     cp config.template.js config.js && \
     npm install && \
     npm cache clean --force && \
     npm run build && \
     npm prune --production && \
     rm config.js && \
     ln -s /usr/local/bin/mediainfo /usr/bin/mediainfo

# add local files
COPY root/ /
COPY VERSION /

# ports and volumes
EXPOSE 443 51415 3000
VOLUME /config /downloads
