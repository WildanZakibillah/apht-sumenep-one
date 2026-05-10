import React, { useState, useEffect } from 'react';
import { supabaseMock } from '../data/mockSupabase';

const FactoryData = () => {
  const [factories, setFactories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      const { data } = await supabaseMock.from('factories').select();
      setFactories(data);
      setLoading(false);
    };
    fetchData();
  }, []);

  const filteredFactories = factories.filter(f => {
    if (filter === 'active') return f.status === 'active';
    if (filter === 'inactive') return f.status === 'inactive';
    return true;
  });

  return (
    <div className="flex flex-col gap-lg w-full max-w-container-max mx-auto p-2 lg:p-0">
      <div className="flex flex-col gap-2">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="font-h1 text-h1 text-primary">Data Pabrik</h1>
            <p className="font-body-md text-body-md text-on-surface-variant mt-1">Manage and monitor all registered tobacco factories within the APHT Sumenep jurisdiction.</p>
          </div>
          <button className="flex items-center gap-xs px-md py-sm bg-primary text-on-primary rounded-lg font-label-sm text-label-sm hover:bg-primary-container transition-colors shadow-sm whitespace-nowrap">
            <span className="material-symbols-outlined text-[18px]">add</span>
            Tambah Pabrik
          </button>
        </div>
      </div>

      <div className="flex flex-col gap-4">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div className="flex items-center bg-surface-container-low rounded-full p-1 border border-outline-variant">
            <button 
              onClick={() => setFilter('all')}
              className={`px-4 py-1.5 rounded-full font-label-sm text-label-sm transition-colors ${filter === 'all' ? 'bg-surface border border-outline-variant shadow-sm text-on-surface' : 'text-on-surface-variant hover:text-on-surface'}`}
            >
              All Factories
            </button>
            <button 
              onClick={() => setFilter('active')}
              className={`px-4 py-1.5 rounded-full font-label-sm text-label-sm transition-colors ${filter === 'active' ? 'bg-surface border border-outline-variant shadow-sm text-on-surface' : 'text-on-surface-variant hover:text-on-surface'}`}
            >
              Active Only
            </button>
            <button 
              onClick={() => setFilter('inactive')}
              className={`px-4 py-1.5 rounded-full font-label-sm text-label-sm transition-colors ${filter === 'inactive' ? 'bg-surface border border-outline-variant shadow-sm text-on-surface' : 'text-on-surface-variant hover:text-on-surface'}`}
            >
              Inactive Only
            </button>
          </div>
          <div className="w-full md:w-64">
             <input 
                type="text" 
                placeholder="Filter by name..." 
                className="w-full px-4 py-2 rounded-lg border border-outline-variant bg-surface-container-lowest text-body-md focus:outline-none focus:border-primary"
             />
          </div>
        </div>

        <div className="bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-outline-variant bg-surface-container-low/50">
                  <th className="p-4 font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider font-semibold">NO</th>
                  <th className="p-4 font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider font-semibold">NAMA PABRIK</th>
                  <th className="p-4 font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider font-semibold">GOLONGAN</th>
                  <th className="p-4 font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider font-semibold">ADMIN NAME</th>
                  <th className="p-4 font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider font-semibold">STATUS</th>
                  <th className="p-4 font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider font-semibold text-center">ACTION</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="6" className="p-4 text-center">Loading...</td></tr>
                ) : (
                  filteredFactories.map((factory, index) => (
                    <tr key={factory.id} className="border-b border-surface-variant hover:bg-surface-container-low transition-colors">
                      <td className="p-4 font-body-md text-on-surface-variant">{factory.no}</td>
                      <td className="p-4 font-body-md font-medium text-primary">{factory.name}</td>
                      <td className="p-4 font-body-md text-on-surface">{factory.golongan}</td>
                      <td className="p-4 font-body-md text-on-surface">{factory.adminName}</td>
                      <td className="p-4">
                        <div className={`w-3 h-3 rounded-full ${factory.status === 'active' ? 'bg-[#21c55e]' : 'bg-error'}`}></div>
                      </td>
                      <td className="p-4 text-center">
                        <button className="text-on-surface-variant hover:text-primary transition-colors p-1 rounded hover:bg-surface-variant">
                           <span className="material-symbols-outlined text-[20px]">more_vert</span>
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
          <div className="p-4 flex flex-col sm:flex-row justify-between items-center gap-4 bg-surface-container-lowest">
            <span className="font-body-md text-on-surface-variant">Showing 1 to {filteredFactories.length} of 45 entries</span>
            <div className="flex items-center gap-1">
              <button className="px-3 py-1.5 border border-outline-variant rounded bg-surface hover:bg-surface-container-low text-body-md">Previous</button>
              <button className="px-3 py-1.5 border border-primary bg-primary text-on-primary rounded text-body-md font-medium">1</button>
              <button className="px-3 py-1.5 border border-outline-variant rounded bg-surface hover:bg-surface-container-low text-body-md">2</button>
              <button className="px-3 py-1.5 border border-outline-variant rounded bg-surface hover:bg-surface-container-low text-body-md">3</button>
              <button className="px-3 py-1.5 border border-outline-variant rounded bg-surface hover:bg-surface-container-low text-body-md">Next</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FactoryData;
