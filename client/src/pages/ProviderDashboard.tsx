import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../services/api';

interface Appointment {
  id: string;
  date: string;
  time: string;
  status: string;
  service: {
    name: string;
    price: number;
  };
  customer: {
    name: string;
  };
}

const ProviderDashboard: React.FC = () => {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [stats, setStats] = useState({
    total: 0,
    pending: 0,
    confirmed: 0,
    completed: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchAppointments();
  }, []);

  const fetchAppointments = async () => {
    try {
      const response = await api.get('/appointments');
      const allAppointments = response.data;
      setAppointments(allAppointments.slice(0, 5));
      
      setStats({
        total: allAppointments.length,
        pending: allAppointments.filter((a: Appointment) => a.status === 'pending').length,
        confirmed: allAppointments.filter((a: Appointment) => a.status === 'confirmed').length,
        completed: allAppointments.filter((a: Appointment) => a.status === 'completed').length,
      });
    } catch (error) {
      console.error('Failed to fetch appointments', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container">
      <h1>Provider Dashboard</h1>

      <div className="card">
        <h2>Quick Actions</h2>
        <Link to="/provider/services" className="btn btn-primary">
          Manage Services
        </Link>
        <Link to="/appointments" className="btn btn-secondary" style={{ marginLeft: '1rem' }}>
          View All Appointments
        </Link>
      </div>

      <div className="grid grid-4" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))' }}>
        <div className="card" style={{ textAlign: 'center' }}>
          <h3 style={{ fontSize: '2rem', color: '#007bff' }}>{stats.total}</h3>
          <p>Total Appointments</p>
        </div>
        <div className="card" style={{ textAlign: 'center' }}>
          <h3 style={{ fontSize: '2rem', color: '#ffc107' }}>{stats.pending}</h3>
          <p>Pending</p>
        </div>
        <div className="card" style={{ textAlign: 'center' }}>
          <h3 style={{ fontSize: '2rem', color: '#28a745' }}>{stats.confirmed}</h3>
          <p>Confirmed</p>
        </div>
        <div className="card" style={{ textAlign: 'center' }}>
          <h3 style={{ fontSize: '2rem', color: '#6c757d' }}>{stats.completed}</h3>
          <p>Completed</p>
        </div>
      </div>

      {loading ? (
        <div className="card">Loading...</div>
      ) : (
        <div className="card">
          <h2>Recent Appointments</h2>
          {appointments.length === 0 ? (
            <p>No appointments yet.</p>
          ) : (
            <div className="appointments-list">
              {appointments.map((apt) => (
                <div key={apt.id} className="appointment-item">
                  <div>
                    <strong>{apt.service.name}</strong>
                    <p>Customer: {apt.customer.name}</p>
                    <p>Date: {new Date(apt.date).toLocaleDateString()} at {apt.time}</p>
                    <p>Price: ${apt.service.price}</p>
                  </div>
                  <span className={`status status-${apt.status}`}>{apt.status}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default ProviderDashboard;
