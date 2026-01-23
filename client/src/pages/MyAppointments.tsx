import React, { useEffect, useState } from 'react';
import api from '../services/api';
import { useAuth } from '../context/AuthContext';
import './MyAppointments.css';

interface Appointment {
  id: string;
  date: string;
  time: string;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  notes?: string;
  service: {
    id: string;
    name: string;
    duration: number;
    price: number;
  };
  provider?: {
    id: string;
    name: string;
    email: string;
  };
  customer?: {
    id: string;
    name: string;
    email: string;
  };
}

const MyAppointments: React.FC = () => {
  const { user } = useAuth();
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchAppointments();
  }, []);

  const fetchAppointments = async () => {
    try {
      const response = await api.get('/appointments');
      setAppointments(response.data);
    } catch (error) {
      console.error('Failed to fetch appointments', error);
    } finally {
      setLoading(false);
    }
  };

  const updateAppointmentStatus = async (id: string, status: string) => {
    try {
      await api.patch(`/appointments/${id}`, { status });
      fetchAppointments();
    } catch (error) {
      console.error('Failed to update appointment', error);
      alert('Failed to update appointment');
    }
  };

  const cancelAppointment = async (id: string) => {
    if (window.confirm('Are you sure you want to cancel this appointment?')) {
      await updateAppointmentStatus(id, 'cancelled');
    }
  };

  const confirmAppointment = async (id: string) => {
    await updateAppointmentStatus(id, 'confirmed');
  };

  if (loading) {
    return (
      <div className="container">
        <div className="card">Loading...</div>
      </div>
    );
  }

  return (
    <div className="container">
      <h1>{user?.role === 'provider' ? 'All Appointments' : 'My Appointments'}</h1>

      {appointments.length === 0 ? (
        <div className="card">
          <p>No appointments found.</p>
        </div>
      ) : (
        <div className="appointments-list">
          {appointments.map((apt) => (
            <div key={apt.id} className="card">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '1rem' }}>
                <div>
                  <h2>{apt.service.name}</h2>
                  <p><strong>Date:</strong> {new Date(apt.date).toLocaleDateString()}</p>
                  <p><strong>Time:</strong> {apt.time}</p>
                  <p><strong>Duration:</strong> {apt.service.duration} minutes</p>
                  <p><strong>Price:</strong> ${apt.service.price}</p>
                  {user?.role === 'customer' && apt.provider && (
                    <p><strong>Provider:</strong> {apt.provider.name}</p>
                  )}
                  {user?.role === 'provider' && apt.customer && (
                    <p><strong>Customer:</strong> {apt.customer.name} ({apt.customer.email})</p>
                  )}
                  {apt.notes && (
                    <p><strong>Notes:</strong> {apt.notes}</p>
                  )}
                </div>
                <span className={`status status-${apt.status}`}>{apt.status}</span>
              </div>
              
              <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                {apt.status === 'pending' && user?.role === 'provider' && (
                  <button
                    onClick={() => confirmAppointment(apt.id)}
                    className="btn btn-success"
                  >
                    Confirm
                  </button>
                )}
                {apt.status !== 'cancelled' && apt.status !== 'completed' && (
                  <button
                    onClick={() => cancelAppointment(apt.id)}
                    className="btn btn-danger"
                  >
                    Cancel
                  </button>
                )}
                {apt.status === 'confirmed' && user?.role === 'provider' && (
                  <button
                    onClick={() => updateAppointmentStatus(apt.id, 'completed')}
                    className="btn btn-success"
                  >
                    Mark as Completed
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default MyAppointments;
