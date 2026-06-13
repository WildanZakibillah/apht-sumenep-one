import React, { useState, useEffect, useMemo } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';
import { useTheme } from '../context/ThemeContext';
import PageHeader from '../components/shared/PageHeader';
import StatCard from '../components/shared/StatCard';
import { SkeletonCard, SkeletonChart } from '../components/shared/Skeleton';
import MonthPicker from '../components/shared/MonthPicker';
import SearchBar from '../components/shared/SearchBar';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, BarChart, CartesianGrid, XAxis, YAxis, Bar, AreaChart, Area, Legend } from 'recharts';
import { useRoleAccess } from '../hooks/useRoleAccess';

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
      <div className="text-[10px] opacity-60 mb-1.5">Kode: {d.code}</div>
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

const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#14b8a6', '#f97316', '#6366f1'];

const DataProduksi = () => {
  const { isDark } = useTheme();
  const { ready } = useAuth();
  const { scopeQuery, isFactoryScoped, factoryId, isDirektur } = useRoleAccess();
  const [productions, setProductions] = useState([]);
  const [factories, setFactories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedFactory, setSelectedFactory] = useState(isFactoryScoped ? factoryId : 'all');
  const [selectedMonth, setSelectedMonth] = useState(() => new Date().toISOString().slice(0, 7));
  const [tableSearch, setTableSearch] = useState('');

  useEffect(() => {
    if (!ready) return;
    const fetchData = async () => {
      setLoading(true);
      try {
        const [prodRes, factRes] = await Promise.all([
          scopeQuery(supabase.from('productions').select('*, factories(name, code)').order('doc_date', { ascending: false })),
          scopeQuery(supabase.from('factories').select('id, name, code, status').order('name'), 'id'),
        ]);
        if (prodRes.data) setProductions(prodRes.data);
        if (factRes.data) setFactories(factRes.data);
      } catch (e) {
        console.error(e);
      }
      setLoading(false);
    };
    fetchData();
  }, [ready]);

  // Factory name for direktur context
  const factoryName = isDirektur && factories.length > 0 ? factories[0]?.name : null;

  // Filter by selected factory
  const filtered = useMemo(() => {
    if (selectedFactory === 'all') return productions;
    return productions.filter((p) => p.factory_id === selectedFactory);
  }, [productions, selectedFactory]);

  // This month only (based on selectedMonth)
  const thisMonth = useMemo(() => {
    return filtered.filter((p) => p.doc_date?.startsWith(selectedMonth));
  }, [filtered, selectedMonth]);

  // Stats
  const totalKemasan = thisMonth.reduce((s, p) => s + (p.jumlah_kemasan || 0), 0);
  const totalBatang = thisMonth.reduce((s, p) => s + (p.jumlah_isi || 0), 0);
  const totalEntries = thisMonth.length;
  const uniqueBrands = [...new Set(thisMonth.map((p) => p.merek))].length;

  // Daily production trend (selected month)
  const dailyTrend = useMemo(() => {
    const days = {};
    
    // Parse selectedMonth (e.g. "2026-06")
    const [year, month] = selectedMonth.split('-');
    const daysInMonth = new Date(year, month, 0).getDate();
    
    for (let i = 1; i <= daysInMonth; i++) {
      const dateStr = `${year}-${month}-${String(i).padStart(2, '0')}`;
      days[dateStr] = { date: dateStr, label: i.toString(), kemasan: 0, batang: 0 };
    }

    thisMonth.forEach((p) => {
      if (days[p.doc_date]) {
        days[p.doc_date].kemasan += p.jumlah_kemasan || 0;
        days[p.doc_date].batang += p.jumlah_isi || 0;
      }
    });
    return Object.values(days);
  }, [thisMonth, selectedMonth]);

  // Production by category (pie)
  const byCategory = useMemo(() => {
    const map = {};
    thisMonth.forEach((p) => {
      const cat = p.jenis || 'Lainnya';
      map[cat] = (map[cat] || 0) + (p.jumlah_kemasan || 0);
    });
    return Object.entries(map).map(([name, value]) => ({ name, value }));
  }, [thisMonth]);

  // Production per factory (bar) - use factory CODE on axis (vertical), keep name+batang+kemasan in tooltip
  const perFactory = useMemo(() => {
    const map = {};
    thisMonth.forEach((p) => {
      const code = p.factories?.code || '-';
      const name = p.factories?.name || 'Unknown';
      const key = code;
      if (!map[key]) map[key] = { code, name, kemasan: 0, batang: 0 };
      map[key].kemasan += p.jumlah_kemasan || 0;
      map[key].batang += p.jumlah_isi || 0;
    });
    return Object.values(map).sort((a, b) => b.kemasan - a.kemasan).slice(0, 10);
  }, [thisMonth]);

  // Top brands
  const topBrands = useMemo(() => {
    const map = {};
    thisMonth.forEach((p) => {
      const brand = p.merek || 'Unknown';
      map[brand] = (map[brand] || 0) + (p.jumlah_kemasan || 0);
    });
    return Object.entries(map)
      .map(([name, value]) => ({ name, value }))
      .sort((a, b) => b.value - a.value)
      .slice(0, 8);
  }, [thisMonth]);

  const formatNumber = (num) => {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(0) + 'K';
    return num.toLocaleString('id-ID');
  };

  const chartColors = {
    grid: isDark ? '#1f2937' : '#f3f4f6',
    text: isDark ? '#6b7280' : '#9ca3af',
  };

  if (loading) {
    return (
      <div className="space-y-5 max-w-[1400px] mx-auto">
        <PageHeader title="Rekap Produksi Seluruh Pabrik" description="Monitoring output produksi harian dari seluruh pabrik." />
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)}
        </div>
        <SkeletonChart />
      </div>
    );
  }

  return (
    <div className="space-y-5 max-w-[1400px] mx-auto">
      <PageHeader title={isDirektur ? `Rekap Produksi ${factoryName || ''}` : 'Rekap Produksi Seluruh Pabrik'} description={isDirektur ? `Monitoring output produksi harian pabrik ${factoryName || 'Anda'}.` : 'Monitoring output produksi harian dari seluruh pabrik.'}>
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
      </PageHeader>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon="inventory_2" label="Total Kemasan" value={formatNumber(totalKemasan)} suffix="bln ini" color="blue" />
        <StatCard icon="straighten" label="Total Batang" value={formatNumber(totalBatang)} suffix="btg" color="green" />
        <StatCard icon="edit_note" label="Entri Produksi" value={totalEntries} suffix="catatan" color="orange" />
        <StatCard icon="sell" label="Merek Aktif" value={uniqueBrands} suffix="merek" color="purple" />
      </div>

      {/* Row 1: Daily Trend (2/3) + Komposisi Jenis Produk (1/3) */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Daily Trend Chart */}
        <div className="lg:col-span-2 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Tren Produksi Harian</h3>
              <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">Bulan terpilih (kemasan)</p>
            </div>
            <div className="flex items-center gap-4 text-xs">
              <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-blue-500"></span><span className="text-gray-500 dark:text-gray-400">Kemasan</span></span>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={260}>
            <AreaChart data={dailyTrend} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="gradProd" x1="0" y1="0" x2="0" y2="1">
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
              <Area type="monotone" dataKey="kemasan" stroke="#3b82f6" strokeWidth={2} fill="url(#gradProd)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Pie: Komposisi Jenis Produk */}
        <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5 flex flex-col">
          <div>
            <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Komposisi Jenis Produk</h3>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">Distribusi per kategori</p>
          </div>
          {byCategory.length === 0 ? (
            <div className="flex-1 flex items-center justify-center text-sm text-gray-400 dark:text-gray-500">Belum ada data</div>
          ) : (
            <div className="flex-1 flex items-center justify-center">
              <ResponsiveContainer width="100%" height={260}>
                <PieChart>
                  <Pie data={byCategory} cx="50%" cy="45%" innerRadius={50} outerRadius={85} dataKey="value" paddingAngle={3} startAngle={90} endAngle={-270}>
                    {byCategory.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                  </Pie>
                  <Legend verticalAlign="bottom" height={30} iconSize={8} formatter={(value) => <span className="text-[10px] text-gray-600 dark:text-gray-400">{value}</span>} />
                  <Tooltip contentStyle={{ backgroundColor: isDark ? '#1f2937' : '#fff', border: `1px solid ${isDark ? '#374151' : '#e5e7eb'}`, borderRadius: '8px', fontSize: '12px' }} formatter={(v) => [formatNumber(v) + ' kemasan', '']} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>
      </div>

      {/* Row 2: Bar Per Pabrik (Admin) + Top Merek */}
      <div className={`grid grid-cols-1 ${isFactoryScoped ? 'lg:grid-cols-1' : 'lg:grid-cols-3'} gap-5`}>
        {/* Bar: Per Factory (Admin Only) */}
        {!isFactoryScoped && (
          <div className="lg:col-span-2 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5">
            <h3 className="text-[15px] font-bold text-gray-900 dark:text-white mb-1">Produksi per Pabrik</h3>
            <p className="text-xs text-gray-400 dark:text-gray-500 mb-4">Output bulan ini (kemasan) — kode pabrik</p>
            {perFactory.length === 0 ? (
              <div className="flex items-center justify-center py-12 text-sm text-gray-400 dark:text-gray-500">Belum ada data</div>
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={perFactory} margin={{ top: 5, right: 5, left: -10, bottom: 10 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke={chartColors.grid} vertical={false} />
                  <XAxis dataKey="code" tick={{ fontSize: 11, fill: chartColors.text }} axisLine={false} tickLine={false} interval={0} />
                  <YAxis tick={{ fontSize: 10, fill: chartColors.text }} axisLine={false} tickLine={false} tickFormatter={formatNumber} />
                  <Tooltip cursor={{ fill: isDark ? 'rgba(59,130,246,0.08)' : 'rgba(59,130,246,0.06)' }} content={(props) => <ProdTooltip {...props} isDark={isDark} />} />
                  <Bar dataKey="kemasan" fill="#3b82f6" radius={[6, 6, 0, 0]} maxBarSize={36} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        )}

        {/* Top Brands */}
        <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-5">
          <h3 className="text-[15px] font-bold text-gray-900 dark:text-white mb-4">Top Merek Produksi</h3>
          <div className="space-y-3">
            {topBrands.length === 0 ? (
              <p className="text-sm text-gray-400 dark:text-gray-500 text-center py-6">Belum ada data</p>
            ) : (
              topBrands.map((brand, i) => {
                const maxVal = topBrands[0]?.value || 1;
                const pct = Math.round((brand.value / maxVal) * 100);
                return (
                  <div key={brand.name} className="space-y-1.5">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium text-gray-800 dark:text-gray-200 flex items-center gap-2">
                        <span className="w-5 h-5 rounded-md flex items-center justify-center text-[10px] font-bold text-white" style={{ backgroundColor: COLORS[i % COLORS.length] }}>{i + 1}</span>
                        {brand.name}
                      </span>
                      <span className="text-xs font-bold text-gray-500 dark:text-gray-400">{formatNumber(brand.value)}</span>
                    </div>
                    <div className="w-full h-1.5 bg-gray-100 dark:bg-gray-800 rounded-full overflow-hidden">
                      <div className="h-full rounded-full transition-all" style={{ width: `${pct}%`, backgroundColor: COLORS[i % COLORS.length] }}></div>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>
      </div>

      {/* Detail Table */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
          <div className="p-5 border-b border-gray-100 dark:border-gray-800 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
            <div>
              <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Detail Produksi Bulan Ini</h3>
              <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{thisMonth.length} catatan produksi</p>
            </div>
            <SearchBar value={tableSearch} onChange={(e) => setTableSearch(e.target.value)} placeholder="Cari pabrik, merek, jenis..." className="md:w-96" />
          </div>
          <div className="overflow-x-auto max-h-[400px] overflow-y-auto custom-scrollbar">
            <table className="w-full text-left">
              <thead className="sticky top-0 z-10">
                <tr className="bg-gray-50 dark:bg-gray-800/80 border-b border-gray-100 dark:border-gray-800">
                  <th className="px-4 py-2.5 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Tanggal</th>
                  <th className="px-4 py-2.5 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Pabrik</th>
                  <th className="px-4 py-2.5 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Merek</th>
                  <th className="px-4 py-2.5 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Jenis</th>
                  <th className="px-4 py-2.5 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Kemasan</th>
                  <th className="px-4 py-2.5 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Batang</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
                {(() => {
                  const q = tableSearch.trim().toLowerCase();
                  const rows = q
                    ? thisMonth.filter((p) =>
                        (p.factories?.name || '').toLowerCase().includes(q) ||
                        (p.factories?.code || '').toLowerCase().includes(q) ||
                        (p.merek || '').toLowerCase().includes(q) ||
                        (p.jenis || '').toLowerCase().includes(q)
                      )
                    : thisMonth;
                  if (rows.length === 0) {
                    return <tr><td colSpan="6" className="px-4 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">{q ? 'Tidak ditemukan' : 'Belum ada produksi bulan ini'}</td></tr>;
                  }
                  return rows.slice(0, 50).map((p) => (
                    <tr key={p.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                      <td className="px-4 py-2.5 text-xs text-gray-500 dark:text-gray-400">{p.doc_date}</td>
                      <td className="px-4 py-2.5 text-xs font-semibold text-gray-900 dark:text-white">{p.factories?.name || '-'}</td>
                      <td className="px-4 py-2.5 text-xs text-gray-700 dark:text-gray-300">{p.merek}</td>
                      <td className="px-4 py-2.5">
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded ${
                          p.jenis === 'SKT' ? 'bg-orange-50 dark:bg-orange-900/20 text-orange-700 dark:text-orange-400' :
                          p.jenis === 'SKM' ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400' :
                          'bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-400'
                        }`}>{p.jenis}</span>
                      </td>
                      <td className="px-4 py-2.5 text-xs text-gray-700 dark:text-gray-300 font-medium text-right">{(p.jumlah_kemasan || 0).toLocaleString()}</td>
                      <td className="px-4 py-2.5 text-xs text-gray-700 dark:text-gray-300 font-medium text-right">{(p.jumlah_isi || 0).toLocaleString()}</td>
                    </tr>
                  ));
                })()}
              </tbody>
            </table>
          </div>
      </div>
    </div>
  );
};

export default DataProduksi;
