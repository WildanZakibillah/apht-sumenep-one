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
  { id: 'brands', label: 'Merek & Produk', icon: 'sell', table: 'brands' },
  { id: 'product_types', label: 'Jenis Produk', icon: 'category', table: 'product_types' },
  { id: 'regions', label: 'Wilayah', icon: 'map', table: 'regions' },
];

const PRODUCT_CATEGORIES = ['SKT', 'SKM', 'SPM'];
const GOLONGAN = ['I', 'II', 'IIIA', 'IIIB'];

const initialForm = {
  brands: { 
    name: '', product_type_id: '', factory_id: '', description: '', status: 'active',
    product_name: '', product_code: '', cigarette_type: 'SKT', variant: '',
    sticks_per_pack: 12, packs_per_slop: 10, slops_per_carton: 20, 
    hje: 0, excise_rate: 0, stock: 0, product_image: '', satuan: 'btg', bahan_kemasan: ''
  },
  product_types: { name: '', category: 'SKT', isi_per_pak: 12 },
  regions: { name: '' },
};

const DataMaster = () => {
  const [activeTab, setActiveTab] = useState('brands');
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedFactoryFilter, setSelectedFactoryFilter] = useState('all');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(initialForm.brands);
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [expandedFactories, setExpandedFactories] = useState({});

  // Lookup data for selects
  const [productTypes, setProductTypes] = useState([]);
  const [factories, setFactories] = useState([]);
  const [allBrands, setAllBrands] = useState([]);

  const { ready } = useAuth();
  const { scopeQuery, isFactoryScoped, factoryId } = useRoleAccess();
  const toast = useToast();

  const loadLookup = async () => {
    const [pt, fc, br] = await Promise.all([
      supabase.from('product_types').select('id, name, category').order('name'),
      scopeQuery(supabase.from('factories').select('id, name, nppbkc, logo_url').order('name'), 'id'),
      scopeQuery(supabase.from('brands').select('id, name, factory_id, product_type_id').order('name')),
    ]);
    if (pt.data) setProductTypes(pt.data);
    if (fc.data) setFactories(fc.data);
    if (br.data) setAllBrands(br.data);
  };

  const loadData = async () => {
    setLoading(true);
    let query;
    switch (activeTab) {
      case 'product_types': 
        query = supabase.from('product_types').select('*').order('name'); 
        break;
      case 'brands': 
        query = scopeQuery(supabase.from('brands').select('*, product_types(name), factories(name), cigarettes(*)').order('name')); 
        break;
      case 'regions': 
        query = supabase.from('regions').select('*').order('name'); 
        break;
      default: 
        query = supabase.from('product_types').select('*');
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
    setSelectedFactoryFilter('all');
    loadData();
  }, [activeTab, ready]); // eslint-disable-line

  const openCreate = (facId = null) => {
    setEditing(null);
    const defaultForm = { ...initialForm[activeTab] };
    if (activeTab === 'brands') {
      if (typeof facId === 'string') {
        defaultForm.factory_id = facId;
      } else if (isFactoryScoped) {
        defaultForm.factory_id = factoryId;
      }
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
        const prod = item.cigarettes?.[0] || {};
        setForm({ 
          name: item.name || '', 
          product_type_id: item.product_type_id || '', 
          factory_id: item.factory_id || '',
          description: item.description || '',
          status: item.status || 'active',
          product_name: prod.product_name || '',
          product_code: prod.product_code || '',
          cigarette_type: prod.cigarette_type || 'SKT',
          variant: prod.variant || '',
          sticks_per_pack: prod.sticks_per_pack !== undefined ? prod.sticks_per_pack : 12,
          packs_per_slop: prod.packs_per_slop !== undefined ? prod.packs_per_slop : 10,
          slops_per_carton: prod.slops_per_carton !== undefined ? prod.slops_per_carton : 20,
          hje: prod.hje !== undefined ? prod.hje : 0,
          excise_rate: prod.excise_rate !== undefined ? prod.excise_rate : 0,
          stock: prod.stock !== undefined ? prod.stock : 0,
          product_image: prod.product_image || '',
          satuan: prod.satuan || 'btg',
          bahan_kemasan: prod.bahan_kemasan || '',
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
    if (activeTab === 'brands') return form.name?.trim() && form.product_name?.trim() && form.factory_id && form.product_type_id && form.hje >= 0 && form.sticks_per_pack > 0;
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
      if (activeTab === 'brands') {
        const brandPayload = { 
          name: form.name.trim(), 
          product_type_id: form.product_type_id || null, 
          factory_id: form.factory_id,
          description: form.description?.trim() || null,
          status: form.status
        };
        const cigarettePayload = {
          product_name: form.product_name?.trim() || form.name.trim(),
          product_code: form.product_code?.trim() || null,
          cigarette_type: form.cigarette_type || 'SKT',
          variant: form.variant?.trim() || null,
          sticks_per_pack: parseInt(form.sticks_per_pack) || 12,
          packs_per_slop: parseInt(form.packs_per_slop) || 10,
          slops_per_carton: parseInt(form.slops_per_carton) || 20,
          hje: parseFloat(form.hje) || 0,
          excise_rate: parseFloat(form.excise_rate) || 0,
          stock: parseInt(form.stock) || 0,
          product_image: form.product_image?.trim() || null,
          satuan: form.satuan?.trim() || 'btg',
          bahan_kemasan: form.bahan_kemasan?.trim() || null,
          product_type_id: form.product_type_id,
          factory_id: form.factory_id,
          status: form.status
        };

        if (editing) {
          const brandRes = await supabase.from('brands').update(brandPayload).eq('id', editing.id);
          if (brandRes.error) throw brandRes.error;
          const checkProduct = await supabase.from('cigarettes').select('id').eq('brand_id', editing.id).maybeSingle();
          if (checkProduct.data) {
            const prodRes = await supabase.from('cigarettes').update(cigarettePayload).eq('id', checkProduct.data.id);
            if (prodRes.error) throw prodRes.error;
          } else {
            const prodRes = await supabase.from('cigarettes').insert({ brand_id: editing.id, ...cigarettePayload });
            if (prodRes.error) throw prodRes.error;
          }
          toast.success('Merek & detail rokok berhasil diperbarui');
        } else {
          const brandRes = await supabase.from('brands').insert(brandPayload).select('id').single();
          if (brandRes.error) throw brandRes.error;
          const brandId = brandRes.data.id;
          const prodRes = await supabase.from('cigarettes').insert({ brand_id: brandId, ...cigarettePayload });
          if (prodRes.error) throw prodRes.error;
          toast.success('Merek & detail rokok berhasil ditambahkan');
        }
      } else {
        let payload = {};
        switch (activeTab) {
          case 'product_types':
            payload = { name: form.name.trim(), category: form.category, isi_per_pak: parseInt(form.isi_per_pak) || 12 };
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
      }
      closeModal();
      await loadData();
      if (activeTab === 'product_types' || activeTab === 'brands') loadLookup();
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
      if (activeTab === 'product_types' || activeTab === 'brands') loadLookup();
    } catch (err) {
      toast.error(err.message);
    }
  };

  const filteredData = (() => {
    let result = data;
    if (activeTab === 'brands' && selectedFactoryFilter !== 'all') {
      result = result.filter((item) => item.factory_id === selectedFactoryFilter);
    }
    const q = search.trim().toLowerCase();
    if (!q) return result;
    return result.filter((item) => {
      switch (activeTab) {
        case 'product_types': 
          return item.name?.toLowerCase().includes(q) || item.category?.toLowerCase().includes(q);
        case 'brands': 
          return item.name?.toLowerCase().includes(q) || item.product_types?.name?.toLowerCase().includes(q) || item.factories?.name?.toLowerCase().includes(q) || item.description?.toLowerCase().includes(q);
        case 'regions': 
          return item.name?.toLowerCase().includes(q);
        default: 
          return true;
      }
    });
  })();

  const groupedBrandsData = (() => {
    if (activeTab !== 'brands') return [];
    
    // Group filtered brands by factory_id
    const brandsByFactory = {};
    filteredData.forEach(brand => {
      const fid = brand.factory_id;
      if (!brandsByFactory[fid]) {
        brandsByFactory[fid] = [];
      }
      brandsByFactory[fid].push(brand);
    });

    const result = [];
    factories.forEach(f => {
      const factoryBrands = brandsByFactory[f.id] || [];
      
      // Filter factories based on selectedFactoryFilter
      if (selectedFactoryFilter !== 'all' && selectedFactoryFilter !== f.id) {
        return;
      }
      
      // If there is search text, only show factories that have matching brands
      if (search.trim() && factoryBrands.length === 0) {
        return;
      }
      
      result.push({
        ...f,
        brands: factoryBrands
      });
    });
    return result;
  })();

  useEffect(() => {
    if (search.trim() && activeTab === 'brands') {
      const newExpanded = {};
      groupedBrandsData.forEach(f => {
        if (f.brands.length > 0) {
          newExpanded[f.id] = true;
        }
      });
      setExpandedFactories(newExpanded);
    }
  }, [search, activeTab]);

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
        if (groupedBrandsData.length === 0) {
          return <div className="px-5 py-12 text-center text-gray-400 dark:text-gray-500 text-sm">Tidak ada pabrik atau merek yang sesuai pencarian</div>;
        }
        return (
          <div className="p-6 space-y-4 bg-gray-50/50 dark:bg-gray-900/40">
            {groupedBrandsData.map((factory) => {
              const isExpanded = !!expandedFactories[factory.id];
              const toggleExpand = () => {
                setExpandedFactories(prev => ({
                  ...prev,
                  [factory.id]: !prev[factory.id]
                }));
              };

              return (
                <div key={factory.id} className="bg-white dark:bg-gray-800 rounded-xl border border-gray-150 dark:border-gray-800 shadow-sm overflow-hidden transition-all duration-200 hover:shadow-md">
                  {/* Factory Header Panel */}
                  <div 
                    onClick={toggleExpand}
                    className="p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 cursor-pointer select-none hover:bg-gray-50/30 dark:hover:bg-gray-800/30 transition-colors"
                  >
                    <div className="flex items-center gap-3.5">
                      {/* Logo or Icon */}
                      <div className="w-12 h-12 rounded-lg bg-blue-50 dark:bg-blue-900/15 border border-blue-100/50 dark:border-blue-900/30 flex items-center justify-center overflow-hidden shrink-0">
                        {factory.logo_url ? (
                          <img src={factory.logo_url} alt={factory.name} className="w-full h-full object-cover" />
                        ) : (
                          <span className="material-symbols-outlined text-[26px] text-blue-600 dark:text-blue-400">domain</span>
                        )}
                      </div>
                      
                      {/* Name & Metadata */}
                      <div>
                        <h3 className="font-bold text-gray-950 dark:text-white text-base flex items-center gap-2 flex-wrap">
                          {factory.name}
                          <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-blue-50 dark:bg-blue-950 text-blue-700 dark:text-blue-400">
                            {factory.brands.length} Merek
                          </span>
                        </h3>
                        {factory.nppbkc && (
                          <p className="text-xs text-gray-400 dark:text-gray-500 font-medium mt-0.5">
                            NPPBKC: <span className="font-semibold text-gray-500 dark:text-gray-400">{factory.nppbkc}</span>
                          </p>
                        )}
                      </div>
                    </div>

                    {/* Actions on the right */}
                    <div className="flex items-center gap-3 self-end sm:self-center" onClick={(e) => e.stopPropagation()}>
                      <button 
                        onClick={() => openCreate(factory.id)} 
                        className="flex items-center gap-1 px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-xs font-semibold transition-all shadow-sm"
                      >
                        <span className="material-symbols-outlined text-[15px] font-bold">add</span>
                        Tambah Merek
                      </button>

                      <button 
                        onClick={toggleExpand}
                        className="p-1.5 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-100 dark:hover:bg-gray-750 text-gray-400 dark:text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
                      >
                        <span className={`material-symbols-outlined text-[20px] transition-transform duration-200 block ${isExpanded ? 'rotate-180' : ''}`}>
                          expand_more
                        </span>
                      </button>
                    </div>
                  </div>

                  {/* Expanded Brands/Products Subtable */}
                  {isExpanded && (
                    <div className="border-t border-gray-100 dark:border-gray-800 overflow-x-auto">
                      {factory.brands.length === 0 ? (
                        <div className="px-5 py-8 text-center text-gray-400 dark:text-gray-500 text-sm">
                          Belum ada merek terdaftar untuk pabrik ini.
                          <button 
                            onClick={() => openCreate(factory.id)} 
                            className="text-blue-600 dark:text-blue-400 hover:underline font-semibold ml-1.5"
                          >
                            Tambah Sekarang
                          </button>
                        </div>
                      ) : (
                        <table className="w-full text-left">
                          <thead>
                            <tr className="bg-gray-50/80 dark:bg-gray-800/40 border-b border-gray-100 dark:border-gray-800">
                              <th className={`${thClass} pl-6`}>No</th>
                              <th className={thClass}>Nama Produk & Merek</th>
                              <th className={thClass}>Kode & Varian</th>
                              <th className={thClass}>Jenis</th>
                              <th className={thClass}>HJE & Cukai</th>
                              <th className={thClass}>Kemasan (Struktur)</th>
                              <th className={thClass}>Stok</th>
                              <th className={thClass}>Status</th>
                              <th className={`${thClass} text-center pr-6`}>Aksi</th>
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-gray-50 dark:divide-gray-800/50">
                            {factory.brands.map((item, index) => {
                              const prod = item.cigarettes?.[0] || {};
                              return (
                                <tr key={item.id} className="hover:bg-gray-50/40 dark:hover:bg-gray-800/20 transition-colors">
                                  <td className={`${tdClass} pl-6 text-gray-400 dark:text-gray-500`}>{index + 1}</td>
                                  <td className={tdClass}>
                                    <div className="flex items-center gap-3">
                                      {prod.product_image && (
                                        <img src={prod.product_image} alt={prod.product_name} className="w-8 h-8 rounded object-cover border border-gray-100 dark:border-gray-700 bg-white" />
                                      )}
                                      <div>
                                        <div className="font-semibold text-gray-900 dark:text-white">{prod.product_name || item.name}</div>
                                        <div className="text-[11px] text-gray-400 dark:text-gray-500">Merek: {item.name}</div>
                                        {item.description && (
                                          <div className="text-[10px] text-gray-400 dark:text-gray-500 font-normal italic mt-0.5">
                                            "{item.description}"
                                          </div>
                                        )}
                                      </div>
                                    </div>
                                  </td>
                                  <td className={tdClass}>
                                    <div>
                                      <div className="font-medium text-gray-800 dark:text-gray-200 text-xs">{prod.product_code || '-'}</div>
                                      {prod.variant && <div className="text-[10px] text-gray-400 dark:text-gray-500">Var: {prod.variant}</div>}
                                    </div>
                                  </td>
                                  <td className={`${tdClass} text-gray-600 dark:text-gray-400 font-medium`}>
                                    <span className="text-xs font-semibold px-2 py-0.5 rounded bg-slate-50 dark:bg-slate-900 text-slate-700 dark:text-slate-400">
                                      {prod.cigarette_type || item.product_types?.category || '-'}
                                    </span>
                                  </td>
                                  <td className={tdClass}>
                                    <div>
                                      <div className="font-semibold text-gray-900 dark:text-white">Rp {Number(prod.hje || 0).toLocaleString('id-ID')}</div>
                                      <div className="text-[10px] text-gray-400 dark:text-gray-500">Cukai: Rp {Number(prod.excise_rate || 0).toLocaleString('id-ID')}/btg</div>
                                    </div>
                                  </td>
                                  <td className={tdClass}>
                                    <div className="text-xs text-gray-700 dark:text-gray-300">
                                      <div className="font-medium">{prod.sticks_per_pack || 0} {prod.satuan || 'btg'}/pak</div>
                                      <div className="text-[10px] text-gray-400 dark:text-gray-500">{prod.packs_per_slop || 10} pak/slop • {prod.slops_per_carton || 20} slop/ktn</div>
                                      {prod.bahan_kemasan && <div className="text-[10px] text-gray-400 dark:text-gray-500 italic">Bahan: {prod.bahan_kemasan}</div>}
                                    </div>
                                  </td>
                                  <td className={`${tdClass} text-gray-900 dark:text-white font-bold`}>
                                    {(prod.stock || 0).toLocaleString('id-ID')}
                                  </td>
                                  <td className={tdClass}>
                                    <span className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2 py-0.5 rounded-full ${
                                      item.status === 'active' 
                                        ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400' 
                                        : 'bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400'
                                    }`}>
                                      <span className={`w-1.5 h-1.5 rounded-full ${item.status === 'active' ? 'bg-emerald-500' : 'bg-red-400'}`}></span>
                                      {item.status === 'active' ? 'Aktif' : 'Tidak Aktif'}
                                    </span>
                                  </td>
                                  <td className={`${tdClass} text-center pr-6`}>
                                    <div className="flex items-center justify-center gap-1">
                                      <button 
                                        onClick={() => openEdit(item)} 
                                        className="p-1.5 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors" 
                                        title="Edit"
                                      >
                                        <span className="material-symbols-outlined text-[18px]">edit</span>
                                      </button>
                                      <button 
                                        onClick={() => setDeleteTarget(item)} 
                                        className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 dark:hover:text-red-400 transition-colors" 
                                        title="Hapus"
                                      >
                                        <span className="material-symbols-outlined text-[18px]">delete</span>
                                      </button>
                                    </div>
                                  </td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
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
            <div className="p-3 bg-blue-50/50 dark:bg-blue-900/10 rounded-lg border border-blue-100/50 dark:border-blue-900/20 mb-2">
              <h4 className="text-xs font-bold text-blue-700 dark:text-blue-400 uppercase tracking-wider mb-2 flex items-center gap-1">
                <span className="material-symbols-outlined text-[16px]">sell</span>
                Identitas Merek (Brand)
              </h4>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Merek <span className="text-red-500">*</span></label>
                  <input value={form.name} onChange={(e) => {
                    const val = e.target.value;
                    setForm(prev => ({ 
                      ...prev, 
                      name: val,
                      product_name: prev.product_name ? prev.product_name : val // Auto-fill product_name
                    }));
                  }} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 focus:ring-1" placeholder="Misal: Gudang Garam" required />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Pabrik <span className="text-red-500">*</span></label>
                  <select value={form.factory_id} onChange={(e) => setForm({ ...form, factory_id: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required disabled={isFactoryScoped}>
                    <option value="">Pilih pabrik...</option>
                    {factories.map((f) => <option key={f.id} value={f.id}>{f.name}</option>)}
                  </select>
                </div>
              </div>
              <div className="mt-3">
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Jenis Master Produk <span className="text-red-500">*</span></label>
                <select value={form.product_type_id} onChange={(e) => {
                  const ptId = e.target.value;
                  const selectedPt = productTypes.find(p => p.id === ptId);
                  setForm(prev => ({
                    ...prev,
                    product_type_id: ptId,
                    cigarette_type: selectedPt ? selectedPt.category : prev.cigarette_type
                  }));
                }} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required>
                  <option value="">Pilih jenis...</option>
                  {productTypes.map((p) => <option key={p.id} value={p.id}>{p.name} ({p.category})</option>)}
                </select>
              </div>
            </div>

            <div className="p-3 bg-slate-50/50 dark:bg-slate-900/10 rounded-lg border border-slate-150 dark:border-slate-800 mb-2">
              <h4 className="text-xs font-bold text-slate-700 dark:text-slate-400 uppercase tracking-wider mb-2 flex items-center gap-1">
                <span className="material-symbols-outlined text-[16px]">pageview</span>
                Detail Varian & Kode
              </h4>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Produk (Spesifik) <span className="text-red-500">*</span></label>
                  <input value={form.product_name} onChange={(e) => setForm({ ...form, product_name: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Misal: Gudang Garam Merah" required />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Kode Produk</label>
                  <input value={form.product_code} onChange={(e) => setForm({ ...form, product_code: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Misal: GGM-01" />
                </div>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-3">
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Varian</label>
                  <input value={form.variant} onChange={(e) => setForm({ ...form, variant: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Misal: Gold, Menthol, Filter" />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Jenis Rokok</label>
                  <select value={form.cigarette_type} onChange={(e) => setForm({ ...form, cigarette_type: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400">
                    <option value="SKT">SKT (Sigaret Kretek Tangan)</option>
                    <option value="SKM">SKM (Sigaret Kretek Mesin)</option>
                    <option value="SPM">SPM (Sigaret Putih Mesin)</option>
                  </select>
                </div>
              </div>
            </div>

            <div className="p-3 bg-emerald-50/20 dark:bg-emerald-950/10 rounded-lg border border-emerald-100/50 dark:border-emerald-900/20 mb-2">
              <h4 className="text-xs font-bold text-emerald-700 dark:text-emerald-400 uppercase tracking-wider mb-2 flex items-center gap-1">
                <span className="material-symbols-outlined text-[16px]">payments</span>
                Harga & Tarif Cukai
              </h4>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">HJE (Harga Jual Eceran) <span className="text-red-500">*</span></label>
                  <input type="number" min="0" step="0.01" value={form.hje} onChange={(e) => setForm({ ...form, hje: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Tarif Cukai per Batang (Rp) <span className="text-red-500">*</span></label>
                  <input type="number" min="0" step="0.01" value={form.excise_rate} onChange={(e) => setForm({ ...form, excise_rate: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required />
                </div>
              </div>
            </div>

            <div className="p-3 bg-orange-50/20 dark:bg-orange-950/10 rounded-lg border border-orange-100/50 dark:border-orange-900/20 mb-2">
              <h4 className="text-xs font-bold text-orange-700 dark:text-orange-400 uppercase tracking-wider mb-2 flex items-center gap-1">
                <span className="material-symbols-outlined text-[16px]">inventory</span>
                Struktur Kemasan & Stok
              </h4>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Isi per Pak (Batang) <span className="text-red-500">*</span></label>
                  <input type="number" min="1" value={form.sticks_per_pack} onChange={(e) => setForm({ ...form, sticks_per_pack: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" required />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Bungkus per Slop</label>
                  <input type="number" min="1" value={form.packs_per_slop} onChange={(e) => setForm({ ...form, packs_per_slop: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Slop per Karton</label>
                  <input type="number" min="1" value={form.slops_per_carton} onChange={(e) => setForm({ ...form, slops_per_carton: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" />
                </div>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mt-3">
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Stok Tersedia</label>
                  <input type="number" min="0" value={form.stock} onChange={(e) => setForm({ ...form, stock: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Satuan</label>
                  <input value={form.satuan} onChange={(e) => setForm({ ...form, satuan: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="btg" />
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Bahan Kemasan</label>
                  <input value={form.bahan_kemasan} onChange={(e) => setForm({ ...form, bahan_kemasan: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="Misal: Kertas, Plastik" />
                </div>
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">URL Foto Produk</label>
              <input value={form.product_image} onChange={(e) => setForm({ ...form, product_image: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="https://example.com/image.jpg" />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 border-t border-gray-100 dark:border-gray-800 pt-4">
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Status Merek</label>
                <select value={form.status} onChange={(e) => setForm({ ...form, status: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400">
                  <option value="active">Aktif</option>
                  <option value="inactive">Tidak Aktif</option>
                </select>
              </div>
              <div>
                <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Deskripsi Merek</label>
                <textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 resize-none" rows="1" placeholder="Deskripsi rasa atau detail merek..." />
              </div>
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
      <PageHeader title="Konfigurasi Data Referensi" description="Kelola data referensi sistem: merek rokok, produk, jenis produk, dan wilayah.">
        <button onClick={() => openCreate()} className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors shadow-sm">
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

        <div className="p-4 border-b border-gray-50 dark:border-gray-800 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <SearchBar value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Cari data..." className="md:w-96" />
          
          {activeTab === 'brands' && !isFactoryScoped && (
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">Filter Pabrik:</span>
              <select
                value={selectedFactoryFilter}
                onChange={(e) => setSelectedFactoryFilter(e.target.value)}
                className="px-3 py-1.5 border border-gray-200 dark:border-gray-700 rounded-lg text-xs bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 focus:ring-1 focus:ring-blue-400"
              >
                <option value="all">Semua Pabrik</option>
                {factories.map((f) => (
                  <option key={f.id} value={f.id}>{f.name}</option>
                ))}
              </select>
            </div>
          )}
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
