namespace: io.cloudslang.postgresql.server

imports:
  postgres: io.cloudslang.postgresql
  utils: io.cloudslang.base.utils
  ssh: io.cloudslang.base.ssh
  strings: io.cloudslang.base.strings

flow:
  name: test_install_postgres_on_redhat

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
    - installation_file:
        default: 'https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-redhat10-10-2.noarch.rpm'
        required: false
    - service_account:
        default: 'postgres'
    - service_name:
        default: 'postgresql-10'
    - service_password:
        default: 'postgres'
    - private_key_file:
        required: false
  workflow:
    - check_host_prereqeust_port:
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
                  ${'sudo netstat -tulnp | grep 5432'}
        publish:
            - return_code
            - return_result
            - exception: ${standard_err}
        navigate:
            - SUCCESS: verify_default_postgres_port_is_not_bind
            - FAILURE: FAILURE

    - verify_default_postgres_port_is_not_bind:
       do:
          strings.string_equals:
            - first_string: ${return_result}
            - second_string: ''
       navigate:
         - SUCCESS: check_host_prereqeust_service_name
         - FAILURE: DEFAULT_PORT_IS_BIND

    - check_host_prereqeust_service_name:
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
                  ${'sudo systemctl list-unit-files --type=service | grep -i ' + service_name}
        publish:
            - return_code
            - return_result
            - exception: ${standard_err}
        navigate:
            - SUCCESS: verify_default_postgres_service_name
            - FAILURE: FAILURE

    - verify_default_postgres_service_name:
       do:
          strings.string_equals:
            - first_string: ${return_result}
            - second_string: ''
       navigate:
         - SUCCESS: derive_postgres_version
         - FAILURE: SERVICE_NAME_HAS_REGISTERED

    - derive_postgres_version:
        do:
          postgres.server.redhat.derive_postgres_version:
            - service_name
        publish:
          - pkg_name
          - home_dir
          - initdb_dir
        navigate:
          - SUCCESS: install_postgres_on_redhat

    - install_postgres_on_redhat:
       do:
         install_postgres_on_redhat:
            - hostname
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - connection_timeout
            - execution_timeout
            - installation_file
            - service_account
            - service_name
            - service_password
            - private_key_file
       publish:
           - install_return_result: ${return_result}
           - install_return_code: ${return_code}
           - install_exception: ${exception}
       navigate:
           - SUCCESS: clear_host_postreqeust
           - POSTGRES_PROCESS_CHECK_FAILURE: clear_host_postreqeust
           - POSTGRES_VERIFY_INSTALL_FAILURE: clear_host_postreqeust
           - POSTGRES_VERIFY_RPM_FAILURE: clear_host_postreqeust
           - POSTGRES_INSTALL_RPM_REPO_FAILURE: clear_host_postreqeust
           - POSTGRES_INSTALL_PACKAGE_FAILURE: clear_host_postreqeust
           - POSTGRES_INIT_DB_FAILURE: clear_host_postreqeust
           - POSTGRES_START_FAILURE: clear_host_postreqeust

    - clear_host_postreqeust:
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
                  ${'sudo systemctl stop ' + service_name+ ' && sudo systemctl disable ' + service_name +  ' && sudo rm -fR ' + initdb_dir + ' && sudo rm -fR /usr/' + home_dir + '/data-test && /usr/lib/systemd/system/' + service_name + '.service'}
        publish:
            - return_code
            - return_result
            - exception: ${standard_err}
  outputs:
    - install_return_result
    - install_return_code
    - install_exception
    - return_result
    - return_code
    - exception
  results:
    - SUCCESS
    - FAILURE
    - DEFAULT_PORT_IS_BIND
    - SERVICE_NAME_HAS_REGISTERED

