/// Application-wide constants for APHT Sumenep One.
class AppConstants {
  AppConstants._();

  // ---------- App Info ----------
  static const String appName = 'APHT Sumenep One';
  static const String appVersion = '1.0.0';

  // ---------- User Roles ----------
  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdminPabrik = 'admin_pabrik';
  static const String roleDirektur = 'direktur';

  // ---------- Table Names ----------
  static const String tableProfiles = 'profiles';
  static const String tableFactories = 'factories';
  static const String tableWarehouses = 'warehouses';
  static const String tableProductTypes = 'product_types';
  static const String tableBrands = 'brands';
  static const String tableProducts = 'products';
  static const String tableProductions = 'productions';
  static const String tableCukaiAllocations = 'cukai_allocations';
  static const String tableCukaiUsageLog = 'cukai_usage_log';
  static const String tableCukaiRequests = 'cukai_requests';
  static const String tableOutgoingGoods = 'outgoing_goods';
  static const String tableReports = 'reports';
  static const String tableNotifications = 'notifications';
  static const String tableRegions = 'regions';
  static const String tableDistributors = 'distributors';
  static const String tableArchives = 'archives';

  // ---------- Role Display Names ----------
  static String roleDisplayName(String role) {
    switch (role) {
      case roleSuperAdmin:
        return 'Super Admin';
      case roleAdminPabrik:
        return 'Admin Pabrik';
      case roleDirektur:
        return 'Direktur';
      default:
        return role;
    }
  }
}
