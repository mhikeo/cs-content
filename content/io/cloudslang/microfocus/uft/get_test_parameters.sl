########################################################################################################################
#!!
#! @description: This flow returns the parameters of an UFT Scenario.
#!               The return value is a list of name:default_value:0/1 input/output objects.
#!
#! @input host: The host where UFT scenarios are located.
#! @input port: The WinRM port of the provided host.
#!                    Default: https: '5986' http: '5985'
#! @input protocol: The WinRM protocol.
#! @input username: The username for the WinRM connection.
#! @input password: The password for the WinRM connection.
#! @input test_path: The path to the UFT scenario.
#! @input uft_workspace_path: The path where the OO will create needed scripts for UFT scenario execution.
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
#! @output parameters: A list of name:default_value:type objects. Type: 0 - input, 1 - output.
#! @output exception: Exception if there was an error when executing, empty otherwise.
#! @output return_code: '0' if success, '-1' otherwise.
#! @output stderr: An error message in case there was an error while running power shell
#! @output return_result: The scripts result.
#! @output script_exit_code: '0' if success, '-1' otherwise.
#! @output script_name: name of the script.
#!
#! @result SUCCESS: The operation executed successfully.
#! @result FAILURE: The operation could not be executed.
#!!#
########################################################################################################################

namespace: io.cloudslang.microfocus.uft

imports:
  utility: io.cloudslang.microfocus.uft.utility
  ps: io.cloudslang.base.powershell
  strings: io.cloudslang.base.strings

flow:
  name: get_test_parameters
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
    - uft_workspace_path
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

  workflow:
    - create_get_robot_params_vb_script:
        do:
          utility.create_get_test_params_vb_script:
            - host: '${host}'
            - port: '${port}'
            - protocol: '${protocol}'
            - username: '${username}'
            - password: '${password}'
            - proxy_host: '${proxy_host}'
            - proxy_port: '${proxy_port}'
            - proxy_username: '${proxy_username}'
            - proxy_password: '${proxy_password}'
            - test_path: '${test_path}'
            - uft_workspace_path: '${uft_workspace_path}'
        publish:
          - exception
          - stderr
          - return_result
          - return_code
          - script_exit_code
          - script_name

        navigate:
          - FAILURE: on_failure
          - SUCCESS: trigger_vb_script
    - trigger_vb_script:
        do:
          ps.powershell_script:
            - host: '${host}'
            - port: '${port}'
            - protocol: '${protocol}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - auth_type: '${auth_type}'
            - proxy_host: '${proxy_host}'
            - proxy_port: '${proxy_port}'
            - proxy_username: '${proxy_username}'
            - proxy_password:
                value: '${proxy_password}'
                sensitive: true
            - trust_all_roots: '${trust_all_roots}'
            - x_509_hostname_verifier: '${x_509_hostname_verifier}'
            - trust_keystore: '${trust_keystore}'
            - trust_password:
                value: '${trust_password}'
                sensitive: true
            - operation_timeout: '${operation_timeout}'
            - script: "${'invoke-expression \"cmd /C cscript ' + script_name + '\"'}"
        publish:
          - exception
          - stderr
          - return_result
          - return_code
          - script_exit_code
          - parameters: "${return_result.replace('::',':<no_value>:')}"
        navigate:
          - SUCCESS: string_equals
          - FAILURE: delete_vb_script_1

    - string_equals:
            do:
              strings.string_equals:
                - first_string: '${script_exit_code}'
                - second_string: '0'
                - ignore_case: 'true'
            navigate:
              - SUCCESS: string_equals1
              - FAILURE: delete_vb_script_1

    - string_equals1:
            do:
              strings.string_equals:
                - first_string: '${parameters}'
                - second_string: ''
                - ignore_case: 'false'
            navigate:
              - SUCCESS: FAILURE
              - FAILURE: delete_vb_script

    - delete_vb_script:
        do:
          ps.powershell_script:
            - host: '${host}'
            - port: '${port}'
            - protocol: '${protocol}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - auth_type: '${auth_type}'
            - proxy_host: '${proxy_host}'
            - proxy_port: '${proxy_port}'
            - proxy_username: '${proxy_username}'
            - proxy_password:
                value: '${proxy_password}'
                sensitive: true
            - trust_all_roots: '${trust_all_roots}'
            - x_509_hostname_verifier: '${x_509_hostname_verifier}'
            - trust_keystore: '${trust_keystore}'
            - trust_password:
                value: '${trust_password}'
                sensitive: true
            - operation_timeout: '${operation_timeout}'
            - script: "${'Remove-Item \"' + script_name +'\"'}"
        publish:
          - exception
          - stderr
          - return_result
          - return_code
          - script_exit_code
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: SUCCESS

    - delete_vb_script_1:
        do:
          ps.powershell_script:
            - host: '${host}'
            - port: '${port}'
            - protocol: '${protocol}'
            - username: '${username}'
            - password:
                value: '${password}'
                sensitive: true
            - auth_type: '${auth_type}'
            - proxy_host: '${proxy_host}'
            - proxy_port: '${proxy_port}'
            - proxy_username: '${proxy_username}'
            - proxy_password:
                value: '${proxy_password}'
                sensitive: true
            - trust_all_roots: '${trust_all_roots}'
            - x_509_hostname_verifier: '${x_509_hostname_verifier}'
            - trust_keystore: '${trust_keystore}'
            - trust_password:
                value: '${trust_password}'
                sensitive: true
            - operation_timeout: '${operation_timeout}'
            - script: "${'Remove-Item \"' + script_name + '\"'}"
        publish:
          - exception
          - stderr
          - return_result
          - return_code
          - script_exit_code
        navigate:
          - SUCCESS: FAILURE
          - FAILURE: on_failure

  outputs:
    - exception
    - stderr
    - return_result
    - return_code
    - script_exit_code
    - parameters
    - script_name: ${get('script_name', '')}

  results:
    - FAILURE
    - SUCCESS

extensions:
  graph:
    steps:
      create_get_robot_params_vb_script:
        x: 37
        y: 130
      trigger_vb_script:
        x: 286
        y: 129
      string_equals:
        x: 579
        y: 2
      delete_vb_script_1:
        x: 550
        y: 269
        navigate:
          b9282c69-423a-2d78-8603-b3649793ccb1:
            targetId: c61959cb-d5b5-9967-42d7-9e288e2573d8
            port: SUCCESS
      string_equals1:
        x: 897
        y: 1
        navigate:
          9e1d5e6c-4685-8c7f-85ff-457550292ac3:
            targetId: c61959cb-d5b5-9967-42d7-9e288e2573d8
            port: SUCCESS
      delete_vb_script:
        x: 1146
        y: 13
        navigate:
          5e587d6a-8d5b-fd6a-b51b-d2d0d42adff8:
            targetId: 712df0f1-61f0-3c93-1863-dbad6e6ff3dd
            port: SUCCESS
    results:
      FAILURE:
        c61959cb-d5b5-9967-42d7-9e288e2573d8:
          x: 870
          y: 274
      SUCCESS:
        712df0f1-61f0-3c93-1863-dbad6e6ff3dd:
          x: 1361
          y: 15

