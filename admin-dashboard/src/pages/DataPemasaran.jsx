import React from 'react';

const DataPemasaran = () => {
  const distributors = [
    { no: '1', name: 'PT Surya Sakti Raya', region: 'Jawa Timur', volume: '450,000', value: '900,000,000' },
    { no: '2', name: 'CV Bintang Harapan', region: 'Jawa Tengah', volume: '320,000', value: '640,000,000' },
    { no: '3', name: 'Maju Jaya Logistik', region: 'DKI Jakarta', volume: '280,000', value: '560,000,000' },
    { no: '4', name: 'PT Nusantara Distribusi', region: 'Jawa Barat', volume: '210,000', value: '420,000,000' },
    { no: '5', name: 'Koperasi Sinar Mas', region: 'Bali', volume: '150,000', value: '300,000,000' },
  ];

  return (
    <div className="flex flex-col gap-lg w-full max-w-container-max mx-auto p-4 lg:p-0">
      
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-surface-variant pb-4">
        <div>
          <h1 className="font-h1 text-[28px] font-bold text-on-surface">Data Pemasaran</h1>
          <p className="font-body-md text-on-surface-variant mt-1">Pantau dan analisis performa distribusi wilayah.</p>
        </div>
        <button className="flex items-center gap-xs px-md py-sm bg-[#00146b] text-white rounded-lg font-label-sm text-sm font-semibold hover:bg-[#001050] transition-colors shadow-sm whitespace-nowrap">
          <span className="material-symbols-outlined text-[18px]">download</span>
          EXPORT LAPORAN
        </button>
      </div>

      {/* Filters */}
      <div className="bg-surface border border-outline-variant rounded-xl p-4 flex flex-col md:flex-row gap-4 items-end mt-2">
        <div className="flex flex-col gap-1 flex-1 w-full">
          <label className="font-label-sm text-[11px] text-on-surface-variant">Pabrik (Factory)</label>
          <div className="relative">
            <select className="w-full appearance-none px-4 py-2 bg-surface border border-outline-variant rounded-lg text-sm text-on-surface focus:outline-none focus:border-primary">
              <option>Semua Pabrik</option>
            </select>
            <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-outline text-[20px] pointer-events-none">expand_more</span>
          </div>
        </div>
        <div className="flex flex-col gap-1 flex-1 w-full">
          <label className="font-label-sm text-[11px] text-on-surface-variant">Wilayah (Region)</label>
          <div className="relative">
            <select className="w-full appearance-none px-4 py-2 bg-surface border border-outline-variant rounded-lg text-sm text-on-surface focus:outline-none focus:border-primary">
              <option>Semua Wilayah</option>
            </select>
            <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-outline text-[20px] pointer-events-none">expand_more</span>
          </div>
        </div>
        <div className="flex flex-col gap-1 flex-1 w-full">
          <label className="font-label-sm text-[11px] text-on-surface-variant">Periode</label>
          <div className="relative">
            <select className="w-full appearance-none px-4 py-2 bg-surface border border-outline-variant rounded-lg text-sm text-on-surface focus:outline-none focus:border-primary">
              <option>Bulan Ini</option>
            </select>
            <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-outline text-[20px] pointer-events-none">expand_more</span>
          </div>
        </div>
        <button className="px-6 py-2 bg-surface-container-low border border-outline-variant text-on-surface rounded-lg text-sm font-medium hover:bg-surface-container transition-colors w-full md:w-auto h-[38px]">
          Terapkan
        </button>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Card 1 */}
        <div className="bg-surface border border-outline-variant rounded-xl p-5 flex flex-col gap-2">
          <div className="flex justify-between items-center">
             <span className="font-label-sm text-xs text-on-surface-variant uppercase tracking-wider font-semibold">TOTAL PENJUALAN</span>
             <span className="material-symbols-outlined text-primary text-[20px] bg-primary-container p-1 rounded">payments</span>
          </div>
          <span className="font-h1 text-[26px] font-bold text-primary mt-2">Rp 4.2 M</span>
          <span className="font-label-sm text-xs text-[#21c55e] font-medium flex items-center"><span className="material-symbols-outlined text-[14px]">arrow_upward</span> +12.5% vs bulan lalu</span>
        </div>
        {/* Card 2 */}
        <div className="bg-surface border border-outline-variant rounded-xl p-5 flex flex-col gap-2">
          <div className="flex justify-between items-center">
             <span className="font-label-sm text-xs text-on-surface-variant uppercase tracking-wider font-semibold">VOLUME TERJUAL</span>
             <span className="material-symbols-outlined text-primary text-[20px] bg-primary-container p-1 rounded">inventory_2</span>
          </div>
          <span className="font-h1 text-[26px] font-bold text-[#1a237e] mt-2">2.1M Btg</span>
          <span className="font-label-sm text-xs text-[#21c55e] font-medium flex items-center"><span className="material-symbols-outlined text-[14px]">arrow_upward</span> +8.2% vs bulan lalu</span>
        </div>
        {/* Card 3 */}
        <div className="bg-surface border border-outline-variant rounded-xl p-5 flex flex-col gap-2">
          <div className="flex justify-between items-center">
             <span className="font-label-sm text-xs text-on-surface-variant uppercase tracking-wider font-semibold">TOTAL DISTRIBUTOR</span>
             <span className="material-symbols-outlined text-primary text-[20px] bg-primary-container p-1 rounded">local_shipping</span>
          </div>
          <span className="font-h1 text-[26px] font-bold text-[#1a237e] mt-2">45</span>
          <span className="font-label-sm text-xs text-on-surface-variant font-medium flex items-center"><span className="material-symbols-outlined text-[14px]">horizontal_rule</span> Stabil</span>
        </div>
        {/* Card 4 */}
        <div className="bg-surface border border-outline-variant rounded-xl p-5 flex flex-col gap-2">
          <div className="flex justify-between items-center">
             <span className="font-label-sm text-xs text-on-surface-variant uppercase tracking-wider font-semibold">CAKUPAN WILAYAH</span>
             <span className="material-symbols-outlined text-primary text-[20px] bg-primary-container p-1 rounded">map</span>
          </div>
          <span className="font-h1 text-[26px] font-bold text-[#1a237e] mt-2">12</span>
          <span className="font-label-sm text-xs text-[#21c55e] font-medium flex items-center"><span className="material-symbols-outlined text-[14px]">add</span> 2 Wilayah Baru</span>
        </div>
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Left Box: Tren Penjualan */}
        <div className="lg:col-span-2 bg-surface border border-outline-variant rounded-xl p-6 flex flex-col relative overflow-hidden min-h-[400px]">
           <div className="flex justify-between items-center z-10 relative bg-surface pb-2">
             <h2 className="font-h2 text-[16px] font-bold text-on-surface">Tren Penjualan 6 Bulan Terakhir</h2>
             <button className="text-outline hover:text-on-surface transition-colors">
               <span className="material-symbols-outlined">more_vert</span>
             </button>
           </div>
           
           {/* SVG Line Chart Placeholder */}
           <div className="absolute inset-0 pt-16 px-6 pb-12 flex flex-col justify-between pointer-events-none">
              {/* Y Axis Lines */}
              <div className="w-full flex justify-between text-[10px] text-outline border-b border-surface-variant relative h-0"><span className="absolute -top-2 -left-4">5M</span></div>
              <div className="w-full flex justify-between text-[10px] text-outline border-b border-surface-variant relative h-0"><span className="absolute -top-2 -left-4">4M</span></div>
              <div className="w-full flex justify-between text-[10px] text-outline border-b border-surface-variant relative h-0"><span className="absolute -top-2 -left-4">3M</span></div>
              <div className="w-full flex justify-between text-[10px] text-outline border-b border-surface-variant relative h-0"><span className="absolute -top-2 -left-4">2M</span></div>
              <div className="w-full flex justify-between text-[10px] text-outline border-b border-surface-variant relative h-0"><span className="absolute -top-2 -left-4">1M</span></div>
              <div className="w-full flex justify-between text-[10px] text-outline border-b border-surface-variant relative h-0"><span className="absolute -top-2 -left-4">0</span></div>
           </div>
           
           <div className="absolute inset-0 pt-16 px-6 pb-12 overflow-hidden flex items-end">
              <svg viewBox="0 0 100 100" preserveAspectRatio="none" className="w-full h-full">
                 <path d="M0,80 C20,75 30,90 40,60 C50,30 65,50 80,20 C90,0 100,20 100,20 L100,100 L0,100 Z" fill="#e8eaf6" opacity="0.5" />
                 <path d="M0,80 C20,75 30,90 40,60 C50,30 65,50 80,20 C90,0 100,20 100,20" fill="none" stroke="#1a237e" strokeWidth="1.5" />
                 <circle cx="40" cy="60" r="3" fill="white" stroke="#1a237e" strokeWidth="1" />
                 <circle cx="80" cy="20" r="3" fill="white" stroke="#1a237e" strokeWidth="1" />
              </svg>
           </div>
           
           {/* X Axis Labels */}
           <div className="absolute bottom-4 left-6 right-6 flex justify-between text-[10px] text-outline z-10 bg-surface/50 backdrop-blur-sm px-2">
             <span>Jan</span><span>Feb</span><span>Mar</span><span>Apr</span><span>Mei</span><span>Jun</span>
           </div>
        </div>

        {/* Right Box: Distribusi per Wilayah */}
        <div className="bg-surface border border-outline-variant rounded-xl p-6 flex flex-col">
           <h2 className="font-h2 text-[16px] font-bold text-on-surface mb-8">Distribusi per Wilayah</h2>
           
           <div className="flex-1 flex flex-col items-center justify-center gap-8">
              {/* Donut Chart representation */}
              <div className="w-48 h-48 relative rounded-xl overflow-hidden shadow-sm border border-outline-variant">
                 <div className="absolute inset-0 bg-[#000051]"></div>
                 <div className="absolute top-0 left-0 w-1/2 h-full bg-[#1a237e]"></div>
                 <div className="absolute bottom-0 left-0 w-full h-1/2 bg-[#534bae]"></div>
                 <div className="absolute top-0 right-0 w-1/2 h-1/2 bg-[#8c9eff] rounded-bl-full"></div>
                 <div className="absolute inset-4 bg-surface rounded-xl flex flex-col items-center justify-center shadow-inner">
                    <span className="font-h1 text-[32px] font-bold text-[#1a237e]">12</span>
                    <span className="font-label-sm text-[10px] text-outline uppercase tracking-wider">Wilayah</span>
                 </div>
              </div>

              {/* Legend */}
              <div className="w-full flex flex-col gap-3">
                 <div className="flex justify-between items-center text-xs">
                    <div className="flex items-center gap-2"><div className="w-3 h-3 bg-[#000051]"></div><span className="text-on-surface">Jawa Timur</span></div>
                    <span className="font-bold">45%</span>
                 </div>
                 <div className="flex justify-between items-center text-xs">
                    <div className="flex items-center gap-2"><div className="w-3 h-3 bg-[#1a237e]"></div><span className="text-on-surface">Jawa Tengah</span></div>
                    <span className="font-bold">30%</span>
                 </div>
                 <div className="flex justify-between items-center text-xs">
                    <div className="flex items-center gap-2"><div className="w-3 h-3 bg-[#534bae]"></div><span className="text-on-surface">Jawa Barat</span></div>
                    <span className="font-bold">15%</span>
                 </div>
                 <div className="flex justify-between items-center text-xs">
                    <div className="flex items-center gap-2"><div className="w-3 h-3 bg-[#8c9eff]"></div><span className="text-on-surface">Lainnya</span></div>
                    <span className="font-bold">10%</span>
                 </div>
              </div>
           </div>
        </div>
      </div>

      {/* Bottom Section: Daftar Distributor */}
      <div className="bg-surface border border-outline-variant rounded-xl overflow-hidden mt-4 mb-8">
        <div className="p-4 border-b border-surface-variant flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
           <h2 className="font-h2 text-[16px] font-bold text-on-surface">Daftar Distributor</h2>
           <div className="relative w-full md:w-64">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-outline text-[18px]">search</span>
              <input type="text" placeholder="Cari distributor..." className="w-full pl-9 pr-4 py-2 bg-surface-container-lowest border border-outline-variant rounded-lg text-sm focus:outline-none focus:border-primary" />
           </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-outline-variant bg-surface-container-low/30">
                <th className="p-4 font-label-sm text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold pl-6">NO</th>
                <th className="p-4 font-label-sm text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold">DISTRIBUTOR</th>
                <th className="p-4 font-label-sm text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold">WILAYAH</th>
                <th className="p-4 font-label-sm text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold">VOLUME (BTG)</th>
                <th className="p-4 font-label-sm text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold text-right">NILAI (RP)</th>
                <th className="p-4 pr-6"></th>
              </tr>
            </thead>
            <tbody>
              {distributors.map((item, index) => (
                <tr key={index} className="border-b border-surface-variant hover:bg-surface-container-low transition-colors">
                  <td className="p-4 font-body-md text-[13px] text-on-surface-variant pl-6">{item.no}</td>
                  <td className="p-4 font-body-md font-bold text-[13px] text-on-surface">{item.name}</td>
                  <td className="p-4 font-body-md text-[13px] text-on-surface-variant">{item.region}</td>
                  <td className="p-4 font-body-md text-[13px] text-on-surface-variant">{item.volume}</td>
                  <td className="p-4 font-body-md text-[13px] text-on-surface-variant text-right">{item.value}</td>
                  <td className="p-4 pr-6 text-right">
                    <span className="material-symbols-outlined text-outline text-[18px] cursor-pointer hover:text-primary">chevron_right</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="p-4 flex justify-between items-center bg-surface-container-lowest text-[11px] text-on-surface-variant border-t border-surface-variant">
          <span>Menampilkan 1-5 dari 45 distributor</span>
          <div className="flex gap-2">
             <button className="px-3 py-1 border border-outline-variant rounded hover:bg-surface-container-low">Prev</button>
             <button className="px-3 py-1 border border-outline-variant rounded hover:bg-surface-container-low">Next</button>
          </div>
        </div>
      </div>

    </div>
  );
};

export default DataPemasaran;
