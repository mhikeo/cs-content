
########################################################################################################################
#!!
#! @description: This flow triggers an UFT Scenario.
#!               The UFT Scenario needs to exist before this flow is ran.
#!
#! @input host: The host where UFT scenarios are located.
#! @input port: The WinRM port of the provided host.
#!                    Default: https: '5986' http: '5985'
#! @input protocol: The WinRM protocol.
#! @input username: The username for the WinRM connection.
#! @input password: The password for the WinRM connection.
#! @input is_test_visible: Parameter to set if the UFT actions should be visible in the UI or not.
#!                          Valid: 'True' or 'False'
#!                          Default value: 'True'
#! @input test_path: The path to the UFT scenario.
#! @input test_results_path: The path where the UFT scenario will save its results.
#! @input test_parameters: parameters from the UFT scenario. A list of name:value pairs separated by comma.
#!                         The parameters are optional in case you are running a UFT scenario without parameters.
#!                          Eg. name1:value1,name2:value2
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
#! @output exception: Exception if there was an error when executing, empty otherwise.
#! @output return_code: '0' if success, '-1' otherwise.
#! @output stderr: The standard error output if any error occurred.
#! @output return_result: The scripts result.
#! @output script_exit_code: '0' if success, '-1' otherwise.
#! @output script_name: name of the script.
#!
#! @result SUCCESS: The operation executed successfully.
#! @result FAILURE: The operation could not be executed.
#!
#!!#
########################################################################################################################

namespace: io.cloudslang.microfocus.uft

imports:
  ps: io.cloudslang.base.powershell
  st: io.cloudslang.strings
  utility: io.cloudslang.microfocus.uft.utility
  strings: io.cloudslang.base.strings


flow:
  name: run_test
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
    - is_test_visible
    - test_path
    - test_results_path
    - uft_workspace_path
    - test_parameters:
            required: false
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
        sensitive: true
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
      - string_equals_1:
          do:
            strings.string_equals:
              - first_string: '${test_parameters}'
              - second_string: ''
              - ignore_case: 'false'
          navigate:
            - SUCCESS: create_trigger_robot_vb_script_no_parameters
            - FAILURE: create_trigger_robot_vb_script
      - create_trigger_robot_vb_script:
          do:
            utility.create_run_test_vb_script:
              - host
              - port
              - protocol
              - username
              - password: '${password}'
              - proxy_host
              - proxy_port
              - proxy_username
              - proxy_password: '${proxy_password}'
              - is_test_visible
              - test_path
              - test_results_path
              - test_parameters
              - uft_workspace_path
          publish:
            - script_name
            - exception
            - return_code
            - return_result
            - stderr
            - script_exit_code
          navigate:
            - FAILURE: on_failure
            - SUCCESS: trigger_vb_script
      - trigger_vb_script:
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
                  value: 'changeit'
                  sensitive: true
              - operation_timeout
              - script: "${'invoke-expression \"cmd /C cscript ' + script_name + '\"'}"
          publish:
            - exception
            - return_code
            - return_result
            - stderr
            - script_exit_code
          navigate:
            - SUCCESS: string_equals
            - FAILURE: delete_vb_script_1
      - string_equals:
          do:
            strings.string_equals:
              - first_string: '${script_exit_code}'
              - second_string: '0'
              - ignore_case: 'false'
          navigate:
            - SUCCESS: delete_vb_script
            - FAILURE: delete_vb_script_1
      - delete_vb_script:
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
                  value: 'changeit'
                  sensitive: true
              - operation_timeout
              - script: "${'Remove-Item \"' + script_name +'\"'}"
          publish:
            - script_name
            - exception
            - return_code
            - return_result
            - stderr
            - script_exit_code
          navigate:
            - SUCCESS: SUCCESS
            - FAILURE: SUCCESS
      - delete_vb_script_1:
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
                  value: 'changeit'
              - operation_timeout
              - script: "${'Remove-Item \"' + script_name + '\"'}"
          publish:
            - script_name
            - exception
            - return_code
            - return_result
            - stderr
            - script_exit_code
          navigate:
            - SUCCESS: FAILURE
            - FAILURE: on_failure
      - create_trigger_robot_vb_script_no_parameters:
          do:
            utility.create_run_test_vb_script_no_parameters:
              - host
              - port
              - protocol
              - username
              - password: '${password}'
              - proxy_host
              - proxy_port
              - proxy_username
              - proxy_password: '${proxy_password}'
              - is_test_visible
              - test_path
              - test_results_path
              - test_parameters
              - uft_workspace_path
          publish:
          - exception
          - stderr
          - return_result
          - return_code
          - script_exit_code
          - script_name

          navigate:
            - FAILURE: on_failure
            - SUCCESS: trigger_vb_script_1
      - trigger_vb_script_1:
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
                  value: 'changeit'
              - operation_timeout
              - script: "${'invoke-expression \"cmd /C cscript ' + script_name + '\"'}"
          publish:
          - exception
          - stderr
          - return_result
          - return_code
          - script_exit_code

          navigate:
            - SUCCESS: string_equals_2
            - FAILURE: delete_vb_script_1
      - string_equals_2:
          do:
            strings.string_equals:
              - first_string: '${script_exit_code}'
              - second_string: '0'
              - ignore_case: 'true'
          navigate:
            - SUCCESS: delete_vb_script
            - FAILURE: delete_vb_script_1
  outputs:
    - exception
    - stderr
    - return_result
    - return_code
    - script_exit_code
    - script_name

  results:
    - FAILURE
    - SUCCESS

extensions:
  graph:
    steps:
      string_equals_2:
        x: 843
        y: 193
      trigger_vb_script_1:
        x: 496
        y: 213
      delete_vb_script:
        x: 1155
        y: 368
        navigate:
          0b0a142b-ae1f-5278-f728-b193dcee85e7:
            targetId: a4db0ee9-f9a7-d43e-b1cc-9786b2e5362b
            port: FAILURE
            vertices:
              - x: 1243
                y: 387
              - x: 1315
                y: 353
              - x: 1351.4605678975008
                y: 352.92990200488515
              - x: 1419
                y: 351
          f90fa9e6-1ffc-794c-8f9e-e0284e0691f1:
            targetId: a4db0ee9-f9a7-d43e-b1cc-9786b2e5362b
            port: SUCCESS
            vertices:
              - x: 1315
                y: 455
              - x: 1416
                y: 455
      string_equals:
        x: 841
        y: 491
      create_trigger_robot_vb_script_no_parameters:
        x: 285
        y: 216
      trigger_vb_script:
        x: 494
        y: 513
      delete_vb_script_1:
        x: 651
        y: 355
        navigate:
          abc30655-fb3e-2b61-0cfe-e872a41ae21b:
            targetId: ead7bc63-9890-3ee7-2656-b91ed8438591
            port: SUCCESS
      string_equals_1:
        x: 117
        y: 344
      create_trigger_robot_vb_script:
        x: 283
        y: 513
    results:
      FAILURE:
        ead7bc63-9890-3ee7-2656-b91ed8438591:
          x: 907
          y: 363
      SUCCESS:
        a4db0ee9-f9a7-d43e-b1cc-9786b2e5362b:
          x: 1448
          y: 374