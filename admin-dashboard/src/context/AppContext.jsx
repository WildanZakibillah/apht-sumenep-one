import React, { createContext, useState, useContext, useEffect } from 'react';
import { supabaseMock } from '../data/mockSupabase';

const AppContext = createContext();

export const AppProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [activeWarehouse, setActiveWarehouse] = useState(null); // null means "All" or "Dashboard view"
  const [factories, setFactories] = useState([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    // Load factories initially
    const loadData = async () => {
      const { data } = await supabaseMock.from('factories').select();
      setFactories(data);
    };
    loadData();
  }, []);

  const login = async (email, password) => {
    setIsLoading(true);
    const { user, error } = await supabaseMock.auth.signIn(email, password);
    if (user) setUser(user);
    setIsLoading(false);
    return { error };
  };

  const logout = async () => {
    setIsLoading(true);
    await supabaseMock.auth.signOut();
    setUser(null);
    setIsLoading(false);
  };

  return (
    <AppContext.Provider value={{ 
        user, login, logout, 
        activeWarehouse, setActiveWarehouse, 
        factories, isLoading 
    }}>
      {children}
    </AppContext.Provider>
  );
};

export const useAppContext = () => useContext(AppContext);
