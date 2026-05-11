// =====================================
// MOCK EXTERNAL DATABASE FETCH SERVICE
// =====================================



// -------------------------------------
// SEARCH BY PHONE NUMBER
// -------------------------------------

const getCitizenByPhoneService = async (
  phoneNumber
) => {

  // =====================================
  // LATER:
  // Replace this with external DB/API call
  // =====================================

  // Example:
  // const result = await axios.get(...)
  // OR PostgreSQL/MySQL Query



  // MOCK DATA
  const mockCitizens = [
    {
      citizenName: "Rahul Kumar",
      phoneNumber: "9876543210",
      address: "Bangalore",
    },

    {
      citizenName: "Suresh",
      phoneNumber: "9988776655",
      address: "Mysore",
    },
  ];



  const citizen = mockCitizens.find(
    (c) => c.phoneNumber === phoneNumber
  );



  return citizen || null;
};





// -------------------------------------
// SEARCH BY CITIZEN NAME
// -------------------------------------

const searchCitizenByNameService = async (
  citizenName
) => {

  // =====================================
  // LATER:
  // Replace this with external DB/API call
  // =====================================



  // MOCK DATA
  const mockCitizens = [
    {
      citizenName: "Rahul Kumar",
      phoneNumber: "9876543210",
      address: "Bangalore",
    },

    {
      citizenName: "Suresh",
      phoneNumber: "9988776655",
      address: "Mysore",
    },

    {
      citizenName: "Rahul Sharma",
      phoneNumber: "9123456780",
      address: "Chennai",
    },
  ];



  const citizens = mockCitizens.filter((c) =>
    c.citizenName
      .toLowerCase()
      .includes(citizenName.toLowerCase())
  );



  return citizens;
};





module.exports = {
  getCitizenByPhoneService,
  searchCitizenByNameService,
};