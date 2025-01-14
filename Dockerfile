#!/usr/bin/docker build .
#
# VERSION               1.0

FROM       alpine:latest
MAINTAINER maniasso@gmail.com

ENV HOSTNAME XoruX
ENV VI_IMAGE 1

# create file to see if this is the firstrun when started
RUN touch /firstrun

RUN apk update && apk add \
    bash \
    wget \
    supervisor \
    busybox-suid \
    apache2 \
    bc \
    net-snmp \
    net-snmp-tools \
    rrdtool \
    perl-rrd \
    perl-xml-simple \
    perl-xml-libxml \
    perl-net-ssleay \
    perl-crypt-ssleay \
    perl-net-snmp \
    net-snmp-perl \
    perl-lwp-protocol-https \
    perl-date-format \
    perl-dbd-pg \
    perl-io-tty \
    perl-want \
    net-tools \
    bind-tools \
    libxml2-utils \
    # snmp-mibs-downloader \
    openssh-client \
    openssh-server \
    ttf-dejavu \
    graphviz \
    vim \
    rsyslog \
    tzdata \
    sudo \
    less \
    ed \
    sharutils \
    make \
    tar \
    perl-dev \
    perl-app-cpanminus

# perl-font-ttf fron testing repo (needed for PDF reports)
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing perl-font-ttf
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing sblim-wbemcli

# install perl PDF API from CPAN
RUN cpanm -l /usr -n PDF::API2

# setup default user
RUN addgroup -S lpar2rrd 
RUN adduser -S lpar2rrd -G lpar2rrd -u 1005 -s /bin/bash
RUN echo 'lpar2rrd:xorux4you' | chpasswd
RUN echo '%lpar2rrd ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN mkdir /home/stor2rrd \
    && mkdir /home/lpar2rrd/stor2rrd \
    && ln -s /home/lpar2rrd/stor2rrd /home/stor2rrd \
    && chown lpar2rrd /home/lpar2rrd/stor2rrd

# configure Apache
COPY configs/apache2 /etc/apache2/sites-available
COPY configs/apache2/htpasswd /etc/apache2/conf/

# change apache user to lpar2rrd
RUN sed -i 's/^User apache/User lpar2rrd/g' /etc/apache2/httpd.conf

# adding web root
ADD htdocs.tar.gz /var/www/localhost
RUN chown -R apache.apache /var/www/localhost
RUN chmod a+w /var/www/localhost/htdocs/js/env.js


ENV LPAR_VER "7.40"
ENV STOR_VER "7.40"

# expose ports for SSH, HTTP, HTTPS and LPAR2RRD daemon
EXPOSE 22 80 443 8162

COPY configs/crontab /var/spool/cron/crontabs/lpar2rrd
RUN chmod 640 /var/spool/cron/crontabs/lpar2rrd && chown lpar2rrd.cron /var/spool/cron/crontabs/lpar2rrd

COPY tz.pl /var/www/localhost/cgi-bin/tz.pl
RUN chmod +x /var/www/localhost/cgi-bin/tz.pl


# download tarballs from official website
ADD https://www.lpar2rrd.com/download-static/lpar2rrd/lpar2rrd-$LPAR_VER.tar /home/lpar2rrd/
ADD https://www.lpar2rrd.com/download-static/stor2rrd/stor2rrd-$STOR_VER.tar /home/stor2rrd/

# extract tarballs
WORKDIR /home/lpar2rrd
RUN tar xvf lpar2rrd-7.40.tar

WORKDIR /home/stor2rrd
RUN tar xvf stor2rrd-7.40.tar

COPY supervisord.conf /etc/
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

RUN mkdir -p /home/lpar2rrd/lpar2rrd /home/stor2rrd/stor2rrd
RUN chown -R lpar2rrd /home/lpar2rrd /home/stor2rrd
VOLUME [ "/home/lpar2rrd/lpar2rrd", "/home/stor2rrd/stor2rrd" ]

ENTRYPOINT [ "/startup.sh" ]

