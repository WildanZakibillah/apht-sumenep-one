import React, { useState } from 'react';

const Toggle = ({ checked, onChange }) => (
  <button
    className={`w-11 h-6 rounded-full transition-colors relative focus:outline-none shrink-0 ${checked ? 'bg-[#000051]' : 'bg-outline-variant'}`}
    onClick={() => onChange(!checked)}
  >
    <div className={`w-4 h-4 rounded-full bg-white absolute top-1 transition-transform ${checked ? 'translate-x-6' : 'translate-x-1'}`}></div>
  </button>
);

const PengaturanAkun = () => {
  const [emailNotif, setEmailNotif] = useState(true);
  const [exciseAlerts, setExciseAlerts] = useState(true);
  const [newReports, setNewReports] = useState(false);

  return (
    <div className="flex flex-col gap-lg w-full max-w-container-max mx-auto p-4 lg:p-0">
      {/* Header */}
      <div className="flex flex-col border-b border-surface-variant pb-4 mb-4">
        <h1 className="font-h1 text-[28px] font-bold text-on-surface">Pengaturan Akun</h1>
        <p className="font-body-md text-on-surface-variant mt-1">Kelola profil, keamanan, dan preferensi notifikasi Anda.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Left Column (Main Settings) */}
        <div className="lg:col-span-2 flex flex-col gap-6">

          {/* Profil Admin */}
          <div className="bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden shadow-sm">
            <div className="bg-surface-container-low px-6 py-4 border-b border-outline-variant">
              <h2 className="font-h2 text-[18px] font-bold text-on-surface">Profil Admin</h2>
            </div>
            <div className="p-6 flex flex-col sm:flex-row items-center sm:items-start gap-6">
              <div className="w-24 h-24 rounded-xl overflow-hidden shrink-0 border border-outline-variant shadow-sm">
                <img
                  src="https://lh3.googleusercontent.com/aida-public/AB6AXuDAMUUoAy_YovdPIXKEvCvE9JODj85l39QSL8y3FjDVtbaNZI0iARKknAHqVm0pUabTpQkWHveRzLsC0N34OkCACH6yi7S_fe_wNOTAstsJNBPzSfBcTO7OUacKxsOyDVSNNxZrurhPnjKbnFD_80p9aQILZzZ3mA97WkbznptGYIjoVJLfhca6dQFoJa8GKEud70ymTYhgo_VYx_G2i7PyAl0Tp3dTxgW4elpy3GUS1Z2cc2AKPTStIWugEGys-EVwYiuEsWQrhjg"
                  alt="Super Admin APHT"
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="flex-1 flex flex-col items-center sm:items-start text-center sm:text-left">
                <span className="font-label-sm text-[11px] text-outline uppercase tracking-wider font-semibold">NAMA LENGKAP</span>
                <h3 className="font-h1 text-[20px] font-bold text-on-surface mt-1">Super Admin APHT</h3>

                <span className="font-label-sm text-[11px] text-outline uppercase tracking-wider font-semibold mt-4">EMAIL INSTITUSI</span>
                <p className="font-body-md text-[14px] text-on-surface-variant mt-1">admin@apht.sumenep.go.id</p>

                <span className="font-label-sm text-[11px] text-outline uppercase tracking-wider font-semibold mt-4">PERAN SISTEM</span>
                <div className="mt-2">
                  <span className="bg-[#000051] text-white px-3 py-1 rounded-full text-[11px] font-bold tracking-wide">Super Administrator</span>
                </div>
              </div>
              <div className="mt-4 sm:mt-0">
                <button className="flex items-center justify-center gap-2 px-4 py-2 border border-outline-variant rounded-lg font-label-sm text-sm font-semibold hover:bg-surface-container-low transition-colors whitespace-nowrap">
                  <span className="material-symbols-outlined text-[18px]">edit</span>
                  Edit Profil
                </button>
              </div>
            </div>
          </div>

          {/* Keamanan */}
          <div className="bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden shadow-sm">
            <div className="bg-surface-container-low px-6 py-4 border-b border-outline-variant">
              <h2 className="font-h2 text-[18px] font-bold text-on-surface">Keamanan</h2>
            </div>
            <div className="p-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
              <div>
                <h3 className="font-body-lg text-[16px] font-bold text-on-surface">Kata Sandi Akun</h3>
                <p className="font-body-md text-[13px] text-on-surface-variant mt-1 flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[16px] text-primary">check_circle</span>
                  Update password terakhir: 2 minggu yang lalu
                </p>
              </div>
              <button className="flex items-center justify-center gap-2 px-6 py-2 bg-[#000051] text-white rounded-lg font-label-sm text-sm font-semibold hover:bg-[#1a237e] transition-colors shadow-sm w-full sm:w-auto whitespace-nowrap">
                <span className="material-symbols-outlined text-[18px]">key</span>
                Ubah Password
              </button>
            </div>
          </div>

          {/* Danger Zone */}
          <div className="bg-[#fff0f0] border border-[#ffcdd2] rounded-xl overflow-hidden mt-4 shadow-sm">
            <div className="p-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
              <div>
                <h3 className="font-body-lg text-[16px] font-bold text-error">Sesi Akun</h3>
                <p className="font-body-md text-[13px] text-on-surface-variant mt-1">Mengakhiri sesi aktif Anda di perangkat ini.</p>
              </div>
              <button className="flex items-center justify-center gap-2 px-6 py-2 bg-error text-white rounded-lg font-label-sm text-sm font-semibold hover:bg-[#93000a] transition-colors shadow-sm w-full sm:w-auto whitespace-nowrap">
                <span className="material-symbols-outlined text-[18px]">logout</span>
                Keluar dari Sistem
              </button>
            </div>
          </div>

        </div>

        {/* Right Column (Secondary Settings) */}
        <div className="flex flex-col gap-6">

          {/* Preferensi Notifikasi */}
          <div className="bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden shadow-sm">
            <div className="bg-surface-container-low px-6 py-4 border-b border-outline-variant">
              <h2 className="font-h2 text-[18px] font-bold text-on-surface">Preferensi Notifikasi</h2>
            </div>
            <div className="p-6 flex flex-col gap-6">
              <div className="flex justify-between items-center gap-4">
                <div className="flex-1">
                  <h3 className="font-body-lg text-[14px] font-bold text-on-surface">Notifikasi Email</h3>
                  <p className="font-body-md text-[12px] text-on-surface-variant mt-0.5 leading-tight">Terima ringkasan sistem via email</p>
                </div>
                <Toggle checked={emailNotif} onChange={setEmailNotif} />
              </div>

              <div className="border-t border-dashed border-outline-variant"></div>

              <div className="flex justify-between items-center gap-4">
                <div className="flex-1">
                  <h3 className="font-body-lg text-[14px] font-bold text-on-surface">Peringatan Cukai (Excise Alerts)</h3>
                  <p className="font-body-md text-[12px] text-on-surface-variant mt-0.5 leading-tight">Laporan anomali data pita cukai</p>
                </div>
                <Toggle checked={exciseAlerts} onChange={setExciseAlerts} />
              </div>

              <div className="border-t border-dashed border-outline-variant"></div>

              <div className="flex justify-between items-center gap-4">
                <div className="flex-1">
                  <h3 className="font-body-lg text-[14px] font-bold text-on-surface">Laporan Masuk Baru</h3>
                  <p className="font-body-md text-[12px] text-on-surface-variant mt-0.5 leading-tight">Pemberitahuan real-time via web</p>
                </div>
                <Toggle checked={newReports} onChange={setNewReports} />
              </div>
            </div>
          </div>

          {/* Tentang Aplikasi */}
          <div className="bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden shadow-sm text-center">
            <div className="bg-surface-container-low px-6 py-4 border-b border-outline-variant text-left">
              <h2 className="font-h2 text-[18px] font-bold text-on-surface">Tentang Aplikasi</h2>
            </div>
            <div className="p-8 flex flex-col items-center gap-3">
              <div className="w-16 h-16 bg-[#000051]/5 border border-[#000051]/10 rounded-2xl flex items-center justify-center text-[#000051] mb-2 shadow-sm">
                <span className="material-symbols-outlined text-[36px]" style={{ fontVariationSettings: "'FILL' 1" }}>admin_panel_settings</span>
              </div>
              <h3 className="font-h1 text-[18px] font-bold text-on-surface">APHT Sumenep One</h3>
              <p className="font-body-md text-[13px] text-on-surface-variant">Sistem Informasi Pengawasan & Data Industri</p>

              <div className="mt-3">
                <span className="bg-surface-variant text-on-surface-variant px-3 py-1 rounded font-mono text-[11px] font-bold tracking-wider">Version 1.0.0</span>
              </div>

              <p className="font-body-md text-[11px] text-outline mt-6">
                © 2026 APHT Sumenep. All rights reserved.
              </p>
            </div>
          </div>

        </div>

      </div>
    </div>
  );
};

export default PengaturanAkun;
