namespace: io.cloudslang.postgresql.configuration

imports:
  postgres: io.cloudslang.postgresql
  ssh: io.cloudslang.base.ssh

flow:
  name: test_configure_postgres_on_redhat

  inputs:
    - hostname:
        required: true
    - username:
        sensitive: true
    - password:
        default: ''
        required: false
        sensitive: true
    - private_key_file:
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
    - listen_addresses:
        default: 'localhost'
        required: false
    - port:
        default: '5432'
        required: false
    - ssl:
        required: false
    - ssl_ca_file:
        required: false
    - ssl_cert_file:
        required: false
    - ssl_key_file:
        required: false
    - max_connections:
        required: false
    - shared_buffers:
        required: false
    - effective_cache_size:
        required: false
    - autovacuum:
        required: false
    - work_mem:
        required: false
    - configuration_file:
        required: false
    - allowed_hosts:
        required: false
    - allowed_users:
        required: false
    - installation_location:
        default: '/var/lib/pgsql/10/data'
    - reboot:
        default: 'no'
    - temp_local_folder:
        default: '/tmp'
        required: false
    - pg_ctl_location:
        default: '/usr/pgsql-10/bin'
        required: false
  workflow:
    # Initial state: server is running
    - check_host_prerequest:
        do:
          postgres.server.redhat.check_postgres_is_up:
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
            - private_key_file
        publish:
            - return_result
            - exception
            - return_code
            - prev_process_id: ${process_id}
        navigate:
          - SUCCESS: configure
          - FAILURE: DB_IS_NOT_RUNNING

    - configure:
        do:
           postgres.configuration.configure_postgres_on_redhat:
              - hostname
              - username
              - password
              - proxy_host
              - proxy_port
              - proxy_username
              - proxy_password
              - connection_timeout
              - execution_timeout
              - listen_addresses
              - port
              - ssl
              - ssl_ca_file
              - ssl_cert_file
              - ssl_key_file
              - max_connections
              - shared_buffers
              - effective_cache_size
              - autovacuum
              - work_mem
              - configuration_file
              - allowed_hosts
              - allowed_users
              - installation_location
              - reboot
              - private_key_file
              - temp_local_folder
              - pg_ctl_location
        publish:
           - return_result
           - exception
           - return_code
        navigate:
          - SUCCESS: get_configuration_query
          - FAILURE: FAILURE

    - get_configuration_query:
        do:
          postgres.configuration.queries.get_configuration_query:
        publish:
          - sql_query
        navigate:
          - SUCCESS: verify

    - verify:
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
            - exception: ${standard_err}

  outputs:
    - return_result: ${return_result.strip()}
    - exception
    - return_code
  results:
    - SUCCESS
    - FAILURE
    - DB_IS_NOT_RUNNING