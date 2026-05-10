import React from 'react';
import { Routes, Route } from 'react-router-dom';
import MainLayout from '../components/layout/MainLayout';
import Beranda from './Beranda';
import DataPabrik from './DataPabrik';
import LaporanMasuk from './LaporanMasuk';
import DetailLaporan from './DetailLaporan';
import PantauCukai from './PantauCukai';
import DataPemasaran from './DataPemasaran';
import ArsipDigital from './ArsipDigital';
import DataMaster from './DataMaster';
import ManajemenUser from './ManajemenUser';
import PengaturanAkun from './PengaturanAkun';

const Dashboard = () => {
  return (
    <MainLayout>
      <Routes>
        <Route path="/" element={<Beranda />} />
        <Route path="/data-pabrik" element={<DataPabrik />} />
        <Route path="/laporan-masuk" element={<LaporanMasuk />} />
        <Route path="/laporan-masuk/:id" element={<DetailLaporan />} />
        <Route path="/pantau-cukai" element={<PantauCukai />} />
        <Route path="/data-pemasaran" element={<DataPemasaran />} />
        <Route path="/arsip-digital" element={<ArsipDigital />} />
        <Route path="/data-master" element={<DataMaster />} />
        <Route path="/manajemen-pengguna" element={<ManajemenUser />} />
        <Route path="/settings" element={<PengaturanAkun />} />
      </Routes>
    </MainLayout>
  );
};

export default Dashboard;
