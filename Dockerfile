FROM alpine:3.10
MAINTAINER Johan Bergström <bugs@bergstroem.nu>

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="mariadb-alpine" \
      org.label-schema.description="A MariaDB container suitable for development" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/jbergstroem/mariadb-alpine" \
      org.label-schema.schema-version="1.0.0-rc.1" \
      org.label-schema.license="Apache-2.0"

COPY run.sh /run.sh
COPY my.cnf /tmp/

RUN apk add --no-cache mariadb=10.3.18-r0 \
  && rm -rf /etc/my.cnf.d/* /etc/my.cnf.apk-new /usr/data/test/db.opt /usr/share/mariadb/README* \
     /usr/share/mariadb/COPYING* /usr/share/mariadb/*.cnf /usr/share/terminfo \
     /usr/share/mariadb/{binary-configure,mysqld_multi.server,mysql-log-rotate,mysql.server,install_spider.sql} \
  && find /usr/share/mariadb/ -mindepth 1 -type d ! -name 'charsets' ! -name 'english' -print0 | xargs -0 rm -rf \
  && touch /usr/share/mariadb/mysql_system_tables_data.sql \
  && mkdir /run/mysqld \
  && chown mysql:mysql /etc/my.cnf.d/ /run/mysqld /usr/share/mariadb/mysql_system_tables_data.sql \
  && for p in aria* myisam* mysqld_* innochecksum \
              mysqlslap replace wsrep* msql2mysql sst_dump \
              resolve_stack_dump mysqlbinlog myrocks_hotbackup test-connect-t \
              $(cd /usr/bin; ls mysql_*| grep -v mysql_install_db); \
              do eval rm /usr/bin/${p}; done

USER mysql

# This is not super helpful; mysqld might be running but not accepting connections.
# Since we have no clients, we can't really connect to it and check.
#
# Below is in my opinion better than no health check.
HEALTHCHECK --start-period=3s CMD pgrep mysqld

VOLUME ["/var/lib/mysql"]
ENTRYPOINT ["/run.sh"]
EXPOSE 3306
