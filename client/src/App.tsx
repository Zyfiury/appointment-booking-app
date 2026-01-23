import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import BookAppointment from './pages/BookAppointment';
import MyAppointments from './pages/MyAppointments';
import ProviderDashboard from './pages/ProviderDashboard';
import ManageServices from './pages/ManageServices';
import Navbar from './components/Navbar';
import './App.css';

const PrivateRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user, loading } = useAuth();
  
  if (loading) {
    return <div className="loading">Loading...</div>;
  }
  
  return user ? <>{children}</> : <Navigate to="/login" />;
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="App">
          <Navbar />
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route
              path="/dashboard"
              element={
                <PrivateRoute>
                  <Dashboard />
                </PrivateRoute>
              }
            />
            <Route
              path="/book"
              element={
                <PrivateRoute>
                  <BookAppointment />
                </PrivateRoute>
              }
            />
            <Route
              path="/appointments"
              element={
                <PrivateRoute>
                  <MyAppointments />
                </PrivateRoute>
              }
            />
            <Route
              path="/provider/dashboard"
              element={
                <PrivateRoute>
                  <ProviderDashboard />
                </PrivateRoute>
              }
            />
            <Route
              path="/provider/services"
              element={
                <PrivateRoute>
                  <ManageServices />
                </PrivateRoute>
              }
            />
            <Route path="/" element={<Navigate to="/dashboard" />} />
          </Routes>
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
