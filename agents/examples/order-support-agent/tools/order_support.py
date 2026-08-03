CUSTOMERS = {
    "Alice": {
        "id": "customer-1",
        "name": "Alice",
        "email": "alice@example.com",
    },
    "Bob": {
        "id": "customer-2",
        "name": "Bob",
        "email": "bob@example.com",
    },
    "Carol": {
        "id": "customer-3",
        "name": "Carol",
        "email": "carol@example.com",
    },
    "David": {
        "id": "customer-4",
        "name": "David",
        "email": "david@example.com",
    },
    "Emma": {
        "id": "customer-5",
        "name": "Emma",
        "email": "emma@example.com",
    },
}

ORDERS = {
    "customer-1": [
        {
            "id": "order-101",
            "product": "Mechanical Keyboard",
            "status": "processing",
            "created_at": "2026-07-10T09:15:00Z",
        },
        {
            "id": "order-102",
            "product": "USB-C Hub",
            "status": "delivered",
            "created_at": "2026-07-18T14:30:00Z",
        },
    ],
    "customer-2": [
        {
            "id": "order-201",
            "product": "Wireless Mouse",
            "status": "shipped",
            "created_at": "2026-07-12T11:45:00Z",
        },
        {
            "id": "order-202",
            "product": "Laptop Stand",
            "status": "cancelled",
            "created_at": "2026-07-20T16:00:00Z",
        },
    ],
    "customer-3": [
        {
            "id": "order-301",
            "product": "Noise-Cancelling Headphones",
            "status": "delivered",
            "created_at": "2026-06-28T08:20:00Z",
        },
        {
            "id": "order-302",
            "product": "Webcam",
            "status": "processing",
            "created_at": "2026-07-15T13:10:00Z",
        },
        {
            "id": "order-303",
            "product": "Desk Lamp",
            "status": "shipped",
            "created_at": "2026-07-22T10:05:00Z",
        },
    ],
    "customer-4": [
        {
            "id": "order-401",
            "product": "Monitor Arm",
            "status": "pending",
            "created_at": "2026-07-19T15:40:00Z",
        },
        {
            "id": "order-402",
            "product": "External SSD",
            "status": "delivered",
            "created_at": "2026-07-25T12:25:00Z",
        },
    ],
    "customer-5": [
        {
            "id": "order-501",
            "product": "Ergonomic Chair",
            "status": "processing",
            "created_at": "2026-07-14T09:50:00Z",
        },
        {
            "id": "order-502",
            "product": "Keyboard Wrist Rest",
            "status": "cancelled",
            "created_at": "2026-07-21T17:35:00Z",
        },
        {
            "id": "order-503",
            "product": "Cable Organizer",
            "status": "delivered",
            "created_at": "2026-07-29T11:15:00Z",
        },
    ],
}


def find_customer(name: str) -> dict | None:
    return CUSTOMERS.get(name)


def list_orders(customer_id: str) -> list[dict]:
    return ORDERS.get(customer_id, [])