import 'package:flutter/material.dart';

import 'admin/admin_app.dart';

void main() {
  // Boots straight into the admin panel while its frontend is being built.
  // Once the login page exists this becomes the auth entry point, which then
  // routes to AdminApp or the user app based on the signed-in role.
  runApp(const AdminApp());
}
