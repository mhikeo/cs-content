namespace: io.cloudslang.postgresql.windows.utils

imports:
  base: io.cloudslang.base.cmd
  strings: io.cloudslang.base.strings
  utils: io.cloudslang.base.utils
  postgres: io.cloudslang.postgresql
  scripts: io.cloudslang.base.powershell

flow:
  name: check_postgres_is_up

  inputs:
    - hostname:
        required: true
    - hostname_port:
         required: false
    - hostname_protocol:
        required: false
    - username:
        sensitive: true
    - password:
        sensitive: true
    - proxy_host:
        required: false
    - proxy_port:
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
    - execution_timeout:
        default: '180'
    - installation_location:
        required: true
    - data_dir:
        required: true
    - service_name:
        required: true
    - operation:
        required: false
    - start_on_boot:
        required: false
    - private_key_file:
        required: false

  workflow:
    - get_pwsh_command_by_operation_name:
        do:
          postgres.windows.utils.get_system_service_command:
             - service_name: ${service_name}
             - operation: 'status'
        publish:
            - pwsh_command
            - exception
            - return_code
            - return_result
        navigate:
          - SUCCESS: run_command
          - FAILURE: FAILURE

    - run_command:
        do:
           scripts.powershell_script:
            - host: ${hostname}
            - port: ${hostname_port}
            - protocol: ${hostname_protocol}
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - operation_timeout: ${execution_timeout}
            - script: ${pwsh_command}
        publish:
          -  return_code
          -  return_result
          -  script_exit_code
          -  exception
          - stderr
        navigate:
          - SUCCESS: verify
          - FAILURE: FAILURE

    - verify:
          do:
            strings.string_occurrence_counter:
              - string_in_which_to_search: ${standard_out}
              - string_to_find: 'Status : Running'
          navigate:
            - SUCCESS: SUCCESS
            - FAILURE: FAILURE
  # pg_ctl: server is running (PID: 30718)
  outputs:
      - process_id : ${standard_out.split('PID:')[1].split(')')[0] if standard_out is not None and 'server is running' in standard_out else ""}
      - return_result
      - exception : ${get('standard_err','').strip()}
      - return_code
  results:
    - SUCCESS
    - FAILURE
