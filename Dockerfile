# -----------------------------------------------------------------------------
# Docker Image for Nagios
# -----------------------------------------------------------------------------

FROM ubuntu:14.04

MAINTAINER Sunggun Yu <sunggun.dev@gmail.com>

# -----------------------------------------------------------------------------
#  Packages
# -----------------------------------------------------------------------------

# Install required packages
RUN set -x \
    && apt-get update \
    && apt-get install -y \
        apt-transport-https \
        ca-certificates \
        wget \
        build-essential \
        automake \
        autoconf \
        gcc \
        libc6 \
        make \
        libgd2-xpm-dev \
        openssl \
        libssl-dev \
        xinetd \
        apache2 \
        apache2-utils \
        php5 \
        libapache2-mod-php5 \
        php5-gd \
        libgd-dev \
        unzip \
        vim \
        openssh-server \
        iputils-ping \
        netcat \
        dnsutils \
        gettext \
        m4 \
        gperf \
        snmp \
        snmpd \
        php5-cli \
        php5-gd \
        runit \
        bc \
        libnet-snmp-perl \
        git \
        libcgi-pm-perl \
        librrds-perl \
        libgd-gd2-perl \
        libnagios-object-perl \
        libnagios-plugin-perl \
        fping \
        libfreeradius-client-dev \
        libnet-snmp-perl \
        libnet-xmpp-perl \
        parallel \
        libcache-memcached-perl \
        libdbd-mysql-perl \
        libdbi-perl \
        libnet-tftp-perl \
        libredis-perl \
        libswitch-perl \
        libwww-perl \
        libjson-perl \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
#  Nagios-Core
#  https://support.nagios.com/kb/article/nagios-core-installing-nagios-core-from-source.html#Ubuntu
# -----------------------------------------------------------------------------

# Setup Nagios user and group
RUN set -x \
    && useradd nagios \
    && groupadd nagcmd \
    && usermod -a -G nagcmd nagios \
    && usermod -a -G nagios www-data

# Install Nagios Core
RUN set -x \
    && cd /tmp \
    && wget https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.3.2.tar.gz \
    && tar xvf nagios-4.3.2.tar.gz \
    && cd nagioscore-nagios-4.3.2/ \
    && ./configure \
        --with-httpd-conf=/etc/apache2/sites-enabled \
    && make all \
    && make install \
    && make install-init \
    && update-rc.d nagios defaults \
    && make install-commandmode \
    && make install-config \
    && make install-webconf \
    && a2enmod rewrite \
    && a2enmod cgi \
    && htpasswd -c -b -s /usr/local/nagios/etc/htpasswd.users nagiosadmin nagios123 \
    && make clean \
    && rm -rf /tmp/nagios*

# -----------------------------------------------------------------------------
#  Nagios-Plugins
#  https://github.com/nagios-plugins/nagios-plugins
# -----------------------------------------------------------------------------

# Install Nagios Plugins
RUN set -x \
    && cd /tmp \
    && wget https://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz \
    && tar xvf nagios-plugins-2.2.1.tar.gz \
    && cd nagios-plugins-2.2.1 \
    && ./configure \
        --with-nagios-user=nagios \
        --with-nagios-group=nagios\
         --with-openssl \
    && make \
    && make install \
    && rm -rf /tmp/nagios*

# -----------------------------------------------------------------------------
#  NRPE Plugin
#  https://github.com/NagiosEnterprises/nrpe
# -----------------------------------------------------------------------------

# Install NRPE
RUN set -x \
    && cd /tmp \
    && wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-3.2.0/nrpe-3.2.0.tar.gz \
    && tar xvf nrpe-3.2.0.tar.gz \
    && cd nrpe-3.2.0 \
    && ./configure \
        --enable-command-args \
        --with-nagios-user=nagios \
        --with-nagios-group=nagios \
        --with-ssl=/usr/bin/openssl \
        --with-ssl-lib=/usr/lib/x86_64-linux-gnu \
    && make all \
    && make install \
    && make install-plugin \
    && make install-daemon \
    && make install-config \
    && make install-inetd \
    && rm -rf /tmp/nrpe*

# -----------------------------------------------------------------------------
#  Nagiosgraph Plugin
#  https://sourceforge.net/p/nagiosgraph/code/HEAD/tree/trunk/nagiosgraph/INSTALL
# -----------------------------------------------------------------------------

# Install Nagiosgraph Plugin
RUN set -x \
    && cd /tmp \
    && wget https://downloads.sourceforge.net/project/nagiosgraph/nagiosgraph/1.5.2/nagiosgraph-1.5.2.tar.gz \
    && tar xvf nagiosgraph-1.5.2.tar.gz \
    && cd nagiosgraph-1.5.2 \
    && ./install.pl --check-prereq \
    && ./install.pl \
        --layout standalone \
        --prefix /usr/local/nagiosgraph \
        --nagios-user nagios \
        --www-user nagios \
    && cp share/nagiosgraph.ssi /usr/local/nagios/share/ssi/common-header.ssi \
    && rm -rf /tmp/nagiosgraph*

# Copy apache2 conf files
ADD apache2/sites-available/* /etc/apache2/sites-available/

# Replace original nagios.conf. and create symlink for site-enabled
RUN set -x \
    && mv /etc/apache2/sites-enabled/nagios.conf /etc/apache2/sites-enabled/nagios.conf.orig \
    && ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/nagios.conf \
    && ln -s /etc/apache2/sites-available/nagiosgraph.conf /etc/apache2/sites-enabled/nagiosgraph.conf

# -----------------------------------------------------------------------------
#  Pagerduty Agent and Integration Plugin
#  https://www.pagerduty.com/docs/guides/nagios-integration-guide/
# -----------------------------------------------------------------------------

# Install Pagerduty agent packages
RUN set -x \
    && wget -O - https://packages.pagerduty.com/GPG-KEY-pagerduty | apt-key add - \
    && sh -c 'echo "deb https://packages.pagerduty.com/pdagent deb/" >/etc/apt/sources.list.d/pdagent.list' \
    && apt-get update \
    && apt-get install -y -f \
        pdagent \
        pdagent-integrations \
    && rm -rf /var/lib/apt/lists/*

# Copy pagerduty cgi file for Two-Way Integration
COPY nagios/sbin/pagerduty.cgi /usr/local/nagios/sbin/pagerduty.cgi

# -----------------------------------------------------------------------------
#  Setup Nagios Configs
# -----------------------------------------------------------------------------

# Create working directory for customized config files
RUN set -x \
    && mkdir -p /var/opt/nagios \
    && mkdir -p /var/opt/nagios/etc/servers \
    && cp -r /usr/local/nagios/etc /var/opt/nagios/etc \
    && cp -r /usr/local/nagios/var /var/opt/nagios/var \
    && chown -R nagios:nagios /var/opt/nagios/etc \
    && chown -R nagios:nagios /var/opt/nagios/var

# Copy customized Nagios config files into working directory
ADD nagios/etc /var/opt/nagios/etc

# Remove original nagios config files.
# customized config files will be copied over from working directory at initial running.
RUN set -x \
    && rm -rf /usr/local/nagios/etc /usr/local/nagios/var

# -----------------------------------------------------------------------------

# Volumes
VOLUME ["/usr/local/nagios/etc", "/usr/local/nagios/var/"]

# Copy Entrypoint file and installer files
ADD scripts/* /

# Set Entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Expose ports
EXPOSE 80

# Set WORKDIR
WORKDIR /usr/local/nagios/etc
