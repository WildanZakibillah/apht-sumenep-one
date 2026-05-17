import { useState, useEffect, useContext, createContext, useCallback } from 'react';
import { authService } from '../services/authService';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let isMounted = true;
    let resolved = false;

    const done = () => {
      if (!resolved && isMounted) {
        resolved = true;
        setLoading(false);
        setReady(true);
      }
    };

    // Hard timeout - ALWAYS finish loading within 3 seconds no matter what
    const hardTimeout = setTimeout(done, 3000);

    const initAuth = async () => {
      try {
        const session = await authService.getSession();
        if (session?.user && isMounted) {
          setUser(session.user);
          // Try to get profile but don't block on it
          const userProfile = await authService.getProfile(session.user.id);
          if (userProfile && isMounted) {
            setProfile(userProfile);
          }
        }
      } catch (error) {
        console.error('Auth init error:', error);
      }
      done();
    };

    initAuth();

    const { data: { subscription } } = authService.onAuthStateChange(async (event, session) => {
      if (!isMounted) return;

      if (event === 'SIGNED_OUT') {
        setUser(null);
        setProfile(null);
        done();
        return;
      }

      if (session?.user) {
        setUser(session.user);
        try {
          const userProfile = await authService.getProfile(session.user.id);
          if (userProfile && isMounted) setProfile(userProfile);
        } catch (err) {
          // ignore
        }
        done();
      }
    });

    return () => {
      isMounted = false;
      clearTimeout(hardTimeout);
      subscription?.unsubscribe();
    };
  }, []);

  const handleSignOut = useCallback(() => {
    setUser(null);
    setProfile(null);
    Object.keys(localStorage).forEach(key => {
      if (key.startsWith('sb-')) localStorage.removeItem(key);
    });
    window.location.href = '/login';
  }, []);

  const value = {
    user,
    profile,
    loading,
    ready,
    signIn: authService.signIn,
    signOut: handleSignOut,
    isAuthenticated: !!user,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
