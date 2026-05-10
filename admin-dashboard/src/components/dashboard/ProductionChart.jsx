import React from 'react';

const ProductionChart = () => {
  const chartData = [
    { label: 'A', value: 80, color: 'bg-primary', hoverColor: 'hover:bg-primary-container' },
    { label: 'B', value: 65, color: 'bg-secondary', hoverColor: 'hover:bg-secondary-container' },
    { label: 'C', value: 40, color: 'bg-primary', hoverColor: 'hover:bg-primary-container' },
    { label: 'D', value: 95, color: 'bg-secondary', hoverColor: 'hover:bg-secondary-container' },
    { label: 'E', value: 30, color: 'bg-primary', hoverColor: 'hover:bg-primary-container' },
    { label: 'F', value: 55, color: 'bg-secondary', hoverColor: 'hover:bg-secondary-container' },
    { label: 'G', value: 70, color: 'bg-primary', hoverColor: 'hover:bg-primary-container' },
    { label: 'H', value: 45, color: 'bg-secondary', hoverColor: 'hover:bg-secondary-container' },
    { label: 'I', value: 85, color: 'bg-primary', hoverColor: 'hover:bg-primary-container' },
    { label: 'J', value: 20, color: 'bg-secondary', hoverColor: 'hover:bg-secondary-container' },
    { label: 'K', value: 60, color: 'bg-primary', hoverColor: 'hover:bg-primary-container' },
  ];

  return (
    <div className="bg-surface-container-lowest border border-outline-variant p-md rounded-xl flex flex-col gap-md">
      <div className="flex justify-between items-center border-b border-surface-variant pb-sm">
        <h3 className="font-h3 text-h3 text-on-surface">PERBANDINGAN PRODUKSI 11 PABRIK</h3>
        <button className="p-1 hover:bg-surface-container-low rounded text-outline">
          <span className="material-symbols-outlined">more_vert</span>
        </button>
      </div>
      
      <div className="relative h-[300px] w-full flex items-end justify-between px-md pt-lg pb-sm gap-2">
        {/* Grid Lines */}
        <div className="absolute inset-0 flex flex-col justify-between pt-lg pb-sm z-0 pointer-events-none opacity-10">
          {[...Array(5)].map((_, i) => (
             <div key={i} className="w-full border-t border-outline"></div>
          ))}
        </div>

        {/* Bars */}
        {chartData.map((data, index) => (
          <div key={index} className="relative z-10 flex flex-col items-center justify-end h-full w-full group">
            <div 
              className={`w-full max-w-[40px] rounded-t-[2px] transition-colors relative ${data.color} ${data.hoverColor}`} 
              style={{ height: `${data.value}%` }}
            >
              <div className="absolute -top-6 left-1/2 -translate-x-1/2 font-label-sm text-label-sm text-on-surface opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                {data.value}k
              </div>
            </div>
            <span className="font-mono text-mono text-outline mt-xs">{data.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ProductionChart;
