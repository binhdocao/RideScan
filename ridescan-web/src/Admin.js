import React, { useState, useEffect } from 'react';
import axios from 'axios';

function AdminPage() {
    const [proposedServices, setProposedServices] = useState([]);

    useEffect(() => {
        // Fetch proposed services
        axios.get('/api/proposedServices') // Updated endpoint
            .then(response => setProposedServices(response.data))
            .catch(error => console.error('Error fetching proposed services', error));
    }, []);

    const handleApprove = (id) => {
        // Approve service
        axios.post(`/api/approveService/${id}`) // Updated endpoint
            .then(() => {
                setProposedServices(proposedServices.filter(service => service._id !== id));
            })
            .catch(error => console.error('Error approving service', error));
    };

    const adminPageStyle = {
        padding: '20px',
        textAlign: 'center'
    };

    const serviceCardStyle = {
        backgroundColor: 'white',
        borderRadius: '5px',
        boxShadow: '0 4px 8px rgba(0, 0, 0, 0.1)',
        padding: '20px',
        margin: '10px auto',
        maxWidth: '400px'
    };

    const buttonStyle = {
        backgroundColor: '#800000', // Maroon color
        color: 'white',
        padding: '10px 20px',
        border: 'none',
        borderRadius: '5px',
        cursor: 'pointer',
        marginTop: '10px',
    };

    return (
        <div style={adminPageStyle}>
            <h1>Admin Page</h1>
            {proposedServices.map(service => (
                <div key={service._id} style={serviceCardStyle}>
                    <h2>{service.serviceName}</h2>
                    <p>{service.contactName}</p>
                    <p>{service.email}</p>
                    {/* Include other service details as needed */}
                    <button style={buttonStyle} onClick={() => handleApprove(service._id)}>Approve</button>
                </div>
            ))}
        </div>
    );
}

export default AdminPage;
