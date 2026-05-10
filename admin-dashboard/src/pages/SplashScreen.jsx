import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

const SplashScreen = () => {
  const navigate = useNavigate();
  const [show, setShow] = useState(false);

  useEffect(() => {
    // Fade in
    setTimeout(() => setShow(true), 100);
    // Redirect after 2s
    const timer = setTimeout(() => {
      navigate('/login');
    }, 2000);
    return () => clearTimeout(timer);
  }, [navigate]);

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-primary w-full">
      <div className={`transition-opacity duration-1000 flex flex-col items-center ${show ? 'opacity-100' : 'opacity-0'}`}>
        <div className="w-20 h-20 rounded-xl bg-surface flex items-center justify-center mb-6 shadow-lg">
          <span className="material-symbols-outlined text-primary text-[48px]" style={{ fontVariationSettings: "'FILL' 1" }}>
            admin_panel_settings
          </span>
        </div>
        <h1 className="text-4xl font-h1 text-on-primary font-bold tracking-tight mb-2">APHT Sumenep One</h1>
        <p className="text-primary-fixed-dim font-body-lg text-lg">Management System for 11 Factories</p>
      </div>
    </div>
  );
};

export default SplashScreen;
