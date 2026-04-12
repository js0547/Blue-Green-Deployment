import React, { useState, useEffect } from 'react';
import './index.css';

function App() {
  const [patients, setPatients] = useState([]);
  const themeColor = import.meta.env.VITE_APP_COLOR_THEME || 'blue';
  const appVersion = import.meta.env.VITE_APP_VERSION || 'v1.0.0';

  useEffect(() => {
    // For demo purposes, we fetch from the backend if it's available.
    fetch('/api/patients')
      .then(res => {
        if (!res.ok) throw new Error("Network response was not ok");
        return res.json();
      })
      .then(data => setPatients(data))
      .catch(err => console.error("Error fetching patients:", err));
  }, []);

  return (
    <div className={`app-container theme-${themeColor}`}>
      <header className="app-header">
        <h1>Secure Healthcare Portal</h1>
        <span className="version-badge">{themeColor.toUpperCase()} | {appVersion}</span>
      </header>
      
      <main className="app-main">
        <section className="dashboard-cards">
          <div className="card">
            <h3>Active Patients</h3>
            <p className="big-number">{patients.length || 0}</p>
          </div>
          <div className="card">
            <h3>Critical Alerts</h3>
            <p className="big-number text-danger">0</p>
          </div>
          <div className="card">
            <h3>System Status</h3>
            <p className="big-number status-ok">Healthy</p>
          </div>
        </section>

        <section className="data-table-section">
          <h2>Recent Patient Records</h2>
          <table className="data-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>First Name</th>
                <th>Last Name</th>
                <th>Email</th>
                <th>Diagnosis</th>
              </tr>
            </thead>
            <tbody>
              {patients.length > 0 ? (
                patients.map(patient => (
                  <tr key={patient.id}>
                    <td>{patient.id}</td>
                    <td>{patient.firstName}</td>
                    <td>{patient.lastName}</td>
                    <td>{patient.email}</td>
                    <td>{patient.diagnosis}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="5" className="empty-state">No patient data available. Ensure backend is connected.</td>
                </tr>
              )}
            </tbody>
          </table>
        </section>
      </main>
    </div>
  );
}

export default App;
