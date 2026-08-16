# KNTU Sports Ticket Reservation System
## Website User Guide

This README explains how to run and use the website for the **Sports Ticket Reservation System** project.

---

## 1. Project Overview

This website is a complete sports ticket reservation platform. Users can:

- Sign up and log in securely
- Verify login using password and OTP
- Search and filter tickets
- View ticket details
- Reserve tickets
- Change ticket or seat before payment
- Pay using card or wallet
- Deposit money into wallet
- View wallet balance and transactions
- Request refunds
- View reservation history
- Submit reports
- Use Elasticsearch full-text search
- Use autocomplete search
- Access support features if logged in as support

The system includes both a normal user role and a support role.

---

## 2. Main Technologies

The project uses:

- **Frontend:** HTML, CSS, JavaScript
- **Backend:** Node.js, Express.js
- **Database:** PostgreSQL
- **OTP and Cache:** Redis
- **Search Engine:** Elasticsearch
- **Container:** Docker for Elasticsearch
- **Authentication:** Password, OTP, JWT

---

## 3. Project Folder Structure

Recommended project structure:

```text
pr_db4042/
├── backend/
│   ├── server.js
│   ├── package.json
│   ├── .env
│   ├── docs/
│   │   └── API_DOCUMENTATION.md
│   └── src/
│       ├── config/
│       ├── controllers/
│       ├── middleware/
│       ├── routes/
│       └── jobs/
│
├── frontend/
│   ├── index.html
│   ├── style.css
│   ├── app.js
│   └── assets/
│       └── home-image.png
│
├── docker-compose.yml
└── README.md
```

---

## 4. Backend Setup

Go to the backend folder:

```bash
cd /Users/arya/Desktop/pr_db4042/backend
```

Install dependencies:

```bash
npm install
```

Run the backend:

```bash
npm run dev
```

The backend should run on:

```text
http://localhost:5001
```

A successful startup should show messages similar to:

```text
Redis connected
Reservation expiry job started
Server is running on port 5001
```

---

## 5. Environment Variables

Create a `.env` file inside the `backend` folder.

Example:

```env
PORT=5001
NODE_ENV=development

DB_HOST=localhost
DB_PORT=5432
DB_NAME=sports_ticketing_db
DB_USER=postgres
DB_PASSWORD=your_postgres_password

JWT_SECRET=arya_db_project_secret_4042
JWT_EXPIRES_IN=1d

REDIS_URL=redis://127.0.0.1:6379
OTP_TTL_SECONDS=300
CACHE_TTL_SECONDS=60
RESERVATION_TTL_MINUTES=10
RESERVATION_EXPIRY_CHECK_SECONDS=60

ELASTICSEARCH_URL=http://localhost:9200
```

Do not commit `.env` to GitHub.

---

## 6. Redis Setup

Redis must be running before testing OTP login.

To start Redis:

```bash
redis-server
```

Or if Redis is installed as a service:

```bash
brew services start redis
```

To check Redis:

```bash
redis-cli ping
```

Expected output:

```text
PONG
```

---

## 7. Elasticsearch Setup

Elasticsearch is used for full-text ticket search and autocomplete.

From the project root:

```bash
cd /Users/arya/Desktop/pr_db4042
docker compose up -d
```

Check if Elasticsearch is running:

```bash
curl http://localhost:9200
```

Expected result: Elasticsearch version information.

---

## 8. Frontend Setup

Open the `frontend` folder in VS Code.

Use **Live Server** to run:

```text
frontend/index.html
```

The website will usually open at:

```text
http://127.0.0.1:5500/frontend/index.html
```

or:

```text
http://127.0.0.1:5500/index.html
```

If changes do not appear, hard refresh the page:

```text
Cmd + Shift + R
```

---

## 9. Test Accounts

Example test users:

```text
Normal User:
Email: ali.ahmadi@example.com
Password: Test12345
Role: spectator

Support User:
Email: support1@example.com
Password: Test12345
Role: support
```

If login fails, make sure `password_hash` exists for these users in the `users` table.

---

## 10. Secure Login Flow

The login process has two steps:

### Step 1: Password Verification

Go to:

```text
Authentication → Secure Login
```

Enter:

```text
Email or Phone
Password
```

Then click:

```text
Verify Password & Send OTP
```

If the password is correct, the system sends/generates an OTP.

### Step 2: OTP Verification

Enter the OTP code and click:

```text
Verify OTP & Login
```

After successful login:

- JWT token is saved in the browser
- User information appears in the sidebar
- The user can access protected features

---

## 11. Profile Page

Go to:

```text
Profile
```

In this section, the user can:

- View profile information
- Update first name
- Update last name
- Update phone number
- Update city
- View wallet balance

Click:

```text
Load Profile
```

to load the current user information.

Click:

```text
Refresh Wallet Balance
```

to show the latest wallet balance.

---

## 12. Wallet Section

Go to:

```text
Wallet
```

The wallet section allows the user to:

- View wallet balance
- Deposit money
- View wallet transactions

### Deposit Money

Enter an amount, for example:

```text
3000000
```

Then click:

```text
Deposit
```

After deposit, the wallet balance should increase.

### Wallet Transactions

Click:

```text
Load Wallet Transactions
```

The system will show wallet transaction history, including deposits, withdrawals, and payment-related transactions.

---

## 13. Ticket Search

Go to:

```text
Tickets → Search Tickets
```

The user can search tickets using advanced filters:

```text
City
Sport
Seat Category
Min Price
Max Price
Match Date
Min Capacity
```

Click:

```text
Search Tickets
```

The system shows ticket cards with:

- Ticket ID
- Sport name
- Teams
- Venue
- City
- Price
- Remaining capacity
- Seat category

This search uses PostgreSQL filters.

---

## 14. Ticket Detail

Go to:

```text
Tickets → Ticket Detail
```

Enter a ticket ID, for example:

```text
11000000
```

Click:

```text
Get Ticket Detail
```

The system shows full ticket information, including:

- Match information
- Venue
- City
- Sport
- Price
- Capacity
- Seat category
- Sport-specific details

---

## 15. Create Reservation

Go to:

```text
Reservations → Create Reservation
```

Enter:

```text
Ticket ID
Quantity
```

Example:

```text
Ticket ID: 11000000
Quantity: 1
```

Click:

```text
Create Reservation
```

If the ticket is active and has enough capacity, the system creates a temporary reservation.

The reservation status will be:

```text
reserved
```

The ticket capacity will decrease.

---

## 16. Change Ticket / Seat

This feature allows a user to change an unpaid reservation to another ticket for the same match.

Go to:

```text
Reservations → Change Ticket / Seat
```

Enter:

```text
Reservation ID
New Ticket ID
```

Important rules:

- Reservation must belong to the logged-in user
- Reservation must still be unpaid
- New ticket must be different from the current ticket
- New ticket must be active
- New ticket must have enough remaining capacity
- New ticket should be for the same match

Click:

```text
Change Ticket
```

If successful, the reservation will be moved to the new ticket and capacities will be updated.

---

## 17. Payment

Go to:

```text
Reservations → Create Payment
```

Enter:

```text
Reservation ID
Payment Method
```

Payment method options:

```text
card
wallet
```

### Card Payment

If `card` is selected, the system creates a successful card payment.

### Wallet Payment

If `wallet` is selected:

- The system checks wallet balance
- If balance is enough, the payment is successful
- The amount is deducted from the wallet
- A wallet transaction is recorded

If balance is not enough, the system returns:

```text
Insufficient wallet balance
```

After a successful payment:

- Payment status becomes `successful`
- Reservation status becomes `paid`

---

## 18. Refund

Go to:

```text
Reservations → Refund
```

Enter:

```text
Payment ID
Reason
```

Click:

```text
Request Refund
```

The system checks the payment and reservation. If valid:

- Refund record is created
- Payment status becomes `refunded`
- Reservation status becomes `cancelled`
- Ticket capacity is restored
- Refund amount is calculated based on cancellation policy

---

## 19. Reservation History

Go to:

```text
Reservations → History
```

Click:

```text
Load History
```

The system shows the logged-in user’s reservation history, including:

- Reservation ID
- Ticket ID
- Sport
- Match
- Venue
- Reservation status
- Payment status
- Refund status

---

## 20. Reports

Go to:

```text
Reports
```

The user can submit a report related to a ticket or reservation.

Example report data:

```text
Ticket ID: 11000000
Reservation ID: 15000016
Report Type: payment_issue
Description: I had a problem with my payment.
```

Click:

```text
Create Report
```

The user can also click:

```text
Load My Reports
```

to view submitted reports.

---

## 21. Support Panel

Login as support:

```text
support1@example.com
Password: Test12345
```

Go to:

```text
Support
```

The support user can:

- View all reports
- Update report status
- View all reservations
- Filter reservations by status
- Update reservation status

Normal users cannot access support actions.

---

## 22. Support Reservation Management

In the support section, support users can manage reservations.

Available actions:

```text
Load Reservations
Update Reservation Status
```

Possible reservation statuses:

```text
reserved
paid
cancelled
expired
```

Example:

```text
Reservation ID: 15000016
New Status: cancelled
Reason: Cancelled by support after review
```

Click:

```text
Update Reservation Status
```

---

## 23. Elasticsearch Search

Go to:

```text
Elasticsearch
```

First click:

```text
Index Tickets
```

This reads active tickets from PostgreSQL and stores them in Elasticsearch.

Then search for words like:

```text
Esteghlal
Azadi
VIP
Tehran
Football
```

Click:

```text
Search
```

Elasticsearch searches in fields such as:

```text
home_team
away_team
sport_name
venue_name
city_name
province
league_or_tournament
facilities
seat_category
```

This is different from normal ticket search because it is full-text search.

---

## 24. Autocomplete

In the Elasticsearch search input, start typing a keyword.

Example:

```text
Az
```

The UI should show related suggestions such as:

```text
Azadi
```

Autocomplete helps the user find tickets faster.

---

## 25. Health Check

To test backend health, open:

```text
GET http://localhost:5001/api/health
```

Expected result:

```json
{
  "success": true,
  "message": "Health check passed"
}
```

This confirms that the backend can connect to PostgreSQL and Redis.

---

## 26. Recommended Full Test Flow

Use this order for final testing:

```text
1. Start PostgreSQL
2. Start Redis
3. Start Elasticsearch with Docker
4. Start Backend
5. Open Frontend with Live Server
6. Login using password and OTP
7. Load Profile
8. Deposit money into Wallet
9. Check Wallet Balance in Profile
10. Search Tickets with filters
11. View Ticket Detail
12. Create Reservation
13. Change Ticket / Seat
14. Pay using Wallet
15. Check Wallet Balance again
16. Create another Reservation
17. Pay using Card
18. Request Refund
19. Load Reservation History
20. Create Report
21. Login as Support
22. Manage Reports
23. Manage Reservations
24. Index Tickets in Elasticsearch
25. Test Elasticsearch Search
26. Test Autocomplete
```

---

## 27. Common Errors and Fixes

### Backend does not start

Check if port 5001 is already in use.

Stop the previous process or restart the terminal.

### Redis error

Make sure Redis is running:

```bash
redis-cli ping
```

Expected:

```text
PONG
```

### Elasticsearch error

Make sure Docker is running, then run:

```bash
docker compose up -d
```

### Invalid login credentials

Check:

- Email is correct
- Password is correct
- `password_hash` exists in the users table
- Backend was restarted after database changes

### Invalid or expired OTP

Generate a new OTP and try again.

### Insufficient wallet balance

Deposit money into the wallet first.

### Route not found

Make sure the latest backend route files are replaced and backend is restarted.

---

## 28. Notes for Submission

Do not upload these files to GitHub:

```text
node_modules/
.env
.DS_Store
```

Recommended files to commit:

```text
backend/
frontend/
README.md
docker-compose.yml
backend/docs/API_DOCUMENTATION.md
database scripts
```

---

## 29. Final Summary

This website provides a full workflow for a sports ticket reservation system. It supports secure authentication, ticket search, reservation, payment, wallet, refund, reports, support management, Elasticsearch search, and autocomplete. The system connects the UI, Backend, PostgreSQL, Redis, and Elasticsearch together to create a complete working web application.
