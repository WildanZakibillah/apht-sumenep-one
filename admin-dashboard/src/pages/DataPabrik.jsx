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

const emptyForm = {
  code: '',
  name: '',
  golongan: 'SKT-I',
  address: '',
  status: 'active',
  owner_name: '',
  director_name: '',
  nppbkc: '',
  nib: '',
  npwp: '',
  phone: '',
  email: '',
  latitude: '',
  longitude: '',
  logo_url: ''
};

const DetailItem = ({ label, value, className = '' }) => (
  <div className={`p-3 bg-gray-50 dark:bg-gray-800/40 rounded-lg border border-gray-100 dark:border-gray-800/60 ${className}`}>
    <span className="text-[10px] uppercase font-bold tracking-wider text-gray-400 dark:text-gray-500 block mb-0.5">{label}</span>
    <span className="text-sm font-medium text-gray-900 dark:text-white break-words">{value || '-'}</span>
  </div>
);

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

  // Logo upload state
  const [logoFile, setLogoFile] = useState(null);
  const [logoPreview, setLogoPreview] = useState('');

  // Detailed view state
  const [selectedFactoryDetail, setSelectedFactoryDetail] = useState(null);
  const [detailBrands, setDetailBrands] = useState([]);
  const [detailAllocations, setDetailAllocations] = useState([]);
  const [loadingDetails, setLoadingDetails] = useState(false);
  const [activeDetailTab, setActiveDetailTab] = useState('profil');
  const [showDetailModal, setShowDetailModal] = useState(false);

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
      // Auto-load details if factory scoped (only 1 factory)
      if (isFactoryScoped && data.length > 0) {
        openDetail(data[0], false);
      }
    }
    setLoading(false);
  };

  useEffect(() => {
    if (ready) loadFactories();
  }, [ready]); // eslint-disable-line

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setLogoFile(null);
    setLogoPreview('');
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
      owner_name: f.owner_name || '',
      director_name: f.director_name || '',
      nppbkc: f.nppbkc || '',
      nib: f.nib || '',
      npwp: f.npwp || '',
      phone: f.phone || '',
      email: f.email || '',
      latitude: f.latitude || '',
      longitude: f.longitude || '',
      logo_url: f.logo_url || '',
    });
    setLogoFile(null);
    setLogoPreview(f.logo_url || '');
    setShowModal(true);
  };

  const closeModal = () => {
    if (saving) return;
    setShowModal(false);
    setEditing(null);
    setForm(emptyForm);
    setLogoFile(null);
    setLogoPreview('');
  };

  const handleLogoChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (!file.type.startsWith('image/')) {
        toast.warning('File harus berupa gambar');
        return;
      }
      if (file.size > 2 * 1024 * 1024) {
        toast.warning('Ukuran file maksimal 2MB');
        return;
      }
      setLogoFile(file);
      setLogoPreview(URL.createObjectURL(file));
    }
  };

  const openDetail = async (factory, openModal = true) => {
    setSelectedFactoryDetail(factory);
    setActiveDetailTab('profil');
    setDetailBrands([]);
    setDetailAllocations([]);
    setLoadingDetails(true);
    if (openModal) {
      setShowDetailModal(true);
    }

    try {
      // Fetch related brands and allocations
      const [brandsRes, allocationsRes] = await Promise.all([
        supabase
          .from('brands')
          .select('*, product_types(name)')
          .eq('factory_id', factory.id)
          .order('name'),
        supabase
          .from('cukai_allocations')
          .select('*')
          .eq('factory_id', factory.id)
          .order('period', { ascending: false })
      ]);

      if (brandsRes.data) setDetailBrands(brandsRes.data);
      if (allocationsRes.data) setDetailAllocations(allocationsRes.data);
    } catch (err) {
      console.error('Gagal memuat detail pabrik:', err);
    } finally {
      setLoadingDetails(false);
    }
  };

  const handleSubmit = async (e) => {
    e?.preventDefault?.();
    if (!form.code.trim() || !form.name.trim()) {
      toast.warning('Kode dan nama pabrik wajib diisi');
      return;
    }
    setSaving(true);
    try {
      let finalLogoUrl = form.logo_url;

      // Upload logo to Supabase Storage if logoFile is present
      if (logoFile) {
        const fileExt = logoFile.name.split('.').pop();
        const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
        const filePath = `${fileName}`;

        const { error: uploadError } = await supabase.storage
          .from('factory-logos')
          .upload(filePath, logoFile);

        if (uploadError) {
          throw new Error('Gagal mengunggah logo: ' + uploadError.message);
        }

        const { data: publicUrlData } = supabase.storage
          .from('factory-logos')
          .getPublicUrl(filePath);

        finalLogoUrl = publicUrlData.publicUrl;

        // Delete old logo file if exists and was overwritten
        if (editing && editing.logo_url && editing.logo_url !== finalLogoUrl) {
          try {
            const urlParts = editing.logo_url.split('/factory-logos/');
            if (urlParts.length > 1) {
              await supabase.storage.from('factory-logos').remove([urlParts[1]]);
            }
          } catch (err) {
            console.error('Gagal menghapus logo lama:', err);
          }
        }
      } else if (form.logo_url === '' && editing?.logo_url) {
        // User explicitly cleared the logo
        try {
          const urlParts = editing.logo_url.split('/factory-logos/');
          if (urlParts.length > 1) {
            await supabase.storage.from('factory-logos').remove([urlParts[1]]);
          }
        } catch (err) {
          console.error('Gagal menghapus logo:', err);
        }
      }

      const payload = {
        code: form.code.trim(),
        name: form.name.trim(),
        golongan: form.golongan,
        address: form.address.trim() || null,
        status: form.status,
        owner_name: form.owner_name.trim() || null,
        director_name: form.director_name.trim() || null,
        nppbkc: form.nppbkc.trim() || null,
        nib: form.nib.trim() || null,
        npwp: form.npwp.trim() || null,
        phone: form.phone.trim() || null,
        email: form.email.trim() || null,
        latitude: form.latitude.trim() || null,
        longitude: form.longitude.trim() || null,
        logo_url: finalLogoUrl || null,
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
      // Delete logo from storage if exists
      if (deleteTarget.logo_url) {
        try {
          const urlParts = deleteTarget.logo_url.split('/factory-logos/');
          if (urlParts.length > 1) {
            await supabase.storage.from('factory-logos').remove([urlParts[1]]);
          }
        } catch (err) {
          console.error('Gagal menghapus logo dari storage:', err);
        }
      }

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
    const matchSearch = !q 
      || f.name?.toLowerCase().includes(q) 
      || f.code?.toLowerCase().includes(q) 
      || f.address?.toLowerCase().includes(q)
      || f.nppbkc?.toLowerCase().includes(q);
    return matchFilter && matchSearch;
  });

  const activeCount = factories.filter((f) => f.status === 'active').length;
  const inactiveCount = factories.filter((f) => f.status === 'inactive').length;

  // Render detail view layout
  const renderDetailView = (factory) => {
    if (!factory) return null;
    return (
      <div className="space-y-6">
        {/* Detail Header */}
        <div className="flex flex-col sm:flex-row items-center sm:items-start gap-4 p-5 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 shadow-sm relative overflow-hidden">
          {factory.logo_url ? (
            <img src={factory.logo_url} alt={factory.name} className="w-20 h-20 rounded-xl object-cover border border-gray-200 dark:border-gray-700 bg-gray-50 shrink-0" />
          ) : (
            <div className="w-20 h-20 rounded-xl bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 flex items-center justify-center border border-blue-100 dark:border-blue-900/30 shrink-0">
              <span className="material-symbols-outlined text-[36px]">domain</span>
            </div>
          )}
          <div className="text-center sm:text-left flex-1 min-w-0">
            <h3 className="text-lg font-bold text-gray-955 dark:text-white leading-tight">{factory.name}</h3>
            <p className="text-xs font-mono text-gray-400 dark:text-gray-500 mt-1 shrink-0">KODE: {factory.code}</p>
            <div className="flex flex-wrap items-center justify-center sm:justify-start gap-2 mt-3">
              <span className="text-[11px] font-bold px-2.5 py-0.5 rounded bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400 border border-blue-100 dark:border-blue-900/30">
                Golongan: {factory.golongan}
              </span>
              <span className={`inline-flex items-center gap-1 text-[11px] font-bold px-2.5 py-0.5 rounded-full border ${
                factory.status === 'active' 
                  ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 border-emerald-100 dark:border-emerald-900/30' 
                  : 'bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 border-red-100 dark:border-red-900/30'
              }`}>
                <span className={`w-1.5 h-1.5 rounded-full ${factory.status === 'active' ? 'bg-emerald-500' : 'bg-red-400'}`}></span>
                {factory.status === 'active' ? 'Aktif' : 'Tidak Aktif'}
              </span>
            </div>
          </div>
          {/* Edit Button in detail view */}
          <div className="absolute right-4 top-4">
            <button 
              onClick={() => openEdit(factory)}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg text-xs font-semibold transition-colors"
            >
              <span className="material-symbols-outlined text-[15px]">edit</span>
              Edit Info
            </button>
          </div>
        </div>

        {/* Tab Selection */}
        <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden shadow-sm">
          <div className="border-b border-gray-100 dark:border-gray-800 px-4 flex items-center gap-1 overflow-x-auto">
            {[
              { id: 'profil', label: 'Profil & Legalitas', icon: 'business_center' },
              { id: 'kontak', label: 'Kontak & Lokasi', icon: 'contact_phone' },
              { id: 'pengurus', label: 'Pemilik & Pengurus', icon: 'badge' },
              { id: 'merek', label: 'Merek Rokok', icon: 'sell' },
              { id: 'cukai', label: 'Alokasi Cukai', icon: 'receipt_long' },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveDetailTab(tab.id)}
                className={`flex items-center gap-1.5 px-4 py-3 text-xs font-semibold border-b-2 transition-colors whitespace-nowrap ${
                  activeDetailTab === tab.id 
                    ? 'border-blue-600 text-blue-600 dark:text-blue-400' 
                    : 'border-transparent text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300'
                }`}
              >
                <span className="material-symbols-outlined text-[16px]">{tab.icon}</span>
                {tab.label}
              </button>
            ))}
          </div>

          <div className="p-5">
            {activeDetailTab === 'profil' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <DetailItem label="Golongan Pabrik" value={factory.golongan} />
                <DetailItem label="NPPBKC" value={factory.nppbkc} />
                <DetailItem label="NIB" value={factory.nib} />
                <DetailItem label="NPWP Perusahaan" value={factory.npwp} />
                <DetailItem label="Alamat Lengkap" value={factory.address} className="md:col-span-2" />
              </div>
            )}

            {activeDetailTab === 'kontak' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <DetailItem label="Nomor Telepon" value={factory.phone} />
                <DetailItem label="Email Perusahaan" value={factory.email} />
                <DetailItem label="Latitude (Garis Lintang)" value={factory.latitude} />
                <DetailItem label="Longitude (Garis Bujur)" value={factory.longitude} />
                {factory.latitude && factory.longitude && (
                  <div className="md:col-span-2 pt-2">
                    <a
                      href={`https://www.google.com/maps/search/?api=1&query=${factory.latitude},${factory.longitude}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-blue-50 hover:bg-blue-100 dark:bg-blue-900/20 dark:hover:bg-blue-900/30 text-blue-700 dark:text-blue-400 rounded-lg text-xs font-semibold transition-colors"
                    >
                      <span className="material-symbols-outlined text-[16px]">map</span>
                      Buka Koordinat di Google Maps
                    </a>
                  </div>
                )}
              </div>
            )}

            {activeDetailTab === 'pengurus' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <DetailItem label="Nama Pemilik" value={factory.owner_name} />
                <DetailItem label="Nama Direktur" value={factory.director_name} />
              </div>
            )}

            {activeDetailTab === 'merek' && (
              <div>
                {loadingDetails ? (
                  <div className="py-8 text-center text-sm text-gray-400 dark:text-gray-500 flex items-center justify-center gap-2">
                    <span className="w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full animate-spin"></span>
                    Memuat daftar merek...
                  </div>
                ) : detailBrands.length === 0 ? (
                  <div className="py-8 text-center text-sm text-gray-400 dark:text-gray-500">
                    Belum ada merek terdaftar untuk pabrik ini.
                  </div>
                ) : (
                  <div className="overflow-hidden border border-gray-100 dark:border-gray-800 rounded-xl">
                    <table className="w-full text-left text-xs">
                      <thead>
                        <tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
                          <th className="px-4 py-3 font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">No</th>
                          <th className="px-4 py-3 font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Nama Merek</th>
                          <th className="px-4 py-3 font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Kategori / Jenis Produk</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
                        {detailBrands.map((b, idx) => (
                          <tr key={b.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/20 transition-colors">
                            <td className="px-4 py-2.5 text-gray-400">{idx + 1}</td>
                            <td className="px-4 py-2.5 font-semibold text-gray-900 dark:text-white">{b.name}</td>
                            <td className="px-4 py-2.5 text-gray-600 dark:text-gray-400">{b.product_types?.name || '-'}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}

            {activeDetailTab === 'cukai' && (
              <div>
                {loadingDetails ? (
                  <div className="py-8 text-center text-sm text-gray-400 dark:text-gray-500 flex items-center justify-center gap-2">
                    <span className="w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full animate-spin"></span>
                    Memuat data cukai...
                  </div>
                ) : detailAllocations.length === 0 ? (
                  <div className="py-8 text-center text-sm text-gray-400 dark:text-gray-500">
                    Belum ada data alokasi cukai terdaftar.
                  </div>
                ) : (
                  <div className="overflow-hidden border border-gray-100 dark:border-gray-800 rounded-xl">
                    <table className="w-full text-left text-xs">
                      <thead>
                        <tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
                          <th className="px-4 py-3 font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Periode</th>
                          <th className="px-4 py-3 font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider text-right">Kuota</th>
                          <th className="px-4 py-3 font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider text-right">Terpakai</th>
                          <th className="px-4 py-3 font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider text-right">Rusak</th>
                          <th className="px-4 py-3 font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider text-right">Sisa Pita Cukai</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
                        {detailAllocations.map((a) => (
                          <tr key={a.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/20 transition-colors">
                            <td className="px-4 py-3 font-medium text-gray-900 dark:text-white">{a.period}</td>
                            <td className="px-4 py-3 text-right text-gray-600 dark:text-gray-400 font-mono">{Number(a.quota).toLocaleString('id-ID')}</td>
                            <td className="px-4 py-3 text-right text-gray-600 dark:text-gray-400 font-mono">{Number(a.used).toLocaleString('id-ID')}</td>
                            <td className="px-4 py-3 text-right text-red-500 font-mono">{Number(a.damaged).toLocaleString('id-ID')}</td>
                            <td className="px-4 py-3 text-right font-bold text-emerald-600 dark:text-emerald-400 font-mono">{Number(a.remaining).toLocaleString('id-ID')}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    );
  };

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

  // Layout for Factory-Scoped users
  if (isFactoryScoped) {
    return (
      <div className="space-y-5 max-w-[1400px] mx-auto">
        <PageHeader title="Info Pabrik" description="Informasi detail dan profil mengenai pabrik rokok Anda." />
        
        {renderDetailView(selectedFactoryDetail)}

        <Modal
          open={showModal}
          onClose={closeModal}
          title="Edit Profil Pabrik"
          footer={
            <>
              <button onClick={closeModal} disabled={saving} className="px-4 py-2 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors disabled:opacity-50">Batal</button>
              <button onClick={handleSubmit} disabled={saving} className="px-5 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition-colors shadow-sm disabled:opacity-60 disabled:cursor-not-allowed">
                {saving ? 'Menyimpan...' : 'Simpan'}
              </button>
            </>
          }
        >
          {/* Form edits inside the detail component for factory scoped users */}
          <form onSubmit={handleSubmit} className="space-y-4 max-h-[70vh] overflow-y-auto pr-1">
            {/* Logo Upload Section */}
            <div className="flex flex-col items-center gap-3 mb-5 bg-gray-50 dark:bg-gray-850 p-4 rounded-xl border border-gray-150 dark:border-gray-800">
              <div className="relative">
                {logoPreview ? (
                  <img src={logoPreview} alt="Preview Logo" className="w-24 h-24 rounded-xl object-cover border border-gray-250 dark:border-gray-700 shadow-sm bg-white dark:bg-gray-900" />
                ) : (
                  <div className="w-24 h-24 rounded-xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center border-2 border-dashed border-gray-300 dark:border-gray-700 text-gray-400 dark:text-gray-500">
                    <span className="material-symbols-outlined text-[36px]">domain</span>
                  </div>
                )}
                <label className="absolute bottom-[-6px] right-[-6px] w-8 h-8 bg-blue-600 hover:bg-blue-700 text-white rounded-full flex items-center justify-center cursor-pointer transition-colors shadow-md border-2 border-white dark:border-gray-900" title="Unggah Logo">
                  <span className="material-symbols-outlined text-[16px]">photo_camera</span>
                  <input type="file" accept="image/png, image/jpeg, image/jpg, image/webp" className="hidden" onChange={handleLogoChange} />
                </label>
              </div>
              {logoPreview && (
                <button
                  type="button"
                  onClick={() => {
                    setLogoFile(null);
                    setLogoPreview('');
                    setForm({ ...form, logo_url: '' });
                  }}
                  className="text-xs font-semibold text-red-500 hover:text-red-650 transition-colors"
                >
                  Hapus Logo
                </button>
              )}
            </div>

            {/* Read-only / Admin managed details */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-semibold text-gray-400 dark:text-gray-500 mb-1.5 block">Kode Pabrik (Terkunci)</label>
                <input value={form.code} disabled className="w-full px-3 py-2 border border-gray-200 dark:border-gray-800 rounded-lg text-sm bg-gray-50 dark:bg-gray-800/60 text-gray-500 dark:text-gray-400 cursor-not-allowed" />
              </div>
              <div>
                <label className="text-xs font-semibold text-gray-400 dark:text-gray-500 mb-1.5 block">Nama Pabrik (Terkunci)</label>
                <input value={form.name} disabled className="w-full px-3 py-2 border border-gray-200 dark:border-gray-800 rounded-lg text-sm bg-gray-50 dark:bg-gray-800/60 text-gray-500 dark:text-gray-400 cursor-not-allowed" />
              </div>
            </div>

            {/* Legalitas Section */}
            <div className="border-t border-gray-100 dark:border-gray-800 pt-4">
              <h4 className="text-xs font-bold text-blue-600 dark:text-blue-400 uppercase tracking-wider mb-3">Legalitas Perusahaan</h4>
              <div className="space-y-3">
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">NPPBKC</label>
                  <input value={form.nppbkc} onChange={(e) => setForm({ ...form, nppbkc: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nomor NPPBKC" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">NIB</label>
                    <input value={form.nib} onChange={(e) => setForm({ ...form, nib: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nomor NIB" />
                  </div>
                  <div>
                    <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">NPWP Perusahaan</label>
                    <input value={form.npwp} onChange={(e) => setForm({ ...form, npwp: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nomor NPWP" />
                  </div>
                </div>
              </div>
            </div>

            {/* Kontak & Lokasi */}
            <div className="border-t border-gray-100 dark:border-gray-800 pt-4">
              <h4 className="text-xs font-bold text-blue-600 dark:text-blue-400 uppercase tracking-wider mb-3">Kontak & Lokasi</h4>
              <div className="space-y-3">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">No. Telepon</label>
                    <input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Telepon pabrik" />
                  </div>
                  <div>
                    <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Email</label>
                    <input value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} type="email" className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="email@perusahaan.com" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Latitude</label>
                    <input value={form.latitude} onChange={(e) => setForm({ ...form, latitude: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Garis lintang lokasi" />
                  </div>
                  <div>
                    <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Longitude</label>
                    <input value={form.longitude} onChange={(e) => setForm({ ...form, longitude: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Garis bujur lokasi" />
                  </div>
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Alamat Lengkap</label>
                  <textarea value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 resize-none" rows="2" placeholder="Alamat pabrik..." />
                </div>
              </div>
            </div>

            {/* Pemilik & Pengurus */}
            <div className="border-t border-gray-100 dark:border-gray-800 pt-4">
              <h4 className="text-xs font-bold text-blue-600 dark:text-blue-400 uppercase tracking-wider mb-3">Pemilik & Pengurus</h4>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Pemilik</label>
                  <input value={form.owner_name} onChange={(e) => setForm({ ...form, owner_name: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nama pemilik" />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Direktur</label>
                  <input value={form.director_name} onChange={(e) => setForm({ ...form, director_name: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nama direktur" />
                </div>
              </div>
            </div>
          </form>
        </Modal>
      </div>
    );
  }

  // Layout for Super Admins
  return (
    <div className="space-y-5 max-w-[1400px] mx-auto">
      <PageHeader title="Daftar Pabrik Terdaftar" description="Kelola dan pantau seluruh pabrik rokok di bawah APHT Sumenep.">
        <button
          onClick={openCreate}
          className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors shadow-sm"
        >
          <span className="material-symbols-outlined text-[18px]">add</span>
          Tambah Pabrik
        </button>
      </PageHeader>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard icon="domain" label="Total Pabrik" value={factories.length} color="blue" />
        <StatCard icon="check_circle" label="Aktif" value={activeCount} color="green" />
        <StatCard icon="cancel" label="Tidak Aktif" value={inactiveCount} color="red" />
      </div>

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
          <SearchBar value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Cari pabrik (nama, kode, nppbkc)..." className="md:w-96" />
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Logo & Nama</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Kode</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Golongan</th>
                <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">NPPBKC</th>
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
                    <td className="px-5 py-3 text-sm">
                      <div className="flex items-center gap-3">
                        {factory.logo_url ? (
                          <img src={factory.logo_url} alt={factory.name} className="w-8 h-8 rounded-lg object-cover bg-gray-55" />
                        ) : (
                          <div className="w-8 h-8 rounded-lg bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold">
                            <span className="material-symbols-outlined text-[16px]">domain</span>
                          </div>
                        )}
                        <span className="font-semibold text-gray-900 dark:text-white">{factory.name}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3 text-sm font-mono text-gray-500 dark:text-gray-400">{factory.code}</td>
                    <td className="px-5 py-3">
                      <span className="text-xs font-semibold px-2 py-1 rounded bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400">{factory.golongan}</span>
                    </td>
                    <td className="px-5 py-3 text-sm text-gray-500 dark:text-gray-400 font-mono">{factory.nppbkc || '-'}</td>
                    <td className="px-5 py-3">
                      <span className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full ${
                        factory.status === 'active' ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400' : 'bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400'
                      }`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${factory.status === 'active' ? 'bg-emerald-500' : 'bg-red-400'}`}></span>
                        {factory.status === 'active' ? 'Aktif' : 'Tidak Aktif'}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-center">
                      <div className="flex items-center justify-center gap-1">
                        <button onClick={() => openDetail(factory)} className="p-1.5 rounded-lg hover:bg-emerald-50 dark:hover:bg-emerald-900/20 text-gray-400 hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors" title="Lihat Detail">
                          <span className="material-symbols-outlined text-[18px]">visibility</span>
                        </button>
                        <button onClick={() => openEdit(factory)} className="p-1.5 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors" title="Edit">
                          <span className="material-symbols-outlined text-[18px]">edit</span>
                        </button>
                        <button onClick={() => setDeleteTarget(factory)} className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 dark:hover:text-red-400 transition-colors" title="Hapus">
                          <span className="material-symbols-outlined text-[18px]">delete</span>
                        </button>
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

      {/* Detail Modal (Super Admin view details modal) */}
      <Modal
        open={showDetailModal}
        onClose={() => setShowDetailModal(false)}
        title="Detail Profil Pabrik"
        footer={
          <button 
            onClick={() => setShowDetailModal(false)}
            className="px-5 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-850 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300 text-sm font-semibold rounded-lg transition-colors"
          >
            Tutup
          </button>
        }
      >
        <div className="max-h-[70vh] overflow-y-auto pr-1">
          {renderDetailView(selectedFactoryDetail)}
        </div>
      </Modal>

      {/* Edit/Create Modal (Super Admin) */}
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
        <form onSubmit={handleSubmit} className="space-y-4 max-h-[70vh] overflow-y-auto pr-1">
          {/* Logo Upload Section */}
          <div className="flex flex-col items-center gap-3 mb-5 bg-gray-50 dark:bg-gray-850 p-4 rounded-xl border border-gray-150 dark:border-gray-800">
            <div className="relative">
              {logoPreview ? (
                <img src={logoPreview} alt="Preview Logo" className="w-24 h-24 rounded-xl object-cover border border-gray-255 dark:border-gray-700 shadow-sm bg-white dark:bg-gray-900" />
              ) : (
                <div className="w-24 h-24 rounded-xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center border-2 border-dashed border-gray-300 dark:border-gray-700 text-gray-400 dark:text-gray-500">
                  <span className="material-symbols-outlined text-[36px]">domain</span>
                </div>
              )}
              <label className="absolute bottom-[-6px] right-[-6px] w-8 h-8 bg-blue-600 hover:bg-blue-700 text-white rounded-full flex items-center justify-center cursor-pointer transition-colors shadow-md border-2 border-white dark:border-gray-900" title="Unggah Logo">
                <span className="material-symbols-outlined text-[16px]">photo_camera</span>
                <input type="file" accept="image/png, image/jpeg, image/jpg, image/webp" className="hidden" onChange={handleLogoChange} />
              </label>
            </div>
            {logoPreview && (
              <button
                type="button"
                onClick={() => {
                  setLogoFile(null);
                  setLogoPreview('');
                  setForm({ ...form, logo_url: '' });
                }}
                className="text-xs font-semibold text-red-500 hover:text-red-650 transition-colors"
              >
                Hapus Logo
              </button>
            )}
          </div>

          {/* Data Perusahaan */}
          <div className="space-y-3">
            <h4 className="text-xs font-bold text-blue-600 dark:text-blue-400 uppercase tracking-wider mb-2">Data Perusahaan</h4>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Kode Pabrik <span className="text-red-500">*</span></label>
                <input
                  value={form.code}
                  onChange={(e) => setForm({ ...form, code: e.target.value })}
                  disabled={!!editing}
                  className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 disabled:opacity-60 disabled:cursor-not-allowed"
                  placeholder="FCT-012"
                  required
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Pabrik <span className="text-red-500">*</span></label>
                <input
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400"
                  placeholder="PT Nama Pabrik"
                  required
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Golongan</label>
                <select
                  value={form.golongan}
                  onChange={(e) => setForm({ ...form, golongan: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400"
                >
                  {GOLONGAN_OPTIONS.map((g) => <option key={g} value={g}>{g}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Status</label>
                <select
                  value={form.status}
                  onChange={(e) => setForm({ ...form, status: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400"
                >
                  <option value="active">Aktif</option>
                  <option value="inactive">Tidak Aktif</option>
                </select>
              </div>
            </div>
          </div>

          {/* Legalitas Section */}
          <div className="border-t border-gray-100 dark:border-gray-800 pt-4">
            <h4 className="text-xs font-bold text-blue-600 dark:text-blue-400 uppercase tracking-wider mb-3">Legalitas Perusahaan</h4>
            <div className="space-y-3">
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">NPPBKC</label>
                <input value={form.nppbkc} onChange={(e) => setForm({ ...form, nppbkc: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nomor NPPBKC" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">NIB</label>
                  <input value={form.nib} onChange={(e) => setForm({ ...form, nib: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nomor NIB" />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">NPWP Perusahaan</label>
                  <input value={form.npwp} onChange={(e) => setForm({ ...form, npwp: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nomor NPWP" />
                </div>
              </div>
            </div>
          </div>

          {/* Kontak & Lokasi */}
          <div className="border-t border-gray-100 dark:border-gray-800 pt-4">
            <h4 className="text-xs font-bold text-blue-600 dark:text-blue-400 uppercase tracking-wider mb-3">Kontak & Lokasi</h4>
            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">No. Telepon</label>
                  <input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Telepon pabrik" />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Email</label>
                  <input value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} type="email" className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="email@perusahaan.com" />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Latitude</label>
                  <input value={form.latitude} onChange={(e) => setForm({ ...form, latitude: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Garis lintang lokasi" />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Longitude</label>
                  <input value={form.longitude} onChange={(e) => setForm({ ...form, longitude: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Garis bujur lokasi" />
                </div>
              </div>
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Alamat Lengkap</label>
                <textarea value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 resize-none" rows="2" placeholder="Alamat pabrik..." />
              </div>
            </div>
          </div>

          {/* Pemilik & Pengurus */}
          <div className="border-t border-gray-100 dark:border-gray-800 pt-4">
            <h4 className="text-xs font-bold text-blue-600 dark:text-blue-400 uppercase tracking-wider mb-3">Pemilik & Pengurus</h4>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Pemilik</label>
                <input value={form.owner_name} onChange={(e) => setForm({ ...form, owner_name: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nama pemilik" />
              </div>
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Direktur</label>
                <input value={form.director_name} onChange={(e) => setForm({ ...form, director_name: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Nama direktur" />
              </div>
            </div>
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
