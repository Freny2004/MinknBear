import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopify_flutter/main.dart';
import 'customer_model.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class CustomerLoginRegister extends StatefulWidget {
  const CustomerLoginRegister({super.key});

  @override
  State<CustomerLoginRegister> createState() => _CustomerLoginRegisterState();
}

class _CustomerLoginRegisterState extends State<CustomerLoginRegister>
    with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _registrationFormKey = GlobalKey<FormState>();
  final _forgotPasswordFormKey = GlobalKey<FormState>();
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController= TextEditingController();
  bool _passwordObscure = true;
  bool _loading = false;
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'IN');
  String _countryCode = '+91'; // Default country code

  void setPhoneNumber(String number) {
    // Check if the number already contains the country code
    if (number.startsWith(_countryCode)) {
      _phoneController.text = number; // Don't add the country code again
    } else {
      _phoneController.text = _countryCode + number; // Add the country code
    }

    // Move the cursor to the end after setting the text
    _phoneController.selection = TextSelection.fromPosition(
        TextPosition(offset: _phoneController.text.length));
  }

  Future<void> _login(BuildContext context) async {

setState(() {
  _loading = true;
});
    final client = GraphQLProvider.of(context).value;

    final result = await client.mutate(MutationOptions(
      document: gql(r'''
					mutation customerAccessTokenCreate ($input: CustomerAccessTokenCreateInput!) {
						customerAccessTokenCreate(input: $input)  {
							customerAccessToken {
								accessToken
								expiresAt
							}
							 
							customerUserErrors {
								code
								
								field
								message
							}
						}
					}
				'''),
      variables: {
        'input': {
          'email': _emailController.text,
          'password': _passwordController.text,
        }
      },
    ));

    if (kDebugMode) {
      print(result);
    }

    List errors =
        result.data!['customerAccessTokenCreate']['customerUserErrors'];

    if (errors.isNotEmpty) {
      setState(() {
        _loading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error! Message: ${errors[0]['message']}')));
      }
      return;
    }

    Map accessToken =
        result.data!['customerAccessTokenCreate']['customerAccessToken'];

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
        'customer',
        jsonEncode({
          'accessToken': accessToken['accessToken'],
          'expiresAt': accessToken['expiresAt'],
        }));

    if (context.mounted) {
      // Clear any existing customer data first
      await context.read<CustomerModel>().getCustomer(context);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Successfully logged-in! Please wait...'),
        duration: Duration(seconds: 3),
      ));
    }

    setState(() {
      _loading = false;
    });

    await Future.delayed(const Duration(seconds: 3));

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _register(BuildContext context) async {
    setState(() {
      _loading = true;
    });

    final client = GraphQLProvider.of(context).value;

    final result = await client.mutate(MutationOptions(
      document: gql(r'''
					mutation customerCreate ($input: CustomerCreateInput!) {
						customerCreate(input: $input)  {
							customer {
								id
							}
							customerUserErrors {
								code
								field
								message
							}
						}
					}
				'''),
      variables: {
        'input': {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        }
      },
    ));

    if (kDebugMode) {
      print(result);
    }

    List errors = result.data!['customerCreate']['customerUserErrors'];

    if (errors.isNotEmpty) {
      setState(() {
        _loading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error! Message: ${errors[0]['message']}')));
      }
      return;
    }

    if (context.mounted) {
      _login(context);
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    setState(() {
      _loading = true;
    });

    final client = GraphQLProvider.of(context).value;

    final result = await client.mutate(MutationOptions(
      document: gql(r'''
					mutation customerRecover ($email: String!) {
						customerRecover(email: $email)  {
							customerUserErrors {
								code
								field
								message
							}
						}
					}
				'''),
      variables: {'email': _emailController.text},
    ));

    if (kDebugMode) {
      print(result);
    }

    setState(() {
      _loading = false;
    });

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (result.hasException) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error! Message: ${result.exception!.graphqlErrors[0].message}')));
      }
      return;
    }

    List errors = result.data!['customerRecover']['customerUserErrors'];

    if (context.mounted) {
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error! Message: ${errors[0]['message']}')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'We\'ve sent you an email with a link to update your password.')));
      }
    }
  }

  Future<void> _forgotPassword() async {
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Form(
              key: _forgotPasswordFormKey,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('Reset your password',
                        style: TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    const Text(
                        'We will send you an email to reset your password',
                        style: TextStyle()),
                    const SizedBox(height: 18),
                    TextFormField(
                      autofocus: true,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), labelText: "Email"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                          onPressed: () async {
                            if (_forgotPasswordFormKey.currentState!
                                .validate()) {
                              setState(() {
                                _loading = true;
                              });
                              _resetPassword(context);
                            }
                          },
                          child: _loading
                              ? const SizedBox(
                                  height: 19,
                                  width: 19,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Submit',
                                  style: TextStyle(fontSize: 16),
                                )),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                          onPressed: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 200));
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Cancel')),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ));
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: seedColor,
        elevation: 0,
        title: const Text(
          'Login or Register',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Login'),
            Tab(text: 'Register'),
          ],
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          indicatorColor: Colors.blueGrey,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Login Form
            _buildLoginForm(),
            // Registration Form
            _buildRegistrationForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return AutofillGroup(
      child: Form(
        key: _loginFormKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24), // Padding for spacing
          children: [
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 30, // Increased font size
                fontWeight: FontWeight.bold,
                color: Colors.black, // Adjusted color for emphasis
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32), // Increased space between title and form
            _buildTextInput(
              controller: _emailController,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              autofillHints: [AutofillHints.email], // Autofill hint for email
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20), // Increased spacing between fields
            _buildTextInput(
              controller: _passwordController,
              labelText: 'Password',
              obscureText: _passwordObscure,
              autofillHints: [AutofillHints.password], // Autofill hint for password
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(_passwordObscure
                    ? Icons.visibility_off
                    : Icons.visibility),
                color: Colors.grey,
                iconSize: 22,
                onPressed: () {
                  setState(() {
                    _passwordObscure = !_passwordObscure;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await Future.delayed(const Duration(milliseconds: 200));
                  _forgotPassword();
                },
                child: const Text(
                  'Forgot your password?',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              label: _loading ? 'Signing In...' : 'Sign In',
              onPressed: () {
                if (_loginFormKey.currentState!.validate()) {
                  _login(context);
                }
              },
            ),
            const SizedBox(height: 20), // More space before 'Create account'
            Divider(color: Colors.grey.withOpacity(0.5), thickness: 1), // Separator
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () async {
                  await Future.delayed(const Duration(milliseconds: 200));
                  _tabController.animateTo(1);
                },
                child: const Text(
                  'Create account',
                  style: TextStyle(
                    color: Colors.black, // Adjust color for consistency
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _registrationFormKey,
      child: ListView(
        children: [
          const Text(
            'Create account',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildTextInput(
            controller: _firstNameController,
            labelText: 'First name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextInput(
            controller: _lastNameController,
            labelText: 'Last name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildPhoneInput(),
          const SizedBox(height: 16),
          _buildTextInput(
            controller: _emailController,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextInput(
            controller: _passwordController,
            labelText: 'Password',
            obscureText: _passwordObscure,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(_passwordObscure
                  ? Icons.visibility_off
                  : Icons.visibility),
              color: Colors.grey,
              iconSize: 22,
              onPressed: () {
                setState(() {
                  _passwordObscure = !_passwordObscure;
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            label: _loading ? 'Creating account...' : 'Create Account',
            onPressed: () {
              if (_registrationFormKey.currentState!.validate()) {
                _register(context);
              }
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 200));
                _tabController.animateTo(0);
              },
              child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    List<String>? autofillHints, // Add this parameter

    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints, // Pass autofillHints here

      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  Widget _buildPhoneInput() {
    return InternationalPhoneNumberInput(
      onInputChanged: (PhoneNumber number) {
        setState(() {
          _phoneNumber = number;
          _countryCode = number.dialCode ?? '+91'; // Default to India
          setPhoneNumber(number.phoneNumber ?? '');
        });
      },
      selectorConfig: SelectorConfig(
        useBottomSheetSafeArea: true,
        setSelectorButtonAsPrefixIcon: true,
        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
        leadingPadding: 10,
      ),
      countries: [], // Optionally filter countries
      searchBoxDecoration: const InputDecoration(hintText: 'Search for a country...'),
      initialValue: _phoneNumber,
      inputDecoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Phone number',
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,

      child: ElevatedButton(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        onPressed: onPressed,
        child: _loading
            ? const SizedBox(
          height: 19,
          width: 19,
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,

          ),
        )
            : Text(
          label,
          style: const TextStyle(fontSize: 16,color: Colors.black),
        ),
      ),
    );
  }

}
