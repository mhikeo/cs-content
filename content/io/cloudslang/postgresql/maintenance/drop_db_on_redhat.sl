########################################################################################################################
#!!
#! @description: Drop a postgresql database on machines that are running
#!               Red Hat based linux
#!
#! @input hostname: Hostname or IP address of the target machine
#! @input username: Username used to connect to the target machine
#! @input password: The root or priviledged account password
#! @input proxy_host: The proxy server used to access the remote machine
#!                    Optional
#! @input proxy_port: The proxy server port
#!                    Valid values: -1 and numbers greater than 0.
#!                    Default: '8080'
#!                    Optional
#! @input proxy_username: The user name used when connecting to the proxy
#!                        Optional
#! @input proxy_password: The proxy server password associated with the proxy_username input value
#!                        Optional
#! @input connection_timeout: Time in milliseconds to wait for the connection to be made
#!                            Default value: '10000'
#!                            Optional
#! @input execution_timeout: Time in milliseconds to wait for the command to complete
#!                           Default: '90000'
#!                           Optional
#! @input installation_location: The postgresql installation location
#!                           Default: '/var/lib/pgsql/10'
#! @input pg_ctl_location: Path of the pg_ctl binay
#!                         Default: '/usr/pgsql-10/bin'
#! @input db_name: Specifies the name of the database to be dropped
#! @input db_echo: Echo the commands that dropdb generates and sends to the server
#!              Valid values: 'true', 'false'
#!              Default value: 'true'
#! @input private_key_file: Absolute path to private key file
#!                          Optional
#!
#! @output return_result: STDOUT of the remote machine in case of success or the cause of the error in case of exception
#! @output return_code: '0' if success, '-1' otherwise
#! @output exception: contains the stack trace in case of an exception
#!
#! @result SUCCESS: The result of a flow
#! @result FAILURE: error
#!!#
########################################################################################################################
namespace: io.cloudslang.postgresql.maintenance

imports:
  base: io.cloudslang.base.cmd
  ssh: io.cloudslang.base.ssh
  strings: io.cloudslang.base.strings
  utils: io.cloudslang.base.utils
  postgres: io.cloudslang.postgresql
  print: io.cloudslang.base.print

flow:
  name: drop_db_on_redhat

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
        default: '/var/lib/pgsql/10'
    - pg_ctl_location:
        default: '/usr/pgsql-10/bin'
    - db_name:
        required: true
    - db_echo:
        default: 'true'
    - private_key_file:
        required: false
  workflow:
    - check_postgress_is_running:
        do:
           postgres.server.redhat.run_pg_ctl_command:
              - operation: 'status'
              - installation_location
              - pg_ctl_location
              - hostname
              - username
              - proxy_host
              - proxy_port
              - proxy_username
              - proxy_password
              - connection_timeout
              - execution_timeout
              - private_key_file
        publish:
            - return_result
            - error_message
            - exception
            - return_code
            - standard_err

    - build_dropdb_command:
        do:
           postgres.maintenance.commands.dropdb_command:
              - db_name
              - db_echo
              - db_username: 'postgres'
        publish:
           - psql_command
        navigate:
           - SUCCESS: drop_database

    - drop_database:
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
                  ${psql_command}
        publish:
            - return_code
            - return_result
            - exception: ${standard_err}

    - check_result:
          do:
            strings.string_equals:
              - first_string: ${exception}
              - second_string: ${''}

  outputs:
    - return_result
    - exception
    - return_code :  ${"0" if exception == '' else "-1"}
  results:
    - SUCCESS
    - FAILURE
