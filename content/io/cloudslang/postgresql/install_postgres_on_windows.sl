########################################################################################################################
#!!
#! @description: Performs several powershell commands in order to deploy install postgresql application on machines that are running
#!               windows Server 2016
#!
#! @prerequisites: Java package
#!
#! @input hostname: hostname or IP address
#! @input username: username
#! @input password: The root or priviledged account password
#! @input proxy_host: Optional - The proxy server used to access the remote machine.
#! @input proxy_port: Optional - The proxy server port.
#!                    Valid values: -1 and numbers greater than 0.
#!                    Default: '8080'
#! @input proxy_username: Optional - The user name used when connecting to the proxy.
#! @input proxy_password: Optional - The proxy server password associated with the proxy_username input value.
#! @input connection_timeout: Optional - Time in milliseconds to wait for the connection to be made.
#!                         Default value: '10000'
#! @input execution_timeout: Optional - Time in milliseconds to wait for the command to complete.
#!                 Default: '90000'
#! @input installation_file: Optional - the postgresql installation file or link - Default: 'https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm'
#! @input service_name: The service name
#! @input service_account: The service account
#! @input service_password: The service password
#! @input private_key_file: Optional - the private key
#!
#! @output return_result: STDOUT of the remote machine in case of success or the cause of the error in case of exception
#! @output return_code: '0' if success, '-1' otherwise
#! @output exception: contains the stack trace in case of an exception
#!
#! @result SUCCESS: Postgresql install and/or startup was successful
#! @result POSTGRES_PROCESS_CHECK_FAILURE: There was an error checking postgresql process
#! @result POSTGRES_VERIFY_INSTALL_FAILURE: error verifying installation
#! @result POSTGRES_VERIFY_RPM_FAILURE: error verifying existence of postgresql rpm installer
#! @result POSTGRES_INSTALL_RPM_REPO_FAILURE: error installation postgresql rpm repo
#! @result POSTGRES_INSTALL_PACKAGE_FAILURE: error installing postgresql package
#! @result POSTGRES_INIT_DB_FAILURE: error initializing db
#! @result POSTGRES_START_FAILURE: error starting postgresql
#!!#
########################################################################################################################

namespace: io.cloudslang.postgresql

imports:
  scripts: io.cloudslang.base.powershell

flow:
  name: install_postgres_on_windows

  inputs:
    - hostname:
        default: 'ec2-34-220-130-20.us-west-2.compute.amazonaws.com'
        required: true
    - port:
        required: false
    - username:
        default: 'Administrator'
        sensitive: true
    - password:
        default: 'OeSM2hZE3G;iFjDhx!!VihxyGRI?iKcK'
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
        default: 'https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm'
        required: false
    - service_account:
        default: 'postgres'
    - service_name:
        default: 'postgresql-9.6'
    - service_password:
        default: 'postgres'

  workflow:
    - verify_if_active_directory_is_installed:
        do:
          scripts.powershell_script:
            - host: ${hostname}
            - port
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - script: >
                ${'Get-Module -ListAvailable -Name ActiveDirectory'}
        publish:
          - return_result
          - standard_err
          - standard_out
          - return_code
          - command_return_code
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: SUCCESS

  outputs:
    - return_result
    - return_code
    - exception
    - standard_err
    - standard_out
    - command_return_code

  results:
    - SUCCESS
