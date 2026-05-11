const generateSlno = (number) => {
  return String(number).padStart(8, "0");
};

module.exports = generateSlno;