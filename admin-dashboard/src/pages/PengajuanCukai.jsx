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

const PengajuanCukai = () => {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('all');
  const [search, setSearch] = useState('');
  const [viewing, setViewing] = useState(null);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [actionTarget, setActionTarget] = useState(null); // { id, action: 'approve' | 'reject' }
  const { ready } = useAuth();
  const { scopeQuery, isFactoryScoped, isDirektur } = useRoleAccess();
  const toast = useToast();

  const loadData = async () => {
    setLoading(true);
    const { data, error } = await scopeQuery(supabase.from('cukai_requests').select('*, factories(name, code)').order('created_at', { ascending: false }));
    if (error) toast.error('Gagal memuat: ' + error.message);
    else if (data) setRequests(data);
    setLoading(false);
  };

  useEffect(() => {
    if (ready) {
      setTimeout(() => loadData(), 0);
    }
  }, [ready]); // eslint-disable-line

  const counts = {
    all: requests.length,
    pending: requests.filter((r) => r.status === 'pending').length,
    approved: requests.filter((r) => r.status === 'approved').length,
    rejected: requests.filter((r) => r.status === 'rejected').length,
  };

  const filteredRequests = requests.filter((r) => {
    const matchTab =
      activeTab === 'pending' ? r.status === 'pending'
      : activeTab === 'approved' ? r.status === 'approved'
      : activeTab === 'rejected' ? r.status === 'rejected'
      : true;
    const q = search.trim().toLowerCase();
    const matchSearch = !q
      || r.factories?.name?.toLowerCase().includes(q)
      || r.doc_number?.toLowerCase().includes(q)
      || r.jenis_pengajuan?.toLowerCase().includes(q);
    return matchTab && matchSearch;
  });

  const handleAction = async () => {
    if (!actionTarget) return;
    try {
      const { error } = await supabase.from('cukai_requests').update({ status: actionTarget.action === 'approve' ? 'approved' : 'rejected' }).eq('id', actionTarget.id);
      if (error) throw error;
      toast.success(`Pengajuan ${actionTarget.action === 'approve' ? 'disetujui' : 'ditolak'}`);
      setActionTarget(null);
      await loadData();
    } catch (err) {
      toast.error(err.message);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      const { error } = await supabase.from('cukai_requests').delete().eq('id', deleteTarget.id);
      if (error) throw error;
      toast.success('Pengajuan dihapus');
      setDeleteTarget(null);
      await loadData();
    } catch (err) {
      toast.error(err.message);
    }
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'approved': return <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400">Disetujui</span>;
      case 'rejected': return <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400">Ditolak</span>;
      default: return <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400">Menunggu</span>;
    }
  };

  if (loading && requests.length === 0) {
    return (
      <div className="space-y-5 max-w-[1400px] mx-auto">
        <PageHeader title="Daftar Pengajuan dari Pabrik" description="Approve atau tolak pengajuan pita cukai dari pabrik." />
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">{Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)}</div>
        <SkeletonTable rows={5} cols={5} />
      </div>
    );
  }

  return (
    <div className="space-y-5 max-w-[1400px] mx-auto">
      <PageHeader title={isDirektur ? 'Pengajuan Cukai Pabrik Anda' : 'Daftar Pengajuan dari Pabrik'} description={isDirektur ? 'Lihat status pengajuan pita cukai pabrik Anda.' : 'Approve atau tolak pengajuan pita cukai dari pabrik.'} />

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <StatCard icon="assignment" label="Total Pengajuan" value={counts.all} color="blue" />
        <StatCard icon="schedule" label="Menunggu" value={counts.pending} color="orange" />
        <StatCard icon="check_circle" label="Disetujui" value={counts.approved} color="green" />
        <StatCard icon="cancel" label="Ditolak" value={counts.rejected} color="red" />
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className="border-b border-gray-100 dark:border-gray-800 px-5 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <div className="flex items-center gap-1 overflow-x-auto -mx-1 px-1">
            {[{ id: 'all', label: 'Semua' }, { id: 'pending', label: 'Menunggu' }, { id: 'approved', label: 'Disetujui' }, { id: 'rejected', label: 'Ditolak' }].map((tab) => (
              <button key={tab.id} onClick={() => setActiveTab(tab.id)} className={`px-4 py-3 text-sm font-semibold border-b-2 transition-colors whitespace-nowrap ${activeTab === tab.id ? 'border-blue-600 text-blue-600 dark:text-blue-400' : 'border-transparent text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300'}`}>
                {tab.label} ({counts[tab.id]})
              </button>
            ))}
          </div>
          <SearchBar value={search} onChange={(e) => setSearch(e.target.value)} placeholder={isFactoryScoped ? "Cari dokumen..." : "Cari pabrik, dokumen..."} className="md:w-96" />
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead><tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
              <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">No. Dokumen</th>
              {!isFactoryScoped && <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Pabrik</th>}
              <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Jenis</th>
              <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Jumlah</th>
              <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Status</th>
              <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase text-center">Aksi</th>
            </tr></thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {filteredRequests.length === 0 ? (
                <tr><td colSpan="6" className="px-5 py-12 text-center text-gray-400 dark:text-gray-500 text-sm">Tidak ada pengajuan</td></tr>
              ) : filteredRequests.map((req) => (
                <tr key={req.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td className="px-5 py-3.5 text-sm font-mono text-gray-600 dark:text-gray-400">{req.doc_number || '-'}</td>
                  {!isFactoryScoped && <td className="px-5 py-3.5 text-sm font-semibold text-gray-900 dark:text-white">{req.factories?.name || '-'}</td>}
                  <td className="px-5 py-3.5"><span className="text-xs font-semibold px-2 py-1 rounded bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-400">{req.jenis_pengajuan}</span></td>
                  <td className="px-5 py-3.5 text-sm text-gray-700 dark:text-gray-300 font-medium">{req.jumlah_lembar?.toLocaleString() || '-'}</td>
                  <td className="px-5 py-3.5">{getStatusBadge(req.status)}</td>
                  <td className="px-5 py-3.5 text-center">
                    <div className="flex items-center justify-center gap-1">
                      <button onClick={() => setViewing(req)} className="p-1.5 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors" title="Detail">
                        <span className="material-symbols-outlined text-[18px]">visibility</span>
                      </button>
                      {!isFactoryScoped && req.status === 'pending' && (
                        <>
                          <button onClick={() => setActionTarget({ id: req.id, action: 'approve', name: req.factories?.name })} className="p-1.5 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-100 dark:hover:bg-emerald-900/40 transition-colors" title="Setujui">
                            <span className="material-symbols-outlined text-[18px]">check</span>
                          </button>
                          <button onClick={() => setActionTarget({ id: req.id, action: 'reject', name: req.factories?.name })} className="p-1.5 rounded-lg bg-red-50 dark:bg-red-900/20 text-red-500 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/40 transition-colors" title="Tolak">
                            <span className="material-symbols-outlined text-[18px]">close</span>
                          </button>
                        </>
                      )}
                      {!isFactoryScoped && (
                        <button onClick={() => setDeleteTarget(req)} className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 dark:hover:text-red-400 transition-colors" title="Hapus">
                          <span className="material-symbols-outlined text-[18px]">delete</span>
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <Modal
        open={!!viewing}
        onClose={() => setViewing(null)}
        title="Detail Pengajuan Cukai"
        size="lg"
        footer={<button onClick={() => setViewing(null)} className="px-4 py-2 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg">Tutup</button>}
      >
        {viewing && (
          <div className="space-y-4 text-sm">
            <div className="grid grid-cols-2 gap-4">
              <div><p className="text-xs text-gray-500 dark:text-gray-400">No. Dokumen</p><p className="font-semibold text-gray-900 dark:text-white">{viewing.doc_number || '-'}</p></div>
              <div><p className="text-xs text-gray-500 dark:text-gray-400">Status</p>{getStatusBadge(viewing.status)}</div>
              <div><p className="text-xs text-gray-500 dark:text-gray-400">Pabrik</p><p className="font-semibold text-gray-900 dark:text-white">{viewing.factories?.name}</p></div>
              <div><p className="text-xs text-gray-500 dark:text-gray-400">Tanggal</p><p className="text-gray-700 dark:text-gray-300">{viewing.request_date}</p></div>
              <div><p className="text-xs text-gray-500 dark:text-gray-400">Jenis Pengajuan</p><p className="text-gray-700 dark:text-gray-300">{viewing.jenis_pengajuan}</p></div>
              <div><p className="text-xs text-gray-500 dark:text-gray-400">Jenis Hasil Tembakau</p><p className="text-gray-700 dark:text-gray-300">{viewing.jenis_hasil_tembakau}</p></div>
              <div><p className="text-xs text-gray-500 dark:text-gray-400">Lokasi</p><p className="text-gray-700 dark:text-gray-300">{viewing.lokasi_penyediaan}</p></div>
              <div><p className="text-xs text-gray-500 dark:text-gray-400">Seri / Warna</p><p className="text-gray-700 dark:text-gray-300">{viewing.seri || '-'} / {viewing.warna || '-'}</p></div>
              <div><p className="text-xs text-gray-500 dark:text-gray-400">Tarif Cukai</p><p className="text-gray-700 dark:text-gray-300">Rp {Number(viewing.tarif_cukai || 0).toLocaleString('id-ID')}</p></div>
              <div><p className="text-xs text-gray-500 dark:text-gray-400">HJE</p><p className="text-gray-700 dark:text-gray-300">Rp {Number(viewing.hje || 0).toLocaleString('id-ID')}</p></div>
              <div><p className="text-xs text-gray-500 dark:text-gray-400">Isi per Bks</p><p className="text-gray-700 dark:text-gray-300">{viewing.isi_per_bks || '-'}</p></div>
              <div><p className="text-xs text-gray-500 dark:text-gray-400">Jumlah Lembar</p><p className="font-bold text-gray-900 dark:text-white">{viewing.jumlah_lembar?.toLocaleString() || '-'}</p></div>
            </div>
            {!isFactoryScoped && viewing.status === 'pending' && (
              <div className="flex gap-2 pt-4 border-t border-gray-100 dark:border-gray-800">
                <button onClick={() => { setActionTarget({ id: viewing.id, action: 'approve', name: viewing.factories?.name }); setViewing(null); }} className="flex-1 px-4 py-2.5 bg-emerald-600 text-white text-sm font-semibold rounded-lg hover:bg-emerald-700 transition-colors">Setujui</button>
                <button onClick={() => { setActionTarget({ id: viewing.id, action: 'reject', name: viewing.factories?.name }); setViewing(null); }} className="flex-1 px-4 py-2.5 bg-red-600 text-white text-sm font-semibold rounded-lg hover:bg-red-700 transition-colors">Tolak</button>
              </div>
            )}
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={!!actionTarget}
        onClose={() => setActionTarget(null)}
        onConfirm={handleAction}
        title={actionTarget?.action === 'approve' ? 'Setujui Pengajuan?' : 'Tolak Pengajuan?'}
        message={actionTarget?.action === 'approve'
          ? `Setujui pengajuan dari ${actionTarget?.name}? Stok cukai pabrik akan otomatis bertambah.`
          : `Tolak pengajuan dari ${actionTarget?.name}? Pengaju akan menerima notifikasi.`}
        confirmText={actionTarget?.action === 'approve' ? 'Ya, Setujui' : 'Ya, Tolak'}
        cancelText="Batal"
        variant={actionTarget?.action === 'approve' ? 'primary' : 'danger'}
        icon={actionTarget?.action === 'approve' ? 'check_circle' : 'cancel'}
      />

      <ConfirmDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDelete}
        title="Hapus Pengajuan?"
        message="Pengajuan akan dihapus permanen dari sistem. Lanjutkan?"
        confirmText="Ya, Hapus"
        cancelText="Batal"
        variant="danger"
        icon="delete"
      />
    </div>
  );
};

export default PengajuanCukai;
