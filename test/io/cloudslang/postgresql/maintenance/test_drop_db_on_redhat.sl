namespace: io.cloudslang.postgresql.maintenance

imports:
  base: io.cloudslang.base.cmd
  ssh: io.cloudslang.base.ssh
  strings: io.cloudslang.base.strings
  utils: io.cloudslang.base.utils
  postgres: io.cloudslang.postgresql
  print: io.cloudslang.base.print

flow:
  name: test_drop_db_on_redhat

  inputs:
    - hostname:
        required: true
    - username:
        sensitive: true
    - password:
        default: ''
        required: false
        sensitive: true
    - proxy_host:
        required: false
    - proxy_port:
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
    - connection_timeout:
        default: '10000'
    - execution_timeout:
        default: '90000'
    - installation_location:
        default: '/var/lib/pgsql/10/data'
    - pg_ctl_location:
        default: '/usr/pgsql-10/bin'
    - db_name:
        required: true
    - db_echo:
        default: 'true'
    - private_key_file:
        required: false
  workflow:
    - check_host_prereqeust:
         do:
            postgres.maintenance.check_if_db_exists_on_redhat:
              - hostname
              - username
              - password
              - proxy_host
              - proxy_port
              - proxy_username
              - proxy_password
              - connection_timeout
              - execution_timeout
              - db_name
              - private_key_file
         publish:
            - return_code
            - return_result
            - exception
         navigate:
            - DB_EXIST: DB_IS_NOT_CLEAN
            - DB_NOT_EXIST: create_db
            - FAILURE: FAILURE

    - create_db:
        do:
          postgres.maintenance.create_db_on_redhat:
            - hostname
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - connection_timeout
            - execution_timeout
            - installation_location
            - pg_ctl_location
            - db_name
            - db_description
            - db_tablespace
            - db_encoding
            - db_locale
            - db_owner
            - db_template
            - db_echo
            - private_key_file
        publish:
          - return_result
          - exception
          - return_code
        navigate:
          - SUCCESS: drop_db
          - FAILURE: FAILURE

    - drop_db:
         do:
            postgres.maintenance.drop_db_on_redhat:
              - hostname
              - username
              - password
              - proxy_host
              - proxy_port
              - proxy_username
              - proxy_password
              - connection_timeout
              - execution_timeout
              - installation_location
              - pg_ctl_location
              - db_name
              - db_echo
              - private_key_file
         publish:
             - return_result
             - exception
             - return_code
         navigate:
          - SUCCESS: verify
          - FAILURE: FAILURE
    - verify:
         do:
            postgres.maintenance.check_if_db_exists_on_redhat:
              - hostname
              - username
              - password
              - proxy_host
              - proxy_port
              - proxy_username
              - proxy_password
              - connection_timeout
              - execution_timeout
              - db_name
              - private_key_file
         publish:
            - return_code
            - return_result
            - exception
         navigate:
            - DB_EXIST: FAILURE
            - DB_NOT_EXIST: SUCCESS
            - FAILURE: FAILURE

  outputs:
    - return_result
    - exception
    - return_code
  results:
    - SUCCESS
    - FAILURE
    - DB_IS_NOT_CLEAN
