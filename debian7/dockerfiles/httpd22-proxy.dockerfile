
#
#    Debian 7 (wheezy) HTTPd22 Proxy profile (dockerfile)
#    Copyright (C) 2016 SOL-ICT
#    This file is part of the Docker High Performance PHP Stack.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

FROM solict/general-purpose-system-distro:debian7_standard
MAINTAINER Luís Pedro Algarvio <lp.algarvio@gmail.com>

#
# Arguments
#

ARG app_httpd_global_mods_core_dis="asis auth_digest authn_anon authn_dbd authn_dbm authnz_ldap authz_dbm authz_owner cache cern_meta cgi cgid charset_lite dav_fs dav dav_lock dbd disk_cache dump_io ext_filter file_cache filter ident imagemap include ldap log_forensic mem_cache mime_magic negotiation proxy_ajp proxy_balancer proxy_connect proxy_ftp proxy_scgi reqtimeout speling substitute suexec unique_id userdir usertrack vhost_alias"
ARG app_httpd_global_mods_core_en="alias dir autoindex mime setenvif env expires headers deflate rewrite actions authn_default authn_alias authn_file authz_default authz_groupfile authz_host authz_user auth_basic ssl proxy proxy_http info status"
ARG app_httpd_global_mods_extra_dis="authnz_external"
ARG app_httpd_global_mods_extra_en="upload_progress xsendfile"
ARG app_httpd_global_user="www-data"
ARG app_httpd_global_group="www-data"
ARG app_httpd_global_home="/var/www"
ARG app_httpd_global_loglevel="warn"
ARG app_httpd_global_listen_addr="0.0.0.0"
ARG app_httpd_global_listen_port_http="80"
ARG app_httpd_global_listen_port_https="443"
ARG app_httpd_global_listen_timeout="140"
ARG app_httpd_global_listen_keepalive_status="On"
ARG app_httpd_global_listen_keepalive_requests="100"
ARG app_httpd_global_listen_keepalive_timeout="5"
ARG app_httpd_vhost_id="default"
ARG app_httpd_vhost_user="www-data"
ARG app_httpd_vhost_group="www-data"
ARG app_httpd_vhost_home="default"
ARG app_httpd_vhost_listen_addr="0.0.0.0"
ARG app_httpd_vhost_listen_port_http="80"
ARG app_httpd_vhost_listen_port_https="443"
ARG app_httpd_vhost_httpd_wlist="127.0.0.1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"

#
# Packages
#

# Install the HTTPd packages
# - apache2: for apache2, the HTTPd server
# - apache2-utils: for ab and others, the HTTPd utilities
# - apachetop: for apachetop, the top-like utility for HTTPd
# - apache2-mpm-worker: the Worker MPM module
# - libapache2-mod-authnz-external: the External Authentication DSO module
# - pwauth: for pwauth, the authenticator for mod_authnz_external
# - libapache2-mod-xsendfile: the X-Sendfile DSO module
# - libapache2-mod-upload-progress: the Upload Progress DSO module
# - ssl-cert: for make-ssl-cert, to generate certificates
RUN printf "# Install the HTTPd packages...\n" && \
    apt-get update && apt-get install -qy \
      apache2 \
      apache2-utils apachetop \
      apache2-mpm-worker \
      libapache2-mod-authnz-external pwauth \
      libapache2-mod-xsendfile libapache2-mod-upload-progress \
      ssl-cert && \
    printf "# Cleanup the Package Manager...\n" && \
    apt-get clean && rm -rf /var/lib/apt/lists/*;

#
# HTTPd DSO modules
#

# Enable/Disable HTTPd modules
RUN printf "# Start installing modules...\n" && \
    \
    printf "# Enabling/disabling modules...\n" && \
    # Core modules \
    a2dismod -f ${app_httpd_global_mods_core_dis} && \
    a2enmod -f ${app_httpd_global_mods_core_en} && \
    # Extra modules \
    a2dismod -f ${app_httpd_global_mods_extra_dis} && \
    a2enmod -f ${app_httpd_global_mods_extra_en} && \
    \
    printf "# Finished installing modules...\n";

#
# Configuration
#

# Add users and groups
RUN printf "Adding users and groups...\n"; \
    # HTTPd daemon \
    id -g ${app_httpd_global_user} || \
    groupadd \
      --system ${app_httpd_global_group} && \
    id -u ${app_httpd_global_user} && \
    usermod \
      --gid ${app_httpd_global_group} \
      --home ${app_httpd_global_home} \
      --shell /usr/sbin/nologin \
      ${app_httpd_global_user} \
    || \
    useradd \
      --system --gid ${app_httpd_global_group} \
      --no-create-home --home-dir ${app_httpd_global_home} \
      --shell /usr/sbin/nologin \
      ${app_httpd_global_user}; \
    \
    # HTTPd vhost \
    app_httpd_vhost_home="${app_httpd_global_home}/${app_httpd_vhost_id}"; \
    id -g ${app_httpd_vhost_user} || \
    groupadd \
      --system ${app_httpd_vhost_group} && \
    id -u ${app_httpd_vhost_user} && \
    usermod \
      --gid ${app_httpd_global_group} \
      --home ${app_httpd_vhost_home} \
      --shell /usr/sbin/nologin \
      ${app_httpd_global_user} \
    || \
    useradd \
      --system --gid ${app_httpd_vhost_group} \
      --create-home --home-dir ${app_httpd_vhost_home} \
      --shell /usr/sbin/nologin \
      ${app_httpd_vhost_user}; \
    mkdir -p ${app_httpd_vhost_home}/bin ${app_httpd_vhost_home}/log ${app_httpd_vhost_home}/html ${app_httpd_vhost_home}/tmp; \
    chown -R ${app_httpd_global_user}:${app_httpd_global_group} ${app_httpd_vhost_home}; \
    chmod -R ug=rwX,o=rX ${app_httpd_vhost_home};

# Supervisor
RUN printf "Updading Supervisor configuration...\n"; \
    \
    # /etc/supervisor/conf.d/init.conf \
    file="/etc/supervisor/conf.d/init.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    perl -0p -i -e "s>supervisorctl start dropbear;>supervisorctl start dropbear; supervisorctl start httpd;>" ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # /etc/supervisor/conf.d/httpd.conf \
    file="/etc/supervisor/conf.d/httpd.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    printf "# httpd\n\
[program:httpd]\n\
command=/bin/bash -c \"\$(which apache2ctl) -d /etc/apache2 -f /etc/apache2/apache2.conf -D FOREGROUND\"\n\
autostart=false\n\
autorestart=true\n\
\n" > ${file}; \
    printf "Done patching ${file}...\n";

# HTTPd
RUN printf "Updading HTTPd configuration...\n"; \
    \
    # /etc/apache2/envvars \
    file="/etc/apache2/envvars"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    # run as user/group \
    perl -0p -i -e "s>APACHE_RUN_USER=.*>APACHE_RUN_USER=${app_httpd_global_user}>" ${file}; \
    perl -0p -i -e "s>APACHE_RUN_GROUP=.*>APACHE_RUN_GROUP=${app_httpd_global_group}>" ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # /etc/apache2/apache2.conf \
    file="/etc/apache2/apache2.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    # change log level \
    perl -0p -i -e "s># alert, emerg.\n#\nLogLevel .*># alert, emerg.\n#\nLogLevel ${app_httpd_global_loglevel}>" ${file}; \
    # change config directory \
    perl -0p -i -e "s># Do NOT add a slash at the end of the directory path.\n#\nServerRoot .*># Do NOT add a slash at the end of the directory path.\n#\nServerRoot \"/etc/apache2\">" ${file}; \
    # replace optional config files \
    perl -0p -i -e "s># Include generic snippets of statements\nInclude conf.d/># Include generic snippets of statements\nInclude conf.d/\*.conf>" ${file}; \
    # replace vhost config files \
    perl -0p -i -e "s># Include the virtual host configurations:\nInclude sites-enabled/># Include the virtual host configurations:\nInclude sites-enabled/\*.conf\n>" ${file}; \
    # change timeout \
    perl -0p -i -e "s># Timeout: The number of seconds before receives and sends time out.\n#\nTimeout .*># Timeout: The number of seconds before receives and sends time out.\n#\nTimeout ${app_httpd_global_listen_timeout}>" ${file}; \
    # change keepalive \
    perl -0p -i -e "s># one request per connection\). Set to \"Off\" to deactivate.\n#\nKeepAlive .*># one request per connection\). Set to \"Off\" to deactivate.\n#\nKeepAlive ${app_httpd_global_listen_keepalive_status}>" ${file}; \
    perl -0p -i -e "s># We recommend you leave this number high, for maximum performance.\n#\nMaxKeepAliveRequests .*># We recommend you leave this number high, for maximum performance.\n#\nMaxKeepAliveRequests ${app_httpd_global_listen_keepalive_requests}>" ${file}; \
    perl -0p -i -e "s># same client on the same connection.\n#\nKeepAliveTimeout .*># same client on the same connection.\n#\nKeepAliveTimeout ${app_httpd_global_listen_keepalive_timeout}>" ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # /etc/apache2/ports.conf \
    file="/etc/apache2/ports.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    perl -0p -i -e "s>NameVirtualHost \*:80>NameVirtualHost ${app_httpd_global_listen_addr}:${app_httpd_global_listen_port_http}>g" ${file}; \
    perl -0p -i -e "s>Listen 80>Listen ${app_httpd_global_listen_addr}:${app_httpd_global_listen_port_http}>g" ${file}; \
    perl -0p -i -e "s>    Listen 443>    NameVirtualHost ${app_httpd_global_listen_addr}:${app_httpd_global_listen_port_http}\n    Listen ${app_httpd_global_listen_addr}:${app_httpd_global_listen_port_https}>g" ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # /etc/apache2/mods-available/proxy_fcgi.load \
    file="/etc/apache2/mods-available/proxy_fcgi.load"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    printf "# Depends: proxy\n\
LoadModule proxy_fcgi_module /usr/lib/apache2/modules/mod_proxy_fcgi.so\n\
\n" > ${file}; \
    \
    # /etc/apache2/conf.d/* \
    # Rename configuration files \
    mv /etc/apache2/conf.d/charset /etc/apache2/conf.d/charset.conf; \
    mv /etc/apache2/conf.d/localized-error-pages /etc/apache2/conf.d/localized-error-pages.conf; \
    mv /etc/apache2/conf.d/other-vhosts-access-log /etc/apache2/conf.d/other-vhosts-access-log.conf; \
    mv /etc/apache2/conf.d/security /etc/apache2/conf.d/security.conf; \
    \
    # Additional configuration files \
    mkdir /etc/apache2/incl.d; \
    \
    # HTTPd vhost \
    app_httpd_vhost_home="${app_httpd_global_home}/${app_httpd_vhost_id}"; \
    \
    # /etc/apache2/incl.d/${app_httpd_vhost_id}-httpd.conf \
    file="/etc/apache2/incl.d/${app_httpd_vhost_id}-httpd.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    printf "# HTTPd info and status\n\
<IfModule info_module>\n\
  # HTTPd info
  <Location /server-info>\n\
    SetHandler server-info\n\
    Allow from ${app_httpd_vhost_httpd_wlist}\n\
  </Location>\n\
</IfModule>\n\
<IfModule status_module>\n\
  # HTTPd status
  <Location /server-status>\n\
    SetHandler server-status\n\
    Allow from ${app_httpd_vhost_httpd_wlist}\n\
  </Location>\n\
</IfModule>\n\
\n" > ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # /etc/apache2/sites-available/${app_httpd_vhost_id}-http.conf \
    file="/etc/apache2/sites-available/${app_httpd_vhost_id}-http.conf"; \
    cp "/etc/apache2/sites-available/default" $file; \
    printf "\n# Applying configuration for ${file}...\n"; \
    printf "Done patching ${file}...\n"; \
    \
    # /etc/apache2/sites-available/${app_httpd_vhost_id}-https.conf \
    file="/etc/apache2/sites-available/${app_httpd_vhost_id}-https.conf"; \
    cp "/etc/apache2/sites-available/default-ssl" $file; \
    printf "\n# Applying configuration for ${file}...\n"; \
    printf "Done patching ${file}...\n"; \
    \
    printf "\n# Generate certificates...\n"; \
    make-ssl-cert generate-default-snakeoil --force-overwrite; \
    \
    printf "\n# Enable sites...\n"; \
    a2dissite default default-ssl; \
    a2ensite ${app_httpd_vhost_id}-http.conf ${app_httpd_vhost_id}-https.conf; \
    \
    # Disable original configuration \
    mv /etc/apache2/sites-available/default /etc/apache2/sites-available/default.orig; \
    mv /etc/apache2/sites-available/default-ssl /etc/apache2/sites-available/default-ssl.orig;

