namespace: io.cloudslang.postgresql.server

imports:
  postgres: io.cloudslang.postgresql

flow:
  name: test_operate_postgres_on_redhat

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
    - operation:
        required: false
    - start_on_boot:
        required: false
    - private_key_file:
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
            - SUCCESS: do_operation
            - FAILURE: DB_IS_NOT_RUNNING

    - do_operation:
        do:
          postgres.server.operate_postgres_on_redhat:
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
             - operation
             - start_on_boot
             - private_key_file
             - pg_ctl_location
        publish:
            - return_result
            - exception
            - command_return_code
            - return_code
            - operation_exception: ${exception}
        navigate:
           - SUCCESS: verify_operation_result
           - FAILURE: check_host_postrequest

    - verify_operation_result:
        do:
          postgres.server.operate_postgres_on_redhat:
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
             - operation: 'status'
             - private_key_file
             - pg_ctl_location
        publish:
            - return_result
            - exception
            - command_return_code
            - return_code
            - operation_return_result: ${return_result}

    - get_system_service_status_on_boot:
        do:
          postgres.server.redhat.get_system_serive_status_on_boot:
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
          - service_status
          - exception
          - return_code

    - check_host_postrequest:
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
          - current_process_id: ${process_id}
        navigate:
            - SUCCESS: SUCCESS
            - FAILURE: start_postgres_postrequest

    - start_postgres_postrequest:
        do:
          postgres.server.operate_postgres_on_redhat:
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
             - operation: 'start'
             - private_key_file
             - pg_ctl_location

  outputs:
    - return_result
    - exception
    - command_return_code
    - return_code
    - operation_return_result: ${get('operation_return_result', '').strip()}
    - operation_exception: ${get('operation_exception', '').strip()}
    - service_status
    - prev_process_id
    - current_process_id
    - is_proccess_id_changed: ${ str(prev_process_id != '' and current_process_id != '' and prev_process_id != current_process_id)}
  results:
    - SUCCESS
    - FAILURE
    - DB_IS_NOT_RUNNING