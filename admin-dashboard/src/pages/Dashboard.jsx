import React from 'react';
import { Routes, Route } from 'react-router-dom';
import MainLayout from '../components/layout/MainLayout';
import Beranda from './Beranda';
import DataPabrik from './DataPabrik';
import DataProduksi from './DataProduksi';
import PantauCukai from './PantauCukai';
import PengajuanCukai from './PengajuanCukai';
import DataPemasaran from './DataPemasaran';
import DataMaster from './DataMaster';
import ManajemenUser from './ManajemenUser';
import Notifikasi from './Notifikasi';
import PengaturanAkun from './PengaturanAkun';

const Dashboard = () => {
  return (
    <MainLayout>
      <Routes>
        <Route path="/" element={<Beranda />} />
        <Route path="/data-pabrik" element={<DataPabrik />} />
        <Route path="/data-produksi" element={<DataProduksi />} />
        <Route path="/pantau-cukai" element={<PantauCukai />} />
        <Route path="/pengajuan-cukai" element={<PengajuanCukai />} />
        <Route path="/data-pemasaran" element={<DataPemasaran />} />
        <Route path="/data-master" element={<DataMaster />} />
        <Route path="/manajemen-pengguna" element={<ManajemenUser />} />
        <Route path="/notifikasi" element={<Notifikasi />} />
        <Route path="/settings" element={<PengaturanAkun />} />
      </Routes>
    </MainLayout>
  );
};

export default Dashboard;
