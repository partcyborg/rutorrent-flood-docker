
FROM lsiobase/ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# package versions
ARG MEDIAINF_VER="20.08"
ARG RUTORRENT_VER="v3.10"

# set env
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
ENV CONTEXT_PATH=/
ENV CREATE_SUBDIR_BY_TRACKERS="no"

LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="partcyborg"

RUN export DEBIAN_FRONTEND=noninteractive && \
 echo "**** install packages ****" && \
 apt-get update && \
 apt-get install -y \
   locales \
	p7zip \
	unrar \
	unzip \
	libssl1.0.0 \
	openssl \
	dtach \
	ffmpeg \
	wget \
	geoip-bin \
	geoip-database \
	logrotate \
	ca-certificates \
	libfcgi-bin \
	libarchive-zip-perl \
	zlib1g \
	libxml2 \
   php7.2 \
   php7.2-cgi \
   php7.2-fpm \
   php7.2-json  \
   php7.2-mbstring \
   php7.2-sockets \
   php-pear \
   php7.2-opcache \
   php7.2-apcu \
   php7.2-ctype \
   php7.2-dev \
   php7.2-fpm \
   php7.2-phar \
   php7.2-zip \
   rar \
   nginx-full \
   libsox3 \
   sox \
   zip \
   openssl1.0 \
   nodejs \
   cksfv \
	irssi && \
 echo "**** install build deps ****" && \
 apt-get install -y \
   libsox-dev \
   cpanminus \
   autoconf \
   automake \
   git \
   libtool \
   gcc-7 \
   g++-7 \
	zlib1g-dev \
	libxml2-dev \
	build-essential \
	libffi-dev \
	libarchive-zip-perl \
	cpanminus \
   libxml-libxml-perl \
   libdigest-sha-perl \
   libjson-perl \
   libjson-xs-perl \
   zlib1g-dev \
   dejagnu \
   libmpc3 \
   libmpc-dev \
   libisl19 \
   libisl-dev \
   libffi6 \
   libffi-dev \
   libmpfr-dev \
   texinfo \
   golang \
   subversion \
   libncurses5-dev \
   nodejs-dev \
   python3-pip \
   ncurses-term \
   npm \
   wget && \
 echo "**** install perl modules ****" && \
	cpanm HTML::Entities Net::SSLeay && \
# install webui
mkdir -p \
        /usr/share/webapps/rutorrent \
        /defaults/rutorrent-conf && \
 git clone -b ${RUTORRENT_VER} https://github.com/Novik/ruTorrent.git \
        /usr/share/webapps/rutorrent/ && \
 mv /usr/share/webapps/rutorrent/conf/* \
        /defaults/rutorrent-conf/ && \
 rm -rf \
        /defaults/rutorrent-conf/users && \
 pip3 install CfScrape \
              cloudscraper && \
# ruTorrent themes
git clone https://github.com/QuickBox/club-QuickBox /usr/share/webapps/rutorrent/plugins/theme/themes/club-QuickBox && \
git clone https://github.com/Phlooo/ruTorrent-MaterialDesign /usr/share/webapps/rutorrent/plugins/theme/themes/MaterialDesign && \
git clone https://github.com/artyuum/3rd-party-ruTorrent-Themes /tmp/rutorrent-themes && \
for theme in Agent34 Agent46 club-QuickBox FlatUI_Dark FlatUI_Light FlatUI_Material OblivionBlue; do \
   mv /tmp/rutorrent-themes/${theme} /usr/share/webapps/rutorrent/plugins/theme/themes; \
done && \
rm -rf /tmp/rutorrent-themes && \
# ruTorrent plugins
cd /usr/share/webapps/rutorrent/plugins/ && \
git clone https://github.com/AceP1983/ruTorrent-plugins  && \
mv ruTorrent-plugins/* . && \
rm -rf ruTorrent-plugins && \
git clone https://github.com/nelu/rutorrent-filemanager filemanager && \
git clone https://github.com/nelu/rutorrent-filemanager-share filemanager-share && \
chmod 755 filemanager/scripts/* && \
git clone https://github.com/Gyran/rutorrent-ratiocolor ratiocolor && \
sed -i 's/changeWhat = "cell-background";/changeWhat = "font";/g' ratiocolor/init.js && \
git clone https://github.com/xombiemp/rutorrentMobile mobile && \
git clone https://github.com/dioltas/AddZip && \
perl -MCPAN -e 'my $c = "CPAN::HandleConfig"; $c->load(doit => 1, autoconfig => 1); $c->edit(prerequisites_policy => "follow"); $c->edit(build_requires_install_policy => "yes"); $c->commit' && \
cd /tmp && \
git clone https://github.com/pyroscope/rtorrent-ps && \
cd rtorrent-ps && \
sed -i 's!INSTALL_ROOT/.local!INSTALL_ROOT!' build.sh && \
INSTALL_ROOT=/usr/local PACKAGE_ROOT=/usr/local/rtorrent BIN_DIR=/usr/local/bin ./build.sh all && \
cd /tmp && \
rm -rf rtorrent-ps && \
# compile mediainfo packages
cd /tmp && \
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
GOPATH=/usr go get -u github.com/pyed/rtelegram && \
# Install flood
cd /usr && \
git clone https://github.com/jfurrow/flood  && \
cp config.template.js config.js && \
npm install && \
npm cache clean --force && \
npm run build && \
#npm prune --production && \
rm config.js && \
ln -s /bin/tar /usr/bin/tar && \
ln -s /bin/bzip2 /usr/bin/bzip2 && \
ln -s /usr/local/bin/mediainfo /usr/bin/mediainfo && \
apt-get purge -y \
   libsox-dev \
   cpanminus \
	zlib1g-dev \
	libxml2-dev \
	build-essential \
	libffi-dev \
   zlib1g-dev \
   libmpc-dev \
   libisl-dev \
   libffi-dev \
   libmpfr-dev \
   golang \
   subversion && \
apt-get --purge autoremove -y && \
apt-get clean && \
rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 443 51415 3000
VOLUME /config /downloads
