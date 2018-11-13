namespace: io.cloudslang.postgresql

imports:
  ssh: io.cloudslang.base.ssh
  remote: io.cloudslang.base.remote_file_transfer
  folders: io.cloudslang.base.os.linux.folders
  groups: io.cloudslang.base.os.linux.groups
  users: io.cloudslang.base.os.linux.users
  strings: io.cloudslang.base.strings

flow:
  name: install_postgres_on_redhat

  inputs:
    - hostname:
        required: true
    - username:
        sensitive: true
    # - password:
    #     default: ''
    #     required: false
    #     sensitive: true
    # - proxy_host
    # - proxy_port
    # - proxy_username
    # - proxy_password
    # - connecion_timeout:
    #     default: '10'
    # - execution_timeout:
    #     default: '90'
    # - installation_file:
    #     required: true
    # - installation_location:
    #     required: true
    # - superuser_password:
    #     default: 'postgres'
    #     required: true
    # - add_in_path:
    #     default: 'false'
    # - create_shortcuts:
    #     default: 'yes'
    # - data_dir
    # - debug_level:
    #     default: '2'
    # - debug_trace
    # - disable_stackbuilder
    # - extract_only:
    #     default: 'false'
    # - help
    # - installer_language:
    #     default: 'en'
    # - install_plpgsql:
    #     default: 'true'
    # - install_runtimes:
    #     default: 'true'
    # - locale
    # - mode
    # - option_file
    # - prefix
    # - server_port
    - service_account:
        default: 'postgres'
    # - service_name:
    #     default: 'postgresql-9.6'
    # - service_password:
    #     default: superuser_password
    - private_key_file:
        default: '/Users/mhjkc/Downloads/mhike-oregon-key-01.pem'

  workflow:
    - verify_if_postgres_is_running:
        do:
          ssh.ssh_flow:
            - host: ${hostname}
            - port: '22'
            - username
            - private_key_file
            - command: >
                ${'systemctl status postgresql-10.service | tail -1'}
        publish:
          - return_result
          - standard_err
          - standard_out
          - return_code
          - command_return_code
        navigate:
          - SUCCESS: check_postgres_is_running
          - FAILURE: POSTGRES_PROCESS_CHECK_FAILURE

    - check_postgres_is_running:
        do:
          strings.string_occurrence_counter:
            - string_in_which_to_search: ${standard_out}
            - string_to_find: 'Started'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: verify_if_postgres_is_installed
          # - FAILURE: POSTGRES_PROCESS_CHECK_FAILURE

    - verify_if_postgres_is_installed:
        do:
          ssh.ssh_flow:
            - host: ${hostname}
            - port: '22'
            - username
            - private_key_file
            - command: >
                ${'export LC_ALL=\"en_US.UTF-8\" && sudo yum list installed | grep postgresql10 | cut -d \".\" -f1'}
        publish:
          - return_result
          - standard_err
          - standard_out
          - return_code
          - command_return_code
        navigate:
          - SUCCESS: check_postgres_is_installed_result
          - FAILURE: POSTGRES_VERIFY_INSTALL_FAILURE

    - check_postgres_is_installed_result:
        do:
          strings.string_occurrence_counter:
            - string_in_which_to_search: ${standard_out}
            - string_to_find: 'postgresql10-server'
        navigate:
          - SUCCESS: start_postgres
          - FAILURE: verify_if_rpms_are_locally_available

    - verify_if_rpms_are_locally_available:
        do:
          ssh.ssh_flow:
            - host: ${hostname}
            - port: '22'
            - username
            - private_key_file
            - command: >
                ${'rpm -qa | grep postgresql10 | cut -d "." -f1'}
        publish:
          - return_result
          - standard_err
          - standard_out
          - return_code
          - command_return_code
        navigate:
          - SUCCESS: check_rpm_exist_result
          - FAILURE: POSTGRES_VERIFY_RPM_FAILURE

    - check_rpm_exist_result:
        do:
          strings.string_occurrence_counter:
            - string_in_which_to_search: ${standard_out}
            - string_to_find: 'postgresql10-server'
        navigate:
          - SUCCESS: install_server_packages
          - FAILURE: install_repository_rpm

    - install_repository_rpm:
        do:
          ssh.ssh_flow:
            - host: ${hostname}
            - port: '22'
            - username
            - private_key_file
            - command: >
                ${'export LC_ALL=\"en_US.UTF-8\" && sudo yum -y -q install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-redhat10-10-2.noarch.rpm'}
        publish:
          - return_result
          - standard_err
          - standard_out
          - return_code
          - command_return_code
        navigate:
          - SUCCESS: install_server_packages
          - FAILURE: POSTGRES_INSTALL_RPM_REPO_FAILURE

    - install_server_packages:
        do:
          ssh.ssh_flow:
            - host: ${hostname}
            - port: '22'
            - username
            - private_key_file
            - command: >
                ${'export LC_ALL=\"en_US.UTF-8\" && sudo yum -y install postgresql10-server postgresql10-contrib'}
        publish:
          - return_result
          - standard_err
          - standard_out
          - return_code
          - command_return_code
        navigate:
          - SUCCESS: initialize_db
          - FAILURE: POSTGRES_INSTALL_PACKAGE_FAILURE

    - initialize_db:
        do:
          ssh.ssh_flow:
            - host: ${hostname}
            - port: '22'
            - username
            - private_key_file
            - command: >
                ${'sudo /usr/pgsql-10/bin/postgresql-10-setup initdb'}
        publish:
          - return_result
          - standard_err
          - standard_out
          - return_code
          - command_return_code
        navigate:
          - SUCCESS: check_postgres_db_initialized
          - FAILURE: PORTGRES_INIT_DB_FAILURE

    - check_postgres_db_initialized:
        do:
          strings.string_occurrence_counter:
            - string_in_which_to_search: ${standard_out}
            - string_to_find: 'Initializing database ... OK'
        publish:
          - return_result
        navigate:
          - SUCCESS: start_postgres
          - FAILURE: PORTGRES_INIT_DB_FAILURE

    - start_postgres:
        do:
          ssh.ssh_flow:
            - host: ${hostname}
            - port: '22'
            - username
            - private_key_file
            - command: >
                ${'sudo systemctl enable postgresql-10 && sudo systemctl start postgresql-10 && sleep 15s && sudo systemctl status postgresql-10 | tail -1'}
        publish:
          - return_result
          - standard_err
          - standard_out
          - return_code
          - command_return_code
        navigate:
          - SUCCESS: check_postgres_has_started
          - FAILURE: POSTGRES_START_FAILURE

    - check_postgres_has_started:
        do:
          strings.string_occurrence_counter:
            - string_in_which_to_search: ${standard_out}
            - string_to_find: 'Started'
        publish:
          - return_result
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: POSTGRES_START_FAILURE


  outputs:
    - return_result
    - standard_err
    - standard_out
    - return_code
    - command_return_code
    - exception
    - message

  results:
    - SUCCESS
    - POSTGRES_PROCESS_CHECK_FAILURE
    - POSTGRES_VERIFY_INSTALL_FAILURE
    # - POSTGRES_INSTALL_CHECK_FAILURE
    - POSTGRES_VERIFY_RPM_FAILURE
    - POSTGRES_INSTALL_RPM_REPO_FAILURE
    - POSTGRES_INSTALL_PACKAGE_FAILURE
    - PORTGRES_INIT_DB_FAILURE
    - POSTGRES_START_FAILURE
