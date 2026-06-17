import React, { useState, useEffect, useMemo } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';
import { useToast } from '../hooks/useToast';
import { useTheme } from '../context/ThemeContext';
import { useRoleAccess } from '../hooks/useRoleAccess';
import PageHeader from '../components/shared/PageHeader';
import StatCard from '../components/shared/StatCard';
import { SkeletonCard, SkeletonTable } from '../components/shared/Skeleton';
import Modal from '../components/shared/Modal';
import SearchBar from '../components/shared/SearchBar';

const STOCK_STATUSES = [
  { id: 'all', label: 'Semua Status', icon: 'splitscreen', color: 'slate' },
  { id: 'safe', label: 'Stok Aman (>100 pak)', icon: 'check_circle', color: 'emerald' },
  { id: 'low', label: 'Stok Menipis (1-100 pak)', icon: 'warning', color: 'amber' },
  { id: 'empty', label: 'Stok Habis (0 pak)', icon: 'error_outline', color: 'rose' }
];

const ADJUST_REASONS = [
  'Stock Opname / Audit Fisik',
  'Koreksi Input Data',
  'Sampel Uji Rasa / Promosi',
  'Produk Rusak / BS (Bad Stock)',
  'Lainnya'
];

const DataStok = () => {
  const { isDark } = useTheme();
  const { ready } = useAuth();
  const { scopeQuery, isFactoryScoped, factoryId, isDirektur } = useRoleAccess();
  const toast = useToast();

  const [cigarettes, setCigarettes] = useState([]);
  const [factories, setFactories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedFactory, setSelectedFactory] = useState(isFactoryScoped ? factoryId : 'all');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [selectedType, setSelectedType] = useState('all');

  // Adjustment Modal State
  const [showAdjustModal, setShowAdjustModal] = useState(false);
  const [adjustingProduct, setAdjustingProduct] = useState(null);
  const [adjustForm, setAdjustForm] = useState({
    type: 'tambah', // 'tambah' or 'kurang'
    qty: '',
    reason: ADJUST_REASONS[0],
    notes: ''
  });
  const [savingAdjust, setSavingAdjust] = useState(false);

  // History Modal State
  const [showHistoryModal, setShowHistoryModal] = useState(false);
  const [historyProduct, setHistoryProduct] = useState(null);
  const [historyLogs, setHistoryLogs] = useState([]);
  const [historyLoading, setHistoryLoading] = useState(false);

  const loadData = async () => {
    setLoading(true);
    try {
      const [cRes, fRes] = await Promise.all([
        scopeQuery(supabase.from('cigarettes').select('*, brands(name, status), factories(name)').order('product_name')),
        scopeQuery(supabase.from('factories').select('id, name').order('name'), 'id')
      ]);

      if (cRes.error) throw cRes.error;
      if (fRes.error) throw fRes.error;

      setCigarettes(cRes.data || []);
      setFactories(fRes.data || []);
    } catch (err) {
      toast.error('Gagal memuat data: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (ready) loadData();
  }, [ready]); // eslint-disable-line

  // Factory name for direktur/admin context
  const factoryName = isDirektur && factories.length > 0 ? factories[0]?.name : null;

  // Filtered Cigarettes
  const filteredCigarettes = useMemo(() => {
    return cigarettes.filter((c) => {
      // 1. Factory Filter
      if (selectedFactory !== 'all' && c.factory_id !== selectedFactory) return false;

      // 2. Product Type / Category Filter
      if (selectedType !== 'all' && c.cigarette_type !== selectedType) return false;

      // 3. Stock Status Filter
      const stock = c.stock || 0;
      if (selectedStatus === 'empty' && stock !== 0) return false;
      if (selectedStatus === 'low' && (stock === 0 || stock > 100)) return false;
      if (selectedStatus === 'safe' && stock <= 100) return false;

      // 4. Search Filter
      const q = search.trim().toLowerCase();
      if (q) {
        const nameMatch = c.product_name?.toLowerCase().includes(q);
        const brandMatch = c.brands?.name?.toLowerCase().includes(q);
        const codeMatch = c.product_code?.toLowerCase().includes(q);
        const factoryMatch = c.factories?.name?.toLowerCase().includes(q);
        return nameMatch || brandMatch || codeMatch || factoryMatch;
      }

      return true;
    });
  }, [cigarettes, selectedFactory, selectedType, selectedStatus, search]);

  // Statistics Computations
  const stats = useMemo(() => {
    const subset = selectedFactory === 'all' 
      ? cigarettes 
      : cigarettes.filter(c => c.factory_id === selectedFactory);

    let totalStockPacks = 0;
    let totalStockSticks = 0;
    let lowStockCount = 0;
    let emptyStockCount = 0;

    subset.forEach((c) => {
      const stock = c.stock || 0;
      const sticks = stock * (c.sticks_per_pack || 12);
      totalStockPacks += stock;
      totalStockSticks += sticks;
      
      if (stock === 0) {
        emptyStockCount++;
      } else if (stock <= 100) {
        lowStockCount++;
      }
    });

    return {
      totalStockPacks,
      totalStockSticks,
      lowStockCount,
      emptyStockCount,
      totalProducts: subset.length
    };
  }, [cigarettes, selectedFactory]);

  // History loader
  const loadProductHistory = async (product) => {
    setHistoryLoading(true);
    setHistoryLogs([]);
    try {
      const [prodRes, outRes] = await Promise.all([
        supabase.from('productions')
          .select('doc_date, doc_number, jumlah_kemasan, created_at')
          .eq('product_id', product.id)
          .order('doc_date', { ascending: false })
          .limit(50),
        supabase.from('outgoing_goods')
          .select('transaction_date, customer_name, volume, created_at')
          .eq('product_id', product.id)
          .order('transaction_date', { ascending: false })
          .limit(50)
      ]);

      if (prodRes.error) throw prodRes.error;
      if (outRes.error) throw outRes.error;

      const sticksPerPack = product.sticks_per_pack || 12;

      const prodLogs = (prodRes.data || []).map(p => ({
        date: p.doc_date,
        createdAt: p.created_at,
        type: 'production',
        label: 'Produksi Masuk',
        reference: p.doc_number,
        detail: 'Produksi baru selesai dicatat',
        qty: p.jumlah_kemasan,
        isPositive: true
      }));

      const outLogs = (outRes.data || []).map(o => ({
        date: o.transaction_date,
        createdAt: o.created_at,
        type: 'outgoing',
        label: 'Distribusi Keluar',
        reference: o.customer_name,
        detail: 'Penjualan ke distributor',
        qty: Math.round(o.volume / sticksPerPack),
        isPositive: false
      }));

      const combined = [...prodLogs, ...outLogs].sort((a, b) => {
        const dateCompare = b.date.localeCompare(a.date);
        if (dateCompare !== 0) return dateCompare;
        return b.createdAt.localeCompare(a.createdAt);
      });

      setHistoryLogs(combined);
    } catch (err) {
      toast.error('Gagal memuat riwayat: ' + err.message);
    } finally {
      setHistoryLoading(false);
    }
  };

  const openAdjustModal = (product) => {
    setAdjustingProduct(product);
    setAdjustForm({
      type: 'tambah',
      qty: '',
      reason: ADJUST_REASONS[0],
      notes: ''
    });
    setShowAdjustModal(true);
  };

  const closeAdjustModal = () => {
    if (savingAdjust) return;
    setShowAdjustModal(false);
    setAdjustingProduct(null);
  };

  const openHistoryModal = (product) => {
    setHistoryProduct(product);
    setShowHistoryModal(true);
    loadProductHistory(product);
  };

  const closeHistoryModal = () => {
    setShowHistoryModal(false);
    setHistoryProduct(null);
    setHistoryLogs([]);
  };

  const handleAdjustSubmit = async (e) => {
    e?.preventDefault?.();
    const qtyInt = parseInt(adjustForm.qty);
    if (!qtyInt || qtyInt <= 0) {
      toast.warning('Jumlah penyesuaian harus lebih dari 0');
      return;
    }
    setSavingAdjust(true);
    try {
      const currentStock = adjustingProduct.stock || 0;
      const adjustQty = adjustForm.type === 'tambah' ? qtyInt : -qtyInt;
      const newStock = currentStock + adjustQty;

      if (newStock < 0) {
        throw new Error('Penyesuaian menyebabkan stok negatif! Batalkan.');
      }

      const { error } = await supabase
        .from('cigarettes')
        .update({ stock: newStock })
        .eq('id', adjustingProduct.id);

      if (error) throw error;

      toast.success(`Stok berhasil disesuaikan menjadi ${newStock} pak`);
      closeAdjustModal();
      await loadData();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setSavingAdjust(false);
    }
  };

  if (loading && cigarettes.length === 0) {
    return (
      <div className="space-y-5 max-w-[1400px] mx-auto">
        <PageHeader title="Manajemen Stok Produk" description="Pantau persediaan rokok, limit minimum stok, dan kelola penyesuaian stok secara manual." />
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)}
        </div>
        <SkeletonTable rows={5} cols={6} />
      </div>
    );
  }

  return (
    <div className="space-y-5 max-w-[1400px] mx-auto">
      <PageHeader 
        title={isDirektur ? `Stok Produk ${factoryName || ''}` : 'Manajemen Stok Produk'} 
        description={isDirektur ? `Pantau stok dan kelola penyesuaian persediaan pabrik ${factoryName || 'Anda'}.` : 'Pantau persediaan rokok, limit minimum stok, dan kelola penyesuaian stok secara manual.'}
      />

      {/* Statistics Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon="inventory_2" label="Total Stok (Pak)" value={stats.totalStockPacks.toLocaleString('id-ID')} color="blue" />
        <StatCard icon="splitscreen" label="Total Stok (Batang)" value={stats.totalStockSticks.toLocaleString('id-ID')} color="green" />
        <StatCard icon="warning_amber" label="Stok Menipis" value={stats.lowStockCount} suffix="produk" color="amber" />
        <StatCard icon="error_outline" label="Stok Habis" value={stats.emptyStockCount} suffix="produk" color="red" />
      </div>

      {/* Filters & Actions Panel */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5 space-y-4 shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <SearchBar value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Cari rokok, kode, atau merek..." className="md:w-96" />

          <div className="flex flex-wrap items-center gap-3">
            {/* Factory Filter */}
            {!isFactoryScoped && (
              <div className="flex items-center gap-2">
                <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">Pabrik:</span>
                <select
                  value={selectedFactory}
                  onChange={(e) => setSelectedFactory(e.target.value)}
                  className="px-3 py-1.5 border border-gray-200 dark:border-gray-700 rounded-lg text-xs bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-indigo-500"
                >
                  <option value="all">Semua Pabrik</option>
                  {factories.map((f) => (
                    <option key={f.id} value={f.id}>{f.name}</option>
                  ))}
                </select>
              </div>
            )}

            {/* Type Filter */}
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">Jenis:</span>
              <select
                value={selectedType}
                onChange={(e) => setSelectedType(e.target.value)}
                className="px-3 py-1.5 border border-gray-200 dark:border-gray-700 rounded-lg text-xs bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-indigo-500"
              >
                <option value="all">Semua Jenis</option>
                <option value="SKT">SKT</option>
                <option value="SKM">SKM</option>
                <option value="SPM">SPM</option>
              </select>
            </div>
          </div>
        </div>

        {/* Tab Status Filters */}
        <div className="flex flex-wrap gap-2 pt-2 border-t border-gray-100 dark:border-gray-800/60">
          {STOCK_STATUSES.map((status) => {
            const isActive = selectedStatus === status.id;
            let btnClass = 'flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold border transition-all duration-150 ';
            
            if (isActive) {
              if (status.color === 'emerald') btnClass += 'bg-emerald-50 dark:bg-emerald-950/30 text-emerald-700 dark:text-emerald-400 border-emerald-200 dark:border-emerald-900/40 shadow-sm';
              else if (status.color === 'amber') btnClass += 'bg-amber-50 dark:bg-amber-950/30 text-amber-700 dark:text-amber-400 border-amber-200 dark:border-amber-900/40 shadow-sm';
              else if (status.color === 'rose') btnClass += 'bg-red-50 dark:bg-red-950/30 text-red-700 dark:text-red-400 border-red-200 dark:border-red-900/40 shadow-sm';
              else btnClass += 'bg-indigo-50 dark:bg-indigo-950/30 text-indigo-700 dark:text-indigo-400 border-indigo-200 dark:border-indigo-900/40 shadow-sm';
            } else {
              btnClass += 'bg-white dark:bg-gray-800 text-gray-500 dark:text-gray-400 border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-750';
            }

            return (
              <button key={status.id} onClick={() => setSelectedStatus(status.id)} className={btnClass}>
                <span className="material-symbols-outlined text-[15px]">{status.icon}</span>
                {status.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Main Stock Table */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-150 dark:border-gray-800">
                <th className="px-5 py-3.5 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider pl-6">Produk & SKU</th>
                <th className="px-5 py-3.5 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Merek & Pabrik</th>
                <th className="px-5 py-3.5 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Jenis</th>
                <th className="px-5 py-3.5 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider text-right">Stok (Pak)</th>
                <th className="px-5 py-3.5 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider text-right">Stok (Batang)</th>
                <th className="px-5 py-3.5 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Harga & Cukai</th>
                <th className="px-5 py-3.5 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider text-center">Status</th>
                <th className="px-5 py-3.5 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider text-center pr-6">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800/60">
              {filteredCigarettes.length === 0 ? (
                <tr>
                  <td colSpan="8" className="px-5 py-16 text-center text-gray-400 dark:text-gray-500 text-sm">
                    {search ? 'Tidak ada stok produk yang sesuai pencarian' : 'Belum ada data persediaan produk'}
                  </td>
                </tr>
              ) : (
                filteredCigarettes.map((c) => {
                  const stock = c.stock || 0;
                  const sticks = stock * (c.sticks_per_pack || 12);
                  const isLow = stock > 0 && stock <= 100;
                  const isEmpty = stock === 0;

                  return (
                    <tr key={c.id} className="hover:bg-gray-50/40 dark:hover:bg-gray-800/10 transition-colors duration-150">
                      {/* Product & SKU */}
                      <td className="px-5 py-4 pl-6">
                        <div className="flex items-center gap-3">
                          {c.product_image ? (
                            <img src={c.product_image} alt={c.product_name} className="w-10 h-10 rounded-lg object-cover border border-gray-200 dark:border-gray-700 bg-white" />
                          ) : (
                            <div className="w-10 h-10 rounded-lg bg-indigo-50 dark:bg-indigo-950/30 border border-indigo-100 dark:border-indigo-900/40 flex items-center justify-center">
                              <span className="material-symbols-outlined text-indigo-600 dark:text-indigo-400 text-[20px]">smoking_rooms</span>
                            </div>
                          )}
                          <div>
                            <div className="font-bold text-gray-900 dark:text-white text-[13.5px]">{c.product_name}</div>
                            <div className="text-[10px] text-gray-400 dark:text-gray-500 font-mono mt-0.5">SKU: {c.product_code || '-'} {c.variant ? `| Varian: ${c.variant}` : ''}</div>
                          </div>
                        </div>
                      </td>

                      {/* Brand & Factory */}
                      <td className="px-5 py-4">
                        <div className="text-xs font-semibold text-gray-800 dark:text-gray-200">{c.brands?.name}</div>
                        <div className="text-[10px] text-gray-400 dark:text-gray-500 font-medium mt-0.5">{c.factories?.name}</div>
                      </td>

                      {/* Category */}
                      <td className="px-5 py-4">
                        <span className="text-[11px] font-bold px-2 py-0.5 rounded bg-slate-50 dark:bg-slate-900 text-slate-700 dark:text-slate-400 border border-slate-100 dark:border-slate-800/50">
                          {c.cigarette_type || '-'}
                        </span>
                      </td>

                      {/* Stock in Packs */}
                      <td className="px-5 py-4 text-right">
                        <div className={`text-sm font-bold ${isEmpty ? 'text-red-500' : isLow ? 'text-amber-500' : 'text-gray-900 dark:text-white'}`}>
                          {stock.toLocaleString('id-ID')}
                        </div>
                        <div className="text-[10px] text-gray-400 dark:text-gray-500 mt-0.5">{c.sticks_per_pack || 12} btg/pak</div>
                      </td>

                      {/* Stock in Sticks */}
                      <td className="px-5 py-4 text-right">
                        <div className="text-xs font-semibold text-gray-600 dark:text-gray-400">
                          {sticks.toLocaleString('id-ID')} btg
                        </div>
                      </td>

                      {/* Price & Excise */}
                      <td className="px-5 py-4">
                        <div className="text-xs font-semibold text-gray-800 dark:text-gray-200">HJE: Rp {Number(c.hje || 0).toLocaleString('id-ID')}</div>
                        <div className="text-[10px] text-gray-400 dark:text-gray-500 font-medium mt-0.5">Cukai: Rp {Number(c.excise_rate || 0).toLocaleString('id-ID')}/btg</div>
                      </td>

                      {/* Status */}
                      <td className="px-5 py-4 text-center">
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold ${
                          isEmpty 
                            ? 'bg-red-50 dark:bg-red-950/20 text-red-600 dark:text-red-400 border border-red-100 dark:border-red-900/20' 
                            : isLow 
                              ? 'bg-amber-50 dark:bg-amber-950/20 text-amber-600 dark:text-amber-400 border border-amber-100 dark:border-amber-900/20' 
                              : 'bg-emerald-50 dark:bg-emerald-950/20 text-emerald-600 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/20'
                        }`}>
                          <span className={`w-1 h-1 rounded-full ${isEmpty ? 'bg-red-500' : isLow ? 'bg-amber-500' : 'bg-emerald-500'}`}></span>
                          {isEmpty ? 'Habis' : isLow ? 'Menipis' : 'Aman'}
                        </span>
                      </td>

                      {/* Actions */}
                      <td className="px-5 py-4 text-center pr-6">
                        <div className="flex items-center justify-center gap-2">
                          <button
                            onClick={() => openAdjustModal(c)}
                            className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-indigo-100 dark:border-indigo-900/40 bg-indigo-50/30 dark:bg-indigo-950/10 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 text-indigo-600 dark:text-indigo-300 text-xs font-semibold transition-all duration-150"
                            title="Sesuaikan Stok"
                          >
                            <span className="material-symbols-outlined text-[15px]">edit_note</span>
                            Adjust
                          </button>
                          
                          <button
                            onClick={() => openHistoryModal(c)}
                            className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
                            title="Riwayat Mutasi Stok"
                          >
                            <span className="material-symbols-outlined text-[16px]">history</span>
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
        
        <div className="px-6 py-3 border-t border-gray-150 dark:border-gray-800 flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
          <span>Menampilkan {filteredCigarettes.length} dari {cigarettes.length} produk</span>
        </div>
      </div>

      {/* Manual Stock Adjustment Modal */}
      <Modal
        open={showAdjustModal}
        onClose={closeAdjustModal}
        title="Penyesuaian Stok (Manual)"
        footer={
          <>
            <button onClick={closeAdjustModal} disabled={savingAdjust} className="px-4 py-2 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">Batal</button>
            <button onClick={handleAdjustSubmit} disabled={savingAdjust} className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-lg shadow-sm transition-all">
              {savingAdjust ? 'Menyimpan...' : 'Simpan Penyesuaian'}
            </button>
          </>
        }
      >
        {adjustingProduct && (
          <form onSubmit={handleAdjustSubmit} className="space-y-4">
            <div className="p-3 bg-gray-50 dark:bg-gray-800/40 rounded-lg border border-gray-100 dark:border-gray-800">
              <div className="text-xs font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Produk Terpilih</div>
              <div className="font-bold text-gray-900 dark:text-white mt-1 text-sm">{adjustingProduct.product_name}</div>
              <div className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">Merek: {adjustingProduct.brands?.name} | Stok Saat Ini: <span className="font-bold text-indigo-600 dark:text-indigo-400">{adjustingProduct.stock || 0} pak</span></div>
            </div>

            {/* Type Selector */}
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Tipe Penyesuaian</label>
              <div className="grid grid-cols-2 gap-3">
                <button
                  type="button"
                  onClick={() => setAdjustForm({ ...adjustForm, type: 'tambah' })}
                  className={`flex items-center justify-center gap-1.5 py-2.5 rounded-lg border text-sm font-semibold transition-all ${
                    adjustForm.type === 'tambah'
                      ? 'bg-emerald-50 dark:bg-emerald-950/20 text-emerald-600 dark:text-emerald-400 border-emerald-200 dark:border-emerald-900/50 shadow-sm'
                      : 'bg-white dark:bg-gray-800 text-gray-500 dark:text-gray-400 border-gray-200 dark:border-gray-700'
                  }`}
                >
                  <span className="material-symbols-outlined text-[18px]">add_circle_outline</span>
                  Tambah Stok
                </button>
                
                <button
                  type="button"
                  onClick={() => setAdjustForm({ ...adjustForm, type: 'kurang' })}
                  className={`flex items-center justify-center gap-1.5 py-2.5 rounded-lg border text-sm font-semibold transition-all ${
                    adjustForm.type === 'kurang'
                      ? 'bg-red-50 dark:bg-red-950/20 text-red-600 dark:text-red-400 border-red-200 dark:border-red-900/50 shadow-sm'
                      : 'bg-white dark:bg-gray-800 text-gray-500 dark:text-gray-400 border-gray-200 dark:border-gray-700'
                  }`}
                >
                  <span className="material-symbols-outlined text-[18px]">remove_circle_outline</span>
                  Kurang Stok
                </button>
              </div>
            </div>

            {/* Quantity Input */}
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Jumlah Penyesuaian (Pak) <span className="text-red-500">*</span></label>
              <input
                type="number"
                min="1"
                required
                value={adjustForm.qty}
                onChange={(e) => setAdjustForm({ ...adjustForm, qty: e.target.value })}
                className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-indigo-500"
                placeholder="Masukkan jumlah dalam bungkus/pak..."
              />
            </div>

            {/* Reason Selector */}
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Alasan Penyesuaian</label>
              <select
                value={adjustForm.reason}
                onChange={(e) => setAdjustForm({ ...adjustForm, reason: e.target.value })}
                className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-indigo-500"
              >
                {ADJUST_REASONS.map((r) => (
                  <option key={r} value={r}>{r}</option>
                ))}
              </select>
            </div>

            {/* Notes */}
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Keterangan Tambahan</label>
              <textarea
                value={adjustForm.notes}
                onChange={(e) => setAdjustForm({ ...adjustForm, notes: e.target.value })}
                rows="2"
                className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-indigo-500 resize-none"
                placeholder="Catatan tambahan penyesuaian..."
              />
            </div>
          </form>
        )}
      </Modal>

      {/* Stock History Audit Log Modal */}
      <Modal
        open={showHistoryModal}
        onClose={closeHistoryModal}
        title="Riwayat & Mutasi Stok (Ledger)"
        size="lg"
        footer={<button onClick={closeHistoryModal} className="px-5 py-2.5 bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 text-xs font-bold rounded-lg transition-colors">Tutup</button>}
      >
        {historyProduct && (
          <div className="space-y-4">
            <div className="p-4 bg-slate-50 dark:bg-slate-900/30 rounded-xl border border-slate-100 dark:border-slate-800 flex items-center justify-between">
              <div>
                <h4 className="font-bold text-gray-900 dark:text-white text-[15px]">{historyProduct.product_name}</h4>
                <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">Merek: {historyProduct.brands?.name} | SKU: {historyProduct.product_code || '-'}</p>
              </div>
              <div className="text-right">
                <div className="text-2xl font-black text-indigo-600 dark:text-indigo-400">{(historyProduct.stock || 0).toLocaleString()}</div>
                <div className="text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Stok Saat Ini (Pak)</div>
              </div>
            </div>

            <div className="border border-gray-150 dark:border-gray-800 rounded-xl overflow-hidden bg-white dark:bg-gray-950">
              <div className="max-h-[350px] overflow-y-auto custom-scrollbar">
                <table className="w-full text-left">
                  <thead>
                    <tr className="bg-gray-50 dark:bg-gray-900 border-b border-gray-150 dark:border-gray-800 sticky top-0 z-10">
                      <th className="px-5 py-2.5 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase pl-6">Tanggal</th>
                      <th className="px-5 py-2.5 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Tipe Mutasi</th>
                      <th className="px-5 py-2.5 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Referensi / Penerima</th>
                      <th className="px-5 py-2.5 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right pr-6">Kuantitas</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-850">
                    {historyLoading ? (
                      <tr>
                        <td colSpan="4" className="px-5 py-12 text-center text-gray-400 dark:text-gray-500 text-sm">
                          <div className="flex flex-col items-center gap-2 justify-center">
                            <div className="w-5 h-5 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
                            <span>Memuat mutasi persediaan...</span>
                          </div>
                        </td>
                      </tr>
                    ) : historyLogs.length === 0 ? (
                      <tr>
                        <td colSpan="4" className="px-5 py-12 text-center text-gray-400 dark:text-gray-500 text-sm">
                          Belum ada catatan mutasi masuk (produksi) atau keluar (penjualan) untuk produk ini.
                        </td>
                      </tr>
                    ) : (
                      historyLogs.map((log, index) => (
                        <tr key={index} className="hover:bg-gray-50/30 dark:hover:bg-gray-800/10">
                          <td className="px-5 py-3 pl-6 text-xs text-gray-500 dark:text-gray-400 font-mono">{log.date}</td>
                          <td className="px-5 py-3">
                            <div className="flex items-center gap-1.5">
                              <span className={`w-1.5 h-1.5 rounded-full ${log.isPositive ? 'bg-emerald-500' : 'bg-red-500'}`}></span>
                              <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">{log.label}</span>
                            </div>
                            <span className="text-[10px] text-gray-450 dark:text-gray-500 block mt-0.5">{log.detail}</span>
                          </td>
                          <td className="px-5 py-3 text-xs text-gray-850 dark:text-gray-200 font-semibold">{log.reference || '-'}</td>
                          <td className={`px-5 py-3 text-right pr-6 text-sm font-bold ${log.isPositive ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-500'}`}>
                            {log.isPositive ? '+' : '-'}{log.qty.toLocaleString('id-ID')} pak
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};

export default DataStok;
