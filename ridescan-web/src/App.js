import './App.css';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import Form from './components/Form';
import SuccessPage from './components/submission';

function App() {
  
  return (
    
    <Router>
      <Routes>
          <Route path="/" element={<Form />} />
          <Route path="/submission-confirmation" element={<SuccessPage />} />
      </Routes>
    </Router> 
  );
}

export default App;
