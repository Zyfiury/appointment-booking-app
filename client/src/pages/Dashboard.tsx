import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import './MyAppointments.css';

interface Appointment {
  id: string;
  date: string;
  time: string;
  status: string;
  service: {
    name: string;
    duration: number;
    price: number;
  };
  provider: {
    name: string;
  };
}

const Dashboard: React.FC = () => {
  const { user } = useAuth();
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (user?.role === 'customer') {
      fetchAppointments();
    } else {
      setLoading(false);
    }
  }, [user]);

  const fetchAppointments = async () => {
    try {
      const response = await api.get('/appointments');
      setAppointments(response.data.slice(0, 5));
    } catch (error) {
      console.error('Failed to fetch appointments', error);
    } finally {
      setLoading(false);
    }
  };

  if (user?.role === 'provider') {
    return (
      <div className="container">
        <h1>Welcome, {user.name}!</h1>
        <div className="card">
          <p>You are logged in as a service provider.</p>
          <Link to="/provider/dashboard" className="btn btn-primary">
            Go to Provider Dashboard
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <h1>Welcome, {user?.name}!</h1>
      
      <div className="card">
        <h2>Quick Actions</h2>
        <Link to="/book" className="btn btn-primary">
          Book New Appointment
        </Link>
        <Link to="/appointments" className="btn btn-secondary" style={{ marginLeft: '1rem' }}>
          View All Appointments
        </Link>
      </div>

      {loading ? (
        <div className="card">Loading...</div>
      ) : (
        <div className="card">
          <h2>Recent Appointments</h2>
          {appointments.length === 0 ? (
            <p>No appointments yet. <Link to="/book">Book your first appointment!</Link></p>
          ) : (
            <div className="appointments-list">
              {appointments.map((apt) => (
                <div key={apt.id} className="appointment-item">
                  <div>
                    <strong>{apt.service.name}</strong>
                    <p>Provider: {apt.provider.name}</p>
                    <p>Date: {new Date(apt.date).toLocaleDateString()} at {apt.time}</p>
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

export default Dashboard;
