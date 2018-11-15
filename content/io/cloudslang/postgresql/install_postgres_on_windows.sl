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
        default: '52.13.110.166'
        required: true
    - port:
        required: false
    - username:
        default: 'Administrator'
        sensitive: true
    - password:
        default: '=%4WWALw=.gmnN9Ocv$BdZ.3JUJG9K*j'
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
        default: '300000'
    - installation_file:
        default: 'http://get.enterprisedb.com/postgresql/postgresql-10.6-1-windows-x64.exe'
        required: false
    - installation_location:
        default: 'C:\\Program Files\\PostgreSQL\\10.6'
        required: false
    - data_dir:
        default: 'C:\\Program Files\\PostgreSQL\\10.6\\data'
        required: false
    - server_port:
        default: '5432'
        required: false
    - service_name:
        default: 'postgresql'
    - service_account:
        default: 'postgres'
    - service_password:
        default: 'postgres'
    - locale:
        default: 'English, United States'
        required: false

  workflow:
    # - download_installer_module:
    #     do:
    #       scripts.powershell_script:
    #         - host: ${hostname}
    #         - port: '5985'
    #         - protocol: 'http'
    #         - username
    #         - password
    #         - proxy_host
    #         - proxy_port
    #         - proxy_username
    #         - proxy_password
    #         - script: >
    #             ${'(New-Object Net.WebClient).DownloadFile(\"https://drive.google.com/uc?export=download&id=1gsjRnxKx8J_WhmdaJ5PPBcAnjj6WKUud\",\"C:\Windows\Temp\Install-Postgres.zip\");(new-object -com shell.application).namespace(\"C:\Program Files\WindowsPowerShell\Modules\").CopyHere((new-object -com shell.application).namespace(\"C:\Windows\Temp\Install-Postgres.zip\").Items(),16)'}
    #     publish:
    #       - return_result
    #       - standard_err
    #       - standard_out
    #       - return_code
    #       - command_return_code
    #     navigate:
    #       - SUCCESS: SUCCESS
    #       - FAILURE: SUCCESS

    # - import_module:
    #     do:
    #       scripts.powershell_script:
    #         - host: ${hostname}
    #         - port: '5985'
    #         - protocol: 'http'
    #         - username
    #         - password
    #         - proxy_host
    #         - proxy_port
    #         - proxy_username
    #         - proxy_password
    #         - script: >
    #             ${'Import-Module Install-Postgres'}
    #     publish:
    #       - return_result
    #       - standard_err
    #       - standard_out
    #       - return_code
    #       - command_return_code
    #     navigate:
    #       - SUCCESS: SUCCESS
    #       - FAILURE: SUCCESS

    - install_postgres:
        do:
          scripts.powershell_script:
            - host: ${hostname}
            - port: '5985'
            - protocol: 'http'
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - script: >
                ${'Install-Postgres -User \"' + username + '\" -Password \"' + password + '\" -InstallerUrl \"' + installation_file + '\" -InstallPath \"' + installation_location + '\" -DataPath \"' + data_dir + '\" -Locale \"' + locale + '\" -Port ' + server_port + ' -ServiceName \"' + service_name + '\"'}
        publish:
          - return_result
          - standard_err
          - standard_out
          - return_code
          - command_return_code
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: POSTGRES_INSTALL_PACKAGE_FAILURE

  outputs:
    - return_result
    - return_code
    - exception
    - standard_err
    - standard_out
    - command_return_code

  results:
    - SUCCESS
    - POSTGRES_INSTALL_PACKAGE_FAILURE
