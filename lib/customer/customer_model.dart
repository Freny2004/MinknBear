import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class CustomerModel with ChangeNotifier {
  Map? _customer;

  Map? get customer => _customer;

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Clear customer data from shared preferences
    await prefs.remove('customer');

    // Set customer to null
    _customer = null;

    // Notify listeners to update UI
    notifyListeners();
  }

  Future<void> initializeCustomer(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? customerEncoded = prefs.getString('customer');

    if (customerEncoded != null) {
      // Decode the stored customer data
      Map customer = jsonDecode(customerEncoded);

      // Load it into the provider state
      _customer = {
        'id': customer['id'],
        'firstName': customer['firstName'],
        'lastName': customer['lastName'],
        'email': customer['email'],
        'phone': customer['phone'],
      };
      notifyListeners();  // Notify UI about the update
    } else {
      _customer = null;
    }
  }

  Future<void> getCustomer(BuildContext context) async {
    final client = GraphQLProvider.of(context).value;
    final prefs = await SharedPreferences.getInstance();
    String? customerEncoded = prefs.getString('customer');

    if (customerEncoded == null) {
      _customer = null;
      notifyListeners();
      return;
    }

    Map customer = jsonDecode(customerEncoded);

    // Check if the customer session is valid
    DateTime expiresAt = DateTime.parse(customer['expiresAt']);
    if (expiresAt.isBefore(DateTime.now())) {
      await prefs.remove('customer');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your session has expired. Please log in again.'),
        ));
      }
      return;
    }

    // Fetch customer data using the access token
    final result = await client.query(
      QueryOptions(
        document: gql(r'''
        query customer($accessToken: String!) {
          customer(customerAccessToken: $accessToken) {
            id
            firstName
            lastName
            phone
            email
          }
        }
      '''),
        variables: {'accessToken': customer['accessToken']},
      ),
    );

    // Update customer data in SharedPreferences
    _customer = result.data!['customer'];
    await prefs.setString('customer', jsonEncode({
      'accessToken': customer['accessToken'],
      'expiresAt': customer['expiresAt'],
      'id': _customer!['id'],
      'firstName': _customer!['firstName'],
      'lastName': _customer!['lastName'],
      'email': _customer!['email'],
      'phone': _customer!['phone'],
    }));

    notifyListeners();
  }
  Future<void> updateCustomer(Map<String, String> updatedData, BuildContext context) async {
    final client = GraphQLProvider.of(context).value;
    final prefs = await SharedPreferences.getInstance();
    String? customerEncoded = prefs.getString('customer');

    if (customerEncoded == null) return;

    Map customer = jsonDecode(customerEncoded);

    // Send mutation to update customer profile
    final result = await client.mutate(
      MutationOptions(
        document: gql(r'''
      mutation updateCustomer($accessToken: String!, $customer: CustomerUpdateInput!) {
        customerUpdate(customerAccessToken: $accessToken, customer: $customer) {
          customer {
            firstName
            lastName
            email
            phone
          }
          userErrors {
            field
            message
          }
        }
      }
    '''),
        variables: {
          'accessToken': customer['accessToken'],
          'customer': {
            'firstName': updatedData['firstName']!,
            'lastName': updatedData['lastName']!,
            'email': updatedData['email']!,
            'phone': updatedData['phone']!,
          },
        },
      ),
    );

    List errors = result.data!['customerUpdate']['userErrors'];

    if (errors.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error! Message: ${errors[0]['message']}'),
        ));
      }
      return;
    }

    // Update the provider with new customer data
    _customer = result.data!['customerUpdate']['customer'];

    // Save the updated customer data in SharedPreferences
    await prefs.setString('customer', jsonEncode({
      'accessToken': customer['accessToken'],
      'expiresAt': customer['expiresAt'],
      'id': _customer!['id'],
      'firstName': _customer!['firstName'],
      'lastName': _customer!['lastName'],
      'email': _customer!['email'],
      'phone': _customer!['phone'],
    }));

    notifyListeners();  // Notify the UI to update with the new profile data
  }

}
