import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './Navbar.css';

const Navbar: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <nav className="navbar">
      <div className="navbar-container">
        <Link to="/dashboard" className="navbar-brand">
          📅 Appointment Booking
        </Link>
        {user && (
          <div className="navbar-menu">
            {user.role === 'customer' ? (
              <>
                <Link to="/dashboard" className="navbar-link">Dashboard</Link>
                <Link to="/book" className="navbar-link">Book Appointment</Link>
                <Link to="/appointments" className="navbar-link">My Appointments</Link>
              </>
            ) : (
              <>
                <Link to="/provider/dashboard" className="navbar-link">Dashboard</Link>
                <Link to="/provider/services" className="navbar-link">Manage Services</Link>
                <Link to="/appointments" className="navbar-link">Appointments</Link>
              </>
            )}
            <span className="navbar-user">Hello, {user.name}</span>
            <button onClick={handleLogout} className="btn btn-secondary btn-sm">
              Logout
            </button>
          </div>
        )}
      </div>
    </nav>
  );
};

export default Navbar;
