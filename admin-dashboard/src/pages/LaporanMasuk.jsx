import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { supabaseMock } from '../data/mockSupabase';

const ReportCard = ({ report }) => {
  const getStatusStyles = (status) => {
    switch (status) {
      case 'verified':
        return 'bg-surface-variant text-on-surface';
      case 'rejected':
        return 'bg-error-container text-error';
      case 'pending':
      default:
        return 'bg-[#5c1800] text-white'; // Dark brown from the mockup
    }
  };

  const statusLabelClass = getStatusStyles(report.status);
  const isRejected = report.status === 'rejected';

  return (
    <div className={`bg-surface-container-lowest border rounded-xl p-4 md:p-6 flex flex-col md:flex-row items-start md:items-center justify-between gap-4 transition-shadow hover:shadow-sm ${isRejected ? 'border-error border-l-4' : 'border-outline-variant'}`}>
      
      <div className="flex items-start gap-4 w-full md:w-auto">
        <div className={`w-12 h-12 rounded-lg flex items-center justify-center shrink-0 ${isRejected ? 'bg-error/10 text-error' : 'bg-surface-container-low text-primary'}`}>
          <span className="material-symbols-outlined text-[24px]">
             {isRejected ? 'domain_disabled' : 'domain'}
          </span>
        </div>
        <div>
          <h3 className="font-h3 text-body-lg font-bold text-on-surface">{report.factoryName}</h3>
          <p className="font-body-md text-on-surface-variant mt-1">ID: {report.factoryCode}</p>
        </div>
      </div>

      <div className="flex flex-col md:flex-row items-start md:items-center gap-6 w-full md:w-auto mt-4 md:mt-0 justify-between md:justify-end flex-1">
        <div className="flex items-start gap-2 min-w-[150px]">
           <span className="material-symbols-outlined text-outline text-[18px]">calendar_month</span>
           <div>
             <p className="font-label-sm text-[11px] text-outline uppercase">Periode</p>
             <p className="font-body-md font-medium text-on-surface">{report.period}</p>
             <p className="font-label-sm text-[11px] text-on-surface-variant mt-1">Dikirim: {report.dateSent}</p>
           </div>
        </div>

        <div className="flex flex-col gap-2 min-w-[150px]">
          <div className="flex items-center gap-2">
            <span className={`material-symbols-outlined text-[16px] ${report.ttdDirektur ? 'text-[#21c55e]' : 'text-outline'}`}>
              {report.ttdDirektur ? 'check_circle' : 'radio_button_unchecked'}
            </span>
            <span className={`font-label-sm text-[12px] ${report.ttdDirektur ? 'text-on-surface' : 'text-outline'}`}>Ttd. Direktur</span>
          </div>
          <div className="flex items-center gap-2">
            <span className={`material-symbols-outlined text-[16px] ${report.validasiAPHT ? 'text-secondary' : (isRejected ? 'text-error' : 'text-outline')}`}>
              {report.validasiAPHT ? 'check_circle' : (isRejected ? 'cancel' : 'radio_button_unchecked')}
            </span>
            <span className={`font-label-sm text-[12px] ${report.validasiAPHT ? 'text-on-surface' : (isRejected ? 'text-error' : 'text-outline')}`}>
              {isRejected ? 'Ditolak Sistem' : 'Validasi APHT'}
            </span>
          </div>
        </div>

        <div className="flex flex-col items-end gap-2 w-full md:w-auto mt-4 md:mt-0 min-w-[160px]">
          <div className={`px-3 py-1 rounded text-[11px] font-medium ${statusLabelClass}`}>
            {report.statusLabel}
          </div>
          <Link to={`/dashboard/laporan-masuk/${report.id}`} className="flex items-center gap-1 text-secondary hover:text-primary transition-colors text-sm font-medium mt-1">
            Open <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
          </Link>
        </div>
      </div>
    </div>
  );
};

const IncomingReports = () => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('Semua');

  useEffect(() => {
    const fetchReports = async () => {
      setLoading(true);
      const { data } = await supabaseMock.from('reports').select();
      setReports(data);
      setLoading(false);
    };
    fetchReports();
  }, []);

  const pendingCount = reports.filter(r => r.status === 'pending').length;
  const verifiedCount = reports.filter(r => r.status === 'verified').length;
  const rejectedCount = reports.filter(r => r.status === 'rejected').length;

  const tabs = [
    { id: 'Semua', label: `Semua(${reports.length})` },
    { id: 'Pending', label: `Pending(${pendingCount})` },
    { id: 'Verified', label: `Verified(${verifiedCount})` },
    { id: 'Tolak', label: `Tolak(${rejectedCount})` }
  ];

  const filteredReports = reports.filter(r => {
    if (activeTab === 'Pending') return r.status === 'pending';
    if (activeTab === 'Verified') return r.status === 'verified';
    if (activeTab === 'Tolak') return r.status === 'rejected';
    return true;
  });

  return (
    <div className="flex flex-col gap-lg w-full max-w-container-max mx-auto p-2 lg:p-0">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <h1 className="font-h1 text-[28px] font-bold text-on-surface">Laporan Masuk</h1>
        <button className="flex items-center gap-xs px-md py-sm bg-surface-container-lowest border border-outline-variant rounded-lg text-on-surface font-label-sm text-label-sm hover:bg-surface-container-low transition-colors">
          <span className="material-symbols-outlined text-[18px]">calendar_month</span>
          Mei 2026
          <span className="material-symbols-outlined text-[18px]">arrow_drop_down</span>
        </button>
      </div>

      <div className="flex flex-col w-full">
        <div className="flex border-b border-surface-variant overflow-x-auto custom-scrollbar">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`px-6 py-3 font-label-sm text-label-sm transition-colors border-b-2 whitespace-nowrap ${
                activeTab === tab.id
                  ? 'border-primary text-primary font-bold'
                  : 'border-transparent text-on-surface-variant hover:text-on-surface'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      <div className="flex flex-col gap-4 mt-2">
        {loading ? (
          <div className="p-4 text-center text-outline">Loading reports...</div>
        ) : (
          filteredReports.map((report) => (
            <ReportCard key={report.id} report={report} />
          ))
        )}
      </div>
    </div>
  );
};

export default IncomingReports;
