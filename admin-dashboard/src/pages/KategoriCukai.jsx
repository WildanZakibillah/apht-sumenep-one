import React, { useState, useEffect } from 'react';
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

const GOLONGAN_OPTIONS = ['I', 'II', 'IIIA', 'IIIB'];
const JENIS_HT_OPTIONS = ['SKM', 'SKT', 'SPM', 'CRT', 'KLM'];

const emptyForm = {
  name: '',
  jenis_ht: 'SKM',
  isi_per_bungkus: 12,
  golongan: 'II',
  hje: 0,
  tarif_cukai: 0,
  is_shared: true,
  keterangan: ''
};

const KategoriCukai = ({ hideHeader = false }) => {
  const { isDark } = useTheme();
  const { profile, ready } = useAuth();
  const toast = useToast();
  
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);

  const isSuperAdmin = profile?.role === 'super_admin';

  const loadCategories = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('cukai_categories')
        .select('*')
        .order('created_at', { ascending: false });
      if (error) throw error;
      if (data) setCategories(data);
    } catch (err) {
      toast.error('Gagal memuat kategori: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (ready) loadCategories();
  }, [ready]); // eslint-disable-line

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setShowModal(true);
  };

  const openEdit = (cat) => {
    setEditing(cat);
    setForm({
      name: cat.name || '',
      jenis_ht: cat.jenis_ht || 'SKM',
      isi_per_bungkus: cat.isi_per_bungkus || 12,
      golongan: cat.golongan || 'II',
      hje: cat.hje || 0,
      tarif_cukai: cat.tarif_cukai || 0,
      is_shared: cat.is_shared !== false,
      keterangan: cat.keterangan || ''
    });
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e?.preventDefault?.();
    if (!form.name.trim()) {
      toast.warning('Nama Kategori wajib diisi');
      return;
    }
    setSaving(true);
    try {
      const payload = {
        name: form.name.trim(),
        jenis_ht: form.jenis_ht,
        isi_per_bungkus: parseInt(form.isi_per_bungkus) || 12,
        golongan: form.golongan,
        hje: parseFloat(form.hje) || 0,
        tarif_cukai: parseFloat(form.tarif_cukai) || 0,
        is_shared: form.is_shared,
        keterangan: form.keterangan.trim() || null
      };

      if (editing) {
        const { error } = await supabase
          .from('cukai_categories')
          .update(payload)
          .eq('id', editing.id);
        if (error) throw error;
        toast.success('Kategori cukai berhasil diperbarui');
      } else {
        const { error } = await supabase
          .from('cukai_categories')
          .insert(payload);
        if (error) throw error;
        toast.success('Kategori cukai baru ditambahkan');
      }
      setShowModal(false);
      await loadCategories();
    } catch (err) {
      toast.error('Gagal menyimpan: ' + err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      const { error } = await supabase
        .from('cukai_categories')
        .delete()
        .eq('id', deleteTarget.id);
      if (error) throw error;
      toast.success('Kategori cukai berhasil dihapus');
      setDeleteTarget(null);
      await loadCategories();
    } catch (err) {
      toast.error('Gagal menghapus: ' + err.message);
    }
  };

  const filteredCategories = categories.filter((cat) => {
    const q = search.toLowerCase().trim();
    if (!q) return true;
    return (
      cat.name.toLowerCase().includes(q) ||
      cat.jenis_ht.toLowerCase().includes(q) ||
      (cat.golongan && cat.golongan.toLowerCase().includes(q))
    );
  });

  const totalCategories = categories.length;
  const sharedCategories = categories.filter(c => c.is_shared).length;
  const exclusiveCategories = totalCategories - sharedCategories;

  if (loading && categories.length === 0) {
    return (
      <div className="space-y-5 max-w-[1400px] mx-auto">
        {!hideHeader && <PageHeader title="Master Kategori Cukai" description="Kelola spesifikasi dan pembagian pita cukai pabrik." />}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <SkeletonCard />
          <SkeletonCard />
          <SkeletonCard />
        </div>
        <SkeletonTable />
      </div>
    );
  }

  return (
    <div className="space-y-5 max-w-[1400px] mx-auto">
      {!hideHeader ? (
        <PageHeader title="Master Kategori Cukai" description="Daftar parameter tarif, HJE, isi bungkus, dan sifat pembagian pita cukai.">
          {isSuperAdmin && (
            <button onClick={openCreate} className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors shadow-sm">
              <span className="material-symbols-outlined text-[18px]">add</span>Kategori Baru
            </button>
          )}
        </PageHeader>
      ) : (
        <div className="flex justify-end pt-2">
          {isSuperAdmin && (
            <button onClick={openCreate} className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors shadow-sm">
              <span className="material-symbols-outlined text-[18px]">add</span>Kategori Baru
            </button>
          )}
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard icon="sell" label="Total Kategori" value={totalCategories} color="blue" />
        <StatCard icon="share" label="Kategori Bersama (Shared)" value={sharedCategories} color="green" />
        <StatCard icon="lock" label="Kategori Eksklusif" value={exclusiveCategories} color="orange" />
      </div>

      {/* Table Section */}
      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className="p-5 border-b border-gray-100 dark:border-gray-800 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <h3 className="text-[15px] font-bold text-gray-900 dark:text-white">Daftar Kategori</h3>
          <SearchBar value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Cari berdasarkan nama, jenis HT..." className="sm:w-80" />
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50 dark:bg-gray-800/80 border-b border-gray-100 dark:border-gray-800">
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase">Nama Kategori</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-center">Jenis HT</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Isi/Bks</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-center">Golongan</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">HJE (Rp)</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-right">Tarif Cukai (Rp)</th>
                <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-center">Sifat Batch</th>
                {isSuperAdmin && <th className="px-5 py-3 text-[10px] font-bold text-gray-400 dark:text-gray-500 uppercase text-center">Aksi</th>}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {filteredCategories.length === 0 ? (
                <tr>
                  <td colSpan={isSuperAdmin ? 8 : 7} className="px-5 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">
                    {search ? 'Pencarian tidak ditemukan' : 'Belum ada data kategori cukai'}
                  </td>
                </tr>
              ) : (
                filteredCategories.map((cat) => (
                  <tr key={cat.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                    <td className="px-5 py-3.5 text-sm font-semibold text-gray-900 dark:text-white">
                      <div>{cat.name}</div>
                      {cat.keterangan && <div className="text-[11px] font-normal text-gray-400 dark:text-gray-500 mt-0.5">{cat.keterangan}</div>}
                    </td>
                    <td className="px-5 py-3.5 text-center">
                      <span className="text-xs font-bold px-2 py-0.5 rounded bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 uppercase">
                        {cat.jenis_ht}
                      </span>
                    </td>
                    <td className="px-5 py-3.5 text-xs text-gray-700 dark:text-gray-300 font-medium text-right">
                      {cat.isi_per_bungkus} btg
                    </td>
                    <td className="px-5 py-3.5 text-xs text-gray-700 dark:text-gray-300 font-medium text-center">
                      Gol. {cat.golongan || '-'}
                    </td>
                    <td className="px-5 py-3.5 text-xs text-gray-900 dark:text-white font-semibold text-right">
                      {(cat.hje || 0).toLocaleString('id-ID')}
                    </td>
                    <td className="px-5 py-3.5 text-xs text-gray-900 dark:text-white font-semibold text-right">
                      {(cat.tarif_cukai || 0).toLocaleString('id-ID')}
                    </td>
                    <td className="px-5 py-3.5 text-center">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${cat.is_shared ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400' : 'bg-orange-50 dark:bg-orange-900/20 text-orange-600 dark:text-orange-400'}`}>
                        {cat.is_shared ? 'SHARED (BERSAMA)' : 'EKSKLUSIF'}
                      </span>
                    </td>
                    {isSuperAdmin && (
                      <td className="px-5 py-3.5 text-center">
                        <div className="flex items-center justify-center gap-1">
                          <button onClick={() => openEdit(cat)} className="p-1.5 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors">
                            <span className="material-symbols-outlined text-[16px]">edit</span>
                          </button>
                          <button onClick={() => setDeleteTarget(cat)} className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 transition-colors">
                            <span className="material-symbols-outlined text-[16px]">delete</span>
                          </button>
                        </div>
                      </td>
                    )}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Form */}
      <Modal open={showModal} onClose={() => !saving && setShowModal(false)} title={editing ? 'Edit Kategori Cukai' : 'Tambah Kategori Cukai Baru'}
        footer={
          <>
            <button onClick={() => setShowModal(false)} disabled={saving} className="px-4 py-2 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg disabled:opacity-50">Batal</button>
            <button onClick={handleSubmit} disabled={saving} className="px-5 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition-colors shadow-sm disabled:opacity-60">
              {saving ? 'Menyimpan...' : 'Simpan'}
            </button>
          </>
        }
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Kategori <span className="text-red-500">*</span></label>
            <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Contoh: SKM 12 HJE 25000" required />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Jenis HT <span className="text-red-500">*</span></label>
              <select value={form.jenis_ht} onChange={(e) => setForm({ ...form, jenis_ht: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required>
                {JENIS_HT_OPTIONS.map((opt) => <option key={opt} value={opt}>{opt}</option>)}
              </select>
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Golongan <span className="text-red-500">*</span></label>
              <select value={form.golongan} onChange={(e) => setForm({ ...form, golongan: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required>
                {GOLONGAN_OPTIONS.map((opt) => <option key={opt} value={opt}>Gol. {opt}</option>)}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Isi per Bungkus <span className="text-red-500">*</span></label>
              <input type="number" min="1" value={form.isi_per_bungkus} onChange={(e) => setForm({ ...form, isi_per_bungkus: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">HJE (Rp) <span className="text-red-500">*</span></label>
              <input type="number" min="0" value={form.hje} onChange={(e) => setForm({ ...form, hje: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Tarif Cukai <span className="text-red-500">*</span></label>
              <input type="number" min="0" value={form.tarif_cukai} onChange={(e) => setForm({ ...form, tarif_cukai: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required />
            </div>
          </div>

          <div className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-800/40 rounded-lg border border-gray-100 dark:border-gray-800/60">
            <input type="checkbox" id="chkIsShared" checked={form.is_shared} onChange={(e) => setForm({ ...form, is_shared: e.target.checked })} className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" />
            <div>
              <label htmlFor="chkIsShared" className="text-xs font-bold text-gray-700 dark:text-gray-300 cursor-pointer">Boleh Dipakai Bersama (Shared)</label>
              <p className="text-[10px] text-gray-400 dark:text-gray-500">Jika dicentang, batch pita cukai dari kategori ini dapat digunakan bersama oleh semua produk dengan kategori cukai yang sama.</p>
            </div>
          </div>

          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Keterangan</label>
            <textarea value={form.keterangan} onChange={(e) => setForm({ ...form, keterangan: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 h-20 resize-none" placeholder="Catatan tambahan mengenai kategori cukai..." />
          </div>
        </form>
      </Modal>

      <ConfirmDialog open={!!deleteTarget} onClose={() => setDeleteTarget(null)} onConfirm={handleDelete} title="Hapus Kategori Cukai?" message={`Hapus kategori cukai "${deleteTarget?.name}"? Tindakan ini dapat memutus relasi pada produk yang menggunakannya.`} confirmText="Ya, Hapus" cancelText="Batal" variant="danger" icon="delete" />
    </div>
  );
};

export default KategoriCukai;
