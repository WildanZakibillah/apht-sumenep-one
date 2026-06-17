import React, { useState, useEffect, useMemo } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';
import { useToast } from '../hooks/useToast';
import { useTheme } from '../context/ThemeContext';
import PageHeader from '../components/shared/PageHeader';
import StatCard from '../components/shared/StatCard';
import { SkeletonCard, SkeletonTable } from '../components/shared/Skeleton';
import Modal from '../components/shared/Modal';
import ConfirmDialog from '../components/shared/ConfirmDialog';
import SearchBar from '../components/shared/SearchBar';
import MonthPicker from '../components/shared/MonthPicker';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { useRoleAccess } from '../hooks/useRoleAccess';

const emptyGoodsForm = {
  transaction_date: new Date().toISOString().slice(0, 10),
  customer_name: '',
  region_id: '',
  product_id: '',
  factory_id: '',
  volume: 0,
  total_value: 0,
  payment_method: 'tunai',
};

const emptyDistForm = { name: '', region_id: '', contact_info: '' };

const DataPemasaran = () => {
  const { isDark } = useTheme();
  const { user, ready } = useAuth();
  const { scopeQuery, isFactoryScoped, factoryId, isDirektur } = useRoleAccess();
  const toast = useToast();
  const [outgoingGoods, setOutgoingGoods] = useState([]);
  const [distributors, setDistributors] = useState([]);
  const [factories, setFactories] = useState([]);
  const [products, setProducts] = useState([]);
  const [regions, setRegions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedMonth, setSelectedMonth] = useState(() => new Date().toISOString().slice(0, 7));
  const [selectedFactory, setSelectedFactory] = useState(isFactoryScoped ? factoryId : 'all');

  // Goods modal
  const [showGoodsModal, setShowGoodsModal] = useState(false);
  const [editingGoods, setEditingGoods] = useState(null);
  const [goodsForm, setGoodsForm] = useState(emptyGoodsForm);
  const [savingGoods, setSavingGoods] = useState(false);
  const [deleteGoodsTarget, setDeleteGoodsTarget] = useState(null);

  // Distributor modal
  const [showDistModal, setShowDistModal] = useState(false);
  const [editingDist, setEditingDist] = useState(null);
  const [distForm, setDistForm] = useState(emptyDistForm);
  const [savingDist, setSavingDist] = useState(false);
  const [deleteDistTarget, setDeleteDistTarget] = useState(null);

  const loadData = async () => {
    setLoading(true);
    const [g, d, f, p, r] = await Promise.all([
      scopeQuery(supabase.from('outgoing_goods').select('*, factories(name), regions(name), cigarettes(product_name, variant, brands(name))').order('transaction_date', { ascending: false }).limit(200)),
      supabase.from('distributors').select('*, regions(name)').order('name'),
      scopeQuery(supabase.from('factories').select('id, name').order('name'), 'id'),
      scopeQuery(supabase.from('cigarettes').select('id, brand_id, product_name, variant, brands(name), factories(name)').order('id')),
      supabase.from('regions').select('id, name').order('name'),
    ]);
    if (g.error) toast.error('Gagal memuat transaksi: ' + g.error.message);
    if (g.data) setOutgoingGoods(g.data);
    if (d.data) setDistributors(d.data);
    if (f.data) setFactories(f.data);
    if (p.data) setProducts(p.data);
    if (r.data) setRegions(r.data);
    setLoading(false);
  };

  useEffect(() => {
    if (ready) loadData();
  }, [ready]); // eslint-disable-line

  // Factory name for direktur context
  const factoryName = isDirektur && factories.length > 0 ? factories[0]?.name : null;

  const filteredGoods = outgoingGoods.filter((g) => {
    const matchFactory = selectedFactory === 'all' || g.factory_id === selectedFactory;
    const matchMonth = g.transaction_date?.startsWith(selectedMonth);
    const q = search.trim().toLowerCase();
    const matchSearch = !q || g.customer_name?.toLowerCase().includes(q) || g.factories?.name?.toLowerCase().includes(q) || g.regions?.name?.toLowerCase().includes(q);
    return matchFactory && matchMonth && matchSearch;
  });

  const totalVolume = filteredGoods.reduce((sum, g) => sum + (g.volume || 0), 0);
  const totalValue = filteredGoods.reduce((sum, g) => sum + Number(g.total_value || 0), 0);

  const formatCurrency = (num) => {
    if (num >= 1000000000) return `Rp ${(num / 1000000000).toFixed(1)} M`;
    if (num >= 1000000) return `Rp ${(num / 1000000).toFixed(1)} Jt`;
    return `Rp ${Number(num).toLocaleString('id-ID')}`;
  };

  const trendData = [
    { month: 'Jan', value: 2400 },
    { month: 'Feb', value: 2800 },
    { month: 'Mar', value: 2600 },
    { month: 'Apr', value: 3100 },
    { month: 'Mei', value: 3000 },
  ];
  const chartColors = { grid: isDark ? '#1f2937' : '#f3f4f6', text: isDark ? '#6b7280' : '#9ca3af' };

  const PIE_COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#14b8a6'];

  // Pie data: volume per region
  const regionPieData = (() => {
    const map = {};
    filteredGoods.forEach((g) => {
      const region = g.regions?.name || 'Lainnya';
      map[region] = (map[region] || 0) + (g.volume || 0);
    });
    return Object.entries(map)
      .map(([name, value]) => ({ name, value }))
      .sort((a, b) => b.value - a.value)
      .slice(0, 6);
  })();

  // ============ Goods CRUD ============
  const openGoodsCreate = () => {
    setEditingGoods(null);
    setGoodsForm({ ...emptyGoodsForm, factory_id: isFactoryScoped ? factoryId : '' });
    setShowGoodsModal(true);
  };
  const openGoodsEdit = (g) => {
    setEditingGoods(g);
    setGoodsForm({
      transaction_date: g.transaction_date || '',
      customer_name: g.customer_name || '',
      region_id: g.region_id || '',
      product_id: g.product_id || '',
      factory_id: g.factory_id || '',
      volume: g.volume || 0,
      total_value: g.total_value || 0,
      payment_method: g.payment_method || 'tunai',
    });
    setShowGoodsModal(true);
  };
  const handleGoodsSubmit = async (e) => {
    e?.preventDefault?.();
    if (!goodsForm.customer_name.trim() || !goodsForm.factory_id || !goodsForm.product_id) {
      toast.warning('Lengkapi field wajib (customer, pabrik, produk)');
      return;
    }
    setSavingGoods(true);
    try {
      const payload = {
        transaction_date: goodsForm.transaction_date,
        customer_name: goodsForm.customer_name.trim(),
        region_id: goodsForm.region_id || null,
        product_id: goodsForm.product_id,
        factory_id: goodsForm.factory_id,
        volume: parseInt(goodsForm.volume) || 0,
        total_value: parseFloat(goodsForm.total_value) || 0,
        payment_method: goodsForm.payment_method,
      };
      if (editingGoods) {
        const { error } = await supabase.from('outgoing_goods').update(payload).eq('id', editingGoods.id);
        if (error) throw error;
        toast.success('Transaksi diperbarui');
      } else {
        payload.created_by = user.id;
        const { error } = await supabase.from('outgoing_goods').insert(payload);
        if (error) throw error;
        toast.success('Transaksi ditambahkan');
      }
      setShowGoodsModal(false);
      setEditingGoods(null);
      await loadData();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setSavingGoods(false);
    }
  };
  const handleGoodsDelete = async () => {
    if (!deleteGoodsTarget) return;
    try {
      const { error } = await supabase.from('outgoing_goods').delete().eq('id', deleteGoodsTarget.id);
      if (error) throw error;
      toast.success('Transaksi dihapus');
      setDeleteGoodsTarget(null);
      await loadData();
    } catch (err) {
      toast.error(err.message);
    }
  };

  // ============ Distributor CRUD ============
  const openDistCreate = () => {
    setEditingDist(null);
    setDistForm(emptyDistForm);
    setShowDistModal(true);
  };
  const openDistEdit = (d) => {
    setEditingDist(d);
    setDistForm({ name: d.name || '', region_id: d.region_id || '', contact_info: d.contact_info || '' });
    setShowDistModal(true);
  };
  const handleDistSubmit = async (e) => {
    e?.preventDefault?.();
    if (!distForm.name.trim()) {
      toast.warning('Nama distributor wajib diisi');
      return;
    }
    setSavingDist(true);
    try {
      const payload = {
        name: distForm.name.trim(),
        region_id: distForm.region_id || null,
        contact_info: distForm.contact_info.trim() || null,
      };
      if (editingDist) {
        const { error } = await supabase.from('distributors').update(payload).eq('id', editingDist.id);
        if (error) throw error;
        toast.success('Distributor diperbarui');
      } else {
        const { error } = await supabase.from('distributors').insert(payload);
        if (error) throw error;
        toast.success('Distributor ditambahkan');
      }
      setShowDistModal(false);
      setEditingDist(null);
      await loadData();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setSavingDist(false);
    }
  };
  const handleDistDelete = async () => {
    if (!deleteDistTarget) return;
    try {
      const { error } = await supabase.from('distributors').delete().eq('id', deleteDistTarget.id);
      if (error) throw error;
      toast.success('Distributor dihapus');
      setDeleteDistTarget(null);
      await loadData();
    } catch (err) {
      toast.error(err.message);
    }
  };

  if (loading && outgoingGoods.length === 0 && distributors.length === 0) {
    return (
      <div className="space-y-5 max-w-[1400px] mx-auto">
        <PageHeader title="Distribusi & Penjualan" description="Pantau distribusi dan penjualan produk ke seluruh wilayah." />
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">{Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)}</div>
        <SkeletonTable rows={5} cols={5} />
      </div>
    );
  }

  return (
    <div className="space-y-5 max-w-[1400px] mx-auto">
      <PageHeader title={isDirektur ? `Pemasaran ${factoryName || ''}` : 'Distribusi & Penjualan'} description={isDirektur ? `Pantau distribusi dan penjualan produk pabrik ${factoryName || 'Anda'}.` : 'Pantau distribusi dan penjualan produk ke seluruh wilayah.'}>
        <MonthPicker value={selectedMonth} onChange={(e) => setSelectedMonth(e.target.value)} />
        {!isFactoryScoped && (
          <select
            value={selectedFactory}
            onChange={(e) => setSelectedFactory(e.target.value)}
            className="text-sm border border-gray-100 dark:border-gray-800 shadow-sm rounded-full px-4 py-2.5 text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-900 focus:outline-none focus:border-blue-400 min-w-[180px] cursor-pointer"
          >
            <option value="all">Semua Pabrik</option>
            {factories.map((f) => (
              <option key={f.id} value={f.id}>{f.name}</option>
            ))}
          </select>
        )}
        <button onClick={openGoodsCreate} className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors shadow-sm">
          <span className="material-symbols-outlined text-[18px]">add</span>
          Transaksi Baru
        </button>
      </PageHeader>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon="storefront" label="Total Penjualan" value={formatCurrency(totalValue)} color="blue" />
        <StatCard icon="inventory_2" label="Volume Terjual" value={totalVolume.toLocaleString()} suffix="btg" color="green" />
        <StatCard icon="storefront" label="Total Distributor" value={distributors.length} color="purple" />
        <StatCard icon="map" label="Cakupan Wilayah" value={regions.length} suffix="wilayah" color="orange" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Tren Penjualan */}
        <div className="lg:col-span-2 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Tren Penjualan</h3>
              <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">5 bulan terakhir</p>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={trendData} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="gradSales" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={chartColors.grid} vertical={false} />
              <XAxis dataKey="month" tick={{ fontSize: 11, fill: chartColors.text }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: chartColors.text }} axisLine={false} tickLine={false} />
              <Tooltip contentStyle={{ backgroundColor: isDark ? '#1f2937' : '#fff', border: `1px solid ${isDark ? '#374151' : '#e5e7eb'}`, borderRadius: '8px', fontSize: '12px' }} />
              <Area type="monotone" dataKey="value" stroke="#3b82f6" strokeWidth={2} fill="url(#gradSales)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Pie: Distribusi per Wilayah */}
        <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5 flex flex-col">
          <div>
            <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Distribusi per Wilayah</h3>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">Volume bulan ini</p>
          </div>
          {regionPieData.length === 0 ? (
            <div className="flex-1 flex items-center justify-center text-sm text-gray-400 dark:text-gray-500">Belum ada data</div>
          ) : (
            <>
              <div className="flex-1 flex items-center justify-center py-3">
                <ResponsiveContainer width="100%" height={160}>
                  <PieChart>
                    <Pie data={regionPieData} cx="50%" cy="50%" innerRadius={45} outerRadius={70} dataKey="value" paddingAngle={2} startAngle={90} endAngle={-270}>
                      {regionPieData.map((_, i) => <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />)}
                    </Pie>
                    <Tooltip contentStyle={{ backgroundColor: isDark ? '#1f2937' : '#fff', border: `1px solid ${isDark ? '#374151' : '#e5e7eb'}`, borderRadius: '8px', fontSize: '12px' }} formatter={(v) => [Number(v).toLocaleString('id-ID') + ' btg', '']} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div className="space-y-1.5 mt-1">
                {regionPieData.map((d, i) => (
                  <div key={d.name} className="flex items-center justify-between text-xs">
                    <span className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor: PIE_COLORS[i % PIE_COLORS.length] }}></span>
                      <span className="text-gray-600 dark:text-gray-400 truncate">{d.name}</span>
                    </span>
                    <span className="font-bold text-gray-900 dark:text-white">{Number(d.value).toLocaleString('id-ID')}</span>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      </div>

      {/* Transactions */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className="p-5 border-b border-gray-100 dark:border-gray-800 flex flex-col md:flex-row md:items-center justify-between gap-3">
          <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Transaksi Barang Keluar</h3>
          <SearchBar value={search} onChange={(e) => setSearch(e.target.value)} placeholder={isFactoryScoped ? "Cari customer, wilayah..." : "Cari customer, pabrik, wilayah..."} className="md:w-96" />
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Tanggal</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Customer</th>
                {!isFactoryScoped && <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Pabrik</th>}
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Volume</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Nilai</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Bayar</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase text-center">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {filteredGoods.length === 0 ? (
                <tr><td colSpan="7" className="px-5 py-12 text-center text-gray-400 dark:text-gray-500 text-sm">{search ? 'Tidak ada hasil pencarian' : 'Belum ada transaksi'}</td></tr>
              ) : (
                filteredGoods.map((item) => (
                  <tr key={item.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                    <td className="px-5 py-3.5 text-sm text-gray-500 dark:text-gray-400">{item.transaction_date}</td>
                    <td className="px-5 py-3.5 text-sm font-semibold text-gray-900 dark:text-white">{item.customer_name}</td>
                    {!isFactoryScoped && <td className="px-5 py-3.5 text-sm text-gray-600 dark:text-gray-400">{item.factories?.name || '-'}</td>}
                    <td className="px-5 py-3.5 text-sm text-gray-700 dark:text-gray-300 font-medium">{Number(item.volume).toLocaleString()}</td>
                    <td className="px-5 py-3.5 text-sm text-gray-700 dark:text-gray-300 font-medium text-right">{formatCurrency(item.total_value)}</td>
                    <td className="px-5 py-3.5">
                      <span className={`text-[11px] font-bold px-2 py-1 rounded ${item.payment_method === 'tunai' ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400' : 'bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400'}`}>{item.payment_method === 'tunai' ? 'Tunai' : 'Kredit'}</span>
                    </td>
                    <td className="px-5 py-3.5 text-center">
                      <div className="flex items-center justify-center gap-1">
                        <button onClick={() => openGoodsEdit(item)} className="p-1.5 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors" title="Edit"><span className="material-symbols-outlined text-[18px]">edit</span></button>
                        <button onClick={() => setDeleteGoodsTarget(item)} className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 dark:hover:text-red-400 transition-colors" title="Hapus"><span className="material-symbols-outlined text-[18px]">delete</span></button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Distributors */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className="p-5 border-b border-gray-100 dark:border-gray-800 flex items-center justify-between">
          <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Daftar Distributor</h3>
          <button onClick={openDistCreate} className="flex items-center gap-2 px-3 py-1.5 bg-blue-600 text-white rounded-lg text-xs font-semibold hover:bg-blue-700 transition-colors">
            <span className="material-symbols-outlined text-[16px]">add</span>Tambah
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">No</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Nama</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Wilayah</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Kontak</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase text-center">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {distributors.length === 0 ? (
                <tr><td colSpan="5" className="px-5 py-8 text-center text-gray-400 dark:text-gray-500 text-sm">Belum ada distributor</td></tr>
              ) : distributors.map((dist, i) => (
                <tr key={dist.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td className="px-5 py-3 text-sm text-gray-400 dark:text-gray-500">{i + 1}</td>
                  <td className="px-5 py-3 text-sm font-semibold text-gray-900 dark:text-white">{dist.name}</td>
                  <td className="px-5 py-3 text-sm text-gray-500 dark:text-gray-400">{dist.regions?.name || '-'}</td>
                  <td className="px-5 py-3 text-sm text-gray-500 dark:text-gray-400">{dist.contact_info || '-'}</td>
                  <td className="px-5 py-3 text-center">
                    <div className="flex items-center justify-center gap-1">
                      <button onClick={() => openDistEdit(dist)} className="p-1.5 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"><span className="material-symbols-outlined text-[18px]">edit</span></button>
                      <button onClick={() => setDeleteDistTarget(dist)} className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 dark:hover:text-red-400 transition-colors"><span className="material-symbols-outlined text-[18px]">delete</span></button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Goods Modal */}
      <Modal
        open={showGoodsModal}
        onClose={() => !savingGoods && setShowGoodsModal(false)}
        title={editingGoods ? 'Edit Transaksi' : 'Tambah Transaksi'}
        size="lg"
        footer={
          <>
            <button onClick={() => setShowGoodsModal(false)} disabled={savingGoods} className="px-4 py-2 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg disabled:opacity-50">Batal</button>
            <button onClick={handleGoodsSubmit} disabled={savingGoods} className="px-5 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition-colors shadow-sm disabled:opacity-60">{savingGoods ? 'Menyimpan...' : 'Simpan'}</button>
          </>
        }
      >
        <form onSubmit={handleGoodsSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Tanggal <span className="text-red-500">*</span></label>
              <input type="date" value={goodsForm.transaction_date} onChange={(e) => setGoodsForm({ ...goodsForm, transaction_date: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Customer <span className="text-red-500">*</span></label>
              <input value={goodsForm.customer_name} onChange={(e) => setGoodsForm({ ...goodsForm, customer_name: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nama customer" required />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Pabrik <span className="text-red-500">*</span></label>
              <select value={goodsForm.factory_id} onChange={(e) => setGoodsForm({ ...goodsForm, factory_id: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required disabled={isFactoryScoped}>
                <option value="">Pilih pabrik...</option>
                {factories.map((f) => <option key={f.id} value={f.id}>{f.name}</option>)}
              </select>
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Produk <span className="text-red-500">*</span></label>
              <select value={goodsForm.product_id} onChange={(e) => setGoodsForm({ ...goodsForm, product_id: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required>
                <option value="">Pilih produk...</option>
                {products.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.product_name || p.brands?.name || '-'} {p.variant ? `(${p.variant})` : ''} — {p.brands?.name || '-'} ({p.factories?.name || '-'})
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Wilayah</label>
              <select value={goodsForm.region_id} onChange={(e) => setGoodsForm({ ...goodsForm, region_id: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400">
                <option value="">— Tidak ditentukan —</option>
                {regions.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}
              </select>
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Pembayaran</label>
              <select value={goodsForm.payment_method} onChange={(e) => setGoodsForm({ ...goodsForm, payment_method: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400">
                <option value="tunai">Tunai</option>
                <option value="kredit">Kredit</option>
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Volume (btg)</label>
              <input type="number" min="0" value={goodsForm.volume} onChange={(e) => setGoodsForm({ ...goodsForm, volume: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Total Nilai (Rp)</label>
              <input type="number" min="0" step="0.01" value={goodsForm.total_value} onChange={(e) => setGoodsForm({ ...goodsForm, total_value: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" />
            </div>
          </div>
        </form>
      </Modal>

      {/* Distributor Modal */}
      <Modal
        open={showDistModal}
        onClose={() => !savingDist && setShowDistModal(false)}
        title={editingDist ? 'Edit Distributor' : 'Tambah Distributor'}
        footer={
          <>
            <button onClick={() => setShowDistModal(false)} disabled={savingDist} className="px-4 py-2 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg disabled:opacity-50">Batal</button>
            <button onClick={handleDistSubmit} disabled={savingDist} className="px-5 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition-colors shadow-sm disabled:opacity-60">{savingDist ? 'Menyimpan...' : 'Simpan'}</button>
          </>
        }
      >
        <form onSubmit={handleDistSubmit} className="space-y-4">
          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Distributor <span className="text-red-500">*</span></label>
            <input value={distForm.name} onChange={(e) => setDistForm({ ...distForm, name: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required />
          </div>
          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Wilayah</label>
            <select value={distForm.region_id} onChange={(e) => setDistForm({ ...distForm, region_id: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400">
              <option value="">— Pilih —</option>
              {regions.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}
            </select>
          </div>
          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Kontak</label>
            <input value={distForm.contact_info} onChange={(e) => setDistForm({ ...distForm, contact_info: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nomor HP / Email / Alamat" />
          </div>
        </form>
      </Modal>

      <ConfirmDialog open={!!deleteGoodsTarget} onClose={() => setDeleteGoodsTarget(null)} onConfirm={handleGoodsDelete} title="Hapus Transaksi?" message={`Hapus transaksi ${deleteGoodsTarget?.customer_name}? Tidak dapat dikembalikan.`} confirmText="Ya, Hapus" cancelText="Batal" variant="danger" icon="delete" />
      <ConfirmDialog open={!!deleteDistTarget} onClose={() => setDeleteDistTarget(null)} onConfirm={handleDistDelete} title="Hapus Distributor?" message={`Hapus distributor ${deleteDistTarget?.name}? Tidak dapat dikembalikan.`} confirmText="Ya, Hapus" cancelText="Batal" variant="danger" icon="delete" />
    </div>
  );
};

export default DataPemasaran;
