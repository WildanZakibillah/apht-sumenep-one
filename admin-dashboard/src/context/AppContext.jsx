import React, { createContext, useState, useContext, useEffect } from 'react';
import { supabase } from '../lib/supabase';

const AppContext = createContext();

export const AppProvider = ({ children }) => {
  const [activeWarehouse, setActiveWarehouse] = useState(null);
  const [factories, setFactories] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  useEffect(() => {
    const loadData = async () => {
      try {
        const { data } = await supabase.from('factories').select('*');
        if (data) setFactories(data);
      } catch (error) {
        console.error('Error loading factories:', error);
      }
    };
    loadData();
  }, []);

  return (
    <AppContext.Provider value={{ 
        activeWarehouse, setActiveWarehouse, 
        factories, isLoading, setIsLoading,
        sidebarCollapsed, setSidebarCollapsed
    }}>
      {children}
    </AppContext.Provider>
  );
};

export const useAppContext = () => useContext(AppContext);
