// Mock Supabase Database Response
export const MOCK_FACTORIES = [
  { id: 1, no: '01', name: 'PT Bintang Timur Semesta', golongan: 'SKT-I', adminName: 'Budi Santoso', status: 'active' },
  { id: 2, no: '02', name: 'CV Tembakau Emas', golongan: 'SKM-II', adminName: 'Siti Aminah', status: 'active' },
  { id: 3, no: '03', name: 'PD Sinar Makmur', golongan: 'SKT-II', adminName: 'Ahmad Riza', status: 'inactive' },
  { id: 4, no: '04', name: 'PT Gudang Daun', golongan: 'SKM-I', adminName: 'Diana Putri', status: 'active' },
  { id: 5, no: '05', name: 'CV Aroma Jaya', golongan: 'SKT-I', adminName: 'Hendro Siswanto', status: 'active' },
  // Additional factories for pagination
  { id: 6, no: '06', name: 'PT Cipta Rasa', golongan: 'SKM-II', adminName: 'Rina Kusuma', status: 'active' },
  { id: 7, no: '07', name: 'CV Sinar Harapan', golongan: 'SKT-II', adminName: 'Agus Salim', status: 'inactive' },
  { id: 8, no: '08', name: 'PT Nusantara Tobacco', golongan: 'SKM-I', adminName: 'Ratna Sari', status: 'active' },
  { id: 9, no: '09', name: 'CV Tembakau Wangi', golongan: 'SKT-I', adminName: 'Bambang Irawan', status: 'active' },
  { id: 10, no: '10', name: 'PD Karya Maju', golongan: 'SKM-II', adminName: 'Lina Marlina', status: 'inactive' },
  { id: 11, no: '11', name: 'PT Sejahtera', golongan: 'SKT-II', adminName: 'Dedi Kurniawan', status: 'active' },
];

export const MOCK_REPORTS = [
  {
    id: 1,
    factoryName: 'PR. Karaoke Damai ...',
    factoryCode: 'FCT-0928',
    period: 'Mei 2026',
    dateSent: '12 Mei 2026, 09:41',
    status: 'pending',
    statusLabel: 'Menunggu Verifikasi APHT',
    ttdDirektur: true,
    validasiAPHT: false,
  },
  {
    id: 2,
    factoryName: 'CV. Sumber Rejeki...',
    factoryCode: 'FCT-0112',
    period: 'Mei 2026',
    dateSent: '10 Mei 2026, 14:20',
    status: 'verified',
    statusLabel: 'Verified APHT',
    ttdDirektur: true,
    validasiAPHT: true,
  },
  {
    id: 3,
    factoryName: 'PT. Maju Mundur...',
    factoryCode: 'FCT-0455',
    period: 'Mei 2026',
    dateSent: '08 Mei 2026, 11:05',
    status: 'rejected',
    statusLabel: 'Data Tidak Sesuai',
    ttdDirektur: true,
    validasiAPHT: false,
  }
];

export const MOCK_PRODUCTION_LOGS = [
  { id: 101, date: '2026-05-08', sku: 'SKU-001', amount: 50000, factoryId: 1 },
  { id: 102, date: '2026-05-08', sku: 'SKU-002', amount: 35000, factoryId: 2 },
  { id: 103, date: '2026-05-07', sku: 'SKU-001', amount: 45000, factoryId: 4 },
];

export const MOCK_USER = {
  id: 'usr-1',
  name: 'Budi Santoso',
  role: 'Admin',
  email: 'admin@apht.com'
};

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

export const supabaseMock = {
  auth: {
    signIn: async (email, password) => {
      await delay(800);
      if (email === 'admin@apht.com' && password === 'password') {
        return { user: MOCK_USER, error: null };
      }
      return { user: null, error: new Error('Invalid login credentials') };
    },
    signOut: async () => {
      await delay(500);
      return { error: null };
    }
  },
  from: (table) => {
    return {
      select: async () => {
        await delay(500);
        if (table === 'factories') return { data: MOCK_FACTORIES, error: null };
        if (table === 'production_logs') return { data: MOCK_PRODUCTION_LOGS, error: null };
        if (table === 'reports') return { data: MOCK_REPORTS, error: null };
        return { data: [], error: null };
      }
    }
  }
};
