import React, { useEffect, useState } from 'react';
import api from '../services/api';

interface Service {
  id: string;
  name: string;
  description: string;
  duration: number;
  price: number;
  category: string;
}

const ManageServices: React.FC = () => {
  const [services, setServices] = useState<Service[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [editingService, setEditingService] = useState<Service | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    duration: '',
    price: '',
    category: '',
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchServices();
  }, []);

  const fetchServices = async () => {
    try {
      const response = await api.get('/services');
      setServices(response.data);
    } catch (error) {
      console.error('Failed to fetch services', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      if (editingService) {
        await api.patch(`/services/${editingService.id}`, formData);
      } else {
        await api.post('/services', formData);
      }
      setShowForm(false);
      setEditingService(null);
      setFormData({ name: '', description: '', duration: '', price: '', category: '' });
      fetchServices();
    } catch (err: any) {
      setError(err.response?.data?.error || 'Failed to save service');
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (service: Service) => {
    setEditingService(service);
    setFormData({
      name: service.name,
      description: service.description,
      duration: service.duration.toString(),
      price: service.price.toString(),
      category: service.category,
    });
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this service?')) {
      try {
        await api.delete(`/services/${id}`);
        fetchServices();
      } catch (error) {
        console.error('Failed to delete service', error);
        alert('Failed to delete service');
      }
    }
  };

  const cancelForm = () => {
    setShowForm(false);
    setEditingService(null);
    setFormData({ name: '', description: '', duration: '', price: '', category: '' });
  };

  return (
    <div className="container">
      <h1>Manage Services</h1>

      {!showForm ? (
        <>
          <div className="card">
            <button onClick={() => setShowForm(true)} className="btn btn-primary">
              Add New Service
            </button>
          </div>

          {services.length === 0 ? (
            <div className="card">
              <p>No services yet. Add your first service!</p>
            </div>
          ) : (
            <div className="grid grid-2">
              {services.map((service) => (
                <div key={service.id} className="card">
                  <h2>{service.name}</h2>
                  <p><strong>Category:</strong> {service.category}</p>
                  <p>{service.description}</p>
                  <p><strong>Duration:</strong> {service.duration} minutes</p>
                  <p><strong>Price:</strong> ${service.price}</p>
                  <div style={{ marginTop: '1rem', display: 'flex', gap: '0.5rem' }}>
                    <button
                      onClick={() => handleEdit(service)}
                      className="btn btn-secondary"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => handleDelete(service.id)}
                      className="btn btn-danger"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      ) : (
        <div className="card">
          <h2>{editingService ? 'Edit Service' : 'Add New Service'}</h2>
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Service Name</label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>
            <div className="form-group">
              <label>Category</label>
              <input
                type="text"
                value={formData.category}
                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                placeholder="e.g., Consultation, Treatment, Checkup"
                required
              />
            </div>
            <div className="form-group">
              <label>Description</label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                required
              />
            </div>
            <div className="form-group">
              <label>Duration (minutes)</label>
              <input
                type="number"
                value={formData.duration}
                onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
                min="15"
                step="15"
                required
              />
            </div>
            <div className="form-group">
              <label>Price ($)</label>
              <input
                type="number"
                value={formData.price}
                onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                min="0"
                step="0.01"
                required
              />
            </div>
            {error && <div className="error">{error}</div>}
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <button type="submit" className="btn btn-primary" disabled={loading}>
                {loading ? 'Saving...' : editingService ? 'Update' : 'Create'}
              </button>
              <button type="button" onClick={cancelForm} className="btn btn-secondary">
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};

export default ManageServices;
