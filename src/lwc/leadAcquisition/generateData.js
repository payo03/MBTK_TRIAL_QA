export default function generateData({ amountOfRecords }) {
  return [...Array(amountOfRecords)].map((_, index) => {
      return {
          name: `Truck A`,
          segment: 'Truck',
          listPrice: Math.floor(200000000),
          closeAt: new Date(
              Date.now() + 86400000 * Math.ceil(Math.random() * 20)
          ),
      };
  });
}