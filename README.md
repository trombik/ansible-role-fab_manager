# `trombik.fab_manager`

`ansible` role to install
[fab-manager](https://github.com/sleede/fab-manager).

# Notes

## For all users

The role assume that the `postgresql` version is 13, in which trusted
extension is supported.

While the application runs fine on a host with 2 GB memory, `webpack` requires
a lot of memory. Make sure the host has enough memory. Adjust `NODE_OPTIONS`
environment variable with `--max-old-space-size` accordingly.

The role does not support `elasticsearch`.

# Requirements

* `git`
* `postgresql`
* `redis`
* `ruby`
* `supervisor`, or other application manager to run rails application

See an example at [requirements.yml](requirements.yml).

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `fab_manager_user` | User name of `fab-manager` | `fab` |
| `fab_manager_group` | Group name of `fab-manager` | `fab` |
| `fab_manager_groups` | List of groups `fab_manager_user` will be added to | `[]` |
| `fab_manager_home` | Path to `$HOME` of `fab-manager` user | `/usr/local/fab` |
| `fab_manager_repo_name` | Basename  of directory to checkout the source | `fab_manager` |
| `fab_manager_repo_dir` | Path to directory to checkout the source | `{{ fab_manager_home }}/{{ fab_manager_repo_name }}` |
| `fab_manager_repo_url` | `git` URL of the source | `https://github.com/trombik/fab-manager.git` |
| `fab_manager_repo_version` | Branch name, tag, or commit to checkout the source | `local` |
| `fab_manager_git_option` | See below | `{"clone"=>true, "dest"=>"{{ fab_manager_repo_dir }}", "repo"=>"{{ fab_manager_repo_url }}", "version"=>"{{ fab_manager_repo_version }}", "update"=>false}` |
| `fab_manager_config_dir` | Path to `config` directory | `{{ fab_manager_repo_dir }}/config` |
| `fab_manager_log_dir` | Path to `log` directory | `{{ fab_manager_repo_dir }}/log` |
| `fab_manager_env` | A dict of `.env` file content | `{}` |
| `fab_manager_config_database` | A dict of `database.yml` | `` |
| `fab_manager_packages` | A list of required packages | `{{ __fab_manager_packages }}` |
| `fab_manager_db_host` | Address of the database | `127.0.0.1` |
| `fab_manager_db_port` | Port number of the database | `5432` |
| `fab_manager_db_name` | Name of the database | `fab` |
| `fab_manager_db_user` | User name of the database | `fab` |
| `fab_manager_db_password` | Password of `fab_manager_db_name` | `` |
| `fab_manager_db_extensions` | A list of `postgresql` extensions to enable. The extensions must be `trusted`. | `["unaccent", "pg_trgm"]` |
| `fab_manager_redis_host` | Address of `redis` server | `127.0.0.1` |
| `fab_manager_es_host` | Port number of `redis` server | `127.0.0.1` |
| `fab_manager_http_address` | Address for `fab-manager` to bind | `127.0.0.1` |
| `fab_manager_http_port` | Port number for `fab-manager` to bind | `5000` |
| `fab_manager_http_schema` | HTTP scheme of the protocol | `http` |
| `fab_manager_extra_packages` | A list of extra packages to install | `[]` |
| `fab_manager_restart_handler` | A list of handlers to notify | `[]` |

## `fab_manager_git_option`

This dict is passed to `ansible.builtin.git` `ansible` module as an argument.
Keys are parameter names of the module.
[ansible.builtin.git module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/git_module.html)
for details.

## Debian

```yaml
---
__fab_manager_packages:
- libpq-dev
- postgresql-client-13
- imagemagick
- nodejs
- yarnpkg
```

## Devuan-4

```yaml
---
__fab_manager_packages:
- libpq-dev
- postgresql-client-13
- imagemagick
- nodejs
- yarnpkg
```

## FreeBSD

```yaml
---
__fab_manager_packages:
- databases/postgresql13-client
- graphics/ImageMagick6
- www/node14
- www/yarn-node14
```

## OpenBSD

```yaml
---
__fab_manager_packages:
- ImageMagick
- node
- yarn
- pkgconf
- libxml
- gtar--
- xz
- ruby27-nokogiri
```

## RedHat

```yaml
---
__fab_manager_packages:
- ruby-devel
- gcc
- gcc-c++
- libpq-devel
- ImageMagick
- nodejs
- yarnpkg
```

# Dependencies

## Collections

* `community.general`
* `community.postgresql`

# Example Playbook

```yaml
---
- hosts: localhost
  roles:
    - trombik.git
    - trombik.sysctl
    - trombik.postgresql
    - trombik.redis
    - trombik.language_ruby
    - ansible-role-fab_manager
    - trombik.supervisor
    - trombik.haproxy
  vars:
    project_fab_manager_admin_user: admin@example.org
    project_fab_manager_admin_password: password
    project_db_host: 127.0.0.1
    project_db_name: fab
    project_db_user: fab
    project_db_password: password
    project_db_admin_user: admin
    project_db_admin_password: password
    project_redis_host: 127.0.0.1
    project_es_host: 127.0.0.1  # XXX unused
    project_rails_env: production

    fab_manager_groups:
      - ansible
    fab_manager_restart_handler:
      - Restart supervisor
    fab_manager_redis_host: "{{ project_redis_host }}"
    fab_manager_db_host: "{{ project_db_host }}"
    fab_manager_db_name: "{{ project_db_name }}"
    fab_manager_db_user: "{{ project_db_user }}"
    fab_manager_db_password: "{{ project_db_password }}"
    fab_manager_db_admin_user: "{{ project_db_admin_user }}"
    fab_manager_db_admin_password: "{{ project_db_admin_password }}"

    fab_manager_config: ""
    fab_manager_config_database:
      development:
        adapter: postgresql
        host: "{{ fab_manager_db_host }}"
        encoding: unicode
        database: "{{ fab_manager_db_name }}"
        pool: 25
        username: "{{ fab_manager_db_user }}"
        password: "{{ fab_manager_db_password }}"
      production:
        adapter: postgresql
        host: "{{ fab_manager_db_host }}"
        encoding: unicode
        database: "{{ fab_manager_db_name }}"
        pool: 25
        username: "{{ fab_manager_db_user }}"
        password: "{{ fab_manager_db_password }}"

    fab_manager_env:
      # XXX webpack needs a lot of memory
      NODE_OPTIONS: "--max-old-space-size=2048"
      RAILS_ENV: "{{ project_rails_env }}"
      # see:
      # https://github.com/sleede/fab-manager/blob/master/doc/environment.md
      POSTGRES_HOST: "{{ fab_manager_db_host }}"
      POSTGRES_USERNAME: "{{ fab_manager_db_user }}"
      POSTGRES_PASSWORD: "{{ fab_manager_db_password }}"
      REDIS_HOST: "{{ fab_manager_redis_host }}"
      ELASTICSEARCH_HOST: "{{ fab_manager_es_host }}"

      SECRET_KEY_BASE: 83daf5e7b80d990f037407bab78dff9904aaf3c195a50f84fa8695a22287e707dfbd9524b403b1dcf116ae1d8c06844c3d7ed942564e5b46be6ae3ead93a9d30

      STRIPE_API_KEY: ""
      STRIPE_PUBLISHABLE_KEY: ""

      OAUTH_CLIENT_ID: github-oauth-app-id
      OAUTH_CLIENT_SECRET: github-oauth-app-secret

      DEFAULT_HOST: "{{ fab_manager_http_address }}:{{ fab_manager_http_port }}"
      DEFAULT_PROTOCOL: "{{ fab_manager_http_schema }}"

      DELIVERY_METHOD: smtp
      SMTP_ADDRESS: 127.0.0.1
      SMTP_PORT: 587
      SMTP_USER_NAME: user
      SMTP_PASSWORD: password
      SMTP_AUTHENTICATION: plain
      SMTP_ENABLE_STARTTLS_AUTO: "true"
      SMTP_OPENSSL_VERIFY_MODE: ""
      SMTP_TLS: "false"

      RAILS_LOCALE: en
      APP_LOCALE: en
      MOMENT_LOCALE: en
      SUMMERNOTE_LOCALE: en-US
      ANGULAR_LOCALE: en
      FULLCALENDAR_LOCALE: en
      INTL_LOCALE: en-US
      INTL_CURRENCY: USD
      FORCE_VERSION_CHECK: "false"
      ALLOW_INSECURE_HTTP: "false"

      POSTGRESQL_LANGUAGE_ANALYZER: english

      TIME_ZONE: Asia/Bangkok
      WEEK_STARTING_DAY: monday
      D3_DATE_FORMAT: "%Y/%m/%d"
      UIB_DATE_FORMAT: "yyyy/MM/dd"
      EXCEL_DATE_FORMAT: "dd/mm/yyyy"

      OPENLAB_BASE_URI: "https://openprojects.fab-manager.com"
      OPENLAB_SSL_VERIFY: "true"

      ADMINSYS_EMAIL: "{{ project_fab_manager_admin_user }}"
      ADMIN_EMAIL: "{{ project_fab_manager_admin_user }}"
      ADMIN_PASSWORD: "{{ project_fab_manager_admin_password }}"
      LOG_LEVEL: debug
      DISK_SPACE_MB_ALERT: 100
      # 5242880 = 5 megabytes
      MAX_IMPORT_SIZE: 5242880
      # 10485760 = 10 megabytes
      MAX_IMAGE_SIZE: 10485760
      # 20971520 = 20 megabytes
      MAX_CAO_SIZE: 20971520

    # ___________________________________postgresql
    postgresql_initial_password: password
    postgresql_debug: yes

    # XXX use 13 for trusted extensions
    os_postgresql_major_version:
      Devuan: "{% if ansible_distribution_version | int >= 4 %}13{% else %}11{% endif %}"
      Ubuntu: 12
    postgresql_major_version: "{{ os_postgresql_major_version[ansible_distribution] | default(13) }}"
    os_sysctl:
      FreeBSD: {}
      OpenBSD:
        kern.seminfo.semmni: 60
        kern.seminfo.semmns: 1024
      Debian: {}
      RedHat: {}
    sysctl: "{{ os_sysctl[ansible_os_family] }}"

    os_postgresql_extra_packages:
      FreeBSD:
        - "databases/postgresql{{ postgresql_major_version }}-contrib"
      OpenBSD:
        - postgresql-contrib
      Debian:
        - postgresql-contrib
      RedHat:
        - postgresql-contrib

    postgresql_extra_packages: "{{ os_postgresql_extra_packages[ansible_os_family] }}"
    postgresql_pg_hba_config: |
      host    all             all             127.0.0.1/32            {{ postgresql_default_auth_method }}
      host    all             all             ::1/128                 {{ postgresql_default_auth_method }}
      local   replication     all                                     trust
      host    replication     all             127.0.0.1/32            trust
      host    replication     all             ::1/128                 trust
    postgresql_config: |
      {% if ansible_os_family == 'Debian' %}
      data_directory = '{{ postgresql_db_dir }}'
      hba_file = '{{ postgresql_conf_dir }}/pg_hba.conf'
      ident_file = '{{ postgresql_conf_dir }}/pg_ident.conf'
      external_pid_file = '/var/run/postgresql/{{ postgresql_major_version }}-main.pid'
      port = 5432
      max_connections = 100
      unix_socket_directories = '/var/run/postgresql'
      ssl = on
      ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
      ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
      shared_buffers = 128MB
      dynamic_shared_memory_type = posix
      log_line_prefix = '%m [%p] %q%u@%d '
      log_timezone = 'UTC'
      cluster_name = '{{ postgresql_major_version }}/main'
      stats_temp_directory = '/var/run/postgresql/{{ postgresql_major_version }}-main.pg_stat_tmp'
      datestyle = 'iso, mdy'
      timezone = 'UTC'
      lc_messages = 'C'
      lc_monetary = 'C'
      lc_numeric = 'C'
      lc_time = 'C'
      default_text_search_config = 'pg_catalog.english'
      include_dir = 'conf.d'
      password_encryption = {{ postgresql_default_auth_method }}
      {% else %}
      max_connections = 100
      shared_buffers = 128MB
      dynamic_shared_memory_type = posix
      max_wal_size = 1GB
      min_wal_size = 80MB
      log_destination = 'syslog'
      log_timezone = 'UTC'
      update_process_title = off
      datestyle = 'iso, mdy'
      timezone = 'UTC'
      lc_messages = 'C'
      lc_monetary = 'C'
      lc_numeric = 'C'
      lc_time = 'C'
      default_text_search_config = 'pg_catalog.english'
      password_encryption = {{ postgresql_default_auth_method }}
      {% endif %}
    postgresql_users:
      - name: "{{ project_db_user }}"
        password: "{{ project_db_password }}"
        role_attr_flags: CREATEDB
      - name: "{{ project_db_admin_user }}"
        password: "{{ project_db_admin_password }}"
        role_attr_flags: SUPERUSER

    postgresql_databases:
      - name: "{{ project_db_name }}"
        owner: "{{ project_db_user }}"
        state: present

    project_postgresql_initdb_flags: --encoding=utf-8 --lc-collate=C --locale=en_US.UTF-8
    project_postgresql_initdb_flags_pwfile: "--pwfile={{ postgresql_initial_password_file }}"
    project_postgresql_initdb_flags_auth: "--auth-host={{ postgresql_default_auth_method }} --auth-local={{ postgresql_default_auth_method }}"
    os_postgresql_initdb_flags:
      FreeBSD: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }} {{ project_postgresql_initdb_flags_auth }}"
      OpenBSD: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }} {{ project_postgresql_initdb_flags_auth }}"
      RedHat: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }} {{ project_postgresql_initdb_flags_auth }}"
      # XXX you cannot use --auth-host or --auth-local here because
      # pg_createcluster, which is executed during the installation, overrides
      # them, forcing md5
      Debian: "{{ project_postgresql_initdb_flags }} {{ project_postgresql_initdb_flags_pwfile }}"

    postgresql_initdb_flags: "{{ os_postgresql_initdb_flags[ansible_os_family] }}"
    os_postgresql_flags:
      FreeBSD: |
        postgresql_flags="-w -s -m fast"
      OpenBSD: ""
      Debian: ""
      RedHat: ""
    postgresql_flags: "{{ os_postgresql_flags[ansible_os_family] }}"

    # ___________________________________redis
    redis_password: ""
    redis_config: |
      databases 17
      save 900 1
      bind {{ project_redis_host }}
      protected-mode no
      port {{ redis_port }}
      timeout 0
      tcp-keepalive 300
      daemonize yes
      pidfile /var/run/redis/{{ redis_service }}.pid
      loglevel notice
      logfile {{ redis_log_file }}
      always-show-logo no
      dbfilename dump.rdb
      dir {{ redis_db_dir }}/

    # ___________________________________supervisor
    os_supervisor_flags:
      OpenBSD: "-c {{ supervisor_conf_file }}"
      FreeBSD: |
        supervisord_config="{{ supervisor_conf_file }}"
        supervisord_user="{{ supervisor_user }}"
    # "
    supervisor_flags: "{{ os_supervisor_flags[ansible_os_family] | default('') }}"

    # see https://github.com/sleede/fab-manager/blob/master/docker/supervisor.conf
    supervisor_config: |
      [unix_http_server]
      file={{ supervisor_unix_socket_file }}

      [supervisord]
      logfile={{ supervisor_log_file }}
      logfile_maxbytes=50MB
      logfile_backups=10
      loglevel=info
      pidfile={{ supervisor_pid_file }}
      nodaemon=false
      minfds=1024
      minprocs=200

      [rpcinterface:supervisor]
      supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

      [supervisorctl]
      serverurl=unix://{{ supervisor_unix_socket_file }}

      [include]
      files = {{ supervisor_conf_d_dir }}/*.conf

      {% set _environment = fab_manager_env.keys() | zip(fab_manager_env.values() | map('regex_replace', '(^.*$)', '\"\\1\"') | map('regex_replace', '%', '%%')) | map('join', '=') | join(',') %}
      {# ' for vim syntax #}

      [program:app]
      user={{ fab_manager_user }}
      environment=PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin",HOME={{ fab_manager_home }},{{ _environment }}
      directory={{ fab_manager_repo_dir }}
      command=bundle exec rails s puma -p {{ fab_manager_http_port }} -b {{ fab_manager_http_address }}
      stderr_logfile={{ supervisor_log_dir }}/app.err.log
      stdout_logfile={{ supervisor_log_dir }}/app.log

      [program:worker]
      user={{ fab_manager_user }}
      environment=PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin",HOME={{ fab_manager_home }},{{ _environment }}
      directory={{ fab_manager_repo_dir }}
      command=bundle exec sidekiq -C {{ fab_manager_repo_dir }}/config/sidekiq.yml
      stderr_logfile={{ supervisor_log_dir }}/worker.err.log
      stdout_logfile={{ supervisor_log_dir }}/worker.log

    # ___________________________________haproxy
    project_backend_port: 8000
    os_haproxy_selinux_seport:
      FreeBSD: {}
      Debian: {}
      RedHat:
        ports:
          - 80
          - 8404
        proto: tcp
        setype: http_port_t
    haproxy_selinux_seport: "{{ os_haproxy_selinux_seport[ansible_os_family] }}"
    haproxy_config: |
      global
        daemon
      {% if ansible_os_family == 'FreeBSD' %}
      # FreeBSD package does not provide default
        maxconn 4096
        log /var/run/log local0 notice
          user {{ haproxy_user }}
          group {{ haproxy_group }}
      {% elif ansible_os_family == 'Debian' %}
        log /dev/log  local0
        log /dev/log  local1 notice
        chroot {{ haproxy_chroot_dir }}
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
        stats timeout 30s
        user {{ haproxy_user }}
        group {{ haproxy_group }}

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
          ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
          ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
          ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
      {% elif ansible_os_family == 'OpenBSD' %}
        log 127.0.0.1   local0 debug
        maxconn 1024
        chroot {{ haproxy_chroot_dir }}
        uid 604
        gid 604
        pidfile /var/run/haproxy.pid
      {% elif ansible_os_family == 'RedHat' %}
      log         127.0.0.1 local2
      chroot      /var/lib/haproxy
      pidfile     /var/run/haproxy.pid
      maxconn     4000
      user        haproxy
      group       haproxy
      daemon
      {% endif %}

      defaults
        log global
        mode http
        timeout connect 5s
        timeout client 10s
        timeout server 10s
        option  httplog
        option  dontlognull
        retries 3
        maxconn 2000
      {% if ansible_os_family == 'Debian' %}
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http
      {% elif ansible_os_family == 'OpenBSD' %}
        option  redispatch
      {% endif %}

      frontend http-in
        bind *:80
        default_backend servers

      backend servers
        option forwardfor
        server server1 {{ fab_manager_http_address }}:{{ fab_manager_http_port }} maxconn 32 check inter 1000

      frontend stats
        bind *:8404
        mode http
        no log
        acl network_allowed src 127.0.0.0/8
        tcp-request connection reject if !network_allowed
        stats enable
        stats uri /
        stats refresh 10s
        stats admin if LOCALHOST

    os_haproxy_flags:
      FreeBSD: |
        haproxy_config="{{ haproxy_conf_file }}"
        #haproxy_flags="-q -f ${haproxy_config} -p ${pidfile}"
      Debian: |
        #CONFIG="/etc/haproxy/haproxy.cfg"
        #EXTRAOPTS="-de -m 16"
      OpenBSD: ""
      RedHat: |
        OPTIONS=""
    haproxy_flags: "{{ os_haproxy_flags[ansible_os_family] }}"
```

# License

```
Copyright (c) 2022 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>

This README was created by [qansible](https://github.com/trombik/qansible)
