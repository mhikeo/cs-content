namespace: io.cloudslang.postgresql.maintenance

imports:
  strings: io.cloudslang.base.strings
  postgres: io.cloudslang.postgresql
  ssh: io.cloudslang.base.ssh
  utils: io.cloudslang.base.utils
  lists: io.cloudslang.base.lists

flow:
  name: test_create_db_on_redhat

  inputs:
    - hostname:
        required: true
    - username:
        required: true
    - password:
        default: ''
        required: false
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
    - db_name: 'cs_test'
    - db_description:
        required: false
    - db_tablespace:
        required: false
    - db_encoding:
        required: false
    - db_locale:
        required: false
    - db_owner:
        required: false
    - db_template:
        required: false
    - db_echo:
        default: 'true'
    - private_key_file:
        required: true
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
          - SUCCESS: build_db_info_query
          - FAILURE: FAILURE

    - build_db_info_query:
        do:
          postgres.maintenance.queries.get_db_info_query:
              - db_name
        publish:
          - sql_query
        navigate:
          - SUCCESS: execute_db_info_query

    - execute_db_info_query:
        do:
          ssh.ssh_flow:
            - host: ${hostname}
            - port: '22'
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - connect_timeout: ${connection_timeout}
            - timeout: ${execution_timeout}
            - private_key_file
            - command: >
                ${'sudo su - postgres -c \"psql -A -t -c \\\"'+ sql_query +'\\\"\"'}
        publish:
          - return_code
          - return_result
          - exception
          - standard_err
          - standard_out
          - db_settings: ${return_result.strip()}

    - clear_host_postreqeust:
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
  outputs:
    - return_result
    - exception
    - return_code
    - db_settings
  results:
    - SUCCESS
    - FAILURE
    - DB_IS_NOT_CLEAN
