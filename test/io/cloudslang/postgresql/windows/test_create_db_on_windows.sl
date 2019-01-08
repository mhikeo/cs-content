########################################################################################################################
#!!
#! @description: Drop a postgresql database on machines that are running on Windows
#!
#!
#! @input hostname: Hostname or IP address of the target machine
#! @input hostname_port: The WinRM service port
#!                       Default: '5985'
#!                       Optional
#! @input hostname_protocol: The WinRM service protocol
#!              Default: 'http'
#!              Optional
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
#! @input execution_timeout: Time in seconds to wait for the command to complete
#!                           Default: '90'
#!                           Optional
#! @input installation_location: The postgresql installation location
#!                               Default: 'C:\\Program Files\\PostgreSQL\\10.6'
#! @input service_name: The service name
#!                      Default: 'postgresql'
#! @input service_account: The service accoount
#! @input service_password: The service password
#! @input db_name: Specifies the name of the database to be dropped
#! @input db_echo: Echo the commands that dropdb generates and sends to the server
#!                 Valid values: 'true', 'false'
#!                 Default value: 'true'
#!
#! @output return_result: STDOUT of the remote machine in case of success or the cause of the error in case of exception
#! @output return_code: '0' if success, '-1' otherwise
#! @output exception: contains the stack trace in case of an exception
#!
#! @result SUCCESS: The result of a flow
#! @result FAILURE: error
#!!#
########################################################################################################################
namespace: io.cloudslang.postgresql.windows

imports:
  base: io.cloudslang.base.cmd
  strings: io.cloudslang.base.strings
  utils: io.cloudslang.base.utils
  postgres: io.cloudslang.postgresql
  scripts: io.cloudslang.base.powershell

flow:
  name: test_create_db_on_windows

  inputs:
    - hostname:
        required: true
    - hostname_port:
        default: '5985'
        required: false
    - hostname_protocol:
        default: 'http'
        required: false
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
    - execution_timeout:
        default: '90'
    - installation_location:
        default: 'C:\\Program Files\\PostgreSQL\\10.6'
    - service_name:
        default: 'postgresql'
    - service_account:
        required: true
    - service_password:
        required: true
        sensitive: true
    - db_name:
        default: 'postgres'
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
  workflow:

    - create_db:
        do:
          postgres.windows.create_db_on_windows:
            - hostname
            - hostname_port
            - hostname_protocol
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - execution_timeout
            - installation_location
            - service_name
            - service_account
            - service_password
            - db_name
            - db_description
            - db_tablespace
            - db_encoding
            - db_locale
            - db_owner
            - db_template
            - db_echo
        publish:
          - return_result
          - exception
          - return_code
          - stderr
        navigate:
          - SUCCESS: build_db_info_query
          - FAILURE: parse_xml_exception

    - build_db_info_query:
        do:
          postgres.common.get_db_info_query:
              - db_name
        publish:
          - sql_query
        navigate:
          - SUCCESS: get_db_info_settings

    - get_db_info_settings:
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
              - script: >
                  ${'$env:PGPASSWORD=\''+service_password+'\';Set-Location -Path \"' + installation_location+'\\\\bin\"; $psql = get-command .\\psql.exe; $user =\''+ service_account +'\'; & $psql -U $user -A -t -c \"'+ sql_query + '\"'}
        publish:
            - return_code
            - return_result
            - exception
            - db_settings: ${return_result.strip()}
        navigate:
          - SUCCESS: drop_db
          - FAILURE: drop_db

    - drop_db:
         do:
            postgres.windows.drop_db_on_windows:
              - hostname
              - hostname_port
              - hostname_protocol
              - username
              - password
              - proxy_host
              - proxy_port
              - proxy_username
              - proxy_password
              - execution_timeout
              - installation_location
              - service_name
              - service_account
              - service_password
              - db_name
              - db_echo
         publish:
              - return_result
              - exception
              - return_code
         navigate:
          - SUCCESS: SUCCESS
          - FAILURE: FAILURE

    - parse_xml_exception:
         do:
            parse_powershell_xml_object:
               - xml_object: ${get('exception', '')}
         publish:
             - exception_from_xml: ${exception_message}
         navigate:
            - SUCCESS: FAILURE

  outputs:
    - return_result
    - db_settings
    - exception_from_xml: ${get('exception_from_xml', '')}
    - exception: ${get('exception', '').strip()}
    - return_code
  results:
    - SUCCESS
    - FAILURE