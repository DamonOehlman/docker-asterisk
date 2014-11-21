FROM centos:centos6
MAINTAINER Doug Smith <info@laboratoryb.org>
ENV build_date 2014-10-02

RUN yum update -y
RUN yum install kernel-headers gcc gcc-c++ cpp ncurses ncurses-devel libxml2 libxml2-devel sqlite sqlite-devel openssl-devel newt-devel kernel-devel libuuid-devel net-snmp-devel xinetd tar -y

# additional deps for asterisk 13
RUN yum update -y
RUN yum install epel-release -y
RUN yum install jansson jansson-devel bzip2 -y

# Get pj project
RUN mkdir /tmp/pjproject
RUN curl -sf -o /tmp/pjproject.tar.bz2 -L http://www.pjsip.org/release/2.3/pjproject-2.3.tar.bz2
RUN tar -xjvf /tmp/pjproject.tar.bz2 -C /tmp/pjproject --strip-components=1
WORKDIR /tmp/pjproject
RUN ./configure --prefix=/usr --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr 1> /dev/null
RUN make dep 1> /dev/null
RUN make 1> /dev/null
RUN make install
RUN ldconfig
RUN ldconfig -p | grep pj

ENV AUTOBUILD_UNIXTIME 1413824400

# download libsrtp
RUN curl -sf -o /tmp/srtp.tgz http://srtp.sourceforge.net/srtp-1.4.2.tgz
RUN mkdir /tmp/srtp
RUN tar -xzf /tmp/srtp.tgz -C /tmp/srtp --strip-components=1

# build srtp
WORKDIR /tmp/srtp
RUN ./configure CFLAGS=-fPIC
RUN make 1> /dev/null && make install

# Download asterisk.
RUN curl -sf -o /tmp/asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz

# gunzip asterisk
RUN mkdir /tmp/asterisk
RUN tar -xzf /tmp/asterisk.tar.gz -C /tmp/asterisk --strip-components=1
WORKDIR /tmp/asterisk

# make asterisk.
ENV rebuild_date 2014-10-07
# Configure
RUN ./configure --libdir=/usr/lib64 --with-gtk2=no 1> /dev/null
# Remove the native build option
RUN make menuselect.makeopts 1> /dev/null
RUN menuselect/menuselect --disable BUILD_NATIVE menuselect.makeopts 1> /dev/null
# Continue with a standard make.
RUN make 1> /dev/null
RUN make install 1> /dev/null
RUN make samples 1> /dev/null
WORKDIR /

RUN mkdir -p /etc/asterisk
# ADD asterisk/modules.conf /etc/asterisk/
ADD asterisk/iax.conf /etc/asterisk/
ADD asterisk/extensions.conf /etc/asterisk/
ADD asterisk/sip.conf /etc/asterisk/
ADD asterisk/http.conf /etc/asterisk/

# setup DTLS certificates
RUN mkdir -p /etc/asterisk/keys
ADD asterisk/ast_tls_cert /tmp/asterisk/contrib/scripts/
RUN /tmp/asterisk/contrib/scripts/ast_tls_cert -C pbx.mycompany.com -O "My Super Company" -d /etc/asterisk/keys

CMD asterisk -f
