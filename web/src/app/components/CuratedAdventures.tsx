import React from "react";

const adventures = [
  {
    id: 1,
    user: "David Martin",
    date: "August 2023",
    title: "GRAND TETON",
    subtitle: "Switchback Loop Hike",
    imageUrl: "/images/grand-teton.jpg",
  },
  {
    id: 2,
    user: "Rover Barkton",
    date: "July 2023",
    title: "GRAND CANYON",
    subtitle: "Angels Triumph Hike",
    imageUrl: "/images/grand-canyon.jpg",
  },
  {
    id: 3,
    user: "Sarah Johnson",
    date: "June 2023",
    title: "YELLOWSTONE",
    subtitle: "Big Falls Hike",
    imageUrl: "/images/yellowstone.jpg",
  },
];

const CuratedAdventures = () => {
  return (
    <div className="text-center py-10">
      <h1 className="text-3xl font-bold mb-8">
        Curated Adventures for Curious Travelers
      </h1>
      <div className="flex justify-center gap-8 flex-wrap">
        {adventures.map((adventure) => (
          <div
            key={adventure.id}
            className="bg-white rounded-lg shadow-lg overflow-hidden max-w-sm text-left"
          >
            <img
              src={adventure.imageUrl}
              alt={adventure.title}
              className="w-full h-48 object-cover"
            />
            <div className="p-6">
              <div className="flex justify-between items-center mb-4">
                <span className="font-bold">{adventure.user}</span>
                <span className="text-gray-500">{adventure.date}</span>
              </div>
              <h2 className="text-xl font-semibold">{adventure.title}</h2>
              <p className="mt-2 text-gray-700">{adventure.subtitle}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default CuratedAdventures;
