FLIGHTS = [
    {
        "id": "flight-101",
        "origin": "New York",
        "destination": "Paris",
        "airline": "Atlantic Air",
        "departure": "2026-08-12T18:30:00Z",
        "price_eur": 640,
    },
    {
        "id": "flight-102",
        "origin": "New York",
        "destination": "Paris",
        "airline": "Skyline Airlines",
        "departure": "2026-08-13T09:15:00Z",
        "price_eur": 715,
    },
    {
        "id": "flight-201",
        "origin": "London",
        "destination": "Tokyo",
        "airline": "Pacific Routes",
        "departure": "2026-08-14T11:00:00Z",
        "price_eur": 980,
    },
    {
        "id": "flight-202",
        "origin": "London",
        "destination": "Tokyo",
        "airline": "Northstar Airways",
        "departure": "2026-08-15T14:45:00Z",
        "price_eur": 1_060,
    },
]

HOTELS = {
    "Paris": [
        {
            "name": "Hotel Lumiere",
            "neighborhood": "Le Marais",
            "nightly_price_eur": 210,
        },
        {
            "name": "Rivoli House",
            "neighborhood": "Louvre",
            "nightly_price_eur": 265,
        },
    ],
    "Tokyo": [
        {
            "name": "Sakura Stay",
            "neighborhood": "Shinjuku",
            "nightly_price_eur": 180,
        },
        {
            "name": "Harbor Tokyo Hotel",
            "neighborhood": "Shibuya",
            "nightly_price_eur": 245,
        },
    ],
}

ACTIVITIES = {
    "Paris": [
        {"name": "Louvre Museum", "category": "museum", "price_eur": 25},
        {"name": "Seine River Cruise", "category": "tour", "price_eur": 40},
    ],
    "Tokyo": [
        {"name": "Tsukiji Food Tour", "category": "food", "price_eur": 65},
        {"name": "Meiji Shrine Walk", "category": "culture", "price_eur": 0},
    ],
}


def search_flights(origin: str, destination: str) -> list[dict]:
    return [
        flight
        for flight in FLIGHTS
        if flight["origin"] == origin and flight["destination"] == destination
    ]


def search_hotels(destination: str) -> list[dict]:
    return HOTELS.get(destination, [])


def list_activities(destination: str) -> list[dict]:
    return ACTIVITIES.get(destination, [])