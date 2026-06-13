import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';
import { useToast } from '../hooks/useToast';
import PageHeader from '../components/shared/PageHeader';
import { SkeletonTable } from '../components/shared/Skeleton';
import Modal from '../components/shared/Modal';
import ConfirmDialog from '../components/shared/ConfirmDialog';
import SearchBar from '../components/shared/SearchBar';
import { useRoleAccess } from '../hooks/useRoleAccess';

const TABS = [
  { id: 'product_types', label: 'Jenis Produk', icon: 'category', table: 'product_types' },
  { id: 'brands', label: 'Merek', icon: 'sell', table: 'brands' },
  { id: 'hje_rates', label: 'HJE', icon: 'price_change', table: 'hje_rates' },
  { id: 'regions', label: 'Wilayah', icon: 'map', table: 'regions' },
];

const PRODUCT_CATEGORIES = ['SKT', 'SKM', 'SPM'];
const GOLONGAN = ['I', 'II', 'IIIA', 'IIIB'];

const initialForm = {
  product_types: { name: '', category: 'SKT', isi_per_pak: 12 },
  brands: { name: '', product_type_id: '', factory_id: '' },
  hje_rates: { product_type_id: '', golongan: 'I', tarif: 0, effective_date: new Date().toISOString().slice(0, 10) },
  regions: { name: '' },
};

const DataMaster = () => {
  const [activeTab, setActiveTab] = useState('product_types');
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(initialForm.product_types);
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  // Lookup data for selects
  const [productTypes, setProductTypes] = useState([]);
  const [factories, setFactories] = useState([]);
  const { ready } = useAuth();
  const { scopeQuery, isFactoryScoped, factoryId } = useRoleAccess();
  const toast = useToast();

  const loadLookup = async () => {
    const [pt, fc] = await Promise.all([
      supabase.from('product_types').select('id, name').order('name'),
      scopeQuery(supabase.from('factories').select('id, name').order('name'), 'id'),
    ]);
    if (pt.data) setProductTypes(pt.data);
    if (fc.data) setFactories(fc.data);
  };

  const loadData = async () => {
    setLoading(true);
    let query;
    switch (activeTab) {
      case 'product_types': query = supabase.from('product_types').select('*').order('name'); break;
      case 'brands': query = scopeQuery(supabase.from('brands').select('*, product_types(name), factories(name)').order('name')); break;
      case 'hje_rates':
        // hje_rates doesn't directly link to factory_id. If needed, we might have to filter it via product_types or just let it be global for direktur (or maybe direktur doesn't see all HJE?).
        // Usually HJE is global. But if we must scope, we'd need a join or something. For now, let's keep it global since it's "Master Data" and rates are usually global per product type.
        query = supabase.from('hje_rates').select('*, product_types(name)').order('effective_date', { ascending: false }); break;
      case 'regions': query = supabase.from('regions').select('*').order('name'); break;
      default: query = supabase.from('product_types').select('*');
    }
    const { data: result, error } = await query;
    if (error) toast.error('Gagal memuat data: ' + error.message);
    else if (result) setData(result);
    setLoading(false);
  };

  useEffect(() => {
    if (ready) loadLookup();
  }, [ready]);

  useEffect(() => {
    if (!ready) return;
    setSearch('');
    loadData();
  }, [activeTab, ready]); // eslint-disable-line

  const openCreate = () => {
    setEditing(null);
    const defaultForm = { ...initialForm[activeTab] };
    if (activeTab === 'brands' && isFactoryScoped) {
      defaultForm.factory_id = factoryId;
    }
    setForm(defaultForm);
    setShowModal(true);
  };

  const openEdit = (item) => {
    setEditing(item);
    switch (activeTab) {
      case 'product_types':
        setForm({ name: item.name || '', category: item.category || 'SKT', isi_per_pak: item.isi_per_pak || 12 });
        break;
      case 'brands':
        setForm({ name: item.name || '', product_type_id: item.product_type_id || '', factory_id: item.factory_id || '' });
        break;
      case 'hje_rates':
        setForm({
          product_type_id: item.product_type_id || '',
          golongan: item.golongan || 'I',
          tarif: item.tarif || 0,
          effective_date: item.effective_date || new Date().toISOString().slice(0, 10),
        });
        break;
      case 'regions':
        setForm({ name: item.name || '' });
        break;
      default: break;
    }
    setShowModal(true);
  };

  const closeModal = () => {
    if (saving) return;
    setShowModal(false);
    setEditing(null);
  };

  const validate = () => {
    if (activeTab === 'product_types') return form.name?.trim();
    if (activeTab === 'brands') return form.name?.trim() && form.factory_id;
    if (activeTab === 'hje_rates') return form.product_type_id && form.tarif > 0 && form.effective_date;
    if (activeTab === 'regions') return form.name?.trim();
    return false;
  };

  const handleSubmit = async (e) => {
    e?.preventDefault?.();
    if (!validate()) {
      toast.warning('Mohon lengkapi field yang wajib diisi');
      return;
    }
    setSaving(true);
    try {
      let payload = {};
      switch (activeTab) {
        case 'product_types':
          payload = { name: form.name.trim(), category: form.category, isi_per_pak: parseInt(form.isi_per_pak) || 12 };
          break;
        case 'brands':
          payload = { name: form.name.trim(), product_type_id: form.product_type_id || null, factory_id: form.factory_id };
          break;
        case 'hje_rates':
          payload = {
            product_type_id: form.product_type_id,
            golongan: form.golongan,
            tarif: parseFloat(form.tarif) || 0,
            effective_date: form.effective_date,
          };
          break;
        case 'regions':
          payload = { name: form.name.trim() };
          break;
        default: break;
      }
      const tableName = TABS.find((t) => t.id === activeTab).table;
      if (editing) {
        const { error } = await supabase.from(tableName).update(payload).eq('id', editing.id);
        if (error) throw error;
        toast.success('Data berhasil diperbarui');
      } else {
        const { error } = await supabase.from(tableName).insert(payload);
        if (error) throw error;
        toast.success('Data berhasil ditambahkan');
      }
      closeModal();
      await loadData();
      if (activeTab === 'product_types') loadLookup();
    } catch (err) {
      toast.error(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      const tableName = TABS.find((t) => t.id === activeTab).table;
      const { error } = await supabase.from(tableName).delete().eq('id', deleteTarget.id);
      if (error) throw error;
      toast.success('Data berhasil dihapus');
      setDeleteTarget(null);
      await loadData();
      if (activeTab === 'product_types') loadLookup();
    } catch (err) {
      toast.error(err.message);
    }
  };

  const filteredData = (() => {
    const q = search.trim().toLowerCase();
    if (!q) return data;
    return data.filter((item) => {
      switch (activeTab) {
        case 'product_types': return item.name?.toLowerCase().includes(q) || item.category?.toLowerCase().includes(q);
        case 'brands': return item.name?.toLowerCase().includes(q) || item.product_types?.name?.toLowerCase().includes(q) || item.factories?.name?.toLowerCase().includes(q);
        case 'hje_rates': return item.product_types?.name?.toLowerCase().includes(q) || item.golongan?.toLowerCase().includes(q);
        case 'regions': return item.name?.toLowerCase().includes(q);
        default: return true;
      }
    });
  })();

  const renderTable = () => {
    if (loading) return <SkeletonTable rows={5} cols={4} />;
    if (filteredData.length === 0) return <div className="px-5 py-12 text-center text-gray-400 dark:text-gray-500 text-sm">{search ? 'Tidak ada data sesuai pencarian' : 'Belum ada data'}</div>;

    const thClass = 'px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider';
    const tdClass = 'px-5 py-3.5 text-sm';
    const actionCell = (item) => (
      <td className={`${tdClass} text-center`}>
        <div className="flex items-center justify-center gap-1">
          <button onClick={() => openEdit(item)} className="p-1.5 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors" title="Edit">
            <span className="material-symbols-outlined text-[18px]">edit</span>
          </button>
          <button onClick={() => setDeleteTarget(item)} className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 dark:hover:text-red-400 transition-colors" title="Hapus">
            <span className="material-symbols-outlined text-[18px]">delete</span>
          </button>
        </div>
      </td>
    );

    switch (activeTab) {
      case 'product_types':
        return (
          <table className="w-full text-left">
            <thead><tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
              <th className={thClass}>No</th><th className={thClass}>Nama Produk</th><th className={thClass}>Kategori</th><th className={thClass}>Isi/Pak</th><th className={`${thClass} text-center`}>Aksi</th>
            </tr></thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {filteredData.map((item, i) => (
                <tr key={item.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td className={`${tdClass} text-gray-400 dark:text-gray-500`}>{i + 1}</td>
                  <td className={`${tdClass} font-semibold text-gray-900 dark:text-white`}>{item.name}</td>
                  <td className={tdClass}><span className={`text-xs font-semibold px-2 py-1 rounded ${item.category === 'SKT' ? 'bg-orange-50 dark:bg-orange-900/20 text-orange-700 dark:text-orange-400' : item.category === 'SKM' ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400' : 'bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-400'}`}>{item.category}</span></td>
                  <td className={`${tdClass} text-gray-600 dark:text-gray-400`}>{item.isi_per_pak} Batang</td>
                  {actionCell(item)}
                </tr>
              ))}
            </tbody>
          </table>
        );
      case 'brands':
        return (
          <table className="w-full text-left">
            <thead><tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
              <th className={thClass}>No</th><th className={thClass}>Merek</th><th className={thClass}>Jenis</th><th className={thClass}>Pabrik</th><th className={`${thClass} text-center`}>Aksi</th>
            </tr></thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {filteredData.map((item, i) => (
                <tr key={item.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td className={`${tdClass} text-gray-400 dark:text-gray-500`}>{i + 1}</td>
                  <td className={`${tdClass} font-semibold text-gray-900 dark:text-white`}>{item.name}</td>
                  <td className={`${tdClass} text-gray-600 dark:text-gray-400`}>{item.product_types?.name || '-'}</td>
                  <td className={`${tdClass} text-gray-600 dark:text-gray-400`}>{item.factories?.name || '-'}</td>
                  {actionCell(item)}
                </tr>
              ))}
            </tbody>
          </table>
        );
      case 'hje_rates':
        return (
          <table className="w-full text-left">
            <thead><tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
              <th className={thClass}>No</th><th className={thClass}>Jenis</th><th className={thClass}>Golongan</th><th className={thClass}>Tarif</th><th className={thClass}>Berlaku</th><th className={`${thClass} text-center`}>Aksi</th>
            </tr></thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {filteredData.map((item, i) => (
                <tr key={item.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td className={`${tdClass} text-gray-400 dark:text-gray-500`}>{i + 1}</td>
                  <td className={`${tdClass} font-semibold text-gray-900 dark:text-white`}>{item.product_types?.name || '-'}</td>
                  <td className={`${tdClass} text-gray-600 dark:text-gray-400`}>{item.golongan}</td>
                  <td className={`${tdClass} text-gray-700 dark:text-gray-300 font-medium`}>Rp {Number(item.tarif).toLocaleString('id-ID')}</td>
                  <td className={`${tdClass} text-gray-500 dark:text-gray-400`}>{item.effective_date}</td>
                  {actionCell(item)}
                </tr>
              ))}
            </tbody>
          </table>
        );
      case 'regions':
        return (
          <table className="w-full text-left">
            <thead><tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
              <th className={thClass}>No</th><th className={thClass}>Nama Wilayah</th><th className={`${thClass} text-center`}>Aksi</th>
            </tr></thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {filteredData.map((item, i) => (
                <tr key={item.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td className={`${tdClass} text-gray-400 dark:text-gray-500`}>{i + 1}</td>
                  <td className={`${tdClass} font-semibold text-gray-900 dark:text-white`}>{item.name}</td>
                  {actionCell(item)}
                </tr>
              ))}
            </tbody>
          </table>
        );
      default: return null;
    }
  };

  const renderForm = () => {
    switch (activeTab) {
      case 'product_types':
        return (
          <>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Produk <span className="text-red-500">*</span></label>
              <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 focus:ring-1 focus:ring-blue-400" placeholder="Misal: SKT Reguler" required />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Kategori</label>
                <select value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400">
                  {PRODUCT_CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Isi per Pak</label>
                <input type="number" min="1" value={form.isi_per_pak} onChange={(e) => setForm({ ...form, isi_per_pak: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" />
              </div>
            </div>
          </>
        );
      case 'brands':
        return (
          <>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Merek <span className="text-red-500">*</span></label>
              <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 focus:ring-1 focus:ring-blue-400" placeholder="Misal: Gudang Garam" required />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Jenis Produk</label>
                <select value={form.product_type_id} onChange={(e) => setForm({ ...form, product_type_id: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400">
                  <option value="">Pilih jenis...</option>
                  {productTypes.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Pabrik <span className="text-red-500">*</span></label>
                <select value={form.factory_id} onChange={(e) => setForm({ ...form, factory_id: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required disabled={isFactoryScoped}>
                  <option value="">Pilih pabrik...</option>
                  {factories.map((f) => <option key={f.id} value={f.id}>{f.name}</option>)}
                </select>
              </div>
            </div>
          </>
        );
      case 'hje_rates':
        return (
          <>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Jenis Produk <span className="text-red-500">*</span></label>
              <select value={form.product_type_id} onChange={(e) => setForm({ ...form, product_type_id: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required>
                <option value="">Pilih jenis...</option>
                {productTypes.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Golongan</label>
                <select value={form.golongan} onChange={(e) => setForm({ ...form, golongan: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400">
                  {GOLONGAN.map((g) => <option key={g} value={g}>{g}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Tarif (Rp) <span className="text-red-500">*</span></label>
                <input type="number" min="0" step="0.01" value={form.tarif} onChange={(e) => setForm({ ...form, tarif: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required />
              </div>
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Berlaku Sejak <span className="text-red-500">*</span></label>
              <input type="date" value={form.effective_date} onChange={(e) => setForm({ ...form, effective_date: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required />
            </div>
          </>
        );
      case 'regions':
        return (
          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Wilayah <span className="text-red-500">*</span></label>
            <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 focus:ring-1 focus:ring-blue-400" placeholder="Misal: Jawa Timur" required />
          </div>
        );
      default: return null;
    }
  };

  const currentTabLabel = TABS.find((t) => t.id === activeTab)?.label || '';

  return (
    <div className="space-y-5 max-w-[1400px] mx-auto">
      <PageHeader title="Konfigurasi Data Referensi" description="Kelola data referensi sistem: produk, merek, HJE, dan wilayah.">
        <button onClick={openCreate} className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors shadow-sm">
          <span className="material-symbols-outlined text-[18px]">add</span>
          Tambah {currentTabLabel}
        </button>
      </PageHeader>

      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className="border-b border-gray-100 dark:border-gray-800 px-5 flex items-center gap-1 overflow-x-auto">
          {TABS.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 px-4 py-3 text-sm font-semibold border-b-2 transition-colors whitespace-nowrap ${
                activeTab === tab.id ? 'border-blue-600 text-blue-600 dark:text-blue-400' : 'border-transparent text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300'
              }`}
            >
              <span className="material-symbols-outlined text-[18px]">{tab.icon}</span>
              {tab.label}
            </button>
          ))}
        </div>

        <div className="p-4 border-b border-gray-50 dark:border-gray-800 flex items-center">
          <SearchBar value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Cari data..." className="md:w-96" />
        </div>

        <div className="overflow-x-auto">{renderTable()}</div>

        <div className="px-5 py-3 border-t border-gray-100 dark:border-gray-800 flex items-center justify-between text-sm text-gray-500 dark:text-gray-400">
          <span>Menampilkan {filteredData.length} dari {data.length} data</span>
        </div>
      </div>

      <Modal
        open={showModal}
        onClose={closeModal}
        title={editing ? `Edit ${currentTabLabel}` : `Tambah ${currentTabLabel}`}
        footer={
          <>
            <button onClick={closeModal} disabled={saving} className="px-4 py-2 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg disabled:opacity-50">Batal</button>
            <button onClick={handleSubmit} disabled={saving} className="px-5 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition-colors shadow-sm disabled:opacity-60">
              {saving ? 'Menyimpan...' : 'Simpan'}
            </button>
          </>
        }
      >
        <form onSubmit={handleSubmit} className="space-y-4">{renderForm()}</form>
      </Modal>

      <ConfirmDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDelete}
        title={`Hapus ${currentTabLabel}?`}
        message="Data akan dihapus permanen dan tidak bisa dikembalikan. Lanjutkan?"
        confirmText="Ya, Hapus"
        cancelText="Batal"
        variant="danger"
        icon="delete"
      />
    </div>
  );
};

export default DataMaster;
