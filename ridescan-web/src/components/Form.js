import React, { useState } from 'react';
import axios from 'axios';
import logo from '../images/ridescan-logo.png';
import { useNavigate } from "react-router-dom";


function Form() {
    const navigate = useNavigate(); 

    const [serviceData, setServiceData] = useState({
        contactName: '',
        email: '',
        phoneNumber: '',
        user_proposed: true,
        send_to_application: false,
        serviceName: '',
        address: '',
        radius: '',
        comments: ''
    });


    const handleChange = (e) => {
        setServiceData({ ...serviceData, [e.target.name]: e.target.value });
    };
    

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            await axios.post('/api/proposedServices', serviceData); // Updated endpoint
            navigate('/submission-confirmation');
        } catch (error) {
            console.error('Error submitting data', error);
        }

        
    };


    const formStyle = {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px',
        backgroundColor: 'white',
        borderRadius: '5px',
        boxShadow: '0 4px 8px rgba(0, 0, 0, 0.1)',
        maxWidth: '400px',
        margin: '50px auto',
        border: '2px solid #800000'
    };

    const inputStyle = {
        margin: '10px 0',
        padding: '10px',
        width: '100%',
        borderRadius: '5px',
        border: '1px solid #800000', // Maroon color
    };

    const buttonStyle = {
        backgroundColor: '#800000', // Maroon color
        color: 'white',
        padding: '10px 20px',
        border: 'none',
        borderRadius: '5px',
        cursor: 'pointer',
        marginTop: '20px',
        width: '100%',
    };
    

    return (
        <div style={{ backgroundColor: '#fff', padding: '40px', textAlign: 'center' }}>
            <img src={logo} alt="RideScan Logo" style={{ maxWidth: '200px', marginBottom: '20px' }} />
            <h1 style={{ color: "#800000", textDecoration:"underline"}}>Service Submission Form</h1>
            <form onSubmit={handleSubmit} style={formStyle}>
                <input
                    style={inputStyle}
                    type="text"
                    name="contactName"
                    value={serviceData.contactName}
                    onChange={handleChange}
                    placeholder="Contact Name"
                />
                <input
                    style={inputStyle}
                    type="text"
                    name="serviceName"
                    value={serviceData.serviceName}
                    onChange={handleChange}
                    placeholder="Service Name"
                />
                <input
                    style={inputStyle}
                    type="email"
                    name="email"
                    value={serviceData.email}
                    onChange={handleChange}
                    placeholder="Email"
                />
                <input
                    style={inputStyle}
                    type="text"
                    name="phoneNumber"
                    value={serviceData.phoneNumber}
                    onChange={handleChange}
                    placeholder="Phone Number"
                />
                <input
                    style={inputStyle}
                    type="text"
                    name="address"
                    value={serviceData.address}
                    onChange={handleChange}
                    placeholder="Based Address"
                />
                <input
                    style={inputStyle}
                    type="text"
                    name="radius"
                    value={serviceData.radius}
                    onChange={handleChange}
                    placeholder="Operational Radius"
                />
                <textarea
                    style={{ ...inputStyle, height: '100px' }} 
                    name="comments"
                    value={serviceData.comments}
                    onChange={handleChange}
                    placeholder="Additional Comments"
                />
                <button style={buttonStyle} type="submit">Submit Proposal</button>
            </form>
        </div>
    );
}

export default Form;
