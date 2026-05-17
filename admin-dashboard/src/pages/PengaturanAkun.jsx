import React, { useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import { useTheme } from '../context/ThemeContext';

const PengaturanAkun = () => {
  const { user, profile, signOut } = useAuth();
  const { isDark, toggleTheme } = useTheme();
  const [emailNotif, setEmailNotif] = useState(true);
  const [exciseAlerts, setExciseAlerts] = useState(true);
  const [newReports, setNewReports] = useState(false);

  const Toggle = ({ checked, onChange }) => (
    <button onClick={() => onChange(!checked)} className={`w-11 h-6 rounded-full transition-colors relative ${checked ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'}`}>
      <div className={`w-4 h-4 rounded-full bg-white absolute top-1 transition-transform shadow-sm ${checked ? 'translate-x-6' : 'translate-x-1'}`}></div>
    </button>
  );

  return (
    <div className="space-y-6 max-w-[900px] mx-auto">
      {/* Profile */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className="bg-gradient-to-r from-blue-600 to-indigo-700 dark:from-blue-800 dark:to-indigo-900 px-6 py-8 text-white relative overflow-hidden">
          <div className="absolute right-0 top-0 w-48 h-48 bg-white/5 rounded-full -translate-y-1/2 translate-x-1/4"></div>
          <div className="flex items-center gap-5 relative z-10">
            <div className="w-16 h-16 rounded-xl bg-white/10 backdrop-blur border border-white/20 flex items-center justify-center text-2xl font-bold">
              {profile?.full_name?.charAt(0) || 'A'}
            </div>
            <div>
              <h3 className="text-xl font-bold">{profile?.full_name || 'Super Admin'}</h3>
              <p className="text-blue-200 text-sm mt-0.5">{user?.email || 'admin@apht.com'}</p>
              <span className="inline-block mt-2 text-[11px] font-bold px-3 py-1 rounded-full bg-white/10 border border-white/20">
                {profile?.role === 'super_admin' ? 'Super Administrator' : profile?.role || 'Admin'}
              </span>
            </div>
          </div>
        </div>
        <div className="p-6 flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-gray-700 dark:text-gray-300">Informasi Profil</p>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">Kelola data profil dan informasi akun</p>
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
