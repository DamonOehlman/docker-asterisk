FROM centos:centos6
MAINTAINER Doug Smith <info@laboratoryb.org>
ENV build_date 2014-10-02

RUN yum update -y
RUN yum install kernel-headers gcc gcc-c++ cpp ncurses ncurses-devel libxml2 libxml2-devel sqlite sqlite-devel openssl-devel newt-devel kernel-devel libuuid-devel net-snmp-devel xinetd tar -y

ENV AUTOBUILD_UNIXTIME 1413824400

# download libsrtp
RUN curl -sf -o /tmp/srtp.tgz http://srtp.sourceforge.net/srtp-1.4.2.tgz
RUN mkdir /tmp/srtp
RUN tar -xzf /tmp/srtp.tgz -C /tmp/srtp --strip-components=1

# build srtp
WORKDIR /tmp/srtp
RUN ./configure CFLAGS=-fPIC
RUN make && make install

# Download asterisk.
# Currently Certified Asterisk 11.6 cert 6.
RUN curl -sf -o /tmp/asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/certified-asterisk/certified-asterisk-11.6-current.tar.gz

# gunzip asterisk
RUN mkdir /tmp/asterisk
RUN tar -xzf /tmp/asterisk.tar.gz -C /tmp/asterisk --strip-components=1
WORKDIR /tmp/asterisk

# make asterisk.
ENV rebuild_date 2014-10-07
# Configure
RUN ./configure --libdir=/usr/lib64 1> /dev/null
# Remove the native build option
RUN make menuselect.makeopts
RUN sed -i "s/BUILD_NATIVE//" menuselect.makeopts
# Continue with a standard make.
RUN make 1> /dev/null
RUN make install 1> /dev/null
RUN make samples 1> /dev/null
WORKDIR /

RUN mkdir -p /etc/asterisk
# ADD modules.conf /etc/asterisk/
ADD iax.conf /etc/asterisk/
ADD extensions.conf /etc/asterisk/
ADD sip.conf /etc/asterisk/
ADD http.conf /etc/asterisk/

# setup DTLS certificates
RUN mkdir -p /etc/asterisk/keys
ADD ast_tls_cert /tmp/asterisk/contrib/scripts/
RUN /tmp/asterisk/contrib/scripts/ast_tls_cert -C pbx.mycompany.com -O "My Super Company" -d /etc/asterisk/keys

CMD asterisk -f
