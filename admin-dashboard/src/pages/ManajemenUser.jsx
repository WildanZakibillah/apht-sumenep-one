import React, { useState, useEffect } from 'react';
import { supabase, supabaseAdmin } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';
import { useToast } from '../hooks/useToast';
import PageHeader from '../components/shared/PageHeader';
import StatCard from '../components/shared/StatCard';
import { SkeletonCard, SkeletonTable } from '../components/shared/Skeleton';
import Modal from '../components/shared/Modal';
import ConfirmDialog from '../components/shared/ConfirmDialog';
import SearchBar from '../components/shared/SearchBar';

const ROLES = [
  { value: 'super_admin', label: 'Super Admin' },
  { value: 'admin_pabrik', label: 'Admin Pabrik' },
  { value: 'staf_lapangan', label: 'Staf Lapangan' },
  { value: 'direktur', label: 'Direktur' },
];

const emptyForm = { full_name: '', email: '', password: '', phone: '', role: 'admin_pabrik', factory_id: '', is_active: true };

const ManajemenUser = () => {
  const [users, setUsers] = useState([]);
  const [factories, setFactories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [filterRole, setFilterRole] = useState('all');
  const [search, setSearch] = useState('');
  const [deleteTarget, setDeleteTarget] = useState(null);
  const { ready } = useAuth();
  const toast = useToast();

  const loadUsers = async () => {
    setLoading(true);
    const [u, f] = await Promise.all([
      supabase.from('profiles').select('*, factories(name, code)').order('created_at', { ascending: false }),
      supabase.from('factories').select('id, name, code').order('name'),
    ]);
    if (u.error) toast.error('Gagal memuat user: ' + u.error.message);
    else if (u.data) setUsers(u.data);
    if (f.data) setFactories(f.data);
    setLoading(false);
  };

  useEffect(() => {
    if (ready) loadUsers();
  }, [ready]); // eslint-disable-line

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setShowModal(true);
  };

  const openEdit = (u) => {
    setEditing(u);
    setForm({
      full_name: u.full_name || '',
      email: u.email || '',
      password: '',
      phone: u.phone || '',
      role: u.role || 'admin_pabrik',
      factory_id: u.factory_id || '',
      is_active: !!u.is_active,
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
    if (!form.full_name.trim() || !form.email.trim()) {
      toast.warning('Nama dan email wajib diisi');
      return;
    }
    setSaving(true);
    try {
      if (editing) {
        // Update existing user profile
        const payload = {
          full_name: form.full_name.trim(),
          email: form.email.trim(),
          phone: form.phone.trim() || null,
          role: form.role,
          factory_id: form.factory_id || null,
          is_active: form.is_active,
        };
        const { error } = await supabase.from('profiles').update(payload).eq('id', editing.id);
        if (error) throw error;

        // Update password if provided
        if (form.password && form.password.length >= 6 && supabaseAdmin) {
          const { error: pwError } = await supabaseAdmin.auth.admin.updateUserById(editing.id, {
            password: form.password,
          });
          if (pwError) {
            toast.warning('Profil diperbarui, tapi gagal ubah password: ' + pwError.message);
          }
        }

        toast.success('User berhasil diperbarui');
      } else {
        // Create new user
        if (!form.password || form.password.length < 6) {
          toast.warning('Password minimal 6 karakter');
          setSaving(false);
          return;
        }

        if (!supabaseAdmin) {
          toast.error('Service Role Key belum dikonfigurasi. Tambahkan VITE_SUPABASE_SERVICE_ROLE_KEY di file .env');
          setSaving(false);
          return;
        }

        // 1. Create auth user via admin API (with display name metadata)
        const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
          email: form.email.trim(),
          password: form.password,
          email_confirm: true,
          user_metadata: {
            full_name: form.full_name.trim(),
          },
        });
        if (authError) throw authError;

        // 2. Update/insert profile with role and factory (use admin client to bypass RLS)
        const userId = authData.user.id;
        const { error: profileError } = await supabaseAdmin.from('profiles').upsert({
          id: userId,
          full_name: form.full_name.trim(),
          email: form.email.trim(),
          phone: form.phone.trim() || null,
          role: form.role,
          factory_id: form.factory_id || null,
          is_active: form.is_active,
        });
        if (profileError) throw profileError;

        toast.success('User baru berhasil dibuat');
      }
      closeModal();
      await loadUsers();
    } catch (err) {
      toast.error(err.message || 'Gagal menyimpan');
    } finally {
      setSaving(false);
    }
  };

  const handleToggleActive = async (u) => {
    try {
      const { error } = await supabase.from('profiles').update({ is_active: !u.is_active }).eq('id', u.id);
      if (error) throw error;
      toast.success(`User ${!u.is_active ? 'diaktifkan' : 'dinonaktifkan'}`);
      await loadUsers();
    } catch (err) {
      toast.error(err.message);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      const userId = deleteTarget.id;
      const adminClient = supabaseAdmin || supabase;

      // 1. Delete notifications
      await adminClient.from('notifications').delete().eq('user_id', userId);

      // 2. Delete profile
      const { error: profileError } = await adminClient.from('profiles').delete().eq('id', userId);
      if (profileError) throw profileError;

      // 3. Try to delete auth user (may fail due to Supabase internal trigger)
      if (supabaseAdmin) {
        try {
          await supabaseAdmin.auth.admin.deleteUser(userId);
        } catch (authErr) {
          // Auth deletion failed - user can be removed manually from Supabase Dashboard
          console.warn('Auth user not deleted (can be removed from Supabase Dashboard):', authErr.message);
        }
      }

      toast.success('User berhasil dihapus dari sistem.');
      setDeleteTarget(null);
      await loadUsers();
    } catch (err) {
      toast.error(err.message);
    }
  };

  const filteredUsers = users.filter((u) => {
    const matchRole = filterRole === 'all' || u.role === filterRole;
    const q = search.trim().toLowerCase();
    const matchSearch = !q
      || u.full_name?.toLowerCase().includes(q)
      || u.email?.toLowerCase().includes(q)
      || u.factories?.name?.toLowerCase().includes(q);
    return matchRole && matchSearch;
  });
  const activeCount = users.filter((u) => u.is_active).length;

  const getRoleBadge = (role) => {
    const map = {
      super_admin: 'bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-400',
      admin_pabrik: 'bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400',
      staf_lapangan: 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400',
      direktur: 'bg-orange-50 dark:bg-orange-900/20 text-orange-700 dark:text-orange-400',
    };
    const labels = { super_admin: 'Super Admin', admin_pabrik: 'Admin Pabrik', staf_lapangan: 'Staf Lapangan', direktur: 'Direktur' };
    return <span className={`text-[11px] font-bold px-2.5 py-1 rounded-full ${map[role] || 'bg-gray-50 dark:bg-gray-800 text-gray-600 dark:text-gray-400'}`}>{labels[role] || role}</span>;
  };

  if (loading && users.length === 0) {
    return (
      <div className="space-y-5 max-w-[1400px] mx-auto">
        <PageHeader title="Daftar Pengguna Sistem" description="Kelola akses dan peran pengguna dalam sistem." />
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">{Array.from({ length: 3 }).map((_, i) => <SkeletonCard key={i} />)}</div>
        <SkeletonTable rows={5} cols={4} />
      </div>
    );
  }

  return (
    <div className="space-y-5 max-w-[1400px] mx-auto">
      <PageHeader title="Daftar Pengguna Sistem" description="Kelola akses dan peran pengguna dalam sistem.">
        <button onClick={openCreate} className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors shadow-sm">
          <span className="material-symbols-outlined text-[18px]">person_add</span>Tambah User
        </button>
      </PageHeader>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard icon="people" label="Total User" value={users.length} color="blue" />
        <StatCard icon="verified_user" label="Aktif" value={activeCount} color="green" />
        <StatCard icon="block" label="Tidak Aktif" value={users.length - activeCount} color="red" />
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
        <div className="p-4 border-b border-gray-100 dark:border-gray-800 flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div className="flex items-center gap-2 flex-wrap">
            {[{ id: 'all', label: 'Semua' }, ...ROLES.map((r) => ({ id: r.value, label: r.label }))].map((f) => (
              <button key={f.id} onClick={() => setFilterRole(f.id)} className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${filterRole === f.id ? 'bg-blue-600 text-white' : 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700'}`}>{f.label}</button>
            ))}
          </div>
          <SearchBar value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Cari nama, email, pabrik..." className="md:w-96" />
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead><tr className="bg-gray-50 dark:bg-gray-800/50 border-b border-gray-100 dark:border-gray-800">
              <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">User</th>
              <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Role</th>
              <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Pabrik</th>
              <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase">Status</th>
              <th className="px-5 py-3 text-[11px] font-bold text-gray-400 dark:text-gray-500 uppercase text-center">Aksi</th>
            </tr></thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {filteredUsers.length === 0 ? (
                <tr><td colSpan="5" className="px-5 py-12 text-center text-gray-400 dark:text-gray-500 text-sm">Tidak ada user</td></tr>
              ) : filteredUsers.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-lg bg-blue-600 text-white flex items-center justify-center font-bold text-[13px] shrink-0">{user.full_name?.charAt(0) || '?'}</div>
                      <div>
                        <p className="text-sm font-semibold text-gray-900 dark:text-white">{user.full_name}</p>
                        <p className="text-[11px] text-gray-400 dark:text-gray-500">{user.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-3.5">{getRoleBadge(user.role)}</td>
                  <td className="px-5 py-3.5 text-sm text-gray-600 dark:text-gray-400">{user.factories?.name || '-'}</td>
                  <td className="px-5 py-3.5">
                    <span className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full ${user.is_active ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400' : 'bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400'}`}>
                      <span className={`w-1.5 h-1.5 rounded-full ${user.is_active ? 'bg-emerald-500' : 'bg-red-400'}`}></span>
                      {user.is_active ? 'Aktif' : 'Tidak Aktif'}
                    </span>
                  </td>
                  <td className="px-5 py-3.5 text-center">
                    <div className="flex items-center justify-center gap-1">
                      <button onClick={() => openEdit(user)} className="p-1.5 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors" title="Edit"><span className="material-symbols-outlined text-[18px]">edit</span></button>
                      <button onClick={() => handleToggleActive(user)} className="p-1.5 rounded-lg hover:bg-orange-50 dark:hover:bg-orange-900/20 text-gray-400 hover:text-orange-500 dark:hover:text-orange-400 transition-colors" title={user.is_active ? 'Nonaktifkan' : 'Aktifkan'}><span className="material-symbols-outlined text-[18px]">{user.is_active ? 'block' : 'check_circle'}</span></button>
                      <button onClick={() => setDeleteTarget(user)} className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 dark:hover:text-red-400 transition-colors" title="Hapus profil"><span className="material-symbols-outlined text-[18px]">delete</span></button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="px-5 py-3 border-t border-gray-100 dark:border-gray-800 flex items-center justify-between text-sm text-gray-500 dark:text-gray-400">
          <span>{filteredUsers.length} dari {users.length} user</span>
        </div>
      </div>

      <Modal
        open={showModal}
        onClose={closeModal}
        title={editing ? 'Edit User' : 'Tambah User Baru'}
        footer={
          <>
            <button onClick={closeModal} disabled={saving} className="px-4 py-2 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg disabled:opacity-50">Batal</button>
            <button onClick={handleSubmit} disabled={saving} className="px-5 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition-colors shadow-sm disabled:opacity-60">
              {saving ? 'Menyimpan...' : 'Simpan'}
            </button>
          </>
        }
      >
        {!editing && !supabaseAdmin && (
          <div className="mb-4 p-3 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-900/40 text-xs text-amber-800 dark:text-amber-300">
            <p className="font-semibold mb-1">⚠ Service Role Key belum dikonfigurasi</p>
            <p>Tambahkan <code className="bg-amber-100 dark:bg-amber-900/40 px-1 rounded">VITE_SUPABASE_SERVICE_ROLE_KEY</code> di file .env untuk mengaktifkan fitur tambah user.</p>
          </div>
        )}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Nama Lengkap <span className="text-red-500">*</span></label>
            <input value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 focus:ring-1 focus:ring-blue-400" placeholder="Nama lengkap" required />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Email <span className="text-red-500">*</span></label>
              <input
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                disabled={!!editing}
                className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 focus:ring-1 focus:ring-blue-400 disabled:opacity-60 disabled:cursor-not-allowed"
                placeholder="email@apht.com"
                type="email"
                required
              />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">
                {editing ? 'Password Baru' : 'Password'} {!editing && <span className="text-red-500">*</span>}
              </label>
              <input
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
                className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400 focus:ring-1 focus:ring-blue-400"
                placeholder={editing ? 'Kosongkan jika tidak diubah' : 'Min. 6 karakter'}
                type="password"
                minLength={editing ? 0 : 6}
                required={!editing}
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">No. HP</label>
              <input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400" placeholder="08..." />
            </div>
            <div>
              <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Role</label>
              <select value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400">
                {ROLES.map((r) => <option key={r.value} value={r.value}>{r.label}</option>)}
              </select>
            </div>
          </div>
          <div>
            <label className="text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5 block">Pabrik</label>
            <select value={form.factory_id} onChange={(e) => setForm({ ...form, factory_id: e.target.value })} className="w-full px-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:border-blue-400">
              <option value="">— Tidak ditugaskan —</option>
              {factories.map((f) => <option key={f.id} value={f.id}>{f.name}</option>)}
            </select>
          </div>
          <div className="flex items-center gap-2">
            <input id="is_active" type="checkbox" checked={form.is_active} onChange={(e) => setForm({ ...form, is_active: e.target.checked })} className="w-4 h-4 rounded text-blue-600 focus:ring-blue-400" />
            <label htmlFor="is_active" className="text-sm text-gray-700 dark:text-gray-300">Akun aktif</label>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDelete}
        title="Hapus User?"
        message={`Hapus user "${deleteTarget?.full_name}" beserta akun loginnya? Data pabrik tetap tersimpan.`}
        confirmText="Ya, Hapus"
        cancelText="Batal"
        variant="danger"
        icon="delete"
      />
    </div>
  );
};

export default ManajemenUser;
