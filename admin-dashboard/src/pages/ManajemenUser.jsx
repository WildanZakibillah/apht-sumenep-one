import React, { useState } from 'react';

const ManajemenUser = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);

  const users = [
    { id: 1, name: 'Budi Santoso', email: 'budi.santoso@apht.com', role: 'Admin Pabrik', roleClass: 'bg-[#d9e2ff] text-[#001945]', status: 'Active', statusClass: 'bg-[#e8f5e9] text-[#2e7d32]' },
    { id: 2, name: 'Siti Aminah', email: 'siti.aminah@apht.com', role: 'Staf Lapangan', roleClass: 'bg-[#e0e0ff] text-[#000767]', status: 'Active', statusClass: 'bg-[#e8f5e9] text-[#2e7d32]' },
    { id: 3, name: 'Ahmad Wijaya', email: 'ahmad.wijaya@apht.com', role: 'Direktur', roleClass: 'bg-[#ffdbd0] text-[#390c00]', status: 'Inactive', statusClass: 'bg-[#ffcdd2] text-[#c62828]' },
  ];

  return (
    <div className="flex flex-col gap-lg w-full max-w-container-max mx-auto p-4 lg:p-0 relative">
      {/* Header */}
      <div className="flex items-center justify-between pb-4">
        <div>
          <h2 className="font-h1 text-[28px] font-bold text-on-surface">Manajemen User</h2>
          <p className="font-body-md text-on-surface-variant mt-1">Kelola akses dan peran pengguna dalam sistem.</p>
        </div>
        <button 
          onClick={() => setIsModalOpen(true)}
          className="bg-[#000051] text-white font-label-sm text-sm px-4 py-2 rounded-lg hover:bg-[#1a237e] transition-colors shadow-sm flex items-center gap-2"
        >
          <span className="material-symbols-outlined text-[18px]">add</span>
          Tambah User
        </button>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
        <div className="bg-surface border border-outline-variant rounded-xl p-5 flex flex-col gap-2">
          <div className="flex justify-between items-center">
             <span className="font-label-sm text-xs text-on-surface-variant uppercase tracking-wider font-semibold">TOTAL USERS</span>
             <span className="material-symbols-outlined text-primary text-[20px] bg-primary-container/10 p-1 rounded">people</span>
          </div>
          <span className="font-h1 text-[26px] font-bold text-on-surface mt-1">34</span>
        </div>
        <div className="bg-surface border border-outline-variant rounded-xl p-5 flex flex-col gap-2">
          <div className="flex justify-between items-center">
             <span className="font-label-sm text-xs text-on-surface-variant uppercase tracking-wider font-semibold">ACTIVE</span>
             <span className="material-symbols-outlined text-[#21c55e] text-[20px] bg-[#21c55e]/10 p-1 rounded">verified_user</span>
          </div>
          <span className="font-h1 text-[26px] font-bold text-on-surface mt-1">31</span>
        </div>
        <div className="bg-surface border border-outline-variant rounded-xl p-5 flex flex-col gap-2">
          <div className="flex justify-between items-center">
             <span className="font-label-sm text-xs text-on-surface-variant uppercase tracking-wider font-semibold">INACTIVE</span>
             <span className="material-symbols-outlined text-error text-[20px] bg-error/10 p-1 rounded">block</span>
          </div>
          <span className="font-h1 text-[26px] font-bold text-on-surface mt-1">3</span>
        </div>
      </div>

      {/* Table Controls */}
      <div className="flex justify-between items-center bg-surface p-4 rounded-t-xl border border-outline-variant border-b-0">
        <div className="relative w-full max-w-[300px]">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-outline text-[20px]">search</span>
          <input 
            className="w-full pl-10 pr-4 py-2 bg-surface-container-lowest border border-outline-variant rounded text-sm text-on-surface focus:border-primary focus:outline-none transition-all" 
            placeholder="Cari user..." 
            type="text" 
          />
        </div>
        <div className="flex gap-3">
          <div className="relative hidden md:block">
            <select className="appearance-none pl-4 pr-10 py-2 border border-outline-variant rounded text-sm text-on-surface focus:border-primary focus:outline-none transition-all bg-surface-container-lowest">
              <option>Semua Role</option>
            </select>
            <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-outline pointer-events-none text-[18px]">expand_more</span>
          </div>
          <div className="relative hidden md:block">
            <select className="appearance-none pl-4 pr-10 py-2 border border-outline-variant rounded text-sm text-on-surface focus:border-primary focus:outline-none transition-all bg-surface-container-lowest">
              <option>Semua Status</option>
            </select>
            <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-outline pointer-events-none text-[18px]">expand_more</span>
          </div>
        </div>
      </div>

      {/* Data Table */}
      <div className="bg-surface-container-lowest rounded-b-xl border border-outline-variant overflow-hidden shadow-sm mb-8">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[800px]">
            <thead className="bg-surface-container-low/30">
              <tr>
                <th className="font-h3 text-xs text-on-surface-variant uppercase tracking-wider font-semibold py-4 px-6 border-b border-outline-variant w-[60px]">NO</th>
                <th className="font-h3 text-xs text-on-surface-variant uppercase tracking-wider font-semibold py-4 px-6 border-b border-outline-variant">USER</th>
                <th className="font-h3 text-xs text-on-surface-variant uppercase tracking-wider font-semibold py-4 px-6 border-b border-outline-variant">ROLE</th>
                <th className="font-h3 text-xs text-on-surface-variant uppercase tracking-wider font-semibold py-4 px-6 border-b border-outline-variant">STATUS</th>
                <th className="font-h3 text-xs text-on-surface-variant uppercase tracking-wider font-semibold py-4 px-6 border-b border-outline-variant text-center w-[120px]">ACTIONS</th>
              </tr>
            </thead>
            <tbody className="font-body-md text-sm text-on-surface">
              {users.map((user, index) => (
                <tr key={index} className="border-b border-outline-variant hover:bg-surface-container-lowest transition-colors">
                  <td className="py-3 px-6 text-on-surface-variant">{index + 1}</td>
                  <td className="py-3 px-6">
                    <div className="flex flex-col">
                      <span className="font-bold text-on-surface">{user.name}</span>
                      <span className="text-xs text-on-surface-variant mt-0.5">{user.email}</span>
                    </div>
                  </td>
                  <td className="py-3 px-6">
                    <span className={`${user.roleClass} px-3 py-1 rounded-full text-[11px] font-bold`}>{user.role}</span>
                  </td>
                  <td className="py-3 px-6">
                    <span className={`${user.statusClass} px-3 py-1 rounded text-[11px] font-bold`}>{user.status}</span>
                  </td>
                  <td className="py-3 px-6 text-center">
                    <div className="flex justify-center gap-2 text-outline">
                      <button className="hover:text-primary transition-colors p-1"><span className="material-symbols-outlined text-[20px]">edit</span></button>
                      <button className="hover:text-error transition-colors p-1"><span className="material-symbols-outlined text-[20px]">delete</span></button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        {/* Pagination */}
        <div className="p-4 border-t border-outline-variant flex justify-between items-center text-xs text-on-surface-variant bg-surface-container-lowest">
          <span>Halaman 1 dari 5</span>
          <div className="flex gap-2">
            <button className="px-3 py-1.5 border border-outline-variant rounded hover:bg-surface-container-low transition-colors disabled:opacity-50" disabled>Prev</button>
            <button className="px-3 py-1.5 border border-outline-variant rounded hover:bg-surface-container-low transition-colors">Next</button>
          </div>
        </div>
      </div>

      {/* Modal: Tambah User Baru */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-[#1b1b21]/60 z-50 flex items-center justify-center p-4">
          <div className="bg-surface-container-lowest rounded-xl shadow-[0px_4px_20px_rgba(0,0,0,0.1)] w-full max-w-[500px] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            
            {/* Modal Header */}
            <div className="flex justify-between items-center p-5 border-b border-outline-variant bg-surface-container-lowest">
              <h3 className="font-h2 text-[18px] font-bold text-on-surface">Tambah User Baru</h3>
              <button 
                onClick={() => setIsModalOpen(false)}
                className="text-outline hover:text-on-surface transition-colors p-1 rounded-full hover:bg-surface-container-low flex items-center justify-center"
              >
                <span className="material-symbols-outlined text-[24px]">close</span>
              </button>
            </div>
            
            {/* Modal Body */}
            <div className="p-6 flex flex-col gap-4 bg-surface-container-lowest">
              <div className="flex flex-col gap-1.5">
                <label className="font-label-sm text-[11px] text-on-surface-variant font-medium">Nama Lengkap</label>
                <input 
                  className="w-full px-3 py-2 border border-outline-variant rounded text-sm text-on-surface focus:border-[#000051] focus:outline-none transition-all placeholder-outline" 
                  placeholder="Masukkan nama lengkap" 
                  type="text" 
                />
              </div>
              
              <div className="flex flex-col gap-1.5">
                <label className="font-label-sm text-[11px] text-on-surface-variant font-medium">Email</label>
                <div className="flex">
                  <input 
                    className="flex-1 px-3 py-2 border border-outline-variant border-r-0 rounded-l text-sm text-on-surface focus:border-[#000051] focus:outline-none transition-all placeholder-outline" 
                    placeholder="username" 
                    type="text" 
                  />
                  <div className="px-3 py-2 bg-surface border border-outline-variant rounded-r text-sm text-on-surface-variant flex items-center justify-center">
                    @apht.com
                  </div>
                </div>
              </div>
              
              <div className="flex flex-col gap-1.5">
                <label className="font-label-sm text-[11px] text-on-surface-variant font-medium">No. Telepon</label>
                <div className="flex">
                  <div className="px-3 py-2 bg-surface border border-outline-variant border-r-0 rounded-l text-sm text-on-surface flex items-center justify-center">
                    +62
                  </div>
                  <input 
                    className="flex-1 px-3 py-2 border border-outline-variant rounded-r text-sm text-on-surface focus:border-[#000051] focus:outline-none transition-all placeholder-outline" 
                    placeholder="8123456789" 
                    type="text" 
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="font-label-sm text-[11px] text-on-surface-variant font-medium">Role</label>
                  <div className="relative">
                    <select className="w-full appearance-none px-3 py-2 border border-outline-variant rounded text-sm text-on-surface focus:border-[#000051] focus:outline-none transition-all bg-surface-container-lowest">
                      <option>Admin Pabrik</option>
                      <option>Staf Lapangan</option>
                      <option>Direktur</option>
                    </select>
                    <span className="material-symbols-outlined absolute right-2 top-1/2 -translate-y-1/2 text-outline pointer-events-none text-[18px]">expand_more</span>
                  </div>
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="font-label-sm text-[11px] text-on-surface-variant font-medium">Pabrik</label>
                  <div className="relative">
                    <select className="w-full appearance-none px-3 py-2 border border-outline-variant rounded text-sm text-on-surface focus:border-[#000051] focus:outline-none transition-all bg-surface-container-lowest">
                      <option>PR. Karaoke</option>
                      <option>PT. Bintang Kejora</option>
                      <option>UD. Sinar Terang</option>
                    </select>
                    <span className="material-symbols-outlined absolute right-2 top-1/2 -translate-y-1/2 text-outline pointer-events-none text-[18px]">expand_more</span>
                  </div>
                </div>
              </div>

              <div className="mt-2 flex items-start gap-3 p-3 bg-[#f0f4ff] border border-[#d9e2ff] rounded-lg text-[13px] text-[#001945]">
                <span className="material-symbols-outlined text-[18px] text-[#2b5bb5] shrink-0 mt-0.5">info</span>
                <p className="leading-relaxed">Password awal akan di-generate otomatis dan ditampilkan setelah user berhasil dibuat.</p>
              </div>

            </div>
            
            {/* Modal Footer */}
            <div className="p-5 border-t border-outline-variant flex justify-end gap-3 bg-surface-container-lowest">
              <button 
                onClick={() => setIsModalOpen(false)}
                className="px-6 py-2 rounded border border-outline-variant text-on-surface font-label-sm text-sm font-semibold hover:bg-surface-container-low transition-colors"
              >
                Batal
              </button>
              <button 
                className="px-6 py-2 rounded bg-[#000051] text-white font-label-sm text-sm font-semibold hover:bg-[#1a237e] transition-colors shadow-sm"
              >
                Simpan User
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default ManajemenUser;
