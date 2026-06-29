import React, { useState, useEffect, useMemo } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';
import { useToast } from '../hooks/useToast';
import { useTheme } from '../context/ThemeContext';
import StatCard from '../components/shared/StatCard';
import PageHeader from '../components/shared/PageHeader';
import { SkeletonCard, SkeletonChart } from '../components/shared/Skeleton';
import Modal from '../components/shared/Modal';
import ConfirmDialog from '../components/shared/ConfirmDialog';
import SearchBar from '../components/shared/SearchBar';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, AreaChart, Area, Legend
} from 'recharts';
import { useRoleAccess } from '../hooks/useRoleAccess';

const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#14b8a6'];
const emptyForm = { factory_id: '', cukai_category_id: '', product_id: '', quota: 0, used: 0, damaged: 0, period: '' };
const currentPeriod = () => { const d = new Date(); return `Q${Math.floor(d.getMonth() / 3) + 1}-${d.getFullYear()}`; };

const PantauCukai = () => {
  const { isDark } = useTheme();
  const { ready } = useAuth();
  const { scopeQuery, isFactoryScoped, factoryId, isDirektur } = useRoleAccess();
  const toast = useToast();
  const [allocations, setAllocations] = useState([]);
  const [usageLogs, setUsageLogs] = useState([]);
  const [factories, setFactories] = useState([]);
  const [batches, setBatches] = useState([]);
  const [cigarettes, setCigarettes] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedFactory, setSelectedFactory] = useState(isFactoryScoped ? factoryId : 'all');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ ...emptyForm, period: currentPeriod() });
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);

  const loadData = async () => {
    setLoading(true);
    const [a, f, u, b, c, cat] = await Promise.all([
      scopeQuery(supabase.from('cukai_allocations').select('*, factories(name, nppbkc), cukai_categories(*), cigarettes(product_name, brands(name))').order('created_at', { ascending: false })),
      scopeQuery(supabase.from('factories').select('id, name, nppbkc').order('name'), 'id'),
      scopeQuery(supabase.from('cukai_usage_log').select('*, factories(name, nppbkc), cigarettes(product_name, brands(name)), profiles:created_by(full_name)').order('usage_date', { ascending: false }).limit(500)),
      scopeQuery(supabase.from('cukai_requests').select('*, factories(name, nppbkc), cukai_categories(*), cigarettes(product_name, brands(name))').eq('status', 'approved').gt('quantity_remaining', 0).order('request_date', { ascending: false })),
      scopeQuery(supabase.from('cigarettes').select('id, product_name, factory_id, brands(name)').order('product_name')),
      supabase.from('cukai_categories').select('*').order('name'),
    ]);
    if (a.error) toast.error('Gagal memuat: ' + a.error.message);
    if (a.data) setAllocations(a.data);
    if (f.data) setFactories(f.data);
    if (u.data) setUsageLogs(u.data);
    if (b.data) setBatches(b.data);
    if (c.data) setCigarettes(c.data);
    if (cat.data) setCategories(cat.data);
    setLoading(false);
  };

  useEffect(() => { if (ready) loadData(); }, [ready]); // eslint-disable-line

  // Factory name for direktur context
  const factoryName = isDirektur && factories.length > 0 ? factories[0]?.name : null;

  const factoryAllocations = useMemo(() => {
    if (selectedFactory === 'all') return allocations;
    return allocations.filter(a => a.factory_id === selectedFactory);
  }, [allocations, selectedFactory]);

  const factoryBatches = useMemo(() => {
    if (selectedFactory === 'all') return batches;
    return batches.filter(b => b.factory_id === selectedFactory);
  }, [batches, selectedFactory]);

  const factoryCigarettes = useMemo(() => {
    if (!form.factory_id) return [];
    return cigarettes.filter(c => c.factory_id === form.factory_id);
  }, [cigarettes, form.factory_id]);

  const totalQuota = factoryAllocations.reduce((s, a) => s + (a.quota || 0), 0);
  const totalUsed = factoryAllocations.reduce((s, a) => s + (a.used || 0), 0);
  const totalDamaged = factoryAllocations.reduce((s, a) => s + (a.damaged || 0), 0);
  const totalRemaining = totalQuota - totalUsed;

  const filteredAllocations = factoryAllocations.filter((a) => {
    const q = search.trim().toLowerCase();
    if (!q) return true;
    return a.factories?.name?.toLowerCase().includes(q) || a.factories?.nppbkc?.toLowerCase().includes(q);
  });

  const getPercentage = (alloc) => {
    if (!alloc.quota) return 0;
    return Math.round(((alloc.quota - (alloc.used || 0)) / alloc.quota) * 100);
  };
  const getBarColor = (percent) => percent <= 10 ? '#ef4444' : percent <= 25 ? '#f97316' : '#3b82f6';
  const formatNumber = (num) => {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(0) + 'K';
    return num.toString();
  };

  // Chart: stacked bar per factory
  const chartData = factoryAllocations.map((a) => ({
    nppbkc: a.factories?.nppbkc || '-',
    name: a.factories?.name || 'Pabrik',
    used: a.used || 0,
    remaining: (a.quota || 0) - (a.used || 0),
    damaged: a.damaged || 0,
  }));

  // Pie: overall distribution
  const pieData = [
    { name: 'Terpakai', value: totalUsed, color: '#3b82f6' },
    { name: 'Rusak', value: totalDamaged, color: '#ef4444' },
    { name: 'Sisa', value: totalRemaining > 0 ? totalRemaining : 0, color: isDark ? '#374151' : '#e5e7eb' },
  ].filter((d) => d.value > 0);

  // Usage trend (last 30 days)
  const usageTrend = useMemo(() => {
    const days = {};
    const now = new Date();
    for (let i = 29; i >= 0; i--) {
      const d = new Date(now); d.setDate(d.getDate() - i);
      const key = d.toISOString().slice(0, 10);
      days[key] = { date: key, label: d.getDate().toString(), used: 0 };
    }
    const logs = selectedFactory === 'all' ? usageLogs : usageLogs.filter((l) => l.factory_id === selectedFactory);
    logs.forEach((l) => { if (days[l.usage_date]) days[l.usage_date].used += l.used_amount || 0; });
    return Object.values(days);
  }, [usageLogs, selectedFactory]);

  const chartColors = { grid: isDark ? '#1f2937' : '#f3f4f6', text: isDark ? '#6b7280' : '#9ca3af' };

  // CRUD
  const openCreate = () => { setEditing(null); setForm({ ...emptyForm, period: currentPeriod() }); setShowModal(true); };
  const openEdit = (a) => { setEditing(a); setForm({ factory_id: a.factory_id || '', cukai_category_id: a.cukai_category_id || '', product_id: a.product_id || '', quota: a.quota || 0, used: a.used || 0, damaged: a.damaged || 0, period: a.period || currentPeriod() }); setShowModal(true); };
  const handleSubmit = async (e) => {
    e?.preventDefault?.();
    if (!form.factory_id || !form.period.trim()) { toast.warning('Pabrik dan periode wajib diisi'); return; }
    setSaving(true);
    try {
      const payload = { 
        factory_id: form.factory_id, 
        cukai_category_id: form.cukai_category_id || null,
        product_id: form.product_id || null,
        quota: parseInt(form.quota) || 0, 
        used: parseInt(form.used) || 0, 
        damaged: parseInt(form.damaged) || 0, 
        period: form.period.trim() 
      };
      if (editing) { const { error } = await supabase.from('cukai_allocations').update(payload).eq('id', editing.id); if (error) throw error; toast.success('Alokasi diperbarui'); }
      else { const { error } = await supabase.from('cukai_allocations').insert(payload); if (error) throw error; toast.success('Alokasi ditambahkan'); }
      setShowModal(false); setEditing(null); await loadData();
    } catch (err) { toast.error(err.message); } finally { setSaving(false); }
  };
  const handleDelete = async () => {
    if (!deleteTarget) return;
    try { const { error } = await supabase.from('cukai_allocations').delete().eq('id', deleteTarget.id); if (error) throw error; toast.success('Alokasi dihapus'); setDeleteTarget(null); await loadData(); }
    catch (err) { toast.error(err.message); }
  };

  if (loading && allocations.length === 0) {
    return (
      <div className="space-y-5 max-w-[1400px] mx-auto">
        <PageHeader title="Monitoring & Distribusi Pita Cukai" description="Pantau distribusi dan sisa pita cukai seluruh pabrik." />
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">{Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)}</div>
        <SkeletonChart />
      </div>
    );
  }

  return (
    <div className="space-y-5 max-w-[1400px] mx-auto">
      <PageHeader title={isDirektur ? `Stok & Kuota Cukai ${factoryName || ''}` : 'Stok & Kuota Cukai'} description={isDirektur ? `Pantau stok batch dan kuota alokasi pita cukai pabrik ${factoryName || 'Anda'}.` : 'Pantau stok batch dan kuota alokasi pita cukai seluruh pabrik.'}>
        {!isFactoryScoped && (
          <>
            <select value={selectedFactory} onChange={(e) => setSelectedFactory(e.target.value)} className="text-sm border border-gray-200 dark:border-gray-700 rounded-lg px-3 py-2 text-gray-600 dark:text-gray-300 bg-white dark:bg-gray-800 focus:outline-none focus:border-blue-400 min-w-[160px]">
              <option value="all">Semua Pabrik</option>
              {factories.map((f) => <option key={f.id} value={f.id}>{f.name}</option>)}
            </select>
            <button onClick={openCreate} className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors shadow-sm">
              <span className="material-symbols-outlined text-[18px]">add</span>Alokasi Baru
            </button>
          </>
        )}
      </PageHeader>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon="confirmation_number" label="Total Kuota" value={formatNumber(totalQuota)} suffix="lembar" color="blue" />
        <StatCard icon="check_circle" label="Terpakai" value={formatNumber(totalUsed)} suffix={`${totalQuota > 0 ? Math.round((totalUsed / totalQuota) * 100) : 0}%`} color="green" trend={`${totalQuota > 0 ? Math.round((totalUsed / totalQuota) * 100) : 0}%`} trendUp />
        <StatCard icon="broken_image" label="Rusak" value={formatNumber(totalDamaged)} color="red" />
        <StatCard icon="hourglass_empty" label="Sisa Tersedia" value={formatNumber(totalRemaining)} suffix="lbr" color="purple" />
      </div>

      {/* Charts Row: Stacked Bar + Pie */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        <div className="lg:col-span-2 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Distribusi Cukai per Pabrik</h3>
              <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">Kuota vs pemakaian vs rusak</p>
            </div>
            <div className="flex items-center gap-3 text-[10px]">
              <span className="flex items-center gap-1"><span className="w-2.5 h-2.5 rounded bg-blue-500"></span>Terpakai</span>
              <span className="flex items-center gap-1"><span className="w-2.5 h-2.5 rounded bg-red-400"></span>Rusak</span>
              <span className="flex items-center gap-1"><span className="w-2.5 h-2.5 rounded bg-gray-300 dark:bg-gray-600"></span>Sisa</span>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={chartData} margin={{ top: 5, right: 5, left: -10, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke={chartColors.grid} vertical={false} />
              <XAxis dataKey="nppbkc" tick={{ fontSize: 10, fill: chartColors.text }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 10, fill: chartColors.text }} axisLine={false} tickLine={false} tickFormatter={formatNumber} />
              <Tooltip contentStyle={{ backgroundColor: isDark ? '#1f2937' : '#fff', border: `1px solid ${isDark ? '#374151' : '#e5e7eb'}`, borderRadius: '8px', fontSize: '12px' }} labelFormatter={(label, payload) => payload?.[0]?.payload?.name || label} formatter={(v, name) => [formatNumber(v), name === 'used' ? 'Terpakai' : name === 'damaged' ? 'Rusak' : 'Sisa']} />
              <Bar dataKey="used" stackId="a" fill="#3b82f6" maxBarSize={28} name="used" />
              <Bar dataKey="damaged" stackId="a" fill="#ef4444" maxBarSize={28} name="damaged" />
              <Bar dataKey="remaining" stackId="a" fill={isDark ? '#374151' : '#e5e7eb'} radius={[4, 4, 0, 0]} maxBarSize={28} name="remaining" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Pie */}
        <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5 flex flex-col">
          <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Komposisi Cukai</h3>
          <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{selectedFactory === 'all' ? 'Total seluruh pabrik' : factories.find(f => f.id === selectedFactory)?.name}</p>
          <div className="flex-1 flex items-center justify-center py-4">
            <div className="relative">
              <ResponsiveContainer width={180} height={180}>
                <PieChart>
                  <Pie data={pieData} cx="50%" cy="50%" innerRadius={55} outerRadius={80} dataKey="value" startAngle={90} endAngle={-270} paddingAngle={2}>
                    {pieData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                  </Pie>
                  <Tooltip contentStyle={{ backgroundColor: isDark ? '#1f2937' : '#fff', border: `1px solid ${isDark ? '#374151' : '#e5e7eb'}`, borderRadius: '8px', fontSize: '12px' }} formatter={(v) => [formatNumber(v) + ' lbr', '']} />
                </PieChart>
              </ResponsiveContainer>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-2xl font-bold text-gray-900 dark:text-white">{totalQuota > 0 ? Math.round((totalUsed / totalQuota) * 100) : 0}%</span>
                <span className="text-[10px] text-gray-400 dark:text-gray-500">Terpakai</span>
              </div>
            </div>
          </div>
          <div className="space-y-2">
            {pieData.map((d) => (
              <div key={d.name} className="flex items-center justify-between text-xs">
                <span className="flex items-center gap-2"><span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: d.color }}></span><span className="text-gray-600 dark:text-gray-400">{d.name}</span></span>
                <span className="font-bold text-gray-900 dark:text-white">{formatNumber(d.value)}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Row: Usage Trend (2/3) + Critical Panel (1/3) */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Usage Trend */}
        <div className="lg:col-span-2 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Tren Pemakaian Cukai Harian</h3>
              <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">30 hari terakhir {selectedFactory !== 'all' ? `— ${factories.find((f) => f.id === selectedFactory)?.name}` : ''}</p>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={240}>
            <AreaChart data={usageTrend} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="gradUsage" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.2} />
                  <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={chartColors.grid} vertical={false} />
              <XAxis dataKey="label" tick={{ fontSize: 10, fill: chartColors.text }} axisLine={false} tickLine={false} interval={2} />
              <YAxis tick={{ fontSize: 10, fill: chartColors.text }} axisLine={false} tickLine={false} tickFormatter={formatNumber} />
              <Tooltip contentStyle={{ backgroundColor: isDark ? '#1f2937' : '#fff', border: `1px solid ${isDark ? '#374151' : '#e5e7eb'}`, borderRadius: '8px', fontSize: '12px' }} labelFormatter={(l, p) => p?.[0]?.payload?.date || l} formatter={(v) => [formatNumber(v) + ' lbr', 'Pemakaian']} />
              <Area type="monotone" dataKey="used" stroke="#8b5cf6" strokeWidth={2} fill="url(#gradUsage)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Critical Panel — scrollable */}
        <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5 flex flex-col max-h-[360px]">
          <h3 className="text-[15px] font-bold text-gray-900 dark:text-white mb-2 flex items-center gap-2">
            <span className="material-symbols-outlined text-red-500 text-[18px]">warning</span>
            Pabrik Kritis
          </h3>
          <p className="text-xs text-gray-400 dark:text-gray-500 mb-4">Sisa pita cukai &lt; 10%</p>
          <div className="flex-1 overflow-y-auto space-y-3 custom-scrollbar">
            {factoryAllocations.filter((a) => getPercentage(a) <= 10).length === 0 ? (
              <div className="text-center py-8">
                <span className="material-symbols-outlined text-emerald-400 dark:text-emerald-500 text-[32px]">verified</span>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">Semua pabrik aman</p>
              </div>
            ) : (
              factoryAllocations.filter((a) => getPercentage(a) <= 10).map((alloc) => (
                <div key={alloc.id} className="p-3.5 rounded-lg bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/30">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-semibold text-gray-800 dark:text-gray-200">{alloc.factories?.name}</span>
                    <span className="text-xs font-bold text-red-600 dark:text-red-400">{getPercentage(alloc)}%</span>
                  </div>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-1">Sisa: {formatNumber(alloc.quota - alloc.used)} dari {formatNumber(alloc.quota)}</p>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Detail Alokasi per Pabrik — full width table */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className="p-5 border-b border-gray-100 dark:border-gray-800 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Detail Alokasi per Pabrik</h3>
          <SearchBar value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Cari pabrik..." className="md:w-96" />
        </div>
        <div className="overflow-x-auto max-h-[400px] overflow-y-auto custom-scrollbar">
          <table className="w-full text-left">
            <thead className="sticky top-0 z-10">
              <tr className="bg-gray-50 dark:bg-gray-800/80 border-b border-gray-100 dark:border-gray-800">
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Pabrik</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Kategori Cukai / Jenis HT</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Periode</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Kuota</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Terpakai</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Rusak</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Sisa</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-center">Status</th>
                {!isFactoryScoped && <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-center">Aksi</th>}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {filteredAllocations.length === 0 ? (
                <tr><td colSpan="9" className="px-5 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">{search ? 'Tidak ditemukan' : 'Belum ada alokasi'}</td></tr>
              ) : filteredAllocations.map((alloc) => {
                const percent = getPercentage(alloc);
                const remaining = (alloc.quota || 0) - (alloc.used || 0);
                return (
                  <tr key={alloc.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                    <td className="px-5 py-3 text-sm font-semibold text-gray-900 dark:text-white">{alloc.factories?.name || '-'}</td>
                    <td className="px-5 py-3 text-xs text-gray-700 dark:text-gray-300 font-medium">
                      {alloc.cukai_categories ? (
                        <div className="flex items-center gap-1.5">
                          <span className="font-semibold text-gray-900 dark:text-white">{alloc.cukai_categories.name}</span>
                          <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 uppercase">
                            {alloc.cukai_categories.jenis_ht}
                          </span>
                        </div>
                      ) : alloc.cigarettes ? (
                        `${alloc.cigarettes.product_name} (${alloc.cigarettes.brands?.name || ''})`
                      ) : (
                        <span className="text-gray-400 italic">Semua Merek</span>
                      )}
                    </td>
                    <td className="px-5 py-3 text-xs text-gray-500 dark:text-gray-400">{alloc.period}</td>
                    <td className="px-5 py-3 text-xs text-gray-700 dark:text-gray-300 font-medium text-right">{(alloc.quota || 0).toLocaleString()}</td>
                    <td className="px-5 py-3 text-xs text-gray-700 dark:text-gray-300 font-medium text-right">{(alloc.used || 0).toLocaleString()}</td>
                    <td className="px-5 py-3 text-xs text-gray-700 dark:text-gray-300 font-medium text-right">{(alloc.damaged || 0).toLocaleString()}</td>
                    <td className="px-5 py-3 text-xs text-gray-700 dark:text-gray-300 font-medium text-right">{remaining.toLocaleString()}</td>
                    <td className="px-5 py-3 text-center">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${percent <= 10 ? 'bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400' : percent <= 25 ? 'bg-orange-50 dark:bg-orange-900/20 text-orange-600 dark:text-orange-400' : 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400'}`}>
                        {percent <= 10 ? 'KRITIS' : percent <= 25 ? 'WARNING' : 'AMAN'}
                      </span>
                    </td>
                    {!isFactoryScoped && (
                      <td className="px-5 py-3 text-center">
                        <div className="flex items-center justify-center gap-1">
                          <button onClick={() => openEdit(alloc)} className="p-1.5 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"><span className="material-symbols-outlined text-[16px]">edit</span></button>
                          <button onClick={() => setDeleteTarget(alloc)} className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 transition-colors"><span className="material-symbols-outlined text-[16px]">delete</span></button>
                        </div>
                      </td>
                    )}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Detail Stok Pita Cukai per Batch */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className="p-5 border-b border-gray-100 dark:border-gray-800 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <div>
            <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Stok Pita Cukai Aktif per Batch</h3>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">Rincian sisa lembar pita cukai per seri dan produk</p>
          </div>
        </div>
        <div className="overflow-x-auto max-h-[400px] overflow-y-auto custom-scrollbar">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50 dark:bg-gray-800/80 border-b border-gray-100 dark:border-gray-800">
                {!isFactoryScoped && <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Pabrik</th>}
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">No. Seri/Batch</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Kategori Cukai & Produk Awal</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Warna / Seri</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Jumlah Awal</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Sisa Lembar</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-center">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {factoryBatches.length === 0 ? (
                <tr><td colSpan={isFactoryScoped ? 6 : 7} className="px-5 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">Tidak ada batch pita cukai aktif</td></tr>
              ) : factoryBatches.map((b) => {
                const sisa = b.quantity_remaining || 0;
                const awal = b.jumlah_lembar || 0;
                const percent = awal > 0 ? Math.round((sisa / awal) * 100) : 0;
                return (
                  <tr key={b.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                    {!isFactoryScoped && <td className="px-5 py-3 text-sm font-semibold text-gray-900 dark:text-white">{b.factories?.name || '-'}</td>}
                    <td className="px-5 py-3 text-xs font-mono text-gray-600 dark:text-gray-400">{b.seri || '-'}</td>
                    <td className="px-5 py-3 text-xs text-gray-800 dark:text-gray-200">
                      {b.cukai_categories && (
                        <div className="flex items-center gap-1.5">
                          <span className="font-semibold text-gray-900 dark:text-white">{b.cukai_categories.name}</span>
                          <span className="text-[9px] font-bold px-1.5 py-0.5 rounded bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 uppercase">
                            {b.cukai_categories.jenis_ht}
                          </span>
                        </div>
                      )}
                      <div className="text-[10px] text-gray-400 dark:text-gray-500 mt-0.5 font-medium">
                        Produk Awal: {b.cigarettes ? `${b.cigarettes.product_name} (${b.cigarettes.brands?.name || ''})` : '-'}
                      </div>
                    </td>
                    <td className="px-5 py-3 text-xs text-gray-500 dark:text-gray-400">{b.warna || '-'}</td>
                    <td className="px-5 py-3 text-xs text-gray-700 dark:text-gray-300 font-medium text-right">{awal.toLocaleString()}</td>
                    <td className="px-5 py-3 text-xs font-semibold text-right text-emerald-600 dark:text-emerald-400">{sisa.toLocaleString()}</td>
                    <td className="px-5 py-3 text-center">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${percent <= 10 ? 'bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400' : percent <= 25 ? 'bg-orange-50 dark:bg-orange-900/20 text-orange-600 dark:text-orange-400' : 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400'}`}>
                        {percent <= 10 ? 'KRITIS' : percent <= 25 ? 'LIMIT' : 'AMAN'}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Riwayat Pemakaian Pita Cukai (Audit Trail) */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className="p-5 border-b border-gray-100 dark:border-gray-800">
          <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Audit Trail Pemakaian Pita Cukai</h3>
          <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">Histori lengkap pelacakan pemakaian dan kerusakan pita cukai fisik per produk</p>
        </div>
        <div className="overflow-x-auto max-h-[400px] overflow-y-auto custom-scrollbar">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50 dark:bg-gray-800/80 border-b border-gray-100 dark:border-gray-800">
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Tanggal</th>
                {!isFactoryScoped && <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Pabrik</th>}
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Produk / Merek</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Dipakai</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Rusak</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Operator</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Keterangan</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {usageLogs.length === 0 ? (
                <tr><td colSpan={isFactoryScoped ? 6 : 7} className="px-5 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">Belum ada riwayat pemakaian pita cukai</td></tr>
              ) : usageLogs.filter(l => selectedFactory === 'all' || l.factory_id === selectedFactory).map((log) => (
                <tr key={log.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td className="px-5 py-3 text-xs text-gray-600 dark:text-gray-400 font-mono">
                    {new Date(log.usage_date).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </td>
                  {!isFactoryScoped && (
                    <td className="px-5 py-3 text-xs font-semibold text-gray-900 dark:text-white">
                      {log.factories?.name || '-'}
                    </td>
                  )}
                  <td className="px-5 py-3 text-xs text-gray-800 dark:text-gray-200">
                    <div className="font-semibold text-gray-950 dark:text-white">
                      {log.cigarettes?.product_name || '-'}
                    </div>
                    {log.cigarettes?.brands && (
                      <div className="text-[10px] text-gray-400 dark:text-gray-500 mt-0.5">
                        Merek: {log.cigarettes.brands.name}
                      </div>
                    )}
                  </td>
                  <td className="px-5 py-3 text-xs font-semibold text-right text-blue-600 dark:text-blue-400">
                    {(log.used_amount || 0).toLocaleString()} lbr
                  </td>
                  <td className="px-5 py-3 text-xs font-semibold text-right text-red-500">
                    {(log.damaged_amount || 0).toLocaleString()} lbr
                  </td>
                  <td className="px-5 py-3 text-xs text-gray-700 dark:text-gray-300">
                    {log.profiles?.full_name || '-'}
                  </td>
                  <td className="px-5 py-3 text-xs text-gray-500 dark:text-gray-400 italic">
                    {log.notes || '-'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal */}
      <Modal open={showModal} onClose={() => !saving && setShowModal(false)} title={editing ? 'Edit Alokasi Cukai' : 'Tambah Alokasi Baru'}
        footer={<><button onClick={() => setShowModal(false)} disabled={saving} className="px-4 py-2 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg disabled:opacity-50">Batal</button><button onClick={handleSubmit} disabled={saving} className="px-5 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition-colors shadow-sm disabled:opacity-60">{saving ? 'Menyimpan...' : 'Simpan'}</button></>}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div><label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Pabrik <span className="text-red-500">*</span></label><select value={form.factory_id} onChange={(e) => setForm({ ...form, factory_id: e.target.value, product_id: '' })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required><option value="">Pilih pabrik...</option>{factories.map((f) => <option key={f.id} value={f.id}>{f.name}</option>)}</select></div>
            <div><label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Periode <span className="text-red-500">*</span></label><input value={form.period} onChange={(e) => setForm({ ...form, period: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Q2-2026" required /></div>
          </div>
          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Kategori Cukai <span className="text-red-500">*</span></label>
            <select 
              value={form.cukai_category_id} 
              onChange={(e) => setForm({ ...form, cukai_category_id: e.target.value })} 
              className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400"
              required
            >
              <option value="">Pilih Kategori Cukai...</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>{c.name} ({c.jenis_ht})</option>
              ))}
            </select>
          </div>
          <div className="grid grid-cols-3 gap-4">
            <div><label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Kuota</label><input type="number" min="0" value={form.quota} onChange={(e) => setForm({ ...form, quota: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" /></div>
            <div><label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Terpakai</label><input type="number" min="0" value={form.used} onChange={(e) => setForm({ ...form, used: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" /></div>
            <div><label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Rusak</label><input type="number" min="0" value={form.damaged} onChange={(e) => setForm({ ...form, damaged: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" /></div>
          </div>
        </form>
      </Modal>

      <ConfirmDialog open={!!deleteTarget} onClose={() => setDeleteTarget(null)} onConfirm={handleDelete} title="Hapus Alokasi?" message={`Hapus alokasi cukai untuk ${deleteTarget?.factories?.name} periode ${deleteTarget?.period}?`} confirmText="Ya, Hapus" cancelText="Batal" variant="danger" icon="delete" />
    </div>
  );
};

export default PantauCukai;
