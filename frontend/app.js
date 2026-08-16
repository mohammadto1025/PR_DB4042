const API_BASE_URL = "http://localhost:5001/api";

let authToken = localStorage.getItem("authToken") || "";
let currentUser = getStoredUser();

function showSection(sectionId, buttonElement) {
  const sections = document.querySelectorAll(".page-section");
  sections.forEach(function (section) {
    section.classList.remove("active-section");
  });

  const navLinks = document.querySelectorAll(".nav-link");
  navLinks.forEach(function (btn) {
    btn.classList.remove("active");
  });

  const targetSection = document.getElementById(sectionId);
  if (targetSection) {
    targetSection.classList.add("active-section");
  }

  if (buttonElement) {
    buttonElement.classList.add("active");
  }

  hideElasticSuggestions();
}

function getStoredUser() {
  try {
    const savedUser = localStorage.getItem("currentUser");
    return savedUser ? JSON.parse(savedUser) : null;
  } catch (error) {
    return null;
  }
}

function saveAuthenticatedUser(user, token) {
  if (token) {
    authToken = token;
    localStorage.setItem("authToken", authToken);
  }

  if (user) {
    currentUser = user;
    localStorage.setItem("currentUser", JSON.stringify(currentUser));
  }

  updateUserStatus();

  if (authToken) {
    refreshWalletPanels();
  }
}

function getUserFullName(user) {
  if (!user) {
    return "Guest User";
  }

  const fullName = ((user.first_name || "") + " " + (user.last_name || "")).trim();
  return fullName || user.email || "Logged In User";
}

function updateUserStatus() {
  const sidebarName = document.getElementById("sidebarUserName");
  const sidebarRole = document.getElementById("sidebarUserRole");
  const sidebarEmail = document.getElementById("sidebarUserEmail");
  const homeName = document.getElementById("homeUserName");
  const homeRole = document.getElementById("homeUserRole");
  const logoutButton = document.getElementById("logoutButton");

  const name = getUserFullName(currentUser);
  const role = currentUser && currentUser.role ? currentUser.role : "Not logged in";
  const email = currentUser && currentUser.email ? currentUser.email : "Login with password + OTP or create an account";

  if (sidebarName) sidebarName.textContent = name;
  if (sidebarRole) sidebarRole.textContent = role;
  if (sidebarEmail) sidebarEmail.textContent = email;
  if (homeName) homeName.textContent = name;

  if (homeRole) {
    if (currentUser) {
      homeRole.textContent = "Role: " + role + " â€¢ " + email;
    } else {
      homeRole.textContent = "Please login or create an account to use authenticated features.";
    }
  }

  if (logoutButton) {
    logoutButton.style.display = currentUser || authToken ? "block" : "none";
  }
}

function logoutUser() {
  authToken = "";
  currentUser = null;
  localStorage.removeItem("authToken");
  localStorage.removeItem("currentUser");
  updateUserStatus();
  updateWalletDisplay(null);
  hideElasticSuggestions();

  const loginResult = document.getElementById("passwordOtpLoginResult");
  if (loginResult) {
    showJson("passwordOtpLoginResult", {
      success: true,
      message: "Logged out successfully",
      data: {
        status: "guest"
      }
    });
  }
}

function showJson(elementId, data) {
  const element = document.getElementById(elementId);

  if (!element) {
    return;
  }

  element.classList.remove("card-results");
  element.classList.add("pretty-results");
  element.innerHTML = renderPrettyResponse(data);
}

function prettyEscape(value) {
  if (value === null || value === undefined || value === "") {
    return "-";
  }

  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function safeText(value) {
  return prettyEscape(value);
}

function prettyLabel(key) {
  return String(key)
    .replaceAll("_", " ")
    .replace(/\b\w/g, function (letter) {
      return letter.toUpperCase();
    });
}

function isDateKey(key) {
  return key.includes("date") || key.includes("time") || key.includes("at");
}

function isMoneyKey(key) {
  return (
    key.includes("price") ||
    key.includes("amount") ||
    key.includes("total") ||
    key.includes("penalty") ||
    key.includes("refund") ||
    key.includes("balance")
  );
}

function prettyValue(key, value) {
  if (value === null || value === undefined || value === "") {
    return "-";
  }

  if (key === "token") {
    return "JWT token generated and saved";
  }

  if (isMoneyKey(key) && !isNaN(Number(value))) {
    return Number(value).toLocaleString("en-US") + " IRR";
  }

  if (isDateKey(key) && String(value).includes("T")) {
    const date = new Date(value);
    return date.toLocaleString("en-US");
  }

  return prettyEscape(value);
}

function formatPrice(value) {
  if (value === null || value === undefined || value === "") {
    return "-";
  }

  return Number(value).toLocaleString("en-US") + " IRR";
}

function formatDate(value) {
  if (!value) {
    return "-";
  }

  const date = new Date(value);
  return date.toLocaleDateString("en-US");
}

function statusClass(value) {
  const text = String(value || "").toLowerCase();

  if (
    text.includes("success") ||
    text.includes("successful") ||
    text.includes("paid") ||
    text.includes("verified") ||
    text.includes("resolved") ||
    text.includes("completed")
  ) {
    return "pretty-status success";
  }

  if (
    text.includes("cancel") ||
    text.includes("refund") ||
    text.includes("reject") ||
    text.includes("failed") ||
    text.includes("error")
  ) {
    return "pretty-status danger";
  }

  if (
    text.includes("reserved") ||
    text.includes("open") ||
    text.includes("pending") ||
    text.includes("sent") ||
    text.includes("progress")
  ) {
    return "pretty-status warning";
  }

  return "pretty-status";
}

function renderPrettyResponse(response) {
  if (!response) {
    return `
      <div class="pretty-empty">
        <h4>No response</h4>
        <p>Nothing was returned from the server.</p>
      </div>
    `;
  }

  const successClass = response.success ? "success" : "danger";
  const message = response.message || (response.success ? "Request completed successfully" : "Request failed");

  let metaHtml = "";

  if (response.count !== undefined) {
    metaHtml += `<span>${response.count} item(s)</span>`;
  }

  if (response.indexed_count !== undefined) {
    metaHtml += `<span>${response.indexed_count} indexed</span>`;
  }

  if (response.query !== undefined) {
    metaHtml += `<span>Query: ${prettyEscape(response.query)}</span>`;
  }

  let bodyData = response.data;

  if (bodyData === undefined) {
    bodyData = {};
    Object.keys(response).forEach(function (key) {
      if (!["success", "message", "count", "query", "indexed_count"].includes(key)) {
        bodyData[key] = response[key];
      }
    });
  }

  return `
    <div class="pretty-header ${successClass}">
      <div>
        <h4>${prettyEscape(message)}</h4>
        <p>${response.success ? "The request was processed by the system." : "Please check the request and try again."}</p>
      </div>
      <span>${response.success ? "SUCCESS" : "ERROR"}</span>
    </div>

    ${metaHtml ? `<div class="pretty-meta">${metaHtml}</div>` : ""}

    ${renderPrettyData(bodyData)}
  `;
}

function renderPrettyData(data) {
  if (Array.isArray(data)) {
    return renderPrettyArray(data);
  }

  if (typeof data === "object" && data !== null) {
    return renderPrettyObject(data);
  }

  return `<div class="pretty-single">${prettyEscape(data)}</div>`;
}

function renderPrettyArray(items) {
  if (!items || items.length === 0) {
    return `
      <div class="pretty-empty">
        <h4>No data found</h4>
        <p>There are no records to display.</p>
      </div>
    `;
  }

  const cards = items.map(function (item, index) {
    return `
      <div class="pretty-card">
        <div class="pretty-card-title">
          <h4>${getCardTitle(item, index)}</h4>
          ${getMainStatusBadge(item)}
        </div>
        ${renderPrettyObjectFields(item)}
      </div>
    `;
  }).join("");

  return `<div class="pretty-list">${cards}</div>`;
}

function renderPrettyObject(obj) {
  const keys = Object.keys(obj);

  if (keys.length === 0) {
    return `
      <div class="pretty-empty">
        <h4>No details</h4>
        <p>No extra data is available.</p>
      </div>
    `;
  }

  const normalFields = {};
  const nestedSections = [];

  keys.forEach(function (key) {
    const value = obj[key];

    if (value && typeof value === "object") {
      nestedSections.push({ key: key, value: value });
    } else {
      normalFields[key] = value;
    }
  });

  let html = "";

  if (Object.keys(normalFields).length > 0) {
    html += `<div class="pretty-card">${renderPrettyObjectFields(normalFields)}</div>`;
  }

  nestedSections.forEach(function (section) {
    html += `
      <div class="pretty-section-card">
        <h4>${prettyLabel(section.key)}</h4>
        ${renderPrettyData(section.value)}
      </div>
    `;
  });

  return html;
}

function renderPrettyObjectFields(obj) {
  return `
    <div class="pretty-field-grid">
      ${Object.keys(obj).map(function (key) {
        const value = obj[key];

        if (value && typeof value === "object") {
          return "";
        }

        const isStatus = key.includes("status") || key === "role";

        return `
          <div class="pretty-field">
            <span>${prettyLabel(key)}</span>
            ${
              isStatus
                ? `<strong class="${statusClass(value)}">${prettyValue(key, value)}</strong>`
                : `<strong>${prettyValue(key, value)}</strong>`
            }
          </div>
        `;
      }).join("")}
    </div>
  `;
}

function getCardTitle(item, index) {
  if (item.home_team && item.away_team) {
    return prettyEscape(item.home_team) + " vs " + prettyEscape(item.away_team);
  }

  if (item.first_name || item.last_name) {
    return prettyEscape((item.first_name || "") + " " + (item.last_name || ""));
  }

  if (item.report_type) {
    return "Report #" + prettyEscape(item.report_id || index + 1);
  }

  if (item.reservation_id) {
    return "Reservation #" + prettyEscape(item.reservation_id);
  }

  if (item.payment_id) {
    return "Payment #" + prettyEscape(item.payment_id);
  }

  if (item.refund_id) {
    return "Refund #" + prettyEscape(item.refund_id);
  }

  if (item.ticket_id) {
    return "Ticket #" + prettyEscape(item.ticket_id);
  }

  return "Record #" + (index + 1);
}

function getMainStatusBadge(item) {
  const status =
    item.reservation_status ||
    item.payment_status ||
    item.refund_status ||
    item.status ||
    item.role;

  if (!status) {
    return "";
  }

  return `<span class="${statusClass(status)}">${prettyEscape(status)}</span>`;
}

function fillTicketId(ticketId) {
  const ticketDetailInput = document.getElementById("ticketId");
  const reservationInput = document.getElementById("reservationTicketId");
  const changeTicketInput = document.getElementById("changeNewTicketId");

  if (ticketDetailInput) {
    ticketDetailInput.value = ticketId;
  }

  if (reservationInput) {
    reservationInput.value = ticketId;
  }

  if (changeTicketInput) {
    changeTicketInput.value = ticketId;
  }
}

function renderTicketCards(elementId, responseData, title) {
  const container = document.getElementById(elementId);
  container.classList.remove("pretty-results");
  container.classList.add("card-results");

  if (!responseData.success) {
    container.innerHTML = `
      <div class="empty-state">
        <h4>Request failed</h4>
        <p>${safeText(responseData.message)}</p>
      </div>
    `;
    return;
  }

  const tickets = responseData.data || [];

  if (tickets.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <h4>No tickets found</h4>
        <p>Try another city, sport, team, or venue.</p>
      </div>
    `;
    return;
  }

  const cards = tickets.map(function (ticket) {
    const scoreBadge = ticket.score
      ? `<span class="score-badge">Score ${Number(ticket.score).toFixed(2)}</span>`
      : "";

    return `
      <article class="ticket-card">
        <div class="ticket-top">
          <div>
            <span class="ticket-sport">${safeText(ticket.sport_name)}</span>
            <h3>${safeText(ticket.home_team)} vs ${safeText(ticket.away_team)}</h3>
          </div>
          ${scoreBadge}
        </div>

        <div class="ticket-info-grid">
          <div><span>Ticket ID</span><strong>${safeText(ticket.ticket_id)}</strong></div>
          <div><span>Price</span><strong>${formatPrice(ticket.price)}</strong></div>
          <div><span>Seat</span><strong>${safeText(ticket.seat_category)}</strong></div>
          <div><span>Capacity</span><strong>${safeText(ticket.capacity_remaining)}</strong></div>
          <div><span>Date</span><strong>${formatDate(ticket.match_date)}</strong></div>
          <div><span>Time</span><strong>${safeText(ticket.match_time)}</strong></div>
        </div>

        <div class="ticket-location">
          <p>${safeText(ticket.venue_name)} â€¢ ${safeText(ticket.city_name)}</p>
          <small>${safeText(ticket.league_or_tournament || ticket.province || "")}</small>
        </div>

        <div class="ticket-actions">
          <button class="small-action-btn" onclick="fillTicketId(${Number(ticket.ticket_id)})">Use Ticket ID</button>
        </div>
      </article>
    `;
  }).join("");

  container.innerHTML = `
    <div class="ticket-summary">
      <div>
        <h4>${safeText(title)}</h4>
        <p>${tickets.length} ticket(s) found</p>
      </div>
    </div>
    <div class="ticket-card-list">${cards}</div>
  `;
}

function renderTicketDetail(elementId, responseData) {
  const container = document.getElementById(elementId);
  container.classList.remove("pretty-results");
  container.classList.add("card-results");

  if (!responseData.success) {
    container.innerHTML = `
      <div class="empty-state">
        <h4>Ticket not found</h4>
        <p>${safeText(responseData.message)}</p>
      </div>
    `;
    return;
  }

  const ticket = responseData.data;

  container.innerHTML = `
    <article class="ticket-detail-card">
      <div class="ticket-detail-header">
        <div>
          <span class="ticket-sport">${safeText(ticket.sport_name)}</span>
          <h3>${safeText(ticket.home_team)} vs ${safeText(ticket.away_team)}</h3>
          <p>${safeText(ticket.venue_name)} â€¢ ${safeText(ticket.city_name)}</p>
        </div>
        <div class="price-pill">${formatPrice(ticket.price)}</div>
      </div>

      <div class="ticket-info-grid detail-grid">
        <div><span>Ticket ID</span><strong>${safeText(ticket.ticket_id)}</strong></div>
        <div><span>Seat Category</span><strong>${safeText(ticket.seat_category)}</strong></div>
        <div><span>Capacity</span><strong>${safeText(ticket.capacity_remaining)}</strong></div>
        <div><span>Date</span><strong>${formatDate(ticket.match_date)}</strong></div>
        <div><span>Time</span><strong>${safeText(ticket.match_time)}</strong></div>
        <div><span>Status</span><strong>${safeText(ticket.match_status)}</strong></div>
        <div><span>Section</span><strong>${safeText(ticket.section_number)}</strong></div>
        <div><span>Row</span><strong>${safeText(ticket.row_number)}</strong></div>
        <div><span>Seat</span><strong>${safeText(ticket.seat_number)}</strong></div>
      </div>

      <div class="detail-note">
        <strong>Facilities:</strong>
        <p>${safeText(ticket.facilities)}</p>
      </div>

      <button class="small-action-btn full" onclick="fillTicketId(${Number(ticket.ticket_id)})">Use this ticket for reservation</button>
    </article>
  `;
}

async function signup() {
  try {
    const firstName = document.getElementById("signupFirstName").value;
    const lastName = document.getElementById("signupLastName").value;
    const email = document.getElementById("signupEmail").value;
    const phone = document.getElementById("signupPhone").value;
    const password = document.getElementById("signupPassword").value;
    const cityId = document.getElementById("signupCityId").value;

    const response = await fetch(API_BASE_URL + "/auth/signup", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        first_name: firstName,
        last_name: lastName,
        email: email,
        phone: phone,
        password: password,
        city_id: Number(cityId)
      })
    });

    const data = await response.json();

    if (data.success && data.data && data.data.token) {
      saveAuthenticatedUser(data.data.user, data.data.token);
      refreshWalletPanels();
    }

    showJson("signupResult", data);
  } catch (error) {
    document.getElementById("signupResult").textContent = "Error: " + error.message;
  }
}

async function sendOtp() {
  try {
    const identifier = document.getElementById("identifier").value;

    if (!identifier) {
      document.getElementById("loginResult").textContent = "Please enter email or phone.";
      return;
    }

    const response = await fetch(API_BASE_URL + "/auth/send-otp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identifier: identifier, purpose: "login" })
    });

    const data = await response.json();
    showJson("loginResult", data);
  } catch (error) {
    document.getElementById("loginResult").textContent = "Error: " + error.message;
  }
}

async function verifyOtp() {
  try {
    const identifier = document.getElementById("identifier").value;
    const otp = document.getElementById("otp").value;

    const response = await fetch(API_BASE_URL + "/auth/verify-otp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identifier: identifier, purpose: "login", otp: otp })
    });

    const data = await response.json();

    if (data.success && data.data && data.data.token) {
      saveAuthenticatedUser(data.data.user, data.data.token);
      refreshWalletPanels();
    }

    showJson("loginResult", data);
  } catch (error) {
    document.getElementById("loginResult").textContent = "Error: " + error.message;
  }
}

async function requestPasswordLoginOtp() {
  try {
    const identifier = document.getElementById("passwordLoginIdentifier").value;
    const password = document.getElementById("passwordLoginPassword").value;

    if (!identifier || !password) {
      document.getElementById("passwordOtpLoginResult").textContent = "Please enter email/phone and password.";
      return;
    }

    const response = await fetch(API_BASE_URL + "/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identifier: identifier, password: password })
    });

    const data = await response.json();

    if (data.success) {
      document.getElementById("passwordLoginOtp").focus();
    }

    showJson("passwordOtpLoginResult", data);
  } catch (error) {
    document.getElementById("passwordOtpLoginResult").textContent = "Error: " + error.message;
  }
}

async function verifyPasswordLoginOtp() {
  try {
    const identifier = document.getElementById("passwordLoginIdentifier").value;
    const otp = document.getElementById("passwordLoginOtp").value;

    if (!identifier || !otp) {
      document.getElementById("passwordOtpLoginResult").textContent = "Please enter email/phone and OTP.";
      return;
    }

    const response = await fetch(API_BASE_URL + "/auth/login/verify-otp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identifier: identifier, otp: otp })
    });

    const data = await response.json();

    if (data.success && data.data && data.data.token) {
      saveAuthenticatedUser(data.data.user, data.data.token);
      refreshWalletPanels();
    }

    showJson("passwordOtpLoginResult", data);
  } catch (error) {
    document.getElementById("passwordOtpLoginResult").textContent = "Error: " + error.message;
  }
}

async function getMyProfile() {
  try {
    const response = await fetch(API_BASE_URL + "/users/me", {
      method: "GET",
      headers: { "Authorization": "Bearer " + authToken }
    });

    const data = await response.json();
    showJson("profileResult", data);

    if (data.success && data.data) {
      saveAuthenticatedUser(data.data, authToken);

      document.getElementById("updateFirstName").value = data.data.first_name || "";
      document.getElementById("updateLastName").value = data.data.last_name || "";
      document.getElementById("updatePhone").value = data.data.phone || "";

      if (data.data.city_id) {
        document.getElementById("updateCityId").value = data.data.city_id;
      }

      refreshWalletPanels();
    }
  } catch (error) {
    document.getElementById("profileResult").textContent = "Error: " + error.message;
  }
}

async function updateMyProfile() {
  try {
    const firstName = document.getElementById("updateFirstName").value;
    const lastName = document.getElementById("updateLastName").value;
    const phone = document.getElementById("updatePhone").value;
    const cityId = document.getElementById("updateCityId").value;

    const body = {};
    if (firstName) body.first_name = firstName;
    if (lastName) body.last_name = lastName;
    if (phone) body.phone = phone;
    if (cityId) body.city_id = Number(cityId);

    const response = await fetch(API_BASE_URL + "/users/me", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + authToken
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();

    if (data.success && data.data) {
      saveAuthenticatedUser({
        ...(currentUser || {}),
        ...data.data
      }, authToken);
    }

    showJson("updateProfileResult", data);
  } catch (error) {
    document.getElementById("updateProfileResult").textContent = "Error: " + error.message;
  }
}


function formatWalletBalance(value) {
  const numberValue = Number(value || 0);
  return numberValue.toLocaleString("en-US") + " IRR";
}

function extractWallet(response) {
  if (!response || !response.data) {
    return null;
  }

  if (response.data.wallet) {
    return response.data.wallet;
  }

  if (response.data.wallet_id !== undefined) {
    return response.data;
  }

  return null;
}

function updateWalletDisplay(wallet) {
  const sidebarWalletBalance = document.getElementById("sidebarWalletBalance");
  const profileWalletBalance = document.getElementById("profileWalletBalance");
  const walletPageBalance = document.getElementById("walletPageBalance");

  const text = wallet && wallet.balance !== undefined
    ? formatWalletBalance(wallet.balance)
    : "-";

  if (sidebarWalletBalance) sidebarWalletBalance.textContent = "Wallet: " + text;
  if (profileWalletBalance) profileWalletBalance.textContent = text;
  if (walletPageBalance) walletPageBalance.textContent = text;
}

async function refreshWalletPanels(resultElementId) {
  if (!authToken) {
    updateWalletDisplay(null);
    return;
  }

  try {
    const response = await fetch(API_BASE_URL + "/wallet/me", {
      method: "GET",
      headers: { "Authorization": "Bearer " + authToken }
    });

    const data = await response.json();
    const wallet = extractWallet(data);

    if (data.success && wallet) {
      updateWalletDisplay(wallet);
    }

    if (resultElementId) {
      showJson(resultElementId, data);
    }
  } catch (error) {
    if (resultElementId) {
      document.getElementById(resultElementId).textContent = "Error: " + error.message;
    }
  }
}

async function loadWalletBalance(resultElementId) {
  await refreshWalletPanels(resultElementId || "walletResult");
}

async function depositWallet() {
  try {
    const amount = document.getElementById("walletDepositAmount").value;
    const description = document.getElementById("walletDepositDescription").value || "User wallet deposit";

    if (!amount || Number(amount) <= 0) {
      document.getElementById("walletDepositResult").textContent = "Please enter a valid deposit amount.";
      return;
    }

    const response = await fetch(API_BASE_URL + "/wallet/deposit", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + authToken
      },
      body: JSON.stringify({
        amount: Number(amount),
        description: description
      })
    });

    const data = await response.json();
    const wallet = extractWallet(data);

    if (data.success && wallet) {
      updateWalletDisplay(wallet);
    }

    showJson("walletDepositResult", data);
  } catch (error) {
    document.getElementById("walletDepositResult").textContent = "Error: " + error.message;
  }
}

async function loadWalletTransactions() {
  try {
    const response = await fetch(API_BASE_URL + "/wallet/transactions", {
      method: "GET",
      headers: { "Authorization": "Bearer " + authToken }
    });

    const data = await response.json();
    showJson("walletTransactionsResult", data);
  } catch (error) {
    document.getElementById("walletTransactionsResult").textContent = "Error: " + error.message;
  }
}

async function searchTickets() {
  try {
    const cityId = document.getElementById("cityId").value;
    const sportId = document.getElementById("sportId").value;
    const seatCategoryId = document.getElementById("seatCategoryId").value;
    const minPrice = document.getElementById("minPrice").value;
    const maxPrice = document.getElementById("maxPrice").value;
    const matchDate = document.getElementById("matchDate").value;
    const minCapacity = document.getElementById("minCapacity").value;

    const params = new URLSearchParams();

    if (cityId) params.append("city_id", cityId);
    if (sportId) params.append("sport_id", sportId);
    if (seatCategoryId) params.append("seat_category_id", seatCategoryId);
    if (minPrice) params.append("min_price", minPrice);
    if (maxPrice) params.append("max_price", maxPrice);
    if (matchDate) params.append("match_date", matchDate);
    if (minCapacity) params.append("min_capacity", minCapacity);

    const url = API_BASE_URL + "/tickets/search" + (params.toString() ? "?" + params.toString() : "");

    const response = await fetch(url);
    const data = await response.json();

    renderTicketCards("ticketsResult", data, "Advanced Ticket Search");
  } catch (error) {
    document.getElementById("ticketsResult").textContent = "Error: " + error.message;
  }
}

async function getTicketDetail() {
  try {
    const ticketId = document.getElementById("ticketId").value;
    const response = await fetch(API_BASE_URL + "/tickets/" + ticketId);
    const data = await response.json();

    renderTicketDetail("ticketDetailResult", data);
  } catch (error) {
    document.getElementById("ticketDetailResult").textContent = "Error: " + error.message;
  }
}

async function createReservation() {
  try {
    const ticketId = document.getElementById("reservationTicketId").value;
    const quantity = document.getElementById("quantity").value;

    const response = await fetch(API_BASE_URL + "/reservations", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + authToken
      },
      body: JSON.stringify({ ticket_id: Number(ticketId), quantity: Number(quantity) })
    });

    const data = await response.json();
    showJson("reservationResult", data);
  } catch (error) {
    document.getElementById("reservationResult").textContent = "Error: " + error.message;
  }
}

async function changeReservationTicket() {
  try {
    const reservationId = document.getElementById("changeReservationId").value;
    const newTicketId = document.getElementById("changeNewTicketId").value;

    if (!reservationId || !newTicketId) {
      document.getElementById("changeTicketResult").textContent = "Please enter reservation id and new ticket id.";
      return;
    }

    const response = await fetch(API_BASE_URL + "/reservations/" + reservationId + "/change-ticket", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + authToken
      },
      body: JSON.stringify({
        new_ticket_id: Number(newTicketId)
      })
    });

    const data = await response.json();
    showJson("changeTicketResult", data);
  } catch (error) {
    document.getElementById("changeTicketResult").textContent = "Error: " + error.message;
  }
}

async function createPayment() {
  try {
    const reservationId = document.getElementById("paymentReservationId").value;
    const paymentMethod = document.getElementById("paymentMethod").value || "card";

    const response = await fetch(API_BASE_URL + "/payments", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + authToken
      },
      body: JSON.stringify({ reservation_id: Number(reservationId), payment_method: paymentMethod })
    });

    const data = await response.json();

    if (data.success) {
      refreshWalletPanels();
    }

    showJson("paymentResult", data);
  } catch (error) {
    document.getElementById("paymentResult").textContent = "Error: " + error.message;
  }
}

async function createRefund() {
  try {
    const paymentId = document.getElementById("refundPaymentId").value;
    const reason = document.getElementById("refundReason").value || "User requested refund";

    const response = await fetch(API_BASE_URL + "/refunds", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + authToken
      },
      body: JSON.stringify({ payment_id: Number(paymentId), reason: reason })
    });

    const data = await response.json();
    showJson("refundResult", data);
  } catch (error) {
    document.getElementById("refundResult").textContent = "Error: " + error.message;
  }
}

async function getReservationHistory() {
  try {
    const response = await fetch(API_BASE_URL + "/reservations/history", {
      method: "GET",
      headers: { "Authorization": "Bearer " + authToken }
    });

    const data = await response.json();
    showJson("historyResult", data);
  } catch (error) {
    document.getElementById("historyResult").textContent = "Error: " + error.message;
  }
}

async function createReport() {
  try {
    const ticketId = document.getElementById("reportTicketId").value;
    const reservationId = document.getElementById("reportReservationId").value;
    const reportType = document.getElementById("reportType").value;
    const description = document.getElementById("reportDescription").value;

    const response = await fetch(API_BASE_URL + "/reports", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + authToken
      },
      body: JSON.stringify({
        ticket_id: Number(ticketId),
        reservation_id: Number(reservationId),
        report_type: reportType,
        description: description
      })
    });

    const data = await response.json();
    showJson("createReportResult", data);
  } catch (error) {
    document.getElementById("createReportResult").textContent = "Error: " + error.message;
  }
}

async function getMyReports() {
  try {
    const response = await fetch(API_BASE_URL + "/reports/my", {
      method: "GET",
      headers: { "Authorization": "Bearer " + authToken }
    });

    const data = await response.json();
    showJson("myReportsResult", data);
  } catch (error) {
    document.getElementById("myReportsResult").textContent = "Error: " + error.message;
  }
}

async function getSupportReports() {
  try {
    const response = await fetch(API_BASE_URL + "/support/reports", {
      method: "GET",
      headers: { "Authorization": "Bearer " + authToken }
    });

    const data = await response.json();
    showJson("supportResult", data);
  } catch (error) {
    document.getElementById("supportResult").textContent = "Error: " + error.message;
  }
}

async function updateSupportReport() {
  try {
    const reportId = document.getElementById("supportReportId").value;
    const status = document.getElementById("supportReportStatus").value;

    const response = await fetch(API_BASE_URL + "/support/reports/" + reportId, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + authToken
      },
      body: JSON.stringify({ status: status })
    });

    const data = await response.json();
    showJson("supportResult", data);
  } catch (error) {
    document.getElementById("supportResult").textContent = "Error: " + error.message;
  }
}

async function getSupportReservations() {
  try {
    const status = document.getElementById("supportReservationStatusFilter").value;

    let url = API_BASE_URL + "/support/reservations";

    if (status) {
      url += "?status=" + encodeURIComponent(status);
    }

    const response = await fetch(url, {
      method: "GET",
      headers: {
        "Authorization": "Bearer " + authToken
      }
    });

    const data = await response.json();
    showJson("supportReservationResult", data);
  } catch (error) {
    document.getElementById("supportReservationResult").textContent = "Error: " + error.message;
  }
}

async function updateSupportReservationStatus() {
  try {
    const reservationId = document.getElementById("supportReservationId").value;
    const status = document.getElementById("supportReservationNewStatus").value;
    const reason = document.getElementById("supportReservationReason").value || "Updated by support";

    const response = await fetch(API_BASE_URL + "/support/reservations/" + reservationId + "/status", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + authToken
      },
      body: JSON.stringify({
        status: status,
        reason: reason
      })
    });

    const data = await response.json();
    showJson("supportReservationResult", data);
  } catch (error) {
    document.getElementById("supportReservationResult").textContent = "Error: " + error.message;
  }
}

async function indexTicketsElastic() {
  try {
    const response = await fetch(API_BASE_URL + "/search/index-tickets", {
      method: "POST"
    });

    const data = await response.json();
    showJson("elasticSearchResult", data);
  } catch (error) {
    document.getElementById("elasticSearchResult").textContent = "Error: " + error.message;
  }
}

async function searchTicketsElastic() {
  try {
    const searchText = document.getElementById("elasticSearchText").value;

    if (!searchText) {
      document.getElementById("elasticSearchResult").textContent = "Please enter search text.";
      return;
    }

    hideElasticSuggestions();

    const response = await fetch(API_BASE_URL + "/search/tickets?q=" + encodeURIComponent(searchText));
    const data = await response.json();

    renderTicketCards("elasticSearchResult", data, "Elasticsearch Ticket Search");
  } catch (error) {
    document.getElementById("elasticSearchResult").textContent = "Error: " + error.message;
  }
}

let elasticAutocompleteTimer = null;

function hideElasticSuggestions() {
  const box = document.getElementById("elasticSuggestions");
  if (box) {
    box.classList.remove("show");
    box.innerHTML = "";
  }
}

function useElasticSuggestion(term) {
  const input = document.getElementById("elasticSearchText");
  if (input) {
    input.value = term;
  }

  hideElasticSuggestions();
  searchTicketsElastic();
}

async function handleElasticAutocomplete() {
  const input = document.getElementById("elasticSearchText");
  const box = document.getElementById("elasticSuggestions");

  if (!input || !box) {
    return;
  }

  const searchText = input.value.trim();

  clearTimeout(elasticAutocompleteTimer);

  if (searchText.length < 2) {
    hideElasticSuggestions();
    return;
  }

  box.classList.add("show");
  box.innerHTML = `<div class="autocomplete-loading">Searching suggestions...</div>`;

  elasticAutocompleteTimer = setTimeout(async function () {
    try {
      const response = await fetch(API_BASE_URL + "/search/tickets?q=" + encodeURIComponent(searchText));
      const data = await response.json();

      if (!data.success || !data.data || data.data.length === 0) {
        box.innerHTML = `<div class="autocomplete-loading">No suggestion found</div>`;
        return;
      }

      renderElasticSuggestions(data.data, searchText);
    } catch (error) {
      box.innerHTML = `<div class="autocomplete-loading">Autocomplete error</div>`;
    }
  }, 300);
}

function renderElasticSuggestions(tickets, searchText) {
  const box = document.getElementById("elasticSuggestions");

  if (!box) {
    return;
  }

  const suggestions = [];
  const seen = {};

  function addSuggestion(label, subtitle, term) {
    if (!term || seen[term]) {
      return;
    }

    seen[term] = true;
    suggestions.push({
      label: label,
      subtitle: subtitle,
      term: term
    });
  }

  tickets.forEach(function (ticket) {
    addSuggestion(ticket.home_team, "Home team", ticket.home_team);
    addSuggestion(ticket.away_team, "Away team", ticket.away_team);
    addSuggestion(ticket.venue_name, "Venue", ticket.venue_name);
    addSuggestion(ticket.city_name, "City", ticket.city_name);
    addSuggestion(ticket.sport_name, "Sport", ticket.sport_name);
    addSuggestion(ticket.seat_category, "Seat category", ticket.seat_category);
    addSuggestion(ticket.league_or_tournament, "League", ticket.league_or_tournament);
  });

  const filteredSuggestions = suggestions
    .filter(function (item) {
      return String(item.term).toLowerCase().includes(searchText.toLowerCase()) || suggestions.length < 5;
    })
    .slice(0, 8);

  if (filteredSuggestions.length === 0) {
    box.innerHTML = `<div class="autocomplete-loading">No suggestion found</div>`;
    return;
  }

  box.innerHTML = filteredSuggestions.map(function (item) {
    return `
      <button type="button" class="autocomplete-item" onclick="useElasticSuggestion('${String(item.term).replaceAll("'", "\'")}')">
        <strong>${safeText(item.label)}</strong>
        <span>${safeText(item.subtitle)}</span>
      </button>
    `;
  }).join("");
}

async function loadCitiesForDropdowns() {
  try {
    const response = await fetch(API_BASE_URL + "/cities");
    const data = await response.json();

    if (!data.success) {
      return;
    }

    const signupCitySelect = document.getElementById("signupCityId");
    const updateCitySelect = document.getElementById("updateCityId");
    const searchCitySelect = document.getElementById("cityId");

    const cityOptions = data.data.map(function (city) {
      return `<option value="${city.city_id}">${city.name} - ${city.province}</option>`;
    }).join("");

    if (signupCitySelect) {
      signupCitySelect.innerHTML = `<option value="">Select city</option>` + cityOptions;
    }

    if (updateCitySelect) {
      updateCitySelect.innerHTML = `<option value="">Select city</option>` + cityOptions;
    }

    if (searchCitySelect) {
      searchCitySelect.innerHTML = `<option value="">All cities</option>` + cityOptions;
    }
  } catch (error) {
    console.log("Could not load cities:", error.message);
  }
}

async function loadSportsForDropdowns() {
  try {
    const response = await fetch(API_BASE_URL + "/sports");
    const data = await response.json();

    if (!data.success) {
      return;
    }

    const searchSportSelect = document.getElementById("sportId");

    const sportOptions = data.data.map(function (sport) {
      return `<option value="${sport.sport_id}">${sport.name}</option>`;
    }).join("");

    if (searchSportSelect) {
      searchSportSelect.innerHTML = `<option value="">All sports</option>` + sportOptions;
    }
  } catch (error) {
    console.log("Could not load sports:", error.message);
  }
}

async function loadSeatCategoriesForDropdowns() {
  try {
    const response = await fetch(API_BASE_URL + "/seat-categories");
    const data = await response.json();

    if (!data.success) {
      return;
    }

    const searchSeatSelect = document.getElementById("seatCategoryId");

    const seatOptions = data.data.map(function (category) {
      return `<option value="${category.seat_category_id}">${category.name}</option>`;
    }).join("");

    if (searchSeatSelect) {
      searchSeatSelect.innerHTML = `<option value="">All seat categories</option>` + seatOptions;
    }
  } catch (error) {
    console.log("Could not load seat categories:", error.message);
  }
}

document.addEventListener("DOMContentLoaded", function () {
  loadCitiesForDropdowns();
  loadSportsForDropdowns();
  loadSeatCategoriesForDropdowns();
  updateUserStatus();

  if (authToken) {
    refreshWalletPanels();
  }

  document.addEventListener("click", function (event) {
    const autocompleteWrapper = document.querySelector(".autocomplete-wrapper");
    if (autocompleteWrapper && !autocompleteWrapper.contains(event.target)) {
      hideElasticSuggestions();
    }
  });
});