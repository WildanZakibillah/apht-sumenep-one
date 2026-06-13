import { useMemo } from 'react';
import { useAuth } from './useAuth';

// Role labels for display
const ROLE_LABELS = {
  super_admin: 'Super Admin',
  direktur: 'Direktur',
  admin_pabrik: 'Admin Pabrik',
};

const DASHBOARD_ROLES = ['super_admin', 'direktur', 'admin_pabrik'];

/**
 * Hook for role-based access control
 * Provides helpers: isSuperAdmin, isDirektur, factoryId, roleLabel, etc.
 */
export const useRoleAccess = () => {
  const { profile } = useAuth();

  const role = profile?.role ? profile.role.toLowerCase() : '';
  const isSuperAdmin = role === 'super_admin';
  const isDirektur = role.includes('direktur');
  const isAdminPabrik = role.includes('admin_pabrik') || role.includes('admin pabrik');
  const factoryId = profile?.factory_id || null;

  // Whether this user's data should be scoped to a specific factory (anyone except super_admin)
  const isFactoryScoped = isDirektur || isAdminPabrik;

  const roleLabel = ROLE_LABELS[role] || role || 'User';

  // Helper: apply factory filter to a supabase query if user is scoped
  const scopeQuery = (query, factoryColumn = 'factory_id') => {
    if (isFactoryScoped) {
      return query.eq(factoryColumn, factoryId);
    }
    return query;
  };

  return useMemo(() => ({
    role,
    isSuperAdmin,
    isDirektur,
    isAdminPabrik,
    factoryId,
    isFactoryScoped,
    roleLabel,
    scopeQuery,
  }), [role, factoryId]); // eslint-disable-line
};

export { ROLE_LABELS, DASHBOARD_ROLES };
