import React, { useState } from 'react';
import { useNotifications } from '../hooks/useNotifications';
import PageHeader from '../components/shared/PageHeader';
import SearchBar from '../components/shared/SearchBar';

const formatTime = (dateStr) => {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'Baru saja';
  if (mins < 60) return `${mins}m lalu`;
  const hrs = Math.floor(diff / 3600000);
  if (hrs < 24) return `${hrs}j lalu`;
  const days = Math.floor(diff / 86400000);
  if (days < 7) return `${days}h lalu`;
  return new Date(dateStr).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' });
};

const getTypeIcon = (type) => {
  switch (type) {
    case 'success': return { icon: 'check_circle', color: 'text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20' };
    case 'error': return { icon: 'error', color: 'text-red-500 dark:text-red-400 bg-red-50 dark:bg-red-900/20' };
    case 'warning': return { icon: 'warning', color: 'text-orange-500 dark:text-orange-400 bg-orange-50 dark:bg-orange-900/20' };
    default: return { icon: 'info', color: 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20' };
  }
};

const Notifikasi = () => {
  const { notifications, unreadCount, loading, markAsRead, markAllAsRead, deleteNotification, deleteAllNotifications } = useNotifications();
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');

  const filtered = notifications.filter((n) => {
    const matchFilter = filter === 'unread' ? !n.is_read : true;
    const q = search.trim().toLowerCase();
    const matchSearch = !q
      || n.title?.toLowerCase().includes(q)
      || n.message?.toLowerCase().includes(q);
    return matchFilter && matchSearch;
  });

  return (
    <div className="space-y-5 max-w-[900px] mx-auto">
      <PageHeader title="Pusat Notifikasi Sistem" description={`${unreadCount} belum dibaca dari ${notifications.length} total`}>
        <div className="flex items-center gap-3">
          {unreadCount > 0 && (
            <button onClick={markAllAsRead} className="text-sm font-medium text-blue-600 dark:text-blue-400 hover:text-blue-700 transition-colors">
              Baca Semua
            </button>
          )}
          {notifications.length > 0 && (
            <button onClick={deleteAllNotifications} className="text-sm font-medium text-red-500 dark:text-red-400 hover:text-red-600 transition-colors">
              Hapus Semua
            </button>
          )}
        </div>
      </PageHeader>

      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div className="flex items-center gap-2">
          {[{ id: 'all', label: `Semua (${notifications.length})` }, { id: 'unread', label: `Belum Dibaca (${unreadCount})` }].map((f) => (
            <button
              key={f.id}
              onClick={() => setFilter(f.id)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${filter === f.id ? 'bg-blue-600 text-white' : 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700'}`}
            >
              {f.label}
            </button>
          ))}
        </div>
        <SearchBar value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Cari notifikasi..." className="md:w-96" />
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden divide-y divide-gray-50 dark:divide-gray-800">
        {loading ? (
          <div className="px-5 py-12 text-center text-gray-400 dark:text-gray-500 text-sm">Memuat...</div>
        ) : filtered.length === 0 ? (
          <div className="px-5 py-12 text-center">
            <span className="material-symbols-outlined text-gray-300 dark:text-gray-600 text-[40px]">notifications_off</span>
            <p className="text-gray-500 dark:text-gray-400 mt-2 text-sm">{search || filter === 'unread' ? 'Tidak ada notifikasi sesuai filter' : 'Tidak ada notifikasi'}</p>
          </div>
        ) : (
          filtered.map((notif) => {
            const typeStyle = getTypeIcon(notif.type);
            return (
              <div
                key={notif.id}
                className={`px-5 py-4 flex items-start gap-4 hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors cursor-pointer ${!notif.is_read ? 'bg-blue-50/30 dark:bg-blue-900/5' : ''}`}
                onClick={() => !notif.is_read && markAsRead(notif.id)}
              >
                <div className={`w-9 h-9 rounded-lg flex items-center justify-center shrink-0 ${typeStyle.color}`}>
                  <span className="material-symbols-outlined text-[18px]">{notif.icon || typeStyle.icon}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <p className={`text-sm ${!notif.is_read ? 'font-bold text-gray-900 dark:text-white' : 'font-medium text-gray-700 dark:text-gray-300'}`}>{notif.title}</p>
                    <div className="flex items-center gap-2 shrink-0">
                      {!notif.is_read && (
                        <>
                          <span className="w-2 h-2 rounded-full bg-blue-600 mt-1.5"></span>
                          <button 
                            onClick={(e) => { e.stopPropagation(); markAsRead(notif.id); }}
                            className="text-gray-400 hover:text-blue-500 transition-colors p-1 rounded hover:bg-blue-50 dark:hover:bg-blue-900/20"
                            title="Tandai dibaca"
                          >
                            <span className="material-symbols-outlined text-[16px]">check</span>
                          </button>
                        </>
                      )}
                      <button 
                        onClick={(e) => { e.stopPropagation(); deleteNotification(notif.id); }}
                        className="text-gray-400 hover:text-red-500 transition-colors p-1 rounded hover:bg-red-50 dark:hover:bg-red-900/20"
                        title="Hapus notifikasi"
                      >
                        <span className="material-symbols-outlined text-[16px]">delete</span>
                      </button>
                    </div>
                  </div>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 line-clamp-2">{notif.message}</p>
                  <p className="text-[11px] text-gray-400 dark:text-gray-500 mt-1.5">{formatTime(notif.created_at)}</p>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};

export default Notifikasi;
