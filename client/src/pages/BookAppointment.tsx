import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';

interface Provider {
  id: string;
  name: string;
  email: string;
  phone?: string;
}

interface Service {
  id: string;
  name: string;
  description: string;
  duration: number;
  price: number;
  category: string;
  providerId: string;
}

const BookAppointment: React.FC = () => {
  const [providers, setProviders] = useState<Provider[]>([]);
  const [services, setServices] = useState<Service[]>([]);
  const [selectedProvider, setSelectedProvider] = useState<string>('');
  const [selectedService, setSelectedService] = useState<string>('');
  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [notes, setNotes] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    fetchProviders();
  }, []);

  useEffect(() => {
    if (selectedProvider) {
      fetchServices(selectedProvider);
    } else {
      setServices([]);
    }
  }, [selectedProvider]);

  const fetchProviders = async () => {
    try {
      const response = await api.get('/users/providers');
      setProviders(response.data);
    } catch (error) {
      console.error('Failed to fetch providers', error);
    }
  };

  const fetchServices = async (providerId: string) => {
    try {
      const response = await api.get(`/services?providerId=${providerId}`);
      setServices(response.data);
    } catch (error) {
      console.error('Failed to fetch services', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setLoading(true);

    try {
      await api.post('/appointments', {
        providerId: selectedProvider,
        serviceId: selectedService,
        date,
        time,
        notes,
      });
      setSuccess('Appointment booked successfully!');
      setTimeout(() => {
        navigate('/appointments');
      }, 2000);
    } catch (err: any) {
      setError(err.response?.data?.error || 'Failed to book appointment');
    } finally {
      setLoading(false);
    }
  };

  const selectedServiceData = services.find(s => s.id === selectedService);
  const minDate = new Date().toISOString().split('T')[0];

  return (
    <div className="container">
      <h1>Book Appointment</h1>
      
      <div className="card">
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Select Provider</label>
            <select
              value={selectedProvider}
              onChange={(e) => {
                setSelectedProvider(e.target.value);
                setSelectedService('');
              }}
              required
            >
              <option value="">Choose a provider...</option>
              {providers.map((provider) => (
                <option key={provider.id} value={provider.id}>
                  {provider.name} {provider.phone && `(${provider.phone})`}
                </option>
              ))}
            </select>
          </div>

          {selectedProvider && (
            <div className="form-group">
              <label>Select Service</label>
              {services.length === 0 ? (
                <p>No services available for this provider.</p>
              ) : (
                <select
                  value={selectedService}
                  onChange={(e) => setSelectedService(e.target.value)}
                  required
                >
                  <option value="">Choose a service...</option>
                  {services.map((service) => (
                    <option key={service.id} value={service.id}>
                      {service.name} - ${service.price} ({service.duration} min)
                    </option>
                  ))}
                </select>
              )}
            </div>
          )}

          {selectedServiceData && (
            <div className="card" style={{ marginBottom: '1.5rem', backgroundColor: '#f8f9fa' }}>
              <h3>{selectedServiceData.name}</h3>
              <p>{selectedServiceData.description}</p>
              <p><strong>Duration:</strong> {selectedServiceData.duration} minutes</p>
              <p><strong>Price:</strong> ${selectedServiceData.price}</p>
            </div>
          )}

          <div className="form-group">
            <label>Date</label>
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              min={minDate}
              required
            />
          </div>

          <div className="form-group">
            <label>Time</label>
            <input
              type="time"
              value={time}
              onChange={(e) => setTime(e.target.value)}
              required
            />
          </div>

          <div className="form-group">
            <label>Notes (Optional)</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Any special requests or notes..."
            />
          </div>

          {error && <div className="error">{error}</div>}
          {success && <div className="success">{success}</div>}

          <button type="submit" className="btn btn-primary" disabled={loading || !selectedService}>
            {loading ? 'Booking...' : 'Book Appointment'}
          </button>
        </form>
      </div>
    </div>
  );
};

export default BookAppointment;
