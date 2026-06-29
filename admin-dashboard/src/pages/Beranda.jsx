import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';
import { SkeletonCard, SkeletonChart } from '../components/shared/Skeleton';
import StatCard from '../components/shared/StatCard';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  AreaChart, Area, PieChart, Pie, Cell
} from 'recharts';
import { useTheme } from '../context/ThemeContext';
import { useRoleAccess } from '../hooks/useRoleAccess';
import SearchBar from '../components/shared/SearchBar';

// Custom tooltip for "Produksi per Pabrik": shows name + batang + kemasan
const ProdTooltip = ({ active, payload, isDark }) => {
  if (!active || !payload || !payload.length) return null;
  const d = payload[0].payload;
  return (
    <div
      className="rounded-lg shadow-lg border text-xs px-3 py-2 min-w-[180px]"
      style={{
        backgroundColor: isDark ? '#1f2937' : '#fff',
        borderColor: isDark ? '#374151' : '#e5e7eb',
        color: isDark ? '#f3f4f6' : '#111827',
      }}
    >
      <div className="font-bold text-[12px] mb-1.5">{d.name}</div>
      <div className="text-[10px] opacity-60 mb-1.5">NPPBKC: {d.nppbkc}</div>
      <div className="flex items-center justify-between gap-3 mb-1">
        <span className="flex items-center gap-1.5">
          <span className="w-2 h-2 rounded-full bg-blue-500"></span>
          <span className="opacity-80">Batang</span>
        </span>
        <span className="font-semibold">{Number(d.batang || 0).toLocaleString('id-ID')} btg</span>
      </div>
      <div className="flex items-center justify-between gap-3">
        <span className="flex items-center gap-1.5">
          <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
          <span className="opacity-80">Kemasan</span>
        </span>
        <span className="font-semibold">{Number(d.kemasan || 0).toLocaleString('id-ID')} kemasan</span>
      </div>
    </div>
  );
};

// Typing animation component
const TypingText = ({ texts, speed = 50, pause = 2500 }) => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [displayed, setDisplayed] = useState('');
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    const text = texts[currentIndex];
    let timeout;

    if (!isDeleting && displayed.length < text.length) {
      timeout = setTimeout(() => setDisplayed(text.slice(0, displayed.length + 1)), speed);
    } else if (!isDeleting && displayed.length === text.length) {
      timeout = setTimeout(() => setIsDeleting(true), pause);
    } else if (isDeleting && displayed.length > 0) {
      timeout = setTimeout(() => setDisplayed(text.slice(0, displayed.length - 1)), speed / 2);
    } else if (isDeleting && displayed.length === 0) {
      setIsDeleting(false);
      setCurrentIndex((prev) => (prev + 1) % texts.length);
    }

    return () => clearTimeout(timeout);
  }, [displayed, isDeleting, currentIndex, texts, speed, pause]);

  return (
    <span>
      {displayed}
      <span className="animate-pulse">|</span>
    </span>
  );
};
const AutoSlider = ({ items }) => {
  const [current, setCurrent] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrent((prev) => (prev + 1) % items.length);
    }, 3500);
    return () => clearInterval(interval);
  }, [items.length]);

  return (
    <div className="flex items-center gap-4 overflow-hidden">
      <div className="flex-1 flex items-center gap-3 transition-all duration-500">
        <div className="w-9 h-9 rounded-lg bg-white/10 flex items-center justify-center flex-shrink-0">
          <span className="material-symbols-outlined text-[18px] text-white/90" style={{ fontVariationSettings: "'FILL' 1" }}>
            {items[current]?.icon}
          </span>
        </div>
        <div className="min-w-0">
          <p className="text-[11px] text-blue-200/60 font-medium">{items[current]?.label}</p>
          <p className="text-sm font-bold text-white truncate">{items[current]?.value}</p>
        </div>
      </div>
      {/* Dots */}
      <div className="flex items-center gap-1.5">
        {items.map((_, i) => (
          <button
            key={i}
            onClick={() => setCurrent(i)}
            className={`w-1.5 h-1.5 rounded-full transition-all ${i === current ? 'bg-white w-4' : 'bg-white/30'}`}
          />
        ))}
      </div>
    </div>
  );
};

const Beranda = () => {
  const { profile, ready } = useAuth();
  const { isDark } = useTheme();
  const { scopeQuery, isFactoryScoped, isDirektur } = useRoleAccess();
  const [loading, setLoading] = useState(true);
  const [factories, setFactories] = useState([]);
  const [allocations, setAllocations] = useState([]);
  const [productions, setProductions] = useState([]);
  const [outgoingGoods, setOutgoingGoods] = useState([]);
  const [cukaiRequests, setCukaiRequests] = useState([]);

  // Current month (auto, no filter)
  const currentMonth = useMemo(() => new Date().toISOString().slice(0, 7), []);
  const todayDate = useMemo(() => new Date().toISOString().slice(0, 10), []);

  // Today label: "Senin, 17 Mei 2026"
  const todayLabel = useMemo(() => {
    return new Date().toLocaleDateString('id-ID', {
      weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
    });
  }, []);

  useEffect(() => {
    if (!ready) return;
    const fetchAll = async () => {
      setLoading(true);
      const [factRes, allocRes, prodRes, goodsRes, cukaiRes] = await Promise.all([
        scopeQuery(supabase.from('factories').select('id, name, nppbkc, status'), 'id'),
        scopeQuery(supabase.from('cukai_allocations').select('*, factories(name, nppbkc)')),
        scopeQuery(supabase.from('productions').select('*, factories(name, nppbkc)').order('doc_date', { ascending: false })),
        scopeQuery(supabase.from('outgoing_goods').select('*, factories(name)').order('transaction_date', { ascending: false }).limit(500)),
        scopeQuery(supabase.from('cukai_requests').select('*, factories(name, nppbkc), cigarettes(product_name, brands(name))').order('created_at', { ascending: false }).limit(50)),
      ]);
      if (factRes.data) setFactories(factRes.data);
      if (allocRes.data) setAllocations(allocRes.data);
      if (prodRes.data) setProductions(prodRes.data);
      if (goodsRes.data) setOutgoingGoods(goodsRes.data);
      if (cukaiRes.data) setCukaiRequests(cukaiRes.data);
      setLoading(false);
    };
    fetchAll();
  }, [ready]);

  // Current month data (auto, no filter)
  const monthProductions = useMemo(() => {
    return productions.filter((p) => p.doc_date?.startsWith(currentMonth));
  }, [productions, currentMonth]);

  const monthGoods = useMemo(() => {
    return outgoingGoods.filter((g) => g.status === 'approved' && g.transaction_date?.startsWith(currentMonth));
  }, [outgoingGoods, currentMonth]);

  // Today's Cukai requests
  const todayCukaiRequests = useMemo(() => {
    return cukaiRequests.filter((r) => r.created_at?.slice(0, 10) === todayDate);
  }, [cukaiRequests, todayDate]);

  // Factory name for direktur context
  const factoryName = isDirektur && factories.length > 0 ? factories[0]?.name : null;

  // Stats
  const activeFactories = factories.filter((f) => f.status === 'active').length;
  const totalQuota = allocations.reduce((s, a) => s + (a.quota || 0), 0);
  const totalUsed = allocations.reduce((s, a) => s + (a.used || 0), 0);
  const totalDamaged = allocations.reduce((s, a) => s + (a.damaged || 0), 0);
  const totalRemaining = totalQuota - totalUsed;
  const totalKemasan = monthProductions.reduce((s, p) => s + (p.jumlah_kemasan || 0), 0);
  const totalRevenue = monthGoods.reduce((s, g) => s + Number(g.total_value || 0), 0);
  const criticalFactories = allocations.filter((a) => a.quota > 0 && ((a.quota - a.used) / a.quota) <= 0.1);

  // Production per factory — use NPPBKC on axis, keep NAME + batang + kemasan in tooltip
  const prodPerFactory = useMemo(() => {
    const map = {};
    monthProductions.forEach((p) => {
      const nppbkc = p.factories?.nppbkc || '-';
      const name = p.factories?.name || 'Unknown';
      const key = nppbkc;
      if (!map[key]) map[key] = { nppbkc, name, kemasan: 0, batang: 0 };
      map[key].kemasan += p.jumlah_kemasan || 0;
      map[key].batang += p.jumlah_isi || 0;
    });
    return Object.values(map).sort((a, b) => b.kemasan - a.kemasan).slice(0, 10);
  }, [monthProductions]);

  // Daily production trend for direktur (daily breakdown of current month)
  const dailyProdTrend = useMemo(() => {
    if (!isDirektur) return [];
    const [year, month] = currentMonth.split('-');
    const daysInMonth = new Date(year, month, 0).getDate();
    const days = {};
    for (let i = 1; i <= daysInMonth; i++) {
      const dateStr = `${year}-${month}-${String(i).padStart(2, '0')}`;
      days[dateStr] = { date: dateStr, label: i.toString(), kemasan: 0, batang: 0 };
    }
    monthProductions.forEach((p) => {
      if (days[p.doc_date]) {
        days[p.doc_date].kemasan += p.jumlah_kemasan || 0;
        days[p.doc_date].batang += p.jumlah_isi || 0;
      }
    });
    return Object.values(days);
  }, [isDirektur, monthProductions, currentMonth]);

  // Monthly trend (last 6 months)
  const monthlyTrend = useMemo(() => {
    const months = [];
    const now = new Date();
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const key = d.toISOString().slice(0, 7);
      const label = d.toLocaleDateString('id-ID', { month: 'short' });
      months.push({ key, label, produksi: 0, pemasaran: 0 });
    }
    productions.forEach((p) => {
      const key = p.doc_date?.slice(0, 7);
      const m = months.find((mo) => mo.key === key);
      if (m) m.produksi += p.jumlah_kemasan || 0;
    });
    outgoingGoods.forEach((g) => {
      if (g.status !== 'approved') return;
      const key = g.transaction_date?.slice(0, 7);
      const m = months.find((mo) => mo.key === key);
      if (m) m.pemasaran += g.volume || 0;
    });
    return months;
  }, [productions, outgoingGoods]);

  // Cukai pie (terpakai + rusak + sisa)
  const cukaiPieData = [
    { name: 'Terpakai', value: totalUsed, color: '#3b82f6' },
    { name: 'Rusak', value: totalDamaged, color: '#ef4444' },
    { name: 'Sisa', value: totalRemaining > 0 ? totalRemaining : 0, color: isDark ? '#4b5563' : '#d1d5db' },
  ].filter((d) => d.value > 0);

  const formatNumber = (num) => {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(0) + 'K';
    return Number(num || 0).toLocaleString('id-ID');
  };
  const formatCurrency = (num) => {
    if (num >= 1000000000) return `Rp ${(num / 1000000000).toFixed(1)}M`;
    if (num >= 1000000) return `Rp ${(num / 1000000).toFixed(0)}Jt`;
    return `Rp ${Number(num).toLocaleString('id-ID')}`;
  };

  const chartColors = { grid: isDark ? '#1f2937' : '#f3f4f6', text: isDark ? '#6b7280' : '#9ca3af' };



  const getStatusBadge = (status) => {
    switch (status) {
      case 'approved':
        return <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400">Disetujui</span>;
      case 'rejected':
        return <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400">Ditolak</span>;
      default:
        return <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400">Menunggu</span>;
    }
  };

  if (loading) {
    return (
      <div className="space-y-6 max-w-[1400px] mx-auto">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">{Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)}</div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5"><div className="lg:col-span-2"><SkeletonChart /></div><SkeletonCard /></div>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-[1400px] mx-auto">

      {/* Welcome Banner with Auto Slider */}
      <div className="bg-gradient-to-r from-blue-600 to-indigo-700 dark:from-blue-800 dark:to-indigo-900 rounded-2xl p-6 lg:p-8 text-white relative overflow-hidden">
        <div className="absolute right-0 top-0 w-72 h-72 bg-white/5 rounded-full -translate-y-1/3 translate-x-1/4"></div>
        <div className="absolute right-32 bottom-0 w-40 h-40 bg-white/5 rounded-full translate-y-1/2"></div>
        <div className="relative z-10 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div className="animate-[fadeSlideIn_0.6s_ease-out]">
            {isDirektur ? (
              <h2 className="text-3xl lg:text-4xl font-extrabold animate-[fadeSlideIn_0.6s_ease-out_0.3s_both]">
                <span className="text-blue-100 font-medium text-2xl block mb-1">Selamat datang Direktur,</span>
                <span className="bg-gradient-to-r from-white via-blue-100 to-cyan-200 bg-clip-text text-transparent">{profile?.full_name || 'User'}</span>
              </h2>
            ) : (
              <>
                <p className="text-blue-100 text-sm font-medium tracking-wide animate-[fadeSlideIn_0.6s_ease-out_0.1s_both]">
                  Selamat datang kembali,
                </p>
                <h2 className="text-3xl lg:text-4xl font-extrabold mt-1.5 animate-[fadeSlideIn_0.6s_ease-out_0.3s_both]">
                  <span className="bg-gradient-to-r from-white via-blue-100 to-cyan-200 bg-clip-text text-transparent">{profile?.full_name || 'Admin'}</span>
                </h2>
              </>
            )}
            {isDirektur && factoryName && (
              <div className="flex items-center gap-2 mt-3 animate-[fadeSlideIn_0.6s_ease-out_0.4s_both]">
                <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-white/10 backdrop-blur-sm rounded-full border border-white/20 text-[12px] font-semibold text-blue-100">
                  <span className="material-symbols-outlined text-[14px]" style={{ fontVariationSettings: "'FILL' 1" }}>domain</span>
                  {factoryName}
                </span>
              </div>
            )}
            <p className="text-blue-200/80 text-[15px] mt-4 max-w-xl h-6 font-medium animate-[fadeSlideIn_0.6s_ease-out_0.5s_both]">
              <TypingText texts={isDirektur ? [
                'Pantau operasional pabrik Anda secara real-time.',
                'Kelola data produksi, cukai, dan pemasaran secara real-time.',
                'Pastikan kepatuhan regulasi pita cukai pabrik Anda.',
                'Monitor distribusi dan penjualan produk pabrik Anda.',
              ] : [
                `Pantau seluruh operasional ${factories.length} pabrik rokok di bawah APHT Sumenep.`,
                'Kelola data produksi, cukai, dan pemasaran secara real-time.',
                'Pastikan kepatuhan regulasi pita cukai seluruh pabrik.',
                'Monitor distribusi dan penjualan ke seluruh wilayah.',
              ]} />
            </p>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 px-4 py-2.5 bg-white/10 backdrop-blur-sm rounded-xl text-sm font-medium border border-white/10">
              <span className="material-symbols-outlined text-[18px]">calendar_today</span>
              <span>{todayLabel}</span>
            </div>
          </div>
        </div>

        {/* Auto Slider - quick stats */}
        <div className="relative z-10 mt-5 pt-5 border-t border-white/10">
          <AutoSlider items={isDirektur ? [
            { icon: 'domain', label: 'Pabrik Anda', value: factoryName || 'Memuat...' },
            { icon: 'inventory_2', label: 'Produksi Bulan Ini', value: `${formatNumber(totalKemasan)} kemasan` },
            { icon: 'confirmation_number', label: 'Sisa Pita Cukai', value: `${formatNumber(totalRemaining)} lembar` },
            { icon: 'storefront', label: 'Pemasaran Bulan Ini', value: formatCurrency(totalRevenue) },
          ] : [
            { icon: 'domain', label: 'Pabrik Aktif', value: `${activeFactories} dari ${factories.length}` },
            { icon: 'inventory_2', label: 'Produksi Bulan Ini', value: `${formatNumber(totalKemasan)} kemasan` },
            { icon: 'confirmation_number', label: 'Sisa Pita Cukai', value: `${formatNumber(totalRemaining)} lembar` },
            { icon: 'storefront', label: 'Pemasaran Bulan Ini', value: formatCurrency(totalRevenue) },
            { icon: 'warning', label: 'Pabrik Kritis', value: `${criticalFactories.length} pabrik` },
          ]} />
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {isDirektur ? (
          <StatCard icon="domain" label="Pabrik Anda" value={factoryName || '-'} color="blue" />
        ) : (
          <StatCard icon="domain" label="Pabrik Aktif" value={activeFactories} suffix={`/ ${factories.length}`} color="blue" />
        )}
        <StatCard icon="inventory_2" label="Produksi" value={formatNumber(totalKemasan)} suffix="kemasan" color="green" />
        <StatCard icon="confirmation_number" label="Sisa Cukai" value={formatNumber(totalRemaining)} suffix="lbr" color="purple" />
        <StatCard icon="storefront" label="Pemasaran" value={formatCurrency(totalRevenue)} color="orange" />
      </div>

      {/* Charts: Trend + Cukai Pie */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Area: Tren 6 bulan */}
        <div className="lg:col-span-2 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Tren Penjualan & Produksi</h3>
              <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">6 bulan terakhir {isDirektur ? `(Pabrik ${factoryName || 'Anda'})` : '(Seluruh Pabrik)'}</p>
            </div>
            <div className="flex items-center gap-4 text-[11px]">
              <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-blue-500"></span>Produksi</span>
              <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span>Pemasaran</span>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={monthlyTrend} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="gB" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#3b82f6" stopOpacity={0.15} /><stop offset="95%" stopColor="#3b82f6" stopOpacity={0} /></linearGradient>
                <linearGradient id="gG" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#10b981" stopOpacity={0.15} /><stop offset="95%" stopColor="#10b981" stopOpacity={0} /></linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={chartColors.grid} vertical={false} />
              <XAxis dataKey="label" tick={{ fontSize: 11, fill: chartColors.text }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: chartColors.text }} axisLine={false} tickLine={false} tickFormatter={formatNumber} />
              <Tooltip contentStyle={{ backgroundColor: isDark ? '#1f2937' : '#fff', border: `1px solid ${isDark ? '#374151' : '#e5e7eb'}`, borderRadius: '8px', fontSize: '12px' }} formatter={(v, name) => [formatNumber(v), name === 'produksi' ? 'Produksi' : 'Pemasaran']} />
              <Area type="monotone" dataKey="produksi" stroke="#3b82f6" strokeWidth={2} fill="url(#gB)" />
              <Area type="monotone" dataKey="pemasaran" stroke="#10b981" strokeWidth={2} fill="url(#gG)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Pie: Cukai */}
        <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5 flex flex-col">
          <div className="flex items-center justify-between">
            <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Pemakaian Cukai</h3>
            <Link to="/dashboard/pantau-cukai" className="text-[11px] font-semibold text-blue-600 dark:text-blue-400 hover:underline">Detail</Link>
          </div>
          <div className="flex-1 flex items-center justify-center py-3">
            <div className="relative">
              <ResponsiveContainer width={170} height={170}>
                <PieChart>
                  <Pie data={cukaiPieData} cx="50%" cy="50%" innerRadius={52} outerRadius={76} dataKey="value" startAngle={90} endAngle={-270} paddingAngle={2}>
                    {cukaiPieData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
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
          <div className="space-y-2 mt-1">
            <div className="flex items-center justify-between text-xs"><span className="flex items-center gap-2"><span className="w-2.5 h-2.5 rounded-full bg-blue-500"></span>Terpakai</span><span className="font-bold text-gray-900 dark:text-white">{formatNumber(totalUsed)}</span></div>
            <div className="flex items-center justify-between text-xs"><span className="flex items-center gap-2"><span className="w-2.5 h-2.5 rounded-full bg-red-500"></span>Rusak</span><span className="font-bold text-gray-900 dark:text-white">{formatNumber(totalDamaged)}</span></div>
            <div className="flex items-center justify-between text-xs"><span className="flex items-center gap-2"><span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: isDark ? '#4b5563' : '#d1d5db' }}></span>Sisa</span><span className="font-bold text-gray-900 dark:text-white">{formatNumber(totalRemaining)}</span></div>
          </div>
        </div>
      </div>

      {/* Produksi Chart + Cukai Kritis */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        <div className="lg:col-span-2 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">{isDirektur ? 'Tren Produksi Harian' : 'Produksi per Pabrik'}</h3>
              <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{isDirektur ? `Output harian bulan ini — ${factoryName || ''}` : 'Output bulan ini'}</p>
            </div>
            <Link to="/dashboard/data-produksi" className="text-[11px] font-semibold text-blue-600 dark:text-blue-400 hover:underline">Lihat Semua</Link>
          </div>
          {isDirektur ? (
            /* Direktur: daily trend area chart */
            dailyProdTrend.length === 0 ? (
              <div className="flex items-center justify-center py-16 text-sm text-gray-400 dark:text-gray-500">Belum ada data produksi bulan ini</div>
            ) : (
              <ResponsiveContainer width="100%" height={260}>
                <AreaChart data={dailyProdTrend} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="gradProdDaily" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke={chartColors.grid} vertical={false} />
                  <XAxis dataKey="label" tick={{ fontSize: 10, fill: chartColors.text }} axisLine={false} tickLine={false} interval={2} />
                  <YAxis tick={{ fontSize: 10, fill: chartColors.text }} axisLine={false} tickLine={false} tickFormatter={formatNumber} />
                  <Tooltip
                    contentStyle={{ backgroundColor: isDark ? '#1f2937' : '#fff', border: `1px solid ${isDark ? '#374151' : '#e5e7eb'}`, borderRadius: '8px', fontSize: '12px' }}
                    labelFormatter={(l, payload) => payload?.[0]?.payload?.date || l}
                    formatter={(v) => [formatNumber(v), 'Kemasan']}
                  />
                  <Area type="monotone" dataKey="kemasan" stroke="#3b82f6" strokeWidth={2} fill="url(#gradProdDaily)" />
                </AreaChart>
              </ResponsiveContainer>
            )
          ) : (
            /* Super Admin: per-factory bar chart */
            prodPerFactory.length === 0 ? (
              <div className="flex items-center justify-center py-16 text-sm text-gray-400 dark:text-gray-500">Belum ada data produksi bulan ini</div>
            ) : (
              <ResponsiveContainer width="100%" height={260}>
                <BarChart data={prodPerFactory} margin={{ top: 5, right: 5, left: -10, bottom: 10 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke={chartColors.grid} vertical={false} />
                  <XAxis dataKey="nppbkc" tick={{ fontSize: 11, fill: chartColors.text }} axisLine={false} tickLine={false} interval={0} />
                  <YAxis tick={{ fontSize: 10, fill: chartColors.text }} axisLine={false} tickLine={false} tickFormatter={formatNumber} />
                  <Tooltip cursor={{ fill: isDark ? 'rgba(59,130,246,0.08)' : 'rgba(59,130,246,0.06)' }} content={(props) => <ProdTooltip {...props} isDark={isDark} />} />
                  <Bar dataKey="kemasan" fill="#3b82f6" radius={[6, 6, 0, 0]} maxBarSize={36} />
                </BarChart>
              </ResponsiveContainer>
            )
          )}
        </div>

        {/* Cukai Kritis */}
        <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-[15px] font-bold text-gray-900 dark:text-white flex items-center gap-2">
              <span className="material-symbols-outlined text-red-500 text-[18px]">warning</span>
              {isDirektur ? 'Status Cukai' : 'Pabrik Kritis'}
            </h3>
            <Link to="/dashboard/pantau-cukai" className="text-[11px] font-semibold text-blue-600 dark:text-blue-400 hover:underline">Lihat Semua</Link>
          </div>
          <p className="text-xs text-gray-400 dark:text-gray-500 mb-4">{isDirektur ? 'Status pita cukai pabrik Anda' : 'Sisa pita cukai < 10%'}</p>
          <div className="space-y-3">
            {criticalFactories.length === 0 ? (
              <div className="text-center py-10">
                <span className="material-symbols-outlined text-emerald-400 dark:text-emerald-500 text-[36px]">verified</span>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">{isDirektur ? 'Cukai pabrik Anda aman' : 'Semua pabrik aman'}</p>
              </div>
            ) : (
              criticalFactories.map((alloc) => {
                const remaining = alloc.quota - (alloc.used || 0);
                const percent = Math.round((remaining / alloc.quota) * 100);
                return (
                  <div key={alloc.id} className="p-3.5 rounded-lg bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/30">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-semibold text-gray-800 dark:text-gray-200">{alloc.factories?.name}</span>
                      <span className="text-xs font-bold text-red-600 dark:text-red-400">{percent}%</span>
                    </div>
                    <div className="w-full h-1.5 bg-red-100 dark:bg-red-900/30 rounded-full mt-2 overflow-hidden">
                      <div className="h-full bg-red-500 rounded-full" style={{ width: `${100 - percent}%` }}></div>
                    </div>
                    <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-1.5">Sisa: {remaining.toLocaleString()} / {alloc.quota.toLocaleString()}</p>
                  </div>
                );
              })
            )}
          </div>
        </div>
      </div>

      {/* Pengajuan Cukai Terbaru Hari Ini */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-[15px] font-bold text-gray-900 dark:text-white flex items-center gap-2">
              <span className="material-symbols-outlined text-blue-500 text-[18px]">receipt_long</span>
              Pengajuan Cukai Terbaru Hari Ini
            </h3>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{todayLabel}</p>
          </div>
          <Link
            to="/dashboard/pengajuan-cukai"
            className="flex items-center gap-1.5 px-3 py-1.5 text-[11px] font-semibold text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
          >
            Lihat Semua
            <span className="material-symbols-outlined text-[14px]">arrow_forward</span>
          </Link>
        </div>

        {todayCukaiRequests.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-10 text-center">
            <span className="material-symbols-outlined text-gray-300 dark:text-gray-600 text-[40px]">inbox</span>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">Belum ada pengajuan cukai hari ini</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100 dark:divide-gray-800">
            {todayCukaiRequests.map((r) => {
              const time = r.created_at ? new Date(r.created_at).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-';
              return (
                <div key={r.id} className="flex items-center gap-3 py-3 first:pt-0 last:pb-0">
                  <div className="w-9 h-9 rounded-lg bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
                    <span className="material-symbols-outlined text-blue-600 dark:text-blue-400 text-[18px]">description</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                        {r.factories?.name || 'Pabrik'}
                      </span>
                      {r.factories?.nppbkc && (
                        <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400">
                          {r.factories.nppbkc}
                        </span>
                      )}
                    </div>
                    <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate mt-0.5">
                      {r.doc_number || '-'} · {r.jenis_pengajuan || '-'} {r.cigarettes ? `· ${r.cigarettes.product_name} (${r.cigarettes.brands?.name || ''})` : ''} · {time}
                    </p>
                  </div>
                  {getStatusBadge(r.status)}
                </div>
              );
            })}
          </div>
        )}
      </div>

    </div>
  );
};

export default Beranda;
