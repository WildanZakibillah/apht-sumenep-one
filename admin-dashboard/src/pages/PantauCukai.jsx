import React from 'react';

const PantauCukai = () => {
  const distributionData = [
    { factory: 'PT. Bintang Kejora', usageText: '40k / 50k (80%)', percentage: 80, barColor: 'bg-[#2962ff]' },
    { factory: 'CV. Makmur Sentosa', usageText: '25k / 35k (71%)', percentage: 71, barColor: 'bg-[#2962ff]' },
    { factory: 'UD. Sinar Terang', usageText: '15k / 20k (75%)', percentage: 75, barColor: 'bg-[#2962ff]' },
    { factory: 'PT. Surya Gemilang', usageText: '48k / 50k (96%)', percentage: 96, barColor: 'bg-[#1a237e]' },
    { factory: 'Koperasi Harapan', usageText: '5k / 15k (33%)', percentage: 33, barColor: 'bg-[#a6c1ee]' },
  ];

  const criticalData = [
    { factory: 'PT. Surya Gemilang', quota: '50,000', sisa: '2,000', percent: '4.0%', status: 'CRITICAL', statusClass: 'bg-[#ffcdd2] text-[#c62828]' },
    { factory: 'CV. Budi Djaya', quota: '10,000', sisa: '850', percent: '8.5%', status: 'WARNING', statusClass: 'bg-[#ffcc80] text-[#ef6c00]' },
    { factory: 'UD. Cipta Karya', quota: '5,000', sisa: '480', percent: '9.6%', status: 'WARNING', statusClass: 'bg-[#ffcc80] text-[#ef6c00]' },
  ];

  return (
    <div className="flex flex-col gap-lg w-full max-w-container-max mx-auto p-4 lg:p-0">
      
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-surface-variant pb-4">
        <div>
          <h1 className="font-h1 text-[28px] font-bold text-on-surface">Monitoring Pita Cukai</h1>
          <p className="font-body-md text-on-surface-variant mt-1">Overview of excise stamp distribution and usage</p>
        </div>
        <div className="flex items-center gap-3">
          <span className="font-label-sm text-xs text-outline uppercase tracking-wider">PERIOD</span>
          <button className="flex items-center gap-xs px-md py-sm bg-surface-container-lowest border border-outline-variant rounded-lg text-on-surface font-label-sm text-sm hover:bg-surface-container-low transition-colors">
            Q3 - 2023
            <span className="material-symbols-outlined text-[18px]">expand_more</span>
          </button>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mt-2">
        {/* Card 1 */}
        <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-6 flex flex-col justify-between h-[120px]">
          <span className="font-label-sm text-xs text-on-surface-variant uppercase tracking-wider font-semibold">STOK APHT</span>
          <div className="flex justify-between items-end">
             <span className="font-h1 text-4xl font-bold text-on-surface">500k</span>
             <span className="material-symbols-outlined text-primary text-[24px]">inventory_2</span>
          </div>
        </div>
        
        {/* Card 2 */}
        <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-6 flex flex-col justify-between h-[120px]">
          <span className="font-label-sm text-xs text-on-surface-variant uppercase tracking-wider font-semibold">TERPAKAI</span>
          <div className="flex justify-between items-end">
             <span className="font-h1 text-4xl font-bold text-on-surface">370k</span>
             <div className="flex flex-col items-end gap-1 w-16">
                <span className="font-label-sm text-[11px] text-primary font-bold">74%</span>
                <div className="w-full bg-surface-variant h-1 rounded-full overflow-hidden">
                  <div className="bg-primary h-full w-[74%] rounded-full"></div>
                </div>
             </div>
          </div>
        </div>

        {/* Card 3 */}
        <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-6 flex flex-col justify-between h-[120px]">
          <span className="font-label-sm text-xs text-on-surface-variant uppercase tracking-wider font-semibold">RUSAK</span>
          <div className="flex justify-between items-end">
             <span className="font-h1 text-4xl font-bold text-error">950</span>
             <span className="material-symbols-outlined text-error text-[24px]">trending_down</span>
          </div>
        </div>

        {/* Card 4 */}
        <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-6 flex flex-col justify-between h-[120px]">
          <span className="font-label-sm text-xs text-on-surface-variant uppercase tracking-wider font-semibold">SISA</span>
          <div className="flex justify-between items-end">
             <span className="font-h1 text-4xl font-bold text-on-surface">129k</span>
             <span className="material-symbols-outlined text-primary text-[24px]">hourglass_empty</span>
          </div>
        </div>
      </div>

      {/* Middle Section: Distribution & Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-2">
        {/* Left Box: Distribusi */}
        <div className="lg:col-span-2 bg-surface-container-lowest border border-outline-variant rounded-xl p-6 flex flex-col gap-6">
           <h2 className="font-h2 text-[16px] font-bold text-on-surface uppercase tracking-wide">DISTRIBUSI CUKAI PER PABRIK</h2>
           
           <div className="flex flex-col gap-5 mt-2">
              {distributionData.map((item, index) => (
                <div key={index} className="flex flex-col gap-1">
                   <div className="flex justify-between items-center text-[11px] font-semibold text-on-surface">
                     <span>{item.factory}</span>
                     <span className="text-on-surface-variant">{item.usageText}</span>
                   </div>
                   <div className="w-full h-4 bg-surface-variant rounded-sm overflow-hidden flex">
                     <div className={`h-full ${item.barColor} transition-all`} style={{ width: `${item.percentage}%` }}></div>
                   </div>
                </div>
              ))}
           </div>
        </div>

        {/* Right Box: Usage Breakdown Empty State */}
        <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-6 flex flex-col items-center justify-center text-center gap-4 min-h-[300px]">
           <span className="material-symbols-outlined text-[48px] text-outline opacity-50">pie_chart</span>
           <h3 className="font-h2 text-[18px] font-bold text-on-surface">Cukai Usage<br/>Breakdown</h3>
           <p className="font-body-sm text-sm text-on-surface-variant max-w-[200px]">Select a factory from the list or chart to view detailed usage breakdown.</p>
        </div>
      </div>

      {/* Bottom Section: Critical Factories */}
      <div className="bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden mt-2 mb-8">
        <div className="p-6 border-b border-surface-variant bg-surface-container-lowest">
           <h2 className="font-h2 text-[16px] font-bold text-on-surface uppercase tracking-wide">PABRIK KRITIS (Sisa &lt; 10%)</h2>
        </div>
        <div className="overflow-x-auto bg-surface-container-lowest">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-outline-variant bg-surface-container-low/30">
                <th className="p-4 font-label-sm text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold pl-6">FACTORY</th>
                <th className="p-4 font-label-sm text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold">QUOTA</th>
                <th className="p-4 font-label-sm text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold">SISA</th>
                <th className="p-4 font-label-sm text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold">%</th>
                <th className="p-4 font-label-sm text-[11px] text-on-surface-variant uppercase tracking-wider font-semibold pr-6">STATUS</th>
              </tr>
            </thead>
            <tbody>
              {criticalData.map((item, index) => (
                <tr key={index} className="border-b border-surface-variant hover:bg-surface-container-low transition-colors">
                  <td className="p-4 font-body-md font-bold text-[13px] text-on-surface pl-6">{item.factory}</td>
                  <td className="p-4 font-body-md text-[13px] text-on-surface-variant">{item.quota}</td>
                  <td className="p-4 font-body-md text-[13px] text-on-surface-variant">{item.sisa}</td>
                  <td className="p-4 font-body-md text-[13px] text-on-surface-variant">{item.percent}</td>
                  <td className="p-4 pr-6">
                    <span className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${item.statusClass}`}>
                      {item.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  );
};

export default PantauCukai;
