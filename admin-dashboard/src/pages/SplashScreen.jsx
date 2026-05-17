import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import logoApht from '../assets/Logo apht.png';

const SplashScreen = () => {
  const navigate = useNavigate();
  const { isAuthenticated, loading } = useAuth();
  const [show, setShow] = useState(false);

  useEffect(() => {
    setTimeout(() => setShow(true), 100);
  }, []);

  useEffect(() => {
    if (!loading) {
      const timer = setTimeout(() => {
        if (isAuthenticated) {
          navigate('/dashboard', { replace: true });
        } else {
          navigate('/login', { replace: true });
        }
      }, 1500);
      return () => clearTimeout(timer);
    }
  }, [loading, isAuthenticated, navigate]);

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-blue-600 to-indigo-700 w-full relative overflow-hidden">
      {/* Background effects */}
      <div className="absolute top-0 right-0 w-96 h-96 bg-white/5 rounded-full -translate-y-1/2 translate-x-1/4"></div>
      <div className="absolute bottom-0 left-0 w-64 h-64 bg-white/5 rounded-full translate-y-1/2 -translate-x-1/4"></div>

      <div className={`transition-all duration-700 flex flex-col items-center ${show ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'}`}>
        <img src={logoApht} alt="APHT Sumenep" className="w-20 h-20 object-contain mb-6 drop-shadow-lg" />
        <h1 className="text-3xl font-bold text-white tracking-tight">APHT SUMENEP</h1>
        <p className="text-blue-100/70 text-sm mt-2">Super Admin Dashboard</p>

        {/* Loading indicator */}
        <div className="mt-8">
          <div className="w-6 h-6 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
        </div>
      </div>
    </div>
  );
};

export default SplashScreen;
