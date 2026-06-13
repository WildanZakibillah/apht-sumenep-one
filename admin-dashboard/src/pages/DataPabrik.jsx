import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';
import { useToast } from '../hooks/useToast';
import PageHeader from '../components/shared/PageHeader';
import StatCard from '../components/shared/StatCard';
import { SkeletonCard, SkeletonTable } from '../components/shared/Skeleton';
import Modal from '../components/shared/Modal';
import ConfirmDialog from '../components/shared/ConfirmDialog';
import SearchBar from '../components/shared/SearchBar';
import { useRoleAccess } from '../hooks/useRoleAccess';

const GOLONGAN_OPTIONS = ['SKT-I', 'SKT-II', 'SKT-IIIA', 'SKT-IIIB', 'SKM-I', 'SKM-II', 'SPM-I', 'SPM-II'];

const emptyForm = { code: '', name: '', golongan: 'SKT-I', address: '', status: 'active' };

const DataPabrik = () => {
  const [factories, setFactories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const { ready } = useAuth();
  const { scopeQuery, isFactoryScoped } = useRoleAccess();
  const toast = useToast();

  const loadFactories = async () => {
    setLoading(true);
    const { data, error } = await scopeQuery(supabase.from('factories').select('*').order('code'), 'id');
    if (error) {
      toast.error('Gagal memuat data: ' + error.message);
    } else if (data) {
      setFactories(data);
    }
    setLoading(false);
  };

  useEffect(() => {
    if (ready) loadFactories();
  }, [ready]); // eslint-disable-line

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setShowModal(true);
  };

  const openEdit = (f) => {
    setEditing(f);
    setForm({
      code: f.code || '',
      name: f.name || '',
      golongan: f.golongan || 'SKT-I',
      address: f.address || '',
      status: f.status || 'active',
    });
    setShowModal(true);
  };

  const closeModal = () => {
    if (saving) return;
    setShowModal(false);
    setEditing(null);
    setForm(emptyForm);
  };

  const handleSubmit = async (e) => {
    e?.preventDefault?.();
    if (!form.code.trim() || !form.name.trim()) {
      toast.warning('Kode dan nama pabrik wajib diisi');
      return;
    }
    setSaving(true);
    try {
      const payload = {
        code: form.code.trim(),
        name: form.name.trim(),
        golongan: form.golongan,
        address: form.address.trim() || null,
        status: form.status,
      };
      if (editing) {
        const { error } = await supabase.from('factories').update(payload).eq('id', editing.id);
        if (error) throw error;
        toast.success('Pabrik berhasil diperbarui');
      } else {
        const { error } = await supabase.from('factories').insert(payload);
        if (error) throw error;
        toast.success('Pabrik berhasil ditambahkan');
      }
      closeModal();
      await loadFactories();
    } catch (err) {
      toast.error(err.message || 'Gagal menyimpan data');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      const { error } = await supabase.from('factories').delete().eq('id', deleteTarget.id);
      if (error) throw error;
      toast.success('Pabrik berhasil dihapus');
      setDeleteTarget(null);
      await loadFactories();
    } catch (err) {
      toast.error(err.message || 'Gagal menghapus pabrik');
    }
  };

  const filteredFactories = factories.filter((f) => {
    const matchFilter = filter === 'all' || f.status === filter;
    const q = search.trim().toLowerCase();
    const matchSearch = !q || f.name?.toLowerCase().includes(q) || f.code?.toLowerCase().includes(q) || f.address?.toLowerCase().includes(q);
    return matchFilter && matchSearch;
  });

  const activeCount = factories.filter((f) => f.status === 'active').length;
  const inactiveCount = factories.filter((f) => f.status === 'inactive').length;

  if (loading && factories.length === 0) {
    return (
      <div className="space-y-5 max-w-[1400px] mx-auto">
        <PageHeader title="Daftar Pabrik Terdaftar" description="Kelola dan pantau seluruh pabrik rokok di bawah APHT Sumenep." />
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {Array.from({ length: 3 }).map((_, i) => <SkeletonCard key={i} />)}
        </div>
        <SkeletonTable rows={6} cols={5} />
      </div>
    );
  }

  return (
    <div className="space-y-5 max-w-[1400px] mx-auto">
      <PageHeader title={isFactoryScoped ? "Info Pabrik" : "Daftar Pabrik Terdaftar"} description={isFactoryScoped ? "Informasi detail mengenai pabrik Anda." : "Kelola dan pantau seluruh pabrik rokok di bawah APHT Sumenep."}>
        {!isFactoryScoped && (
          <button
            onClick={openCreate}
            className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors shadow-sm"
          >
            <span className="material-symbols-outlined text-[18px]">add</span>
            Tambah Pabrik
          </button>
        )}
      </PageHeader>

      {!isFactoryScoped && (
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <StatCard icon="domain" label="Total Pabrik" value={factories.length} color="blue" />
          <StatCard icon="check_circle" label="Aktif" value={activeCount} color="green" />
          <StatCard icon="cancel" label="Tidak Aktif" value={inactiveCount} color="red" />
        </div>
      )}

      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className="p-4 border-b border-gray-100 dark:border-gray-800 flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            {['all', 'active', 'inactive'].map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
                  filter === f ? 'bg-blue-600 text-white' : 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700'
                }`}
              >
                {f === 'all' ? 'Semua' : f === 'active' ? 'Aktif' : 'Tidak Aktif'}
              </button>
            ))}
          </div>
          <SearchBar value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Cari pabrik..." className="md:w-96" />
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Kode</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Nama Pabrik</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Golongan</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Alamat</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider text-center">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {filteredFactories.length === 0 ? (
                <tr><td colSpan="6" className="px-5 py-8 text-center text-gray-400 dark:text-gray-500 text-sm">{search || filter !== 'all' ? 'Tidak ada data sesuai filter' : 'Belum ada data pabrik'}</td></tr>
              ) : (
                filteredFactories.map((factory) => (
                  <tr key={factory.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                    <td className="px-5 py-3.5 text-sm font-mono text-gray-500 dark:text-gray-400">{factory.code}</td>
                    <td className="px-5 py-3.5 text-sm font-semibold text-gray-900 dark:text-white">{factory.name}</td>
                    <td className="px-5 py-3.5">
                      <span className="text-xs font-semibold px-2 py-1 rounded bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400">{factory.golongan}</span>
                    </td>
                    <td className="px-5 py-3.5 text-sm text-gray-500 dark:text-gray-400 max-w-[200px] truncate">{factory.address || '-'}</td>
                    <td className="px-5 py-3.5">
                      <span className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full ${
                        factory.status === 'active' ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400' : 'bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400'
                      }`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${factory.status === 'active' ? 'bg-emerald-500' : 'bg-red-400'}`}></span>
                        {factory.status === 'active' ? 'Aktif' : 'Tidak Aktif'}
                      </span>
                    </td>
                    <td className="px-5 py-3.5 text-center">
                      <div className="flex items-center justify-center gap-1">
                        <button onClick={() => openEdit(factory)} className="p-1.5 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors" title="Edit">
                          <span className="material-symbols-outlined text-[18px]">edit</span>
                        </button>
                        {!isFactoryScoped && (
                          <button onClick={() => setDeleteTarget(factory)} className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 dark:hover:text-red-400 transition-colors" title="Hapus">
                            <span className="material-symbols-outlined text-[18px]">delete</span>
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="px-5 py-3 border-t border-gray-100 dark:border-gray-800 flex items-center justify-between text-sm text-gray-500 dark:text-gray-400">
          <span>Menampilkan {filteredFactories.length} dari {factories.length} pabrik</span>
        </div>
      </div>

      <Modal
        open={showModal}
        onClose={closeModal}
        title={editing ? 'Edit Pabrik' : 'Tambah Pabrik Baru'}
        footer={
          <>
            <button onClick={closeModal} disabled={saving} className="px-4 py-2 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors disabled:opacity-50">Batal</button>
            <button onClick={handleSubmit} disabled={saving} className="px-5 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition-colors shadow-sm disabled:opacity-60 disabled:cursor-not-allowed">
              {saving ? 'Menyimpan...' : 'Simpan'}
            </button>
          </>
        }
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Kode Pabrik <span className="text-red-500">*</span></label>
            <input
              value={form.code}
              onChange={(e) => setForm({ ...form, code: e.target.value })}
              className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 focus:ring-1 focus:ring-blue-400"
              placeholder="FCT-012"
              required
            />
          </div>
          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Pabrik <span className="text-red-500">*</span></label>
            <input
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 focus:ring-1 focus:ring-blue-400"
              placeholder="PT Nama Pabrik"
              required
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Golongan</label>
              <select
                value={form.golongan}
                onChange={(e) => setForm({ ...form, golongan: e.target.value })}
                className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400"
              >
                {GOLONGAN_OPTIONS.map((g) => <option key={g} value={g}>{g}</option>)}
              </select>
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Status</label>
              <select
                value={form.status}
                onChange={(e) => setForm({ ...form, status: e.target.value })}
                className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400"
              >
                <option value="active">Aktif</option>
                <option value="inactive">Tidak Aktif</option>
              </select>
            </div>
          </div>
          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Alamat</label>
            <textarea
              value={form.address}
              onChange={(e) => setForm({ ...form, address: e.target.value })}
              className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 resize-none"
              rows="2"
              placeholder="Jl. ..."
            />
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDelete}
        title="Hapus Pabrik?"
        message={`Yakin menghapus "${deleteTarget?.name}"? Data terkait (alokasi cukai, pengajuan, dll) juga akan terhapus dan tidak bisa dikembalikan.`}
        confirmText="Ya, Hapus"
        cancelText="Batal"
        variant="danger"
        icon="delete"
      />
    </div>
  );
};

export default DataPabrik;
