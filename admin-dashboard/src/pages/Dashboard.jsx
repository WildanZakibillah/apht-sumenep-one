import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useRoleAccess } from '../hooks/useRoleAccess';
import MainLayout from '../components/layout/MainLayout';
import Beranda from './Beranda';
import DataPabrik from './DataPabrik';
import DataProduksi from './DataProduksi';
import PantauCukai from './PantauCukai';
import PengajuanCukai from './PengajuanCukai';
import DataPemasaran from './DataPemasaran';
import DataMaster from './DataMaster';
import DataStok from './DataStok';
import ManajemenUser from './ManajemenUser';
import PengaturanAkun from './PengaturanAkun';

const Dashboard = () => {
  const { isFactoryScoped } = useRoleAccess();

  return (
    <MainLayout>
      <Routes>
        <Route path="/" element={<Beranda />} />
        {!isFactoryScoped && <Route path="/data-pabrik" element={<DataPabrik />} />}
        <Route path="/data-produksi" element={<DataProduksi />} />
        <Route path="/pantau-cukai" element={<PantauCukai />} />
        <Route path="/pengajuan-cukai" element={<PengajuanCukai />} />
        <Route path="/data-pemasaran" element={<DataPemasaran />} />
        <Route path="/data-stok" element={<DataStok />} />
        <Route path="/data-master" element={<DataMaster />} />
        {!isFactoryScoped && <Route path="/manajemen-pengguna" element={<ManajemenUser />} />}
        <Route path="/settings" element={<PengaturanAkun />} />
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </MainLayout>
  );
};

export default Dashboard;
