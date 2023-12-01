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

    return (
        <div>
            <h1>Admin Page</h1>
            {proposedServices.map(service => (
                <div key={service._id}>
                    <h2>{service.serviceName}</h2>
                    <button onClick={() => handleApprove(service._id)}>Approve</button>
                </div>
            ))}
        </div>
    );
}

export default AdminPage;
