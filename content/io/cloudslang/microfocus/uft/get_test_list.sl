########################################################################################################################
#!!
#! @description: This flow returns the existing UFT scenarios in a provided path.
#!
#! @input host: The host where UFT scenarios are located.
#! @input port: The WinRM port of the provided host.
#!                    Default: https: '5986' http: '5985'
#! @input protocol: The WinRM protocol.
#! @input username: The username for the WinRM connection.
#! @input password: The password for the WinRM connection.
#! @input test_path: The path to the UFT scenario.
#! @input iterator: Used for development purposes.
#! @input auth_type:Type of authentication used to execute the request on the target server
#!                  Valid: 'basic', digest', 'ntlm', 'kerberos', 'anonymous' (no authentication).
#!                    Default: 'basic'
#!                    Optional
#! @input proxy_host: The proxy host.
#!                    Optional
#! @input proxy_port: The proxy port.
#!                    Default: '8080'
#!                    Optional
#! @input proxy_username: Proxy server user name.
#!                        Optional
#! @input proxy_password: Proxy server password associated with the proxy_username input value.
#!                        Optional
#! @input trust_all_roots: Specifies whether to enable weak security over SSL/TSL.
#!                         A certificate is trusted even if no trusted certification authority issued it.
#!                         Valid: 'true' or 'false'
#!                         Default: 'false'
#!                         Optional
#! @input x_509_hostname_verifier: Specifies the way the server hostname must match a domain name in the subject's
#!                                 Common Name (CN) or subjectAltName field of the X.509 certificate. The hostname
#!                                 verification system prevents communication with other hosts other than the ones you
#!                                 intended. This is done by checking that the hostname is in the subject alternative
#!                                 name extension of the certificate. This system is designed to ensure that, if an
#!                                 attacker(Man In The Middle) redirects traffic to his machine, the client will not
#!                                 accept the connection. If you set this input to "allow_all", this verification is
#!                                 ignored and you become vulnerable to security attacks. For the value
#!                                 "browser_compatible" the hostname verifier works the same way as Curl and Firefox.
#!                                 The hostname must match either the first CN, or any of the subject-alts. A wildcard
#!                                 can occur in the CN, and in any of the subject-alts. The only difference between
#!                                 "browser_compatible" and "strict" is that a wildcard (such as "*.foo.com") with
#!                                 "browser_compatible" matches all subdomains, including "a.b.foo.com".
#!                                 From the security perspective, to provide protection against possible
#!                                 Man-In-The-Middle attacks, we strongly recommend to use "strict" option.
#!                                 Valid: 'strict', 'browser_compatible', 'allow_all'.
#!                                 Default: 'strict'.
#!                                 Optional
#! @input trust_keystore: The pathname of the Java TrustStore file. This contains certificates from
#!                        other parties that you expect to communicate with, or from Certificate Authorities that
#!                        you trust to identify other parties.  If the protocol (specified by the 'url') is not
#!                       'https' or if trust_all_roots is 'true' this input is ignored.
#!                        Format: Java KeyStore (JKS)
#!                        Default value: 'JAVA_HOME/java/lib/security/cacerts'
#!                        Optional
#! @input trust_password: The password associated with the trust_keystore file. If trust_all_roots is false
#!                        and trust_keystore is empty, trust_password default will be supplied.
#!                        Default value: 'changeit'
#!                        Optional
#! @input operation_timeout: Defines the operation_timeout value in seconds to indicate that the clients expect a
#!                           response or a fault within the specified time.
#!                           Default: '60'
#!
#! @output tests: UFT scenario list from the specified path.
#! @output exception: Exception if there was an error when executing, empty otherwise.
#! @output return_code: '0' if success, '-1' otherwise.
#! @output return_result: The scripts result.
#! @output stderr: An error message in case there was an error while running power shell
#! @output script_exit_code: '0' if success, '-1' otherwise.
#! @output folders: folders from the specified path.
#! @output test_file_exists: file exist.
#!
#! @result SUCCESS: The operation executed successfully.
#! @result FAILURE: The operation could not be executed.
#!!#
########################################################################################################################

namespace: io.cloudslang.microfocus.uft

imports:
  ps: io.cloudslang.base.powershell
  strings: io.cloudslang.base.strings
  lists: io.cloudslang.base.lists
  math: io.cloudslang.base.math
  utils: io.cloudslang.base.utils

flow:
  name: get_test_list
  inputs:
    - host
    - username:
        required: false
    - password:
        required: false
        sensitive: true
    - port:
        required: false
    - protocol:
        required: false
    - test_path
    -  auth_type:
        default: 'basic'
        required: false
    - proxy_host:
        required: false
    - proxy_port:
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
    - trust_all_roots:
        default: 'false'
        required: false
    - x_509_hostname_verifier:
        default: 'strict'
        required: false
    - trust_keystore:
        default: ''
        required: false
    - trust_password:
        default: 'changeit'
        required: false
        sensitive: true
    - operation_timeout:
        default: '60'
        required: false
    - iterator:
        default: '0'
        private: true

  workflow:
    - get_folders:
        do:
          ps.powershell_script:
            - host
            - port
            - protocol
            - username
            - password:
                value: '${password}'
                sensitive: true
            - auth_type
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password:
                value: '${proxy_password}'
                sensitive: true
            - trust_all_roots
            - x_509_hostname_verifier
            - trust_keystore
            - trust_password:
                value: '${trust_password}'
                sensitive: true
            - operation_timeout
            - script: "${'(Get-ChildItem -Path \"'+ test_path +'\" -Directory).Name -join \",\"'}"
        publish:
          - exception
          - stderr
          - return_result
          - return_code
          - script_exit_code
          - folders: "${return_result.replace('\\n',',')}"
        navigate:
          - SUCCESS: string_equals_1
          - FAILURE: FAILURE

    - string_equals_1:
              do:
                strings.string_equals:
                  - first_string: '${folders}'
                  - second_string: ''
                  - ignore_case: 'false'

              navigate:
                - SUCCESS: FAILURE
                - FAILURE: length
    - length:
        do:
          lists.length:
            - list: "${get('folders', '')}"
        publish:
          - list_length: '${return_result}'
          - exception
          - return_result
          - return_code
        navigate:
          - SUCCESS: is_done
          - FAILURE: FAILURE
    - is_done:
        do:
          strings.string_equals:
            - first_string: '${iterator}'
            - second_string: '${list_length}'
        navigate:
          - SUCCESS: default_if_empty
          - FAILURE: get_by_index

    - default_if_empty:
        do:
          utils.default_if_empty:
            - initial_value: "${get('tests_list', '')}"
            - default_value: No tests founded in the provided path.
        publish:
          - tests_list: '${return_result}'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
    - get_by_index:
        do:
          lists.get_by_index:
            - list: '${folders}'
            - delimiter: ','
            - index: '${iterator}'
        publish:
          - folder_to_check: '${return_result}'
          - tests_list
        navigate:
          - SUCCESS: test_file_exists
          - FAILURE: on_failure

    - test_file_exists:
        do:
          ps.powershell_script:
            - host
            - port
            - protocol
            - username
            - password:
                value: '${password}'
                sensitive: true
            - auth_type
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password:
                value: '${proxy_password}'
                sensitive: true
            - trust_all_roots
            - x_509_hostname_verifier
            - trust_keystore
            - trust_password:
                value: '${trust_password}'
                sensitive: true
            - operation_timeout
            - script: "${'Test-Path \"' + test_path.rstrip(\\\\) + \"\\\\\" + folder_to_check + '\\\\Test.tsp\"'}"
        publish:
          - exception
          - stderr
          - return_result
          - return_code
          - script_exit_code
          - test_file_exists: "${return_result.replace('\\n',',')}"
        navigate:
          - SUCCESS: string_equals
          - FAILURE: on_failure

    - string_equals:
        do:
          strings.string_equals:
            - first_string: '${test_file_exists}'
            - second_string: 'True'
        navigate:
          - SUCCESS: append
          - FAILURE: add_numbers

    - append:
        do:
          strings.append:
            - origin_string: "${get('tests_list', '')}"
            - text: "${folder_to_check + ','}"
        publish:
          - tests_list: '${new_string}'
        navigate:
          - SUCCESS: add_numbers

    - add_numbers:
        do:
          math.add_numbers:
            - value1: '${iterator}'
            - value2: '1'
        publish:
          - iterator: '${result}'
        navigate:
          - SUCCESS: is_done
          - FAILURE: on_failure

  outputs:
    - tests: ${get('tests_list.rstrip(",")', '')}
    - exception
    - stderr
    - return_result
    - return_code
    - script_exit_code

  results:
    - SUCCESS
    - FAILURE

extensions:
  graph:
    steps:
      length:
        x: 425
        y: 196
        navigate:
          1f83690e-0523-fb80-85f6-b17086b3fffc:
            targetId: da13692d-054f-12fb-908d-c64cbc3a4de2
            port: FAILURE
      default_if_empty:
        x: 863
        y: 23
        navigate:
          0b09f8f5-d4e1-2102-87c5-3bdf6375597c:
            targetId: 5d5e95ed-dfdf-ef1d-d3e4-4fe51cf6f93c
            port: SUCCESS
      add_numbers:
        x: 1053
        y: 201
      string_equals:
        x: 1356
        y: 188
      test_file_exists:
        x: 1334
        y: 373
      get_by_index:
        x: 880
        y: 374
      is_done:
        x: 705
        y: 173
      append:
        x: 1320
        y: 42
      get_folders:
        x: 40
        y: 199
        navigate:
          bc932a00-711f-4a2d-6449-ada15f9c6a78:
            targetId: da13692d-054f-12fb-908d-c64cbc3a4de2
            port: FAILURE
      string_equals_1:
        x: 271
        y: 30
        navigate:
          9bc69bc3-65ef-d443-8844-5ea65c925357:
            targetId: da13692d-054f-12fb-908d-c64cbc3a4de2
            port: SUCCESS
    results:
      FAILURE:
        da13692d-054f-12fb-908d-c64cbc3a4de2:
          x: 244
          y: 371
      SUCCESS:
        5d5e95ed-dfdf-ef1d-d3e4-4fe51cf6f93c:
          x: 1058
          y: 33