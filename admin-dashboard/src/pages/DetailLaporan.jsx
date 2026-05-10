import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { supabaseMock } from '../data/mockSupabase';

const DetailLaporan = () => {
  const { id } = useParams();
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // In a real app, we would fetch the specific report by ID
    // For the mockup, we will use the specific details from the screenshot directly
    const fetchReport = async () => {
      setLoading(true);
      const { data } = await supabaseMock.from('reports').select();
      // Even if we fetch, we will hardcode the display data for now to match the exact mockup
      setReport({
        id: id,
        factoryName: 'PR. Karaoke Damai Di Hati',
        status: 'MENUNGGU VERIFIKASI'
      });
      setLoading(false);
    };
    fetchReport();
  }, [id]);

  if (loading) return <div className="p-4 text-center">Loading...</div>;

  return (
    <div className="flex flex-col gap-lg w-full max-w-[1000px] mx-auto p-4 lg:p-0">
      
      {/* Header & Breadcrumb */}
      <div className="flex flex-col gap-1">
        <div className="flex items-center gap-2 text-sm">
          <Link to="/dashboard/laporan-masuk" className="text-on-surface-variant hover:text-primary transition-colors font-medium">Laporan</Link>
          <span className="material-symbols-outlined text-[16px] text-outline">chevron_right</span>
          <span className="text-on-surface-variant">Review: PR. Karaoke Damai Di Hati</span>
        </div>
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mt-2">
          <h1 className="font-h1 text-[28px] font-bold text-primary">PR. Karaoke Damai Di Hati</h1>
          <div className="flex items-center gap-2 px-4 py-2 bg-[#ffe4d6] text-[#b34000] rounded-full font-label-sm text-sm font-semibold whitespace-nowrap">
            <span className="material-symbols-outlined text-[18px]">assignment_late</span>
            MENUNGGU VERIFIKASI
          </div>
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-4">
        
        {/* Left Column: DATA PRODUKSI */}
        <div className="bg-surface border border-outline-variant rounded-xl p-6 flex flex-col gap-6">
          <div className="flex items-center gap-3 border-b border-surface-variant pb-4">
            <span className="material-symbols-outlined text-primary text-[24px]">conveyor_belt</span>
            <h2 className="font-h2 text-[18px] font-bold text-on-surface tracking-wide">DATA PRODUKSI</h2>
          </div>
          
          <div className="bg-surface-container-lowest border border-surface-variant rounded-lg p-5">
            <p className="font-label-sm text-xs text-outline uppercase tracking-wider mb-1">KATEGORI PABRIK</p>
            <h3 className="font-h1 text-[24px] font-bold text-primary">SKT</h3>
            <p className="font-body-md text-on-surface-variant mt-1">Sigaret Kretek Tangan</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-surface-container-lowest border border-surface-variant rounded-lg p-4">
              <p className="font-label-sm text-xs text-outline uppercase tracking-wider mb-1">Total Pack</p>
              <p className="font-h1 text-[22px] font-bold text-on-surface">12,500</p>
            </div>
            <div className="bg-surface-container-lowest border border-surface-variant rounded-lg p-4">
              <p className="font-label-sm text-xs text-outline uppercase tracking-wider mb-1">Total Batang</p>
              <p className="font-h1 text-[22px] font-bold text-on-surface">150,000</p>
            </div>
          </div>

          <div className="flex flex-col gap-2 mt-2">
             <p className="font-label-sm text-xs text-outline uppercase tracking-wider border-b border-surface-variant pb-2">BRANDS DIPRODUKSI</p>
             <div className="flex flex-wrap gap-2 pt-2">
               <span className="px-3 py-1 bg-surface-container-low border border-outline-variant rounded text-sm text-on-surface">Karaoke Merah</span>
               <span className="px-3 py-1 bg-surface-container-low border border-outline-variant rounded text-sm text-on-surface">Karaoke Biru 12</span>
             </div>
          </div>
        </div>

        {/* Right Column: PENGGUNAAN PITA CUKAI */}
        <div className="bg-surface border border-outline-variant rounded-xl p-6 flex flex-col gap-6">
          <div className="flex justify-between items-center border-b border-surface-variant pb-4">
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-primary text-[24px]">receipt_long</span>
              <h2 className="font-h2 text-[18px] font-bold text-on-surface tracking-wide">PENGGUNAAN PITA CUKAI</h2>
            </div>
            <span className="font-body-md text-sm text-outline">Periode: Okt 2023</span>
          </div>
          
          <div className="bg-surface-container-lowest border border-surface-variant rounded-lg p-6 flex flex-col gap-4">
            
            <div className="flex justify-between items-center">
              <span className="font-body-md text-on-surface-variant text-sm">Saldo Awal (Stock Start)</span>
              <span className="font-body-lg font-bold text-on-surface">45,000</span>
            </div>
            
            <div className="flex justify-between items-center text-primary">
              <span className="font-body-md text-sm flex items-center gap-2"><span className="material-symbols-outlined text-[16px]">add</span> Penerimaan Baru (In)</span>
              <span className="font-body-lg font-bold">10,000</span>
            </div>

            <div className="border-t border-dashed border-outline-variant my-2"></div>

            <div className="flex justify-between items-center">
              <span className="font-body-md text-outline text-sm">Subtotal Tersedia</span>
              <span className="font-body-lg font-bold text-on-surface">55,000</span>
            </div>

            <div className="flex justify-between items-center text-error mt-4">
              <span className="font-body-md text-sm flex items-center gap-2"><span className="material-symbols-outlined text-[16px]">remove</span> Pita Rusak (Damaged)</span>
              <span className="font-body-lg font-bold">- 150</span>
            </div>

            <div className="flex justify-between items-center text-on-surface mt-2">
              <span className="font-body-md text-sm flex items-center gap-2 text-on-surface-variant"><span className="material-symbols-outlined text-[16px]">remove</span> Digunakan (Used)</span>
              <span className="font-body-lg font-bold">- 12,500</span>
            </div>

            <div className="mt-6 bg-primary-container/30 border border-primary-container rounded-lg p-4 flex justify-between items-center">
              <span className="font-h3 text-[18px] font-bold text-primary">Saldo Akhir (Final Balance)</span>
              <span className="font-h1 text-[26px] font-bold text-primary">42,350</span>
            </div>

          </div>
        </div>
      </div>

      {/* Bottom Row: VALIDASI SISTEM */}
      <div className="bg-surface border border-outline-variant rounded-xl overflow-hidden flex flex-col md:flex-row mt-4 mb-8">
        <div className="bg-surface-container-lowest p-8 flex flex-col justify-center gap-4 w-full md:w-[350px] border-b md:border-b-0 md:border-r border-outline-variant">
          <div className="w-12 h-12 rounded-lg bg-primary-container/50 border border-primary/20 flex items-center justify-center text-primary">
            <span className="material-symbols-outlined text-[24px]">verified_user</span>
          </div>
          <div>
             <h2 className="font-h2 text-[20px] font-bold text-on-surface">VALIDASI SISTEM</h2>
             <p className="font-body-md text-on-surface-variant text-sm mt-2 leading-relaxed">Pemeriksaan otomatis silang data laporan terhadap basis data master.</p>
          </div>
        </div>
        
        <div className="p-8 flex-1 flex flex-col gap-6">
           <div className="flex gap-4">
             <span className="material-symbols-outlined text-primary text-[24px] shrink-0">check_circle</span>
             <div>
               <h3 className="font-body-lg font-bold text-on-surface text-[15px]">Kesesuaian Produksi vs Pita Cukai</h3>
               <p className="font-body-md text-on-surface-variant text-sm mt-1">Jumlah pack diproduksi (12,500) cocok dengan jumlah pita cukai yang digunakan.</p>
             </div>
           </div>
           
           <div className="flex gap-4">
             <span className="material-symbols-outlined text-primary text-[24px] shrink-0">check_circle</span>
             <div>
               <h3 className="font-body-lg font-bold text-on-surface text-[15px]">Kelengkapan Dokumen Lampiran</h3>
               <p className="font-body-md text-on-surface-variant text-sm mt-1">Bukti setor dan foto fisik pita cukai terlampir dan terbaca oleh sistem.</p>
             </div>
           </div>

           <div className="flex gap-4">
             <span className="material-symbols-outlined text-primary text-[24px] shrink-0">check_circle</span>
             <div>
               <h3 className="font-body-lg font-bold text-on-surface text-[15px]">Validitas Tanda Tangan Digital</h3>
               <p className="font-body-md text-on-surface-variant text-sm mt-1">Tanda tangan penanggung jawab pabrik valid dan sertifikat aktif.</p>
             </div>
           </div>
        </div>
      </div>

    </div>
  );
};

export default DetailLaporan;
