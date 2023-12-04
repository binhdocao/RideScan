import './App.css';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import Form from './components/Form';
import SuccessPage from './components/submission';
import AdminPage from './Admin';

function App() {
  
  return (
    
    <Router>
      <Routes>
          <Route path="/" element={<Form />} />
          <Route path="/submission-confirmation" element={<SuccessPage />} />
          <Route path="/admin" element={<AdminPage />} />
      </Routes>
    </Router> 
  );
}

export default App;
