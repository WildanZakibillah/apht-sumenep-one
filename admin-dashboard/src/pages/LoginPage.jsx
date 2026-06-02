import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import logoApht from '../assets/Logo apht.png';
import gedungBg from '../assets/gedung.png';

// Typing animation
const TypingText = ({ texts, speed = 45, pause = 2800 }) => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [displayed, setDisplayed] = useState('');
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    const text = texts[currentIndex];
    let timeout;
    if (!isDeleting && displayed.length < text.length) {
      timeout = setTimeout(() => setDisplayed(text.slice(0, displayed.length + 1)), speed);
    } else if (!isDeleting && displayed.length === text.length) {
      timeout = setTimeout(() => setIsDeleting(true), pause);
    } else if (isDeleting && displayed.length > 0) {
      timeout = setTimeout(() => setDisplayed(text.slice(0, displayed.length - 1)), speed / 2);
    } else if (isDeleting && displayed.length === 0) {
      setIsDeleting(false);
      setCurrentIndex((prev) => (prev + 1) % texts.length);
    }
    return () => clearTimeout(timeout);
  }, [displayed, isDeleting, currentIndex, texts, speed, pause]);

  return <span>{displayed}<span className="animate-pulse">|</span></span>;
};

const LoginPage = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const { signIn, loading, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const [errorMsg, setErrorMsg] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [factoryCount, setFactoryCount] = useState(0);

  useEffect(() => {
    setTimeout(() => setMounted(true), 100);
    // Fetch factory count
    const fetchCount = async () => {
      const { count } = await (await import('../lib/supabase')).supabase
        .from('factories')
        .select('*', { count: 'exact', head: true });
      if (count) setFactoryCount(count);
    };
    fetchCount();
  }, []);

  useEffect(() => {
    if (isAuthenticated) {
      navigate('/dashboard', { replace: true });
    }
  }, [isAuthenticated, navigate]);

  const handleLogin = async (e) => {
    e.preventDefault();
    setErrorMsg('');
    setIsSubmitting(true);
    try {
      await signIn(email, password);
    } catch (error) {
      setErrorMsg(error.message || 'Login gagal. Periksa email dan password Anda.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex">
      {/* Left Panel - Image Background */}
      <div className="hidden lg:flex lg:w-[55%] relative overflow-hidden">
        <img src={gedungBg} alt="" className="absolute inset-0 w-full h-full object-cover scale-105" />
        <div className="absolute inset-0 bg-gradient-to-t from-indigo-950/90 via-indigo-900/50 to-indigo-900/30"></div>
        
        {/* Logo + Text - Top Left */}
        <div className={`absolute top-8 left-8 z-10 flex items-center gap-3 transition-all duration-700 ${mounted ? 'opacity-100 translate-y-0' : 'opacity-0 -translate-y-4'}`}>
          <img src={logoApht} alt="APHT" className="w-11 h-11 object-contain drop-shadow-2xl" />
          <div>
            <h2 className="text-xl font-extrabold text-white tracking-tight">APHT SUMENEP</h2>
            <p className="text-indigo-200/60 text-[10px] font-medium tracking-wider uppercase">Super Admin Dashboard</p>
          </div>
        </div>

        {/* Floating particles effect */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute top-20 left-20 w-32 h-32 bg-white/5 rounded-full animate-pulse"></div>
          <div className="absolute bottom-40 right-20 w-24 h-24 bg-indigo-400/10 rounded-full animate-pulse" style={{ animationDelay: '1s' }}></div>
          <div className="absolute top-1/2 left-1/3 w-16 h-16 bg-cyan-400/10 rounded-full animate-pulse" style={{ animationDelay: '2s' }}></div>
        </div>

        <div className="absolute bottom-0 left-0 right-0 p-12 z-10">
          <div className={`transition-all duration-700 ${mounted ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'}`}>
            <p className="text-indigo-100/90 text-xl max-w-lg leading-relaxed h-8 font-semibold">
              <TypingText texts={[
                'Sistem Informasi Pengawasan Industri Hasil Tembakau.',
                'Monitoring produksi, cukai, dan pemasaran real-time.',
                `Kelola ${factoryCount || '...'} pabrik rokok di Kabupaten Sumenep.`,
                'Pastikan kepatuhan regulasi pita cukai.',
              ]} />
            </p>
          </div>

          {/* Stats row */}
          <div className={`flex items-center gap-6 mt-6 transition-all duration-700 delay-300 ${mounted ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'}`}>
            <div className="flex items-center gap-2 px-4 py-2.5 bg-white/10 backdrop-blur-md rounded-xl border border-white/10">
              <span className="material-symbols-outlined text-cyan-300 text-[18px]" style={{ fontVariationSettings: "'FILL' 1" }}>domain</span>
              <span className="text-white/90 text-sm font-semibold">{factoryCount || '...'} Pabrik</span>
            </div>
            <div className="flex items-center gap-2 px-4 py-2.5 bg-white/10 backdrop-blur-md rounded-xl border border-white/10">
              <span className="material-symbols-outlined text-emerald-300 text-[18px]" style={{ fontVariationSettings: "'FILL' 1" }}>confirmation_number</span>
              <span className="text-white/90 text-sm font-semibold">Real-time</span>
            </div>
            <div className="flex items-center gap-2 px-4 py-2.5 bg-white/10 backdrop-blur-md rounded-xl border border-white/10">
              <span className="material-symbols-outlined text-amber-300 text-[18px]" style={{ fontVariationSettings: "'FILL' 1" }}>verified_user</span>
              <span className="text-white/90 text-sm font-semibold">Secure</span>
            </div>
          </div>
        </div>
      </div>

      {/* Right Panel - Login Form */}
      <div className="flex-1 flex items-center justify-center p-6 bg-gradient-to-br from-slate-50 via-white to-indigo-50/30 relative overflow-hidden">
        {/* Decorative bg */}
        <div className="absolute -top-32 -right-32 w-64 h-64 bg-indigo-100/40 rounded-full blur-3xl"></div>
        <div className="absolute -bottom-20 -left-20 w-48 h-48 bg-blue-100/30 rounded-full blur-3xl"></div>

        <div className={`w-full max-w-md relative z-10 transition-all duration-700 delay-200 ${mounted ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'}`}>
          {/* Mobile Logo */}
          <div className="lg:hidden text-center mb-8">
            <img src={logoApht} alt="APHT Sumenep" className="w-14 h-14 object-contain mx-auto mb-3" />
            <h1 className="text-xl font-bold text-gray-900">APHT SUMENEP</h1>
          </div>

          {/* Login Card */}
          <div className="bg-white/80 backdrop-blur-xl rounded-3xl shadow-2xl shadow-indigo-100/60 border border-white/60 p-9">
            {/* Header */}
            <div className="mb-8">
              <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-indigo-500 to-blue-600 flex items-center justify-center mb-5 shadow-lg shadow-indigo-200/50">
                <span className="material-symbols-outlined text-white text-[24px]" style={{ fontVariationSettings: "'FILL' 1" }}>lock_open</span>
              </div>
              <h2 className="text-2xl font-extrabold text-gray-900">Masuk ke Dashboard</h2>
              <p className="text-sm text-gray-500 mt-1.5">Masukkan kredensial untuk mengakses panel admin.</p>
            </div>

            {errorMsg && (
              <div className="mb-5 p-3.5 bg-red-50/80 backdrop-blur border border-red-100 text-red-700 text-sm rounded-2xl flex items-center gap-2 animate-[fadeSlideIn_0.3s_ease-out]">
                <span className="material-symbols-outlined text-[18px]">error</span>
                {errorMsg}
              </div>
            )}

            <form onSubmit={handleLogin} className="space-y-5">
              <div>
                <label className="text-xs font-bold text-gray-600 mb-2 block uppercase tracking-wider">Email</label>
                <div className="relative group">
                  <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-indigo-500 text-[20px] transition-colors">mail</span>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full pl-12 pr-4 py-3.5 bg-gray-50/80 border border-gray-200/80 rounded-2xl text-sm text-gray-800 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/10 focus:bg-white transition-all"
                    placeholder="contoh@gmail.com"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-gray-600 mb-2 block uppercase tracking-wider">Password</label>
                <div className="relative group">
                  <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-indigo-500 text-[20px] transition-colors">lock</span>
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full pl-12 pr-12 py-3.5 bg-gray-50/80 border border-gray-200/80 rounded-2xl text-sm text-gray-800 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/10 focus:bg-white transition-all"
                    placeholder="password"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                  >
                    <span className="material-symbols-outlined text-[20px]">
                      {showPassword ? 'visibility_off' : 'visibility'}
                    </span>
                  </button>
                </div>
              </div>

              <div className="flex items-center pt-1">
                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input type="checkbox" className="w-4 h-4 rounded-md border-gray-300 text-indigo-600 focus:ring-indigo-500" />
                  <span className="text-sm text-gray-600">Ingat saya</span>
                </label>
              </div>

              <button
                type="submit"
                disabled={isSubmitting || loading}
                className="w-full py-4 bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-2xl font-bold text-sm hover:from-indigo-700 hover:to-blue-700 active:scale-[0.98] transition-all shadow-xl shadow-indigo-200/50 disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {(isSubmitting || loading) ? (
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                ) : (
                  <>
                    Masuk ke Dashboard
                    <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
                  </>
                )}
              </button>
            </form>
          </div>

          <p className="text-center text-xs text-gray-400 mt-6">
            &copy; 2026 APHT Sumenep. All rights reserved.
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
