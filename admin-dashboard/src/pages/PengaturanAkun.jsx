import React, { useState, useEffect } from 'react';
import { useAuth } from '../hooks/useAuth';
import { useTheme } from '../context/ThemeContext';
import { useRoleAccess } from '../hooks/useRoleAccess';
import { supabase } from '../lib/supabase';

const Toggle = ({ checked, onChange }) => (
  <button onClick={() => onChange(!checked)} className={`w-11 h-6 rounded-full transition-colors relative ${checked ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'}`}>
    <div className={`w-4 h-4 rounded-full bg-white absolute top-1 transition-transform shadow-sm ${checked ? 'translate-x-6' : 'translate-x-1'}`}></div>
  </button>
);

const PengaturanAkun = () => {
  const { user, profile, signOut, ready } = useAuth();
  const { isDark, toggleTheme } = useTheme();
  const { isDirektur, roleLabel, scopeQuery } = useRoleAccess();
  const [emailNotif, setEmailNotif] = useState(true);
  const [exciseAlerts, setExciseAlerts] = useState(true);
  const [newReports, setNewReports] = useState(false);
  const [factoryName, setFactoryName] = useState(null);

  useEffect(() => {
    if (!ready || !isDirektur) return;
    const fetchFactory = async () => {
      const { data } = await scopeQuery(supabase.from('factories').select('name'), 'id');
      if (data && data.length > 0) setFactoryName(data[0].name);
    };
    fetchFactory();
  }, [ready, isDirektur, scopeQuery]);

  const getRoleBadgeStyle = () => {
    if (isDirektur) return 'bg-amber-500/20 border-amber-400/30 text-amber-100';
    return 'bg-white/10 border-white/20 text-white/90';
  };

  const getRoleDisplayName = () => {
    if (profile?.role === 'super_admin') return 'Super Administrator';
    if (profile?.role === 'direktur') return 'Direktur';
    return roleLabel;
  };

  return (
    <div className="space-y-6 max-w-[900px] mx-auto">
      {/* Profile */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className={`${isDirektur ? 'bg-gradient-to-r from-amber-600 to-orange-700 dark:from-amber-800 dark:to-orange-900' : 'bg-gradient-to-r from-blue-600 to-indigo-700 dark:from-blue-800 dark:to-indigo-900'} px-6 py-8 text-white relative overflow-hidden`}>
          <div className="absolute right-0 top-0 w-48 h-48 bg-white/5 rounded-full -translate-y-1/2 translate-x-1/4"></div>
          <div className="flex items-center gap-5 relative z-10">
            <div className="w-16 h-16 rounded-xl bg-white/10 backdrop-blur border border-white/20 flex items-center justify-center text-2xl font-bold">
              {profile?.full_name?.charAt(0) || 'A'}
            </div>
            <div>
              <h3 className="text-xl font-bold">{profile?.full_name || 'User'}</h3>
              <p className="text-white/70 text-sm mt-0.5">{user?.email || '-'}</p>
              <div className="flex items-center gap-2 mt-2">
                <span className={`inline-flex items-center gap-1.5 text-[11px] font-bold px-3 py-1 rounded-full border ${getRoleBadgeStyle()}`}>
                  <span className="material-symbols-outlined text-[14px]" style={{ fontVariationSettings: "'FILL' 1" }}>
                    {isDirektur ? 'badge' : 'admin_panel_settings'}
                  </span>
                  {getRoleDisplayName()}
                </span>
                {isDirektur && factoryName && (
                  <span className="inline-flex items-center gap-1.5 text-[11px] font-bold px-3 py-1 rounded-full bg-white/10 border border-white/20 text-white/90">
                    <span className="material-symbols-outlined text-[14px]" style={{ fontVariationSettings: "'FILL' 1" }}>domain</span>
                    {factoryName}
                  </span>
                )}
              </div>
            </div>
          </div>
        </div>
        <div className="p-6 flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-gray-700 dark:text-gray-300">Informasi Profil</p>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">
              {isDirektur ? `Anda masuk sebagai Direktur ${factoryName || ''}` : 'Kelola data profil dan informasi akun'}
            </p>
          </div>
          <button className="flex items-center gap-2 px-4 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
            <span className="material-symbols-outlined text-[18px]">edit</span>Edit Profil
          </button>
        </div>
      </div>

      {/* Security */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6">
        <h3 className="text-[15px] font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
          <span className="material-symbols-outlined text-gray-400 dark:text-gray-500 text-[20px]">shield</span>Keamanan
        </h3>
        <div className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
          <div>
            <p className="text-sm font-medium text-gray-700 dark:text-gray-300">Kata Sandi</p>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5 flex items-center gap-1">
              <span className="material-symbols-outlined text-emerald-500 text-[14px]">check_circle</span>Terakhir diubah 2 minggu lalu
            </p>
          </div>
          <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors">
            <span className="material-symbols-outlined text-[18px]">key</span>Ubah
          </button>
        </div>
      </div>

      {/* Appearance */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6">
        <h3 className="text-[15px] font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
          <span className="material-symbols-outlined text-gray-400 dark:text-gray-500 text-[20px]">palette</span>Tampilan
        </h3>
        <div className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
          <div>
            <p className="text-sm font-medium text-gray-700 dark:text-gray-300">Mode Gelap</p>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">Sesuaikan tampilan dashboard</p>
          </div>
          <Toggle checked={isDark} onChange={toggleTheme} />
        </div>
      </div>

      {/* Notifications */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6">
        <h3 className="text-[15px] font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
          <span className="material-symbols-outlined text-gray-400 dark:text-gray-500 text-[20px]">notifications</span>Preferensi Notifikasi
        </h3>
        <div className="space-y-3">
          {[
            { label: 'Notifikasi Email', desc: 'Terima ringkasan via email', state: emailNotif, setter: setEmailNotif },
            { label: 'Peringatan Cukai', desc: 'Alert saat pita mendekati batas', state: exciseAlerts, setter: setExciseAlerts },
            { label: 'Laporan Masuk', desc: 'Pemberitahuan real-time', state: newReports, setter: setNewReports },
          ].map((item) => (
            <div key={item.label} className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
              <div>
                <p className="text-sm font-medium text-gray-700 dark:text-gray-300">{item.label}</p>
                <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{item.desc}</p>
              </div>
              <Toggle checked={item.state} onChange={item.setter} />
            </div>
          ))}
        </div>
      </div>

      {/* Danger */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-red-200 dark:border-red-900/50 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-[15px] font-bold text-red-600 dark:text-red-400 flex items-center gap-2">
              <span className="material-symbols-outlined text-[20px]">warning</span>Sesi Akun
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">Mengakhiri sesi aktif di perangkat ini.</p>
          </div>
          <button onClick={signOut} className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-semibold hover:bg-red-700 transition-colors">
            <span className="material-symbols-outlined text-[18px]">logout</span>Keluar
          </button>
        </div>
      </div>

      <div className="text-center py-4">
        <p className="text-xs text-gray-400 dark:text-gray-500">APHT Sumenep One &middot; v1.0.0</p>
      </div>
    </div>
  );
};

export default PengaturanAkun;
