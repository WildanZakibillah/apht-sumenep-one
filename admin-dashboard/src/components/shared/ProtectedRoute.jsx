import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';

export const ProtectedRoute = () => {
  const { isAuthenticated, loading, profile } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-[3px] border-blue-600 border-t-transparent rounded-full animate-spin"></div>
          <p className="text-sm text-gray-400">Memuat...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  // If profile loaded and role is NOT super_admin, block access
  if (profile && profile.role !== 'super_admin') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 p-4">
        <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-8 max-w-md text-center shadow-lg">
          <div className="w-16 h-16 rounded-full bg-red-50 dark:bg-red-900/20 flex items-center justify-center mx-auto mb-4">
            <span className="material-symbols-outlined text-red-500 text-[32px]">block</span>
          </div>
          <h2 className="text-xl font-bold text-gray-900 dark:text-white">Akses Ditolak</h2>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
            Hanya Super Admin yang dapat mengakses dashboard ini.
          </p>
          <button
            onClick={() => { Object.keys(localStorage).forEach(k => { if (k.startsWith('sb-')) localStorage.removeItem(k); }); window.location.href = '/login'; }}
            className="mt-6 px-5 py-2.5 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors"
          >
            Kembali ke Login
          </button>
        </div>
      </div>
    );
  }

  // If profile is null (still loading or failed), allow access anyway
  // The pages will handle their own data loading
  return <Outlet />;
};
