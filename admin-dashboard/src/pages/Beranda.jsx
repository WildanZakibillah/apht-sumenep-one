import React from 'react';
import StatCard from '../components/dashboard/StatCard';
import HeroSection from '../components/dashboard/HeroSection';
import ProductionChart from '../components/dashboard/ProductionChart';
import ActivityList from '../components/dashboard/ActivityList';

const DashboardHome = () => {
  return (
    <div className="flex flex-col gap-lg w-full max-w-container-max mx-auto">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-md">
        <h1 className="font-h1 text-h1 text-primary">RINGKASAN: MEI 2026</h1>
        <div className="flex items-center gap-sm">
          <button className="flex items-center gap-xs px-md py-sm bg-surface-container-lowest border border-outline-variant rounded-lg text-on-surface font-label-sm text-label-sm hover:bg-surface-container-low transition-colors">
            <span className="material-symbols-outlined text-[18px]">calendar_month</span>
            Mei 2026
            <span className="material-symbols-outlined text-[18px]">arrow_drop_down</span>
          </button>
          <button className="flex items-center gap-xs px-md py-sm bg-primary text-on-primary rounded-lg font-label-sm text-label-sm hover:bg-primary-container transition-colors shadow-sm">
            <span className="material-symbols-outlined text-[18px]">download</span>
            Export
          </button>
        </div>
      </div>

      {/* Hero Section or Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-md">
        <StatCard 
          title="Total Pabrik" 
          value="11" 
          subtitle="Aktif" 
          icon="factory" 
          trend="0% dari bulan lalu" 
          colorClass="text-primary bg-surface-container" 
          trendIcon="horizontal_rule"
          trendClass="text-outline"
        />
        <StatCard 
          title="Produksi Total" 
          value="3.450.000" 
          subtitle="Btg" 
          icon="conveyor_belt" 
          trend="12% naik dari bulan lalu" 
          colorClass="text-secondary bg-surface-container" 
          trendIcon="trending_up"
          trendClass="text-secondary"
        />
        <StatCard 
          title="Sisa Pita" 
          value="120.500" 
          subtitle="Lbr" 
          icon="receipt_long" 
          trend="8% turun dari bulan lalu" 
          colorClass="text-error bg-error-container" 
          trendIcon="trending_down"
          trendClass="text-error"
        />
      </div>

      <HeroSection />

      <ProductionChart />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-lg mb-20 lg:mb-0">
        <ActivityList />
        {/* Report Status Panel */}
        <div className="bg-surface-container-lowest border border-outline-variant rounded-xl flex flex-col h-[320px]">
          <div className="p-md border-b border-surface-variant flex justify-between items-center bg-surface-container-low rounded-t-xl">
            <h3 className="font-h3 text-h3 text-on-surface flex items-center gap-xs">
              <span className="material-symbols-outlined text-primary">fact_check</span>
              STATUS LAPORAN (Mei)
            </h3>
          </div>
          <div className="flex-1 p-md flex flex-col justify-center gap-lg">
            <div className="flex flex-col gap-xs">
              <div className="flex justify-between items-end">
                <span className="font-body-md text-body-md font-medium text-on-surface">Selesai (Complete)</span>
                <span className="font-h3 text-h3 text-primary">9/11</span>
              </div>
              <div className="w-full bg-surface-variant h-2 rounded-full overflow-hidden">
                <div className="bg-primary h-full rounded-full" style={{ width: '81%' }}></div>
              </div>
            </div>
            <div className="flex flex-col gap-xs">
              <div className="flex justify-between items-end">
                <span className="font-body-md text-body-md font-medium text-on-surface">Dalam Review</span>
                <span className="font-h3 text-h3 text-tertiary">1/11</span>
              </div>
              <div className="w-full bg-surface-variant h-2 rounded-full overflow-hidden">
                <div className="bg-tertiary h-full rounded-full" style={{ width: '9%' }}></div>
              </div>
            </div>
            <div className="flex flex-col gap-xs">
              <div className="flex justify-between items-end">
                <span className="font-body-md text-body-md font-medium text-on-surface">Belum Kirim</span>
                <span className="font-h3 text-h3 text-error">1/11</span>
              </div>
              <div className="w-full bg-surface-variant h-2 rounded-full overflow-hidden">
                <div className="bg-error h-full rounded-full" style={{ width: '9%' }}></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardHome;
