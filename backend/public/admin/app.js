const API_BASE = ''; // relative URLs since we are serving statically

// Auth state helper
function getAuth() {
  const admin = localStorage.getItem('kuakata_admin');
  return admin ? JSON.parse(admin) : null;
}

function setAuth(adminData) {
  localStorage.setItem('kuakata_admin', JSON.stringify(adminData));
}

function clearAuth() {
  localStorage.removeItem('kuakata_admin');
}

// Global cached data
let hotels = [];
let managers = [];
let spots = [];
let reviews = [];
let complaints = [];
let slides = [];
let bikes = [];
let vans = [];
let boards = [];
let boats = [];
let foods = [];

// ==================== APP INITIALIZE ====================
document.addEventListener('DOMContentLoaded', () => {
  setupAuth();
  setupNavigation();
  setupForms();
});

// Setup Login / Auth Checks
function setupAuth() {
  const auth = getAuth();
  if (auth) {
    showDashboard();
  } else {
    showLogin();
  }

  // Handle Login submission
  document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value.trim();
    const errorEl = document.getElementById('auth-error');

    errorEl.classList.add('hidden');

    try {
      const response = await fetch(`${API_BASE}/api/admin/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({ username, password })
      });

      const data = await response.json();

      if (response.ok) {
        setAuth({
          name: data.name,
          email: data.email,
          username: username
        });
        showDashboard();
      } else {
        errorEl.textContent = data.error || 'Invalid credentials. Please try again.';
        errorEl.classList.remove('hidden');
      }
    } catch (err) {
      errorEl.textContent = 'Server connection failed. Is the server running?';
      errorEl.classList.remove('hidden');
    }
  });

  // Logout Button
  document.getElementById('btn-logout').addEventListener('click', () => {
    clearAuth();
    showLogin();
  });
}

function showLogin() {
  document.getElementById('auth-container').classList.remove('hidden');
  document.getElementById('dashboard-container').classList.add('hidden');
}

function showDashboard() {
  document.getElementById('auth-container').classList.add('hidden');
  document.getElementById('dashboard-container').classList.remove('hidden');
  
  // Set user badge name
  const auth = getAuth();
  if (auth) {
    document.querySelector('.user-name').textContent = auth.name || 'Super Admin';
  }

  // Load overview data
  loadAllData();
}

// Setup SPA Routing Navigation
function setupNavigation() {
  const navItems = document.querySelectorAll('.nav-item');
  const views = document.querySelectorAll('.content-view');

  navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const target = item.getAttribute('data-target');

      // Update Nav active state
      navItems.forEach(n => n.classList.remove('active'));
      item.classList.add('active');

      // Update Page Title in Navbar
      let title = 'Dashboard Overview';
      if (target === 'view-hotels') title = 'Hotels Directory';
      if (target === 'view-managers') title = 'Manager Accounts';
      if (target === 'view-complaints') title = 'Reviews & Complaints';
      if (target === 'view-spots') title = 'Popular Spots';
      if (target === 'view-slider') title = 'Homepage Image Slider';
      if (target === 'view-bikes') title = 'Bikes Directory';
      if (target === 'view-vans') title = 'Vans Directory';
      if (target === 'view-boards') title = 'Speedboats Directory';
      if (target === 'view-boats') title = 'Boats Directory';
      if (target === 'view-foods') title = 'Restaurants & Food';
      document.getElementById('page-title').textContent = title;

      // Switch View
      views.forEach(v => {
        if (v.id === target) {
          v.classList.remove('hidden');
          v.classList.add('active');
        } else {
          v.classList.add('hidden');
          v.classList.remove('active');
        }
      });

      // Reload view specific data
      refreshViewData(target);
    });
  });

  // Handle Inner Sub-tabs (Reviews / Complaints)
  const subtabBtns = document.querySelectorAll('.subtab-btn');
  const subviews = document.querySelectorAll('.subview-content');

  subtabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const target = btn.getAttribute('data-subtarget');
      subtabBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      subviews.forEach(sv => {
        if (sv.id === target) {
          sv.classList.remove('hidden');
        } else {
          sv.classList.add('hidden');
        }
      });
    });
  });

  // Handle Overview "View All" redirects
  document.querySelectorAll('.view-all-link').forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      const target = link.getAttribute('data-target');
      const navItem = document.querySelector(`.nav-item[data-target="${target}"]`);
      if (navItem) {
        navItem.click();
      }
    });
  });
}

// Refresh data depending on current view
function refreshViewData(viewId) {
  if (viewId === 'view-overview') loadAllData();
  if (viewId === 'view-hotels') loadHotels();
  if (viewId === 'view-managers') loadManagers();
  if (viewId === 'view-complaints') loadComplaintsAndReviews();
  if (viewId === 'view-spots') loadSpots();
  if (viewId === 'view-slider') loadSlides();
  if (viewId === 'view-bikes') loadBikes();
  if (viewId === 'view-vans') loadVans();
  if (viewId === 'view-boards') loadBoards();
  if (viewId === 'view-boats') loadBoats();
  if (viewId === 'view-foods') loadFoods();
}

// API Loader: Load all app stats and lists
async function loadAllData() {
  await Promise.all([
    loadHotels(),
    loadManagers(),
    loadSpots(),
    loadComplaintsAndReviews(),
    loadSlides(),
    loadBikes(),
    loadVans(),
    loadBoards(),
    loadBoats(),
    loadFoods()
  ]);

  // Update Stats counts on Overview
  document.getElementById('stat-count-hotels').textContent = hotels.length;
  document.getElementById('stat-count-managers').textContent = managers.length;
  document.getElementById('stat-count-spots').textContent = spots.length;
  
  const pendingCount = complaints.filter(c => c.status === 'Pending').length;
  document.getElementById('stat-count-complaints').textContent = pendingCount;

  // Populates Overview Mini Lists
  populateOverviewLists();
}

// Fetch hotels list
async function loadHotels() {
  try {
    const res = await fetch(`${API_BASE}/api/content/hotel`);
    hotels = await res.json();
    populateHotelsTable();
  } catch (err) {
    console.error('Error loading hotels', err);
  }
}

// Fetch managers list
async function loadManagers() {
  try {
    const res = await fetch(`${API_BASE}/api/admin/managers`);
    managers = await res.json();
    populateManagersTable();
  } catch (err) {
    console.error('Error loading managers', err);
  }
}

// Fetch popular spots list
async function loadSpots() {
  try {
    const res = await fetch(`${API_BASE}/api/content/spot`);
    spots = await res.json();
    populateSpotsTable();
  } catch (err) {
    console.error('Error loading spots', err);
  }
}

// Fetch reviews and complaints
async function loadComplaintsAndReviews() {
  try {
    const [reviewsRes, complaintsRes] = await Promise.all([
      fetch(`${API_BASE}/api/admin/reviews`),
      fetch(`${API_BASE}/api/admin/complaints`)
    ]);

    reviews = await reviewsRes.json();
    complaints = await complaintsRes.json();

    populateReviewsTable();
    populateComplaintsTable();
  } catch (err) {
    console.error('Error loading reviews/complaints', err);
  }
}

// Fetch homepage slides
async function loadSlides() {
  try {
    const res = await fetch(`${API_BASE}/api/content/slider`);
    slides = await res.json();
    populateSliderTable();
  } catch (err) {
    console.error('Error loading slides', err);
  }
}

// Fetch bikes
async function loadBikes() {
  try {
    const res = await fetch(`${API_BASE}/api/content/bike`);
    bikes = await res.json();
    populateBikesTable();
  } catch (err) {
    console.error('Error loading bikes', err);
  }
}

// Fetch vans
async function loadVans() {
  try {
    const res = await fetch(`${API_BASE}/api/content/van`);
    vans = await res.json();
    populateVansTable();
  } catch (err) {
    console.error('Error loading vans', err);
  }
}

// Fetch boards
async function loadBoards() {
  try {
    const res = await fetch(`${API_BASE}/api/content/board`);
    boards = await res.json();
    populateBoardsTable();
  } catch (err) {
    console.error('Error loading boards', err);
  }
}

// Fetch boats
async function loadBoats() {
  try {
    const res = await fetch(`${API_BASE}/api/content/boat`);
    boats = await res.json();
    populateBoatsTable();
  } catch (err) {
    console.error('Error loading boats', err);
  }
}

// Fetch foods
async function loadFoods() {
  try {
    const res = await fetch(`${API_BASE}/api/content/food`);
    foods = await res.json();
    populateFoodsTable();
  } catch (err) {
    console.error('Error loading foods', err);
  }
}


// ==================== RENDERING UTILITIES ====================

// Populate mini list widgets in Overview Screen
function populateOverviewLists() {
  const reviewsEl = document.getElementById('overview-reviews-list');
  const complaintsEl = document.getElementById('overview-complaints-list');

  // Populate Reviews
  if (reviews.length === 0) {
    reviewsEl.innerHTML = '<p class="loading-text">No reviews available</p>';
  } else {
    reviewsEl.innerHTML = reviews.slice(0, 5).map(r => `
      <div class="mini-item">
        <div class="mini-info">
          <h4>${escapeHtml(r.userName || 'Anonymous')}</h4>
          <p>${escapeHtml(r.comment || '')}</p>
        </div>
        <div class="mini-meta">
          <div class="star-rating">${'★'.repeat(r.rating || 5)}${'☆'.repeat(5 - (r.rating || 5))}</div>
          <span class="mini-date">${formatDate(r.createdAt)}</span>
        </div>
      </div>
    `).join('');
  }

  // Populate Complaints
  if (complaints.length === 0) {
    complaintsEl.innerHTML = '<p class="loading-text">No complaints available</p>';
  } else {
    complaintsEl.innerHTML = complaints.slice(0, 5).map(c => `
      <div class="mini-item">
        <div class="mini-info">
          <h4>${escapeHtml(c.subject || 'Complaint')}</h4>
          <p>By: ${escapeHtml(c.userName || 'Anonymous')}</p>
        </div>
        <div class="mini-meta">
          <span class="badge badge-${getBadgeClass(c.status)}">${escapeHtml(c.status)}</span>
          <br><span class="mini-date">${formatDate(c.createdAt)}</span>
        </div>
      </div>
    `).join('');
  }
}

// Populate Hotels Table
function populateHotelsTable() {
  const body = document.getElementById('hotels-table-body');
  if (hotels.length === 0) {
    body.innerHTML = '<tr><td colspan="6" class="loading-text">No hotels found in directory.</td></tr>';
    return;
  }

  body.innerHTML = hotels.map(h => {
    const tagsEn = Array.isArray(h.tags_en) ? h.tags_en : [];
    const rooms = Array.isArray(h.rooms) ? h.rooms : [];
    
    return `
      <tr>
        <td>
          <div class="user-badge" style="gap:16px;">
            <img src="${escapeHtml(h.image || '')}" alt="Cover" class="cell-image" onclick="previewFullImage('${escapeHtml(h.image || '')}')" onerror="this.src='https://placehold.co/100x100?text=Hotel'">
            <div>
              <span class="cell-title">${escapeHtml(h.name_en || '')}</span>
              <span class="cell-sub">${escapeHtml(h.name_bn || '')}</span>
              <div class="tag-list">
                ${tagsEn.map(t => `<span class="tag">${escapeHtml(t)}</span>`).join('')}
              </div>
            </div>
          </div>
        </td>
        <td>${escapeHtml(h.distance_en || '')}<br><span class="cell-sub">${escapeHtml(h.distance_bn || '')}</span></td>
        <td><strong>${escapeHtml(h.priceRange || '')}</strong></td>
        <td>${escapeHtml(h.phone || '')}</td>
        <td><span class="text-success" style="font-weight:700;">${rooms.length} Room Types</span></td>
        <td class="text-right">
          <div style="display:inline-flex; gap:6px;">
            <button class="btn btn-icon edit-icon" onclick="editHotel('${h._id}')" title="Edit Hotel">
              <span class="material-icons">edit</span>
            </button>
            <button class="btn btn-icon delete-icon" onclick="deleteHotel('${h._id}', '${escapeHtml(h.name_en)}')" title="Delete Hotel">
              <span class="material-icons">delete</span>
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

// Populate Managers Table
function populateManagersTable() {
  const body = document.getElementById('managers-table-body');
  if (managers.length === 0) {
    body.innerHTML = '<tr><td colspan="6" class="loading-text">No manager accounts available.</td></tr>';
    return;
  }

  body.innerHTML = managers.map(m => `
    <tr>
      <td>
        <span class="cell-title">${escapeHtml(m.name || '')}</span>
        <span class="cell-sub">ID: ${m._id}</span>
      </td>
      <td><strong>${escapeHtml(m.mobile || '')}</strong></td>
      <td>${escapeHtml(m.email || 'N/A')}</td>
      <td>
        <span class="text-purple" style="font-weight:700;">${escapeHtml(m.hotelName || 'Unassigned')}</span>
        <span class="cell-sub">Hotel ID: ${escapeHtml(m.managedHotelId || '')}</span>
      </td>
      <td>${escapeHtml(m.address || '')}</td>
      <td class="text-right">
        <button class="btn btn-icon delete-icon" onclick="deleteContentItem('manager', '${m._id}', '${escapeHtml(m.name)}')" title="Delete Account">
          <span class="material-icons">delete</span>
        </button>
      </td>
    </tr>
  `).join('');
}

// Populate Reviews Table
function populateReviewsTable() {
  const body = document.getElementById('reviews-table-body');
  if (reviews.length === 0) {
    body.innerHTML = '<tr><td colspan="5" class="loading-text">No reviews found.</td></tr>';
    return;
  }

  body.innerHTML = reviews.map(r => `
    <tr>
      <td>
        <div class="star-rating">${'★'.repeat(r.rating || 5)}${'☆'.repeat(5 - (r.rating || 5))}</div>
        <span class="cell-sub">${escapeHtml(r.itemType || '').toUpperCase()} (${escapeHtml(r.itemId || '')})</span>
      </td>
      <td>
        <span class="cell-title">${escapeHtml(r.userName || 'Anonymous')}</span>
        <span class="cell-sub">${formatDate(r.createdAt)}</span>
      </td>
      <td><p style="max-width:320px; word-wrap:break-word;">${escapeHtml(r.comment || '')}</p></td>
      <td>
        ${r.adminReply ? `
          <div style="font-size:12.5px; color:var(--purple); padding-left:8px; border-left:2px solid var(--purple);">
            <strong>Response:</strong> ${escapeHtml(r.adminReply)}
          </div>
        ` : `<span class="cell-sub">Unanswered</span>`}
      </td>
      <td class="text-right">
        <button class="btn btn-outline btn-small" onclick="openReviewReplyModal('${r._id}')">
          <span class="material-icons">reply</span>
          <span>${r.adminReply ? 'Edit Reply' : 'Reply'}</span>
        </button>
      </td>
    </tr>
  `).join('');
}

// Populate Complaints Table
function populateComplaintsTable() {
  const body = document.getElementById('complaints-table-body');
  if (complaints.length === 0) {
    body.innerHTML = '<tr><td colspan="6" class="loading-text">No complaints found in box.</td></tr>';
    return;
  }

  body.innerHTML = complaints.map(c => `
    <tr>
      <td>
        <span class="badge badge-${getBadgeClass(c.status)}">${escapeHtml(c.status)}</span>
      </td>
      <td>
        <span class="cell-title">${escapeHtml(c.userName || 'Unknown')}</span>
        <span class="cell-sub">Tel: ${escapeHtml(c.userMobile || '')}</span>
      </td>
      <td>
        <strong>${escapeHtml(c.subject || '')}</strong>
        <p class="cell-sub" style="max-width:300px; white-space:pre-wrap; margin-top:4px;">${escapeHtml(c.description || '')}</p>
        <span class="cell-sub" style="margin-top:6px;">Date: ${formatDate(c.createdAt)}</span>
      </td>
      <td>
        ${c.image ? `
          <img src="${escapeHtml(c.image)}" alt="Attachment" class="cell-image" onclick="previewFullImage('${escapeHtml(c.image)}')">
        ` : `<span class="cell-sub">No file</span>`}
      </td>
      <td>
        ${c.adminReply ? `
          <div style="font-size:12.5px; color:var(--purple); padding-left:8px; border-left:2px solid var(--purple);">
            <strong>Resolution:</strong> ${escapeHtml(c.adminReply)}
          </div>
        ` : `<span class="cell-sub">Not addressed</span>`}
      </td>
      <td class="text-right">
        <button class="btn btn-primary btn-small" onclick="openComplaintReplyModal('${c._id}')">
          <span class="material-icons">edit_note</span>
          <span>Resolve</span>
        </button>
      </td>
    </tr>
  `).join('');
}

// Populate Popular Spots Table
function populateSpotsTable() {
  const body = document.getElementById('spots-table-body');
  if (spots.length === 0) {
    body.innerHTML = '<tr><td colspan="5" class="loading-text">No popular spots added yet.</td></tr>';
    return;
  }

  body.innerHTML = spots.map(s => `
    <tr>
      <td>
        <div class="user-badge" style="gap:16px;">
          <img src="${escapeHtml(s.image || '')}" alt="Spot" class="cell-image" onclick="previewFullImage('${escapeHtml(s.image || '')}')" onerror="this.src='https://placehold.co/100x100?text=Spot'">
          <div>
            <span class="cell-title">${escapeHtml(s.title_en || '')}</span>
            <span class="cell-sub">${escapeHtml(s.title_bn || '')}</span>
          </div>
        </div>
      </td>
      <td>${escapeHtml(s.location_en || '')}<br><span class="cell-sub">${escapeHtml(s.location_bn || '')}</span></td>
      <td>${escapeHtml(s.timings_en || '')}<br><span class="cell-sub">${escapeHtml(s.timings_bn || '')}</span></td>
      <td><p style="max-width:240px; text-overflow:ellipsis; overflow:hidden; white-space:nowrap;">${escapeHtml(s.desc_en || '')}</p></td>
      <td class="text-right">
        <div style="display:inline-flex; gap:6px;">
          <button class="btn btn-icon edit-icon" onclick="editSpot('${s._id}')" title="Edit Spot">
            <span class="material-icons">edit</span>
          </button>
          <button class="btn btn-icon delete-icon" onclick="deleteContentItem('spot', '${s._id}', '${escapeHtml(s.title_en)}')" title="Delete Spot">
            <span class="material-icons">delete</span>
          </button>
        </div>
      </td>
    </tr>
  `).join('');
}

// Populate Slider Table
function populateSliderTable() {
  const body = document.getElementById('slider-table-body');
  if (slides.length === 0) {
    body.innerHTML = '<tr><td colspan="4" class="loading-text">No image slides found. App will use default slides.</td></tr>';
    return;
  }

  body.innerHTML = slides.map(sl => `
    <tr>
      <td>
        <img src="${escapeHtml(sl.image || '')}" alt="Slide" style="width:140px; height:70px; object-fit:cover; border-radius:var(--radius-sm); border:1px solid var(--border-color); cursor:pointer;" onclick="previewFullImage('${escapeHtml(sl.image || '')}')" onerror="this.src='https://placehold.co/140x70?text=Slide'">
      </td>
      <td><span class="cell-title">${escapeHtml(sl.title_en || '')}</span></td>
      <td><span class="cell-title">${escapeHtml(sl.title_bn || '')}</span></td>
      <td class="text-right">
        <div style="display:inline-flex; gap:6px;">
          <button class="btn btn-icon edit-icon" onclick="editSlide('${sl._id}')" title="Edit Slide">
            <span class="material-icons">edit</span>
          </button>
          <button class="btn btn-icon delete-icon" onclick="deleteContentItem('slider', '${sl._id}', '${escapeHtml(sl.title_en)}')" title="Delete Slide">
            <span class="material-icons">delete</span>
          </button>
        </div>
      </td>
    </tr>
  `).join('');
}

// Populate Bikes Table
function populateBikesTable() {
  const body = document.getElementById('bikes-table-body');
  if (bikes.length === 0) {
    body.innerHTML = '<tr><td colspan="6" class="loading-text">No bikers added yet.</td></tr>';
    return;
  }

  body.innerHTML = bikes.map(b => `
    <tr>
      <td>
        <div class="user-badge" style="gap:16px;">
          <img src="${escapeHtml(b.image || '')}" alt="Biker" class="cell-image" onclick="previewFullImage('${escapeHtml(b.image || '')}')" onerror="this.src='https://placehold.co/100x100?text=Biker'">
          <div>
            <span class="cell-title">${escapeHtml(b.name_en || '')}</span>
            <span class="cell-sub">${escapeHtml(b.name_bn || '')}</span>
          </div>
        </div>
      </td>
      <td>${escapeHtml(b.bike_en || '')}<br><span class="cell-sub">${escapeHtml(b.bike_bn || '')}</span></td>
      <td><strong>${escapeHtml(b.price_en || '')}</strong><br><span class="cell-sub">${escapeHtml(b.price_bn || '')}</span></td>
      <td>${escapeHtml(b.phone || '')}</td>
      <td><span class="text-success" style="font-weight:700;">★ ${b.rating || '4.8'}</span><br><span class="cell-sub">${b.rides || '100'} rides</span></td>
      <td class="text-right">
        <div style="display:inline-flex; gap:6px;">
          <button class="btn btn-icon edit-icon" onclick="editBike('${b._id}')" title="Edit Biker">
            <span class="material-icons">edit</span>
          </button>
          <button class="btn btn-icon delete-icon" onclick="deleteContentItem('bike', '${b._id}', '${escapeHtml(b.name_en)}')" title="Delete Biker">
            <span class="material-icons">delete</span>
          </button>
        </div>
      </td>
    </tr>
  `).join('');
}

// Populate Vans Table
function populateVansTable() {
  const body = document.getElementById('vans-table-body');
  if (vans.length === 0) {
    body.innerHTML = '<tr><td colspan="6" class="loading-text">No vans added yet.</td></tr>';
    return;
  }

  body.innerHTML = vans.map(v => `
    <tr>
      <td>
        <div class="user-badge" style="gap:16px;">
          <img src="${escapeHtml(v.image || '')}" alt="Driver" class="cell-image" onclick="previewFullImage('${escapeHtml(v.image || '')}')" onerror="this.src='https://placehold.co/100x100?text=Van'">
          <div>
            <span class="cell-title">${escapeHtml(v.name_en || '')}</span>
            <span class="cell-sub">${escapeHtml(v.name_bn || '')}</span>
          </div>
        </div>
      </td>
      <td>${escapeHtml(v.van_en || '')}<br><span class="cell-sub">${escapeHtml(v.van_bn || '')}</span></td>
      <td><strong>${escapeHtml(v.price_en || '')}</strong><br><span class="cell-sub">${escapeHtml(v.price_bn || '')}</span></td>
      <td>${escapeHtml(v.phone || '')}</td>
      <td><span class="text-success" style="font-weight:700;">★ ${v.rating || '4.7'}</span><br><span class="cell-sub">${v.trips || '100'} trips</span></td>
      <td class="text-right">
        <div style="display:inline-flex; gap:6px;">
          <button class="btn btn-icon edit-icon" onclick="editVan('${v._id}')" title="Edit Van">
            <span class="material-icons">edit</span>
          </button>
          <button class="btn btn-icon delete-icon" onclick="deleteContentItem('van', '${v._id}', '${escapeHtml(v.name_en)}')" title="Delete Van">
            <span class="material-icons">delete</span>
          </button>
        </div>
      </td>
    </tr>
  `).join('');
}

// Populate Speedboats Table
function populateBoardsTable() {
  const body = document.getElementById('boards-table-body');
  if (boards.length === 0) {
    body.innerHTML = '<tr><td colspan="6" class="loading-text">No speedboats added yet.</td></tr>';
    return;
  }

  body.innerHTML = boards.map(b => `
    <tr>
      <td>
        <div class="user-badge" style="gap:16px;">
          <img src="${escapeHtml(b.image || '')}" alt="Driver" class="cell-image" onclick="previewFullImage('${escapeHtml(b.image || '')}')" onerror="this.src='https://placehold.co/100x100?text=Speedboat'">
          <div>
            <span class="cell-title">${escapeHtml(b.name_en || '')}</span>
            <span class="cell-sub">${escapeHtml(b.name_bn || '')}</span>
          </div>
        </div>
      </td>
      <td>${escapeHtml(b.boat_en || '')}<br><span class="cell-sub">${escapeHtml(b.boat_bn || '')}</span></td>
      <td><strong>${escapeHtml(b.price_en || '')}</strong><br><span class="cell-sub">${escapeHtml(b.price_bn || '')}</span></td>
      <td>${escapeHtml(b.phone || '')}</td>
      <td><span class="text-success" style="font-weight:700;">★ ${b.rating || '4.9'}</span><br><span class="cell-sub">${b.trips || '100'} trips</span></td>
      <td class="text-right">
        <div style="display:inline-flex; gap:6px;">
          <button class="btn btn-icon edit-icon" onclick="editBoard('${b._id}')" title="Edit Speedboat">
            <span class="material-icons">edit</span>
          </button>
          <button class="btn btn-icon delete-icon" onclick="deleteContentItem('board', '${b._id}', '${escapeHtml(b.name_en)}')" title="Delete Speedboat">
            <span class="material-icons">delete</span>
          </button>
        </div>
      </td>
    </tr>
  `).join('');
}

// Populate Boats Table
function populateBoatsTable() {
  const body = document.getElementById('boats-table-body');
  if (boats.length === 0) {
    body.innerHTML = '<tr><td colspan="6" class="loading-text">No boatmen added yet.</td></tr>';
    return;
  }

  body.innerHTML = boats.map(b => `
    <tr>
      <td>
        <div class="user-badge" style="gap:16px;">
          <img src="${escapeHtml(b.image || '')}" alt="Boatman" class="cell-image" onclick="previewFullImage('${escapeHtml(b.image || '')}')" onerror="this.src='https://placehold.co/100x100?text=Boatman'">
          <div>
            <span class="cell-title">${escapeHtml(b.name_en || '')}</span>
            <span class="cell-sub">${escapeHtml(b.name_bn || '')}</span>
          </div>
        </div>
      </td>
      <td>${escapeHtml(b.boat_en || '')}<br><span class="cell-sub">${escapeHtml(b.boat_bn || '')}</span></td>
      <td><strong>${escapeHtml(b.price_en || '')}</strong><br><span class="cell-sub">${escapeHtml(b.price_bn || '')}</span></td>
      <td>${escapeHtml(b.phone || '')}</td>
      <td><span class="text-success" style="font-weight:700;">★ ${b.rating || '4.7'}</span><br><span class="cell-sub">${b.trips || '100'} trips</span></td>
      <td class="text-right">
        <div style="display:inline-flex; gap:6px;">
          <button class="btn btn-icon edit-icon" onclick="editBoat('${b._id}')" title="Edit Boatman">
            <span class="material-icons">edit</span>
          </button>
          <button class="btn btn-icon delete-icon" onclick="deleteContentItem('boat', '${b._id}', '${escapeHtml(b.name_en)}')" title="Delete Boatman">
            <span class="material-icons">delete</span>
          </button>
        </div>
      </td>
    </tr>
  `).join('');
}

// Populate Foods Table (Restaurants)
function populateFoodsTable() {
  const body = document.getElementById('foods-table-body');
  if (foods.length === 0) {
    body.innerHTML = '<tr><td colspan="6" class="loading-text">No restaurants added yet.</td></tr>';
    return;
  }

  body.innerHTML = foods.map(f => {
    const menuItems = Array.isArray(f.menu) ? f.menu : [];
    const menuTypeLabel = f.menu_type === 'image' ? 'Single Card Image' : 'Food Dishes List';
    return `
      <tr>
        <td>
          <div class="user-badge" style="gap:16px;">
            <img src="${escapeHtml(f.image || '')}" alt="Cover" class="cell-image" onclick="previewFullImage('${escapeHtml(f.image || '')}')" onerror="this.src='https://placehold.co/100x100?text=Food'">
            <div>
              <span class="cell-title">${escapeHtml(f.name_en || '')}</span>
              <span class="cell-sub">${escapeHtml(f.name_bn || '')}</span>
            </div>
          </div>
        </td>
        <td>${escapeHtml(f.address || '')}</td>
        <td>${escapeHtml(f.phone || '')}</td>
        <td><span class="badge badge-resolved">${escapeHtml(menuTypeLabel)}</span></td>
        <td><span class="text-purple" style="font-weight:700;">${menuItems.length} Dishes</span></td>
        <td class="text-right">
          <div style="display:inline-flex; gap:6px;">
            <button class="btn btn-icon edit-icon" onclick="editFood('${f._id}')" title="Edit Restaurant">
              <span class="material-icons">edit</span>
            </button>
            <button class="btn btn-icon delete-icon" onclick="deleteContentItem('food', '${f._id}', '${escapeHtml(f.name_en)}')" title="Delete Restaurant">
              <span class="material-icons">delete</span>
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

// ==================== IMAGE UPLOADER BASE64 ====================
function bindImageUploader(fileInputId, urlInputId, previewDivId) {
  const fileInput = document.getElementById(fileInputId);
  const urlInput = document.getElementById(urlInputId);
  const previewDiv = document.getElementById(previewDivId);

  if (!fileInput || !urlInput || !previewDiv) return;

  fileInput.addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    // Show loading text in preview
    previewDiv.innerHTML = '<span class="loading-text">Uploading image file...</span>';
    previewDiv.classList.remove('hidden');

    const reader = new FileReader();
    reader.onload = async () => {
      const base64String = reader.result;
      
      try {
        const uploadRes = await fetch(`${API_BASE}/api/upload`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode({ image: base64String })
        });
        
        if (uploadRes.ok) {
          const data = await uploadRes.json();
          urlInput.value = data.url;
          
          // Show preview
          previewDiv.innerHTML = `<img src="${data.url}" alt="Uploaded Preview">`;
        } else {
          previewDiv.innerHTML = '<span style="color:var(--danger)">Upload failed!</span>';
        }
      } catch (err) {
        previewDiv.innerHTML = '<span style="color:var(--danger)">Connection failed!</span>';
      }
    };
    reader.readAsDataURL(file);
  });

  // Listen to text URL field input changes
  urlInput.addEventListener('input', () => {
    const url = urlInput.value.trim();
    if (url) {
      previewDiv.innerHTML = `<img src="${url}" alt="Preview" onerror="this.parentNode.classList.add('hidden')">`;
      previewDiv.classList.remove('hidden');
    } else {
      previewDiv.classList.add('hidden');
    }
  });
}

// ==================== DIALOG CONTROLLER (MODALS) ====================
function openModal(id) {
  document.getElementById(id).classList.remove('hidden');
}

function closeModal(id) {
  document.getElementById(id).classList.add('hidden');
}

// Manage dynamic rows for hotel rooms
function addRoomRow(roomData = null) {
  const container = document.getElementById('rooms-rows-container');
  const index = container.children.length;

  const row = document.createElement('div');
  row.className = 'room-row';
  row.setAttribute('data-index', index);

  const nameEn = roomData ? roomData.name_en || '' : '';
  const nameBn = roomData ? roomData.name_bn || '' : '';
  const price = roomData ? roomData.price || '' : '';
  
  let amenitiesEn = '';
  let amenitiesBn = '';
  if (roomData) {
    if (Array.isArray(roomData.amenities_en)) amenitiesEn = roomData.amenities_en.join(', ');
    if (Array.isArray(roomData.amenities_bn)) amenitiesBn = roomData.amenities_bn.join(', ');
  }

  row.innerHTML = `
    <div style="display:flex; gap:6px; flex-direction:column;">
      <input type="text" class="room-name-en" placeholder="Room Type (English) *" value="${escapeHtml(nameEn)}" required>
      <input type="text" class="room-name-bn" placeholder="Room Type (Bangla) *" value="${escapeHtml(nameBn)}" required>
    </div>
    <div style="display:flex; gap:6px; flex-direction:column; align-self:stretch;">
      <input type="number" class="room-price" placeholder="Price (৳) *" value="${price}" required style="height:100%;">
    </div>
    <div style="display:flex; gap:6px; flex-direction:column;">
      <input type="text" class="room-amenities-en" placeholder="Amenities En (e.g. AC, TV, Wi-Fi)" value="${escapeHtml(amenitiesEn)}">
      <input type="text" class="room-amenities-bn" placeholder="Amenities Bn (e.g. এসি, টিভি, ওয়াই-ফাই)" value="${escapeHtml(amenitiesBn)}">
    </div>
    <button type="button" class="btn btn-icon delete-icon" onclick="this.parentNode.remove()" style="align-self:center;">
      <span class="material-icons">delete</span>
    </button>
  `;

  container.appendChild(row);
}

// Clear hotel room rows
function clearRoomRows() {
  document.getElementById('rooms-rows-container').innerHTML = '';
}

// Open Hotel Modal (Add state)
function openHotelModal() {
  document.getElementById('hotel-form').reset();
  document.getElementById('hotel-id').value = '';
  document.getElementById('hotel-modal-title').textContent = 'Add New Hotel';
  document.getElementById('hotel-image-preview').classList.add('hidden');
  clearRoomRows();
  
  // Add 1 empty room row by default
  addRoomRow();
  
  openModal('modal-hotel');
}

// Edit Hotel Modal (Edit state)
function editHotel(id) {
  const hotel = hotels.find(h => h._id === id);
  if (!hotel) return;

  document.getElementById('hotel-id').value = hotel._id;
  document.getElementById('hotel-modal-title').textContent = 'Edit Hotel Details';
  
  document.getElementById('hotel-name-en').value = hotel.name_en || '';
  document.getElementById('hotel-name-bn').value = hotel.name_bn || '';
  document.getElementById('hotel-distance-en').value = hotel.distance_en || '';
  document.getElementById('hotel-distance-bn').value = hotel.distance_bn || '';
  document.getElementById('hotel-price-range').value = hotel.priceRange || '';
  document.getElementById('hotel-phone').value = hotel.phone || '';
  document.getElementById('hotel-image-url').value = hotel.image || '';
  document.getElementById('hotel-desc-en').value = hotel.desc_en || '';
  document.getElementById('hotel-desc-bn').value = hotel.desc_bn || '';

  const tagsEn = Array.isArray(hotel.tags_en) ? hotel.tags_en.join(', ') : '';
  const tagsBn = Array.isArray(hotel.tags_bn) ? hotel.tags_bn.join(', ') : '';
  document.getElementById('hotel-tags-en').value = tagsEn;
  document.getElementById('hotel-tags-bn').value = tagsBn;

  // Set image preview
  const preview = document.getElementById('hotel-image-preview');
  if (hotel.image) {
    preview.innerHTML = `<img src="${hotel.image}" alt="Preview">`;
    preview.classList.remove('hidden');
  } else {
    preview.classList.add('hidden');
  }

  // Set room rows
  clearRoomRows();
  const rooms = Array.isArray(hotel.rooms) ? hotel.rooms : [];
  if (rooms.length > 0) {
    rooms.forEach(r => addRoomRow(r));
  } else {
    addRoomRow();
  }

  openModal('modal-hotel');
}

// Delete Hotel
async function deleteHotel(id, hotelName) {
  if (!confirm(`Are you sure you want to delete "${hotelName}"? This will remove it from the directory.`)) return;

  try {
    const res = await fetch(`${API_BASE}/api/content/hotel/${id}`, {
      method: 'DELETE'
    });
    if (res.ok) {
      loadHotels();
    } else {
      alert('Failed to delete hotel');
    }
  } catch (err) {
    alert('Failed to connect to the backend server.');
  }
}

// Open Manager Modal
async function openManagerModal() {
  document.getElementById('manager-form').reset();
  
  // Populate hotel options in dropdown selector
  const select = document.getElementById('mgr-hotel');
  select.innerHTML = '<option value="" disabled selected>-- Choose Hotel --</option>';
  
  if (hotels.length === 0) {
    await loadHotels();
  }

  hotels.forEach(h => {
    select.innerHTML += `<option value="${h._id}">${escapeHtml(h.name_en)}</option>`;
  });

  openModal('modal-manager');
}

// Open Review Reply Modal
function openReviewReplyModal(id) {
  const review = reviews.find(r => r._id === id);
  if (!review) return;

  document.getElementById('reply-review-id').value = review._id;
  document.getElementById('reply-review-user').textContent = review.userName || 'Anonymous';
  
  const ratingEl = document.getElementById('reply-review-stars');
  ratingEl.innerHTML = '★'.repeat(review.rating || 5) + '☆'.repeat(5 - (review.rating || 5));
  
  document.getElementById('reply-review-comment').textContent = `"${review.comment || ''}"`;
  document.getElementById('review-reply-text').value = review.adminReply || '';

  openModal('modal-review-reply');
}

// Open Complaint Reply Modal
function openComplaintReplyModal(id) {
  const complaint = complaints.find(c => c._id === id);
  if (!complaint) return;

  document.getElementById('reply-complaint-id').value = complaint._id;
  document.getElementById('reply-complaint-user').textContent = complaint.userName || 'Unknown';
  document.getElementById('reply-complaint-mobile').textContent = complaint.userMobile || '';
  document.getElementById('reply-complaint-subject').textContent = complaint.subject || '';
  document.getElementById('reply-complaint-desc').textContent = `"${complaint.description || ''}"`;
  document.getElementById('complaint-reply-text').value = complaint.adminReply || '';
  document.getElementById('complaint-status').value = complaint.status || 'Pending';

  openModal('modal-complaint-reply');
}

// Open Spot Modal (Add state)
function openSpotModal() {
  document.getElementById('spot-form').reset();
  document.getElementById('spot-id').value = '';
  document.getElementById('spot-modal-title').textContent = 'Add Popular Spot';
  document.getElementById('spot-image-preview').classList.add('hidden');
  openModal('modal-spot');
}

// Edit Spot Modal
function editSpot(id) {
  const spot = spots.find(s => s._id === id);
  if (!spot) return;

  document.getElementById('spot-id').value = spot._id;
  document.getElementById('spot-modal-title').textContent = 'Edit Tourist Spot Details';
  
  document.getElementById('spot-title-en').value = spot.title_en || '';
  document.getElementById('spot-title-bn').value = spot.title_bn || '';
  document.getElementById('spot-desc-en').value = spot.desc_en || '';
  document.getElementById('spot-desc-bn').value = spot.desc_bn || '';
  document.getElementById('spot-image-url').value = spot.image || '';
  document.getElementById('spot-location-en').value = spot.location_en || '';
  document.getElementById('spot-location-bn').value = spot.location_bn || '';
  document.getElementById('spot-timings-en').value = spot.timings_en || '';
  document.getElementById('spot-timings-bn').value = spot.timings_bn || '';
  document.getElementById('spot-about-en').value = spot.about_en || '';
  document.getElementById('spot-about-bn').value = spot.about_bn || '';
  document.getElementById('spot-tips-en').value = spot.tips_en || '';
  document.getElementById('spot-tips-bn').value = spot.tips_bn || '';
  document.getElementById('spot-trans-en').value = spot.transport_en || '';
  document.getElementById('spot-trans-bn').value = spot.transport_bn || '';

  const preview = document.getElementById('spot-image-preview');
  if (spot.image) {
    preview.innerHTML = `<img src="${spot.image}" alt="Preview">`;
    preview.classList.remove('hidden');
  } else {
    preview.classList.add('hidden');
  }

  openModal('modal-spot');
}

// Open Slider Modal (Add state)
function openSliderModal() {
  document.getElementById('slider-form').reset();
  document.getElementById('slider-id').value = '';
  document.getElementById('slider-modal-title').textContent = 'Add Home Slide';
  document.getElementById('slide-image-preview').classList.add('hidden');
  openModal('modal-slider');
}

// Edit Slider Modal
function editSlide(id) {
  const slide = slides.find(sl => sl._id === id);
  if (!slide) return;

  document.getElementById('slider-id').value = slide._id;
  document.getElementById('slider-modal-title').textContent = 'Edit Slide Details';
  
  document.getElementById('slide-title-en').value = slide.title_en || '';
  document.getElementById('slide-title-bn').value = slide.title_bn || '';
  document.getElementById('slide-image-url').value = slide.image || '';

  const preview = document.getElementById('slide-image-preview');
  if (slide.image) {
    preview.innerHTML = `<img src="${slide.image}" alt="Preview">`;
    preview.classList.remove('hidden');
  } else {
    preview.classList.add('hidden');
  }

  openModal('modal-slider');
}

// Open Bike Modal
function openBikeModal() {
  document.getElementById('bike-form').reset();
  document.getElementById('bike-id').value = '';
  document.getElementById('bike-modal-title').textContent = 'Add New Biker';
  document.getElementById('bike-image-preview').classList.add('hidden');
  openModal('modal-bike');
}

// Edit Bike Modal
function editBike(id) {
  const b = bikes.find(item => item._id === id);
  if (!b) return;

  document.getElementById('bike-id').value = b._id;
  document.getElementById('bike-modal-title').textContent = 'Edit Biker Details';
  document.getElementById('bike-name-en').value = b.name_en || '';
  document.getElementById('bike-name-bn').value = b.name_bn || '';
  document.getElementById('bike-model-en').value = b.bike_en || '';
  document.getElementById('bike-model-bn').value = b.bike_bn || '';
  document.getElementById('bike-price-en').value = b.price_en || '';
  document.getElementById('bike-price-bn').value = b.price_bn || '';
  document.getElementById('bike-rating').value = b.rating || '4.8';
  document.getElementById('bike-rides').value = b.rides || '100';
  document.getElementById('bike-phone').value = b.phone || '';
  document.getElementById('bike-image-url').value = b.image || '';
  document.getElementById('bike-exp-en').value = b.experience_en || '';
  document.getElementById('bike-exp-bn').value = b.experience_bn || '';

  const preview = document.getElementById('bike-image-preview');
  if (b.image) {
    preview.innerHTML = `<img src="${b.image}" alt="Preview">`;
    preview.classList.remove('hidden');
  } else {
    preview.classList.add('hidden');
  }
  openModal('modal-bike');
}

// Open Van Modal
function openVanModal() {
  document.getElementById('van-form').reset();
  document.getElementById('van-id').value = '';
  document.getElementById('van-modal-title').textContent = 'Add New Van';
  document.getElementById('van-image-preview').classList.add('hidden');
  openModal('modal-van');
}

// Edit Van Modal
function editVan(id) {
  const v = vans.find(item => item._id === id);
  if (!v) return;

  document.getElementById('van-id').value = v._id;
  document.getElementById('van-modal-title').textContent = 'Edit Van Details';
  document.getElementById('van-name-en').value = v.name_en || '';
  document.getElementById('van-name-bn').value = v.name_bn || '';
  document.getElementById('van-model-en').value = v.van_en || '';
  document.getElementById('van-model-bn').value = v.van_bn || '';
  document.getElementById('van-price-en').value = v.price_en || '';
  document.getElementById('van-price-bn').value = v.price_bn || '';
  document.getElementById('van-rating').value = v.rating || '4.7';
  document.getElementById('van-trips').value = v.trips || '100';
  document.getElementById('van-phone').value = v.phone || '';
  document.getElementById('van-image-url').value = v.image || '';
  document.getElementById('van-details-en').value = v.details_en || '';
  document.getElementById('van-details-bn').value = v.details_bn || '';

  const preview = document.getElementById('van-image-preview');
  if (v.image) {
    preview.innerHTML = `<img src="${v.image}" alt="Preview">`;
    preview.classList.remove('hidden');
  } else {
    preview.classList.add('hidden');
  }
  openModal('modal-van');
}

// Open Board Modal
function openBoardModal() {
  document.getElementById('board-form').reset();
  document.getElementById('board-id').value = '';
  document.getElementById('board-modal-title').textContent = 'Add New Speedboat';
  document.getElementById('board-image-preview').classList.add('hidden');
  openModal('modal-board');
}

// Edit Board Modal
function editBoard(id) {
  const b = boards.find(item => item._id === id);
  if (!b) return;

  document.getElementById('board-id').value = b._id;
  document.getElementById('board-modal-title').textContent = 'Edit Speedboat Details';
  document.getElementById('board-name-en').value = b.name_en || '';
  document.getElementById('board-name-bn').value = b.name_bn || '';
  document.getElementById('board-model-en').value = b.boat_en || '';
  document.getElementById('board-model-bn').value = b.boat_bn || '';
  document.getElementById('board-price-en').value = b.price_en || '';
  document.getElementById('board-price-bn').value = b.price_bn || '';
  document.getElementById('board-rating').value = b.rating || '4.9';
  document.getElementById('board-trips').value = b.trips || '100';
  document.getElementById('board-phone').value = b.phone || '';
  document.getElementById('board-image-url').value = b.image || '';
  document.getElementById('board-details-en').value = b.details_en || '';
  document.getElementById('board-details-bn').value = b.details_bn || '';

  const preview = document.getElementById('board-image-preview');
  if (b.image) {
    preview.innerHTML = `<img src="${b.image}" alt="Preview">`;
    preview.classList.remove('hidden');
  } else {
    preview.classList.add('hidden');
  }
  openModal('modal-board');
}

// Open Boat Modal
function openBoatModal() {
  document.getElementById('boat-form').reset();
  document.getElementById('boat-id').value = '';
  document.getElementById('boat-modal-title').textContent = 'Add New Boatman';
  document.getElementById('boat-image-preview').classList.add('hidden');
  openModal('modal-boat');
}

// Edit Boat Modal
function editBoat(id) {
  const b = boats.find(item => item._id === id);
  if (!b) return;

  document.getElementById('boat-id').value = b._id;
  document.getElementById('boat-modal-title').textContent = 'Edit Boatman Details';
  document.getElementById('boat-name-en').value = b.name_en || '';
  document.getElementById('boat-name-bn').value = b.name_bn || '';
  document.getElementById('boat-model-en').value = b.boat_en || '';
  document.getElementById('boat-model-bn').value = b.boat_bn || '';
  document.getElementById('boat-price-en').value = b.price_en || '';
  document.getElementById('boat-price-bn').value = b.price_bn || '';
  document.getElementById('boat-rating').value = b.rating || '4.7';
  document.getElementById('boat-trips').value = b.trips || '100';
  document.getElementById('boat-phone').value = b.phone || '';
  document.getElementById('boat-image-url').value = b.image || '';
  document.getElementById('boat-details-en').value = b.details_en || '';
  document.getElementById('boat-details-bn').value = b.details_bn || '';

  const preview = document.getElementById('boat-image-preview');
  if (b.image) {
    preview.innerHTML = `<img src="${b.image}" alt="Preview">`;
    preview.classList.remove('hidden');
  } else {
    preview.classList.add('hidden');
  }
  openModal('modal-boat');
}

// Open Food Modal
function openFoodModal() {
  document.getElementById('food-form').reset();
  document.getElementById('food-id').value = '';
  document.getElementById('food-modal-title').textContent = 'Add Restaurant';
  document.getElementById('food-image-preview').classList.add('hidden');
  document.getElementById('food-menu-image-preview').classList.add('hidden');
  document.getElementById('dishes-rows-container').innerHTML = '';
  addDishRow(); // Add an empty dish row by default
  document.getElementById('food-menu-type').dispatchEvent(new Event('change'));
  openModal('modal-food');
}

// Edit Food Modal
function editFood(id) {
  const f = foods.find(item => item._id === id);
  if (!f) return;

  document.getElementById('food-id').value = f._id;
  document.getElementById('food-modal-title').textContent = 'Edit Restaurant Details';
  document.getElementById('food-name-en').value = f.name_en || '';
  document.getElementById('food-name-bn').value = f.name_bn || '';
  document.getElementById('food-address').value = f.address || '';
  document.getElementById('food-phone').value = f.phone || '';
  document.getElementById('food-image-url').value = f.image || '';
  document.getElementById('food-menu-type').value = f.menu_type || 'list';
  document.getElementById('food-menu-image-url').value = f.menu_image || '';

  const preview = document.getElementById('food-image-preview');
  if (f.image) {
    preview.innerHTML = `<img src="${f.image}" alt="Preview">`;
    preview.classList.remove('hidden');
  } else {
    preview.classList.add('hidden');
  }

  const menuPreview = document.getElementById('food-menu-image-preview');
  if (f.menu_image) {
    menuPreview.innerHTML = `<img src="${f.menu_image}" alt="Menu Preview">`;
    menuPreview.classList.remove('hidden');
  } else {
    menuPreview.classList.add('hidden');
  }

  // Populate dishes list
  document.getElementById('dishes-rows-container').innerHTML = '';
  const menuItems = Array.isArray(f.menu) ? f.menu : [];
  if (menuItems.length > 0) {
    menuItems.forEach(item => addDishRow(item));
  } else {
    addDishRow();
  }

  document.getElementById('food-menu-type').dispatchEvent(new Event('change'));
  openModal('modal-food');
}

// Manage dynamic rows for restaurant menu dishes
function addDishRow(dishData = null) {
  const container = document.getElementById('dishes-rows-container');
  const index = container.children.length;

  const row = document.createElement('div');
  row.className = 'room-row'; // reuse the styling of room row which has the same flex layout
  row.setAttribute('data-index', index);

  const nameEn = dishData ? dishData.name_en || '' : '';
  const nameBn = dishData ? dishData.name_bn || '' : '';
  const price = dishData ? dishData.price || '' : '';
  const imgUrl = dishData ? dishData.image || '' : '';

  row.innerHTML = `
    <div style="display:flex; gap:6px; flex-direction:column;">
      <input type="text" class="dish-name-en" placeholder="Dish Name (English) *" value="${escapeHtml(nameEn)}" required>
      <input type="text" class="dish-name-bn" placeholder="Dish Name (Bangla) *" value="${escapeHtml(nameBn)}" required>
    </div>
    <div style="display:flex; gap:6px; flex-direction:column; align-self:stretch;">
      <input type="number" class="dish-price" placeholder="Price (৳) *" value="${price}" required style="height:100%;">
    </div>
    <div style="display:flex; gap:6px; flex-direction:column; width:100%;">
      <div class="image-upload-wrapper">
        <input type="file" class="dish-file-input file-input" accept="image/*">
        <input type="text" class="dish-image-url" placeholder="Dish Image URL *" value="${escapeHtml(imgUrl)}" required>
      </div>
    </div>
    <button type="button" class="btn btn-icon delete-icon" onclick="this.parentNode.remove()" style="align-self:center;">
      <span class="material-icons">delete</span>
    </button>
  `;

  // Bind file upload to base64 inside the row
  const fileInput = row.querySelector('.dish-file-input');
  const urlInput = row.querySelector('.dish-image-url');

  fileInput.addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    urlInput.placeholder = 'Uploading...';

    const reader = new FileReader();
    reader.onload = async () => {
      const base64String = reader.result;
      try {
        const uploadRes = await fetch(`${API_BASE}/api/upload`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ image: base64String })
        });
        if (uploadRes.ok) {
          const data = await uploadRes.json();
          urlInput.value = data.url;
        } else {
          alert('Upload failed');
        }
      } catch (err) {
        alert('Upload connection failed');
      } finally {
        urlInput.placeholder = 'Dish Image URL *';
      }
    };
    reader.readAsDataURL(file);
  });

  container.appendChild(row);
}

// Delete Content Item Generic (Spot, Slide, Manager)
async function deleteContentItem(type, id, itemName) {
  if (!confirm(`Are you sure you want to delete "${itemName}"?`)) return;

  try {
    let res;
    if (type === 'manager') {
      // In backend managers deletion matches user deletions, wait: does server.js support delete manager?
      // Let's check: actually, manager is a user with role 'manager'. Let's see if server.js has delete user API.
      // Wait, let's delete them as a user. In server.js, let's see if we can use deleteContentItem. Wait! In server.js:
      // Oh, ContentItem has a delete endpoint: app.delete('/api/content/:id').
      // Wait, is User deleted using deleteContent? Users are stored in 'users' collection. Does server.js have a user deletion?
      // Let's check server.js for users delete endpoint. We didn't see one in server.js! Let's check if there is any user delete route.
      // Ah! Let's write a route to delete users in server.js or we can check server.js. No, we viewed server.js entirely earlier and there is no user delete API!
      // Let's add it to server.js first. Yes! That is important so deleting managers works.
    }
    
    // For spots, slides, hotels they are ContentItem, so we call deleteContent(type, id) or delete /api/content/:id
    res = await fetch(`${API_BASE}/api/content/${id}`, {
      method: 'DELETE'
    });

    if (res.ok) {
      if (type === 'spot') loadSpots();
      if (type === 'slider') loadSlides();
      if (type === 'bike') loadBikes();
      if (type === 'van') loadVans();
      if (type === 'board') loadBoards();
      if (type === 'boat') loadBoats();
      if (type === 'food') loadFoods();
    } else {
      alert('Deletion failed');
    }
  } catch (err) {
    alert('Failed to connect to the backend server.');
  }
}

// Preview full screen image
function previewFullImage(url) {
  if (!url) return;
  const modal = document.getElementById('modal-image-preview');
  const img = document.getElementById('full-image-preview-element');
  img.src = url;
  modal.classList.remove('hidden');
}

// ==================== FORM ACTIONS SUBMISSION ====================
function setupForms() {
  // Bind uploaders
  bindImageUploader('hotel-image-file', 'hotel-image-url', 'hotel-image-preview');
  bindImageUploader('spot-image-file', 'spot-image-url', 'spot-image-preview');
  bindImageUploader('slide-image-file', 'slide-image-url', 'slide-image-preview');
  bindImageUploader('bike-image-file', 'bike-image-url', 'bike-image-preview');
  bindImageUploader('van-image-file', 'van-image-url', 'van-image-preview');
  bindImageUploader('board-image-file', 'board-image-url', 'board-image-preview');
  bindImageUploader('boat-image-file', 'boat-image-url', 'boat-image-preview');
  bindImageUploader('food-image-file', 'food-image-url', 'food-image-preview');
  bindImageUploader('food-menu-image-file', 'food-menu-image-url', 'food-menu-image-preview');

  // Toggle food menu type displays
  const foodMenuTypeSelect = document.getElementById('food-menu-type');
  if (foodMenuTypeSelect) {
    foodMenuTypeSelect.addEventListener('change', () => {
      const val = foodMenuTypeSelect.value;
      const imgGroup = document.getElementById('menu-image-group');
      const listGroup = document.getElementById('dishes-section');
      if (val === 'image') {
        imgGroup.classList.remove('hidden');
        listGroup.classList.add('hidden');
      } else {
        imgGroup.classList.add('hidden');
        listGroup.classList.remove('hidden');
      }
    });
  }



  // Submit Hotel Form
  document.getElementById('hotel-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('hotel-id').value;
    
    // Map room rows
    const rooms = [];
    document.querySelectorAll('#rooms-rows-container .room-row').forEach(row => {
      const nameEn = row.querySelector('.room-name-en').value.trim();
      const nameBn = row.querySelector('.room-name-bn').value.trim();
      const price = parseFloat(row.querySelector('.room-price').value);
      
      const amEnRaw = row.querySelector('.room-amenities-en').value.trim();
      const amBnRaw = row.querySelector('.room-amenities-bn').value.trim();
      
      const amenitiesEn = amEnRaw ? amEnRaw.split(',').map(s => s.trim()) : [];
      const amenitiesBn = amBnRaw ? amBnRaw.split(',').map(s => s.trim()) : [];

      if (nameEn && nameBn && !isNaN(price)) {
        rooms.push({
          name_en: nameEn,
          name_bn: nameBn,
          price: price,
          image: 'https://images.unsplash.com/photo-1611891405788-d130a84e2d9a?auto=format&fit=crop&w=400&q=80', // Default room image placeholder
          amenities_en: amenitiesEn,
          amenities_bn: amenitiesBn
        });
      }
    });

    const hotelData = {
      name_en: document.getElementById('hotel-name-en').value.trim(),
      name_bn: document.getElementById('hotel-name-bn').value.trim(),
      distance_en: document.getElementById('hotel-distance-en').value.trim(),
      distance_bn: document.getElementById('hotel-distance-bn').value.trim(),
      priceRange: document.getElementById('hotel-price-range').value.trim(),
      phone: document.getElementById('hotel-phone').value.trim(),
      image: document.getElementById('hotel-image-url').value.trim(),
      desc_en: document.getElementById('hotel-desc-en').value.trim(),
      desc_bn: document.getElementById('hotel-desc-bn').value.trim(),
      tags_en: document.getElementById('hotel-tags-en').value.split(',').map(s => s.trim()).filter(Boolean),
      tags_bn: document.getElementById('hotel-tags-bn').value.split(',').map(s => s.trim()).filter(Boolean),
      rooms: rooms,
      rating: 4.5,
      reviews: 120
    };

    try {
      let res;
      if (id) {
        // Update
        res = await fetch(`${API_BASE}/api/content/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(hotelData)
        });
      } else {
        // Create
        res = await fetch(`${API_BASE}/api/content/hotel`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(hotelData)
        });
      }

      if (res.ok) {
        closeModal('modal-hotel');
        loadHotels();
      } else {
        alert('Failed to save hotel data.');
      }
    } catch (err) {
      alert('Connection error.');
    }
  });

  // Submit Manager Form
  document.getElementById('manager-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const select = document.getElementById('mgr-hotel');
    const hotelId = select.value;
    const hotelName = select.options[select.selectedIndex].text;

    const mgrData = {
      name: document.getElementById('mgr-name').value.trim(),
      mobile: document.getElementById('mgr-mobile').value.trim(),
      pin: document.getElementById('mgr-pin').value.trim(),
      email: document.getElementById('mgr-email').value.trim(),
      address: document.getElementById('mgr-address').value.trim(),
      managedHotelId: hotelId,
      hotelName: hotelName
    };

    try {
      const res = await fetch(`${API_BASE}/api/admin/managers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode(mgrData)
      });

      if (res.ok) {
        closeModal('modal-manager');
        loadManagers();
      } else {
        const err = await res.json();
        alert(err.error || 'Failed to create manager account.');
      }
    } catch (err) {
      alert('Connection error.');
    }
  });

  // Submit Review Reply Form
  document.getElementById('review-reply-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('reply-review-id').value;
    const reply = document.getElementById('review-reply-text').value.trim();

    try {
      const res = await fetch(`${API_BASE}/api/admin/reviews/${id}/reply`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({ reply })
      });

      if (res.ok) {
        closeModal('modal-review-reply');
        loadComplaintsAndReviews();
      } else {
        alert('Failed to submit reply.');
      }
    } catch (err) {
      alert('Connection error.');
    }
  });

  // Submit Complaint Reply Form
  document.getElementById('complaint-reply-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('reply-complaint-id').value;
    const reply = document.getElementById('complaint-reply-text').value.trim();
    const status = document.getElementById('complaint-status').value;

    try {
      const res = await fetch(`${API_BASE}/api/admin/complaints/${id}/reply`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({ reply, status })
      });

      if (res.ok) {
        closeModal('modal-complaint-reply');
        loadComplaintsAndReviews();
      } else {
        alert('Failed to update complaint.');
      }
    } catch (err) {
      alert('Connection error.');
    }
  });

  // Submit Spot Form
  document.getElementById('spot-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('spot-id').value;

    const spotData = {
      title_en: document.getElementById('spot-title-en').value.trim(),
      title_bn: document.getElementById('spot-title-bn').value.trim(),
      desc_en: document.getElementById('spot-desc-en').value.trim(),
      desc_bn: document.getElementById('spot-desc-bn').value.trim(),
      image: document.getElementById('spot-image-url').value.trim(),
      location_en: document.getElementById('spot-location-en').value.trim(),
      location_bn: document.getElementById('spot-location-bn').value.trim(),
      timings_en: document.getElementById('spot-timings-en').value.trim(),
      timings_bn: document.getElementById('spot-timings-bn').value.trim(),
      about_en: document.getElementById('spot-about-en').value.trim(),
      about_bn: document.getElementById('spot-about-bn').value.trim(),
      tips_en: document.getElementById('spot-tips-en').value.trim(),
      tips_bn: document.getElementById('spot-tips-bn').value.trim(),
      transport_en: document.getElementById('spot-trans-en').value.trim(),
      transport_bn: document.getElementById('spot-trans-bn').value.trim(),
    };

    try {
      let res;
      if (id) {
        res = await fetch(`${API_BASE}/api/content/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(spotData)
        });
      } else {
        res = await fetch(`${API_BASE}/api/content/spot`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(spotData)
        });
      }

      if (res.ok) {
        closeModal('modal-spot');
        loadSpots();
      } else {
        alert('Failed to save tourist spot.');
      }
    } catch (err) {
      alert('Connection error.');
    }
  });

  // Submit Slider Form
  document.getElementById('slider-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('slider-id').value;

    const slideData = {
      title_en: document.getElementById('slide-title-en').value.trim(),
      title_bn: document.getElementById('slide-title-bn').value.trim(),
      image: document.getElementById('slide-image-url').value.trim()
    };

    try {
      let res;
      if (id) {
        res = await fetch(`${API_BASE}/api/content/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(slideData)
        });
      } else {
        res = await fetch(`${API_BASE}/api/content/slider`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(slideData)
        });
      }

      if (res.ok) {
        closeModal('modal-slider');
        loadSlides();
      } else {
        alert('Failed to save homepage slide.');
      }
    } catch (err) {
      alert('Connection error.');
    }
  });

  // Submit Bike Form
  document.getElementById('bike-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('bike-id').value;

    const bikeData = {
      name_en: document.getElementById('bike-name-en').value.trim(),
      name_bn: document.getElementById('bike-name-bn').value.trim(),
      bike_en: document.getElementById('bike-model-en').value.trim(),
      bike_bn: document.getElementById('bike-model-bn').value.trim(),
      price_en: document.getElementById('bike-price-en').value.trim(),
      price_bn: document.getElementById('bike-price-bn').value.trim(),
      rating: parseFloat(document.getElementById('bike-rating').value) || 4.8,
      rides: parseInt(document.getElementById('bike-rides').value) || 100,
      phone: document.getElementById('bike-phone').value.trim(),
      image: document.getElementById('bike-image-url').value.trim() || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
      experience_en: document.getElementById('bike-exp-en').value.trim(),
      experience_bn: document.getElementById('bike-exp-bn').value.trim()
    };

    try {
      let res;
      if (id) {
        res = await fetch(`${API_BASE}/api/content/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(bikeData)
        });
      } else {
        res = await fetch(`${API_BASE}/api/content/bike`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(bikeData)
        });
      }

      if (res.ok) {
        closeModal('modal-bike');
        loadBikes();
      } else {
        alert('Failed to save biker details.');
      }
    } catch (err) {
      alert('Connection error.');
    }
  });

  // Submit Van Form
  document.getElementById('van-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('van-id').value;

    const vanData = {
      name_en: document.getElementById('van-name-en').value.trim(),
      name_bn: document.getElementById('van-name-bn').value.trim(),
      van_en: document.getElementById('van-model-en').value.trim(),
      van_bn: document.getElementById('van-model-bn').value.trim(),
      price_en: document.getElementById('van-price-en').value.trim(),
      price_bn: document.getElementById('van-price-bn').value.trim(),
      rating: parseFloat(document.getElementById('van-rating').value) || 4.7,
      trips: parseInt(document.getElementById('van-trips').value) || 100,
      phone: document.getElementById('van-phone').value.trim(),
      image: document.getElementById('van-image-url').value.trim() || 'https://images.unsplash.com/photo-1542909168-82c3e7fdca5c?auto=format&fit=crop&w=300&q=80',
      details_en: document.getElementById('van-details-en').value.trim(),
      details_bn: document.getElementById('van-details-bn').value.trim()
    };

    try {
      let res;
      if (id) {
        res = await fetch(`${API_BASE}/api/content/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(vanData)
        });
      } else {
        res = await fetch(`${API_BASE}/api/content/van`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(vanData)
        });
      }

      if (res.ok) {
        closeModal('modal-van');
        loadVans();
      } else {
        alert('Failed to save van details.');
      }
    } catch (err) {
      alert('Connection error.');
    }
  });

  // Submit Speedboat Form
  document.getElementById('board-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('board-id').value;

    const boardData = {
      name_en: document.getElementById('board-name-en').value.trim(),
      name_bn: document.getElementById('board-name-bn').value.trim(),
      boat_en: document.getElementById('board-model-en').value.trim(),
      boat_bn: document.getElementById('board-model-bn').value.trim(),
      price_en: document.getElementById('board-price-en').value.trim(),
      price_bn: document.getElementById('board-price-bn').value.trim(),
      rating: parseFloat(document.getElementById('board-rating').value) || 4.9,
      trips: parseInt(document.getElementById('board-trips').value) || 100,
      phone: document.getElementById('board-phone').value.trim(),
      image: document.getElementById('board-image-url').value.trim() || 'https://images.unsplash.com/photo-1500048993953-d23a436266cf?auto=format&fit=crop&w=300&q=80',
      details_en: document.getElementById('board-details-en').value.trim(),
      details_bn: document.getElementById('board-details-bn').value.trim()
    };

    try {
      let res;
      if (id) {
        res = await fetch(`${API_BASE}/api/content/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(boardData)
        });
      } else {
        res = await fetch(`${API_BASE}/api/content/board`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(boardData)
        });
      }

      if (res.ok) {
        closeModal('modal-board');
        loadBoards();
      } else {
        alert('Failed to save speedboat details.');
      }
    } catch (err) {
      alert('Connection error.');
    }
  });

  // Submit Boat Form
  document.getElementById('boat-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('boat-id').value;

    const boatData = {
      name_en: document.getElementById('boat-name-en').value.trim(),
      name_bn: document.getElementById('boat-name-bn').value.trim(),
      boat_en: document.getElementById('boat-model-en').value.trim(),
      boat_bn: document.getElementById('boat-model-bn').value.trim(),
      price_en: document.getElementById('boat-price-en').value.trim(),
      price_bn: document.getElementById('boat-price-bn').value.trim(),
      rating: parseFloat(document.getElementById('boat-rating').value) || 4.7,
      trips: parseInt(document.getElementById('boat-trips').value) || 100,
      phone: document.getElementById('boat-phone').value.trim(),
      image: document.getElementById('boat-image-url').value.trim() || 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
      details_en: document.getElementById('boat-details-en').value.trim(),
      details_bn: document.getElementById('boat-details-bn').value.trim()
    };

    try {
      let res;
      if (id) {
        res = await fetch(`${API_BASE}/api/content/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(boatData)
        });
      } else {
        res = await fetch(`${API_BASE}/api/content/boat`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(boatData)
        });
      }

      if (res.ok) {
        closeModal('modal-boat');
        loadBoats();
      } else {
        alert('Failed to save boat details.');
      }
    } catch (err) {
      alert('Connection error.');
    }
  });

  // Submit Food Form (Restaurant)
  document.getElementById('food-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('food-id').value;

    // Map dishes rows
    const menu = [];
    document.querySelectorAll('#dishes-rows-container .room-row').forEach(row => {
      const nameEn = row.querySelector('.dish-name-en').value.trim();
      const nameBn = row.querySelector('.dish-name-bn').value.trim();
      const price = parseFloat(row.querySelector('.dish-price').value);
      const image = row.querySelector('.dish-image-url').value.trim();

      if (nameEn && nameBn && !isNaN(price)) {
        menu.push({
          name_en: nameEn,
          name_bn: nameBn,
          price: price,
          image: image || 'https://images.unsplash.com/photo-1553618551-fba689030290?auto=format&fit=crop&w=400&q=80'
        });
      }
    });

    const foodData = {
      name_en: document.getElementById('food-name-en').value.trim(),
      name_bn: document.getElementById('food-name-bn').value.trim(),
      address: document.getElementById('food-address').value.trim(),
      phone: document.getElementById('food-phone').value.trim(),
      image: document.getElementById('food-image-url').value.trim() || 'https://images.unsplash.com/photo-1553618551-fba689030290?auto=format&fit=crop&w=400&q=80',
      menu_type: document.getElementById('food-menu-type').value,
      menu_image: document.getElementById('food-menu-image-url').value.trim(),
      menu: menu
    };

    try {
      let res;
      if (id) {
        res = await fetch(`${API_BASE}/api/content/${id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(foodData)
        });
      } else {
        res = await fetch(`${API_BASE}/api/content/food`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode(foodData)
        });
      }

      if (res.ok) {
        closeModal('modal-food');
        loadFoods();
      } else {
        alert('Failed to save restaurant details.');
      }
    } catch (err) {
      alert('Connection error.');
    }
  });
}

// Custom delete manager function since we need to write the backend API
async function deleteManagerUser(id, managerName) {
  if (!confirm(`Are you sure you want to delete manager "${managerName}"?`)) return;
  try {
    const res = await fetch(`${API_BASE}/api/admin/managers/${id}`, {
      method: 'DELETE'
    });
    if (res.ok) {
      loadManagers();
    } else {
      alert('Failed to delete manager account.');
    }
  } catch (err) {
    alert('Connection failed.');
  }
}

// Override original deleteContentItem for manager to route to deleteManagerUser
const originalDeleteContentItem = deleteContentItem;
deleteContentItem = function(type, id, itemName) {
  if (type === 'manager') {
    deleteManagerUser(id, itemName);
  } else {
    originalDeleteContentItem(type, id, itemName);
  }
};

// ==================== CONVERSION / FORMATTING HELPERS ====================
function formatDate(dateString) {
  if (!dateString) return 'N/A';
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { day: 'numeric', month: 'short', year: 'numeric' });
  } catch (_) {
    return dateString;
  }
}

function getBadgeClass(status) {
  if (status === 'Resolved') return 'resolved';
  if (status === 'Under Investigation') return 'investigation';
  return 'pending';
}

function escapeHtml(str) {
  if (!str) return '';
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// Helper to handle JSON serializing without strict JS engine dependencies
function jsonEncode(obj) {
  return JSON.stringify(obj);
}
