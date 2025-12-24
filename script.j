// =================== DATA & STORAGE ===================

let notes = JSON.parse(localStorage.getItem("advancedNotesApp")) || [];
let editingId = null;
let currentViewId = null;

// Elements
const noteTitle = document.getElementById("noteTitle");
const noteCategory = document.getElementById("noteCategory");
const noteTags = document.getElementById("noteTags");
const noteBody = document.getElementById("noteBody");
const notePinned = document.getElementById("notePinned");
const noteFavorite = document.getElementById("noteFavorite");
const saveNoteBtn = document.getElementById("saveNoteBtn");
const clearFormBtn = document.getElementById("clearFormBtn");
const formTitle = document.getElementById("formTitle");

const notesList = document.getElementById("notesList");
const searchInput = document.getElementById("searchInput");
const categoryFilter = document.getElementById("categoryFilter");
const statusFilter = document.getElementById("statusFilter");
const sortSelect = document.getElementById("sortSelect");
const darkModeToggle = document.getElementById("darkModeToggle");

// Modal elements
const noteModal = document.getElementById("noteModal");
const closeModal = document.getElementById("closeModal");
const modalTitle = document.getElementById("modalTitle");
const modalMeta = document.getElementById("modalMeta");
const modalBody = document.getElementById("modalBody");
const editNoteBtn = document.getElementById("editNoteBtn");
const downloadPdfBtn = document.getElementById("downloadPdfBtn");
const toggleArchiveBtn = document.getElementById("toggleArchiveBtn");
const toggleFavoriteBtn = document.getElementById("toggleFavoriteBtn");
const togglePinBtn = document.getElementById("togglePinBtn");
const deleteNoteBtn = document.getElementById("deleteNoteBtn");

// =================== UTILITIES ===================

function saveToStorage() {
    localStorage.setItem("advancedNotesApp", JSON.stringify(notes));
}

function generateId() {
    return Date.now().toString();
}

function formatDate(ts) {
    const d = new Date(ts);
    return d.toLocaleString();
}

function stripHtml(html) {
    const div = document.createElement("div");
    div.innerHTML = html;
    return div.textContent || div.innerText || "";
}

// =================== RENDER FUNCTIONS ===================

function updateCategoryFilterOptions() {
    const categories = new Set();
    notes.forEach(n => {
        if (n.category) categories.add(n.category.trim());
    });

    // reset
    categoryFilter.innerHTML = `<option value="all">All</option>`;
    categories.forEach(cat => {
        const opt = document.createElement("option");
        opt.value = cat;
        opt.textContent = cat;
        categoryFilter.appendChild(opt);
    });
}

function renderNotes() {
    updateCategoryFilterOptions();

    let filtered = [...notes];

    // status filter
    const status = statusFilter.value;
    if (status === "active") {
        filtered = filtered.filter(n => !n.archived);
    } else if (status === "archived") {
        filtered = filtered.filter(n => n.archived);
    } else if (status === "pinned") {
        filtered = filtered.filter(n => n.pinned);
    } else if (status === "favorite") {
        filtered = filtered.filter(n => n.favorite);
    }

    // category filter
    const catVal = categoryFilter.value;
    if (catVal !== "all") {
        filtered = filtered.filter(n => n.category === catVal);
    }

    // search filter
    const q = searchInput.value.trim().toLowerCase();
    if (q) {
        filtered = filtered.filter(n => {
            const text = (
                n.title + " " +
                stripHtml(n.body) + " " +
                (n.tags || []).join(" ")
            ).toLowerCase();
            return text.includes(q);
        });
    }

    // sort
    const sort = sortSelect.value;
    if (sort === "newest") {
        filtered.sort((a, b) => b.createdAt - a.createdAt);
    } else if (sort === "oldest") {
        filtered.sort((a, b) => a.createdAt - b.createdAt);
    } else if (sort === "title") {
        filtered.sort((a, b) => a.title.localeCompare(b.title));
    }

    // Pinned first automatically
    filtered.sort((a, b) => (b.pinned === true) - (a.pinned === true));

    // Render
    notesList.innerHTML = "";
    if (filtered.length === 0) {
        notesList.innerHTML = `<p style="font-size:14px; color:var(--text-muted);">No notes found.</p>`;
        return;
    }

    filtered.forEach(note => {
        const card = document.createElement("div");
        card.className = "note-card";
        card.dataset.id = note.id;

        const tagsText = (note.tags || []).join(", ");
        const previewText = stripHtml(note.body).substring(0, 80);

        card.innerHTML = `
            <div>
                <div class="note-title">
                    ${note.title || "(Untitled)"}
                    ${note.pinned ? `<span class="badge">Pinned</span>` : ""}
                    ${note.favorite ? `<span class="badge">★</span>` : ""}
                    ${note.archived ? `<span class="badge">Archived</span>` : ""}
                </div>
                <div class="note-meta">
                    ${note.category ? `Category: ${note.category} • ` : ""}
                    Created: ${formatDate(note.createdAt)}
                </div>
                <div class="note-preview">${previewText || "(Empty note)"}</div>
                <div class="note-tags">
                    ${tagsText ? "Tags: " + tagsText : ""}
                </div>
            </div>
            <div class="note-actions">
                <button data-action="view">Open</button>
                <button data-action="pin">${note.pinned ? "Unpin" : "Pin"}</button>
                <button data-action="favorite">${note.favorite ? "Unfavorite" : "Favorite"}</button>
                <button data-action="archive">${note.archived ? "Unarchive" : "Archive"}</button>
                <button data-action="delete">Delete</button>
            </div>
        `;

        notesList.appendChild(card);
    });
}

// =================== FORM HANDLING ===================

function clearForm() {
    editingId = null;
    formTitle.textContent = "Create New Note";
    noteTitle.value = "";
    noteCategory.value = "";
    noteTags.value = "";
    noteBody.innerHTML = "";
    notePinned.checked = false;
    noteFavorite.checked = false;
}

function saveNote() {
    const title = noteTitle.value.trim();
    const category = noteCategory.value.trim();
    const tags = noteTags.value
        .split(",")
        .map(t => t.trim())
        .filter(Boolean);
    const body = noteBody.innerHTML.trim();

    if (!title && !body) {
        alert("Please write something or give a title.");
        return;
    }

    if (editingId) {
        const idx = notes.findIndex(n => n.id === editingId);
        if (idx !== -1) {
            notes[idx].title = title || "(Untitled)";
            notes[idx].category = category;
            notes[idx].tags = tags;
            notes[idx].body = body;
            notes[idx].pinned = notePinned.checked;
            notes[idx].favorite = noteFavorite.checked;
            notes[idx].updatedAt = Date.now();
        }
    } else {
        const newNote = {
            id: generateId(),
            title: title || "(Untitled)",
            category,
            tags,
            body,
            pinned: notePinned.checked,
            favorite: noteFavorite.checked,
            archived: false,
            createdAt: Date.now(),
            updatedAt: Date.now()
        };
        notes.push(newNote);
    }

    saveToStorage();
    clearForm();
    renderNotes();
}

// =================== NOTE CARD ACTIONS ===================

notesList.addEventListener("click", (e) => {
    const card = e.target.closest(".note-card");
    if (!card) return;

    const id = card.dataset.id;
    const action = e.target.dataset.action;

    if (!action) return;

    if (action === "view") {
        openNoteModal(id);
    } else if (action === "pin") {
        togglePin(id);
    } else if (action === "favorite") {
        toggleFavorite(id);
    } else if (action === "archive") {
        toggleArchive(id);
    } else if (action === "delete") {
        deleteNote(id);
    }
});

function togglePin(id) {
    const note = notes.find(n => n.id === id);
    if (!note) return;
    note.pinned = !note.pinned;
    note.updatedAt = Date.now();
    saveToStorage();
    renderNotes();
}

function toggleFavorite(id) {
    const note = notes.find(n => n.id === id);
    if (!note) return;
    note.favorite = !note.favorite;
    note.updatedAt = Date.now();
    saveToStorage();
    renderNotes();
}

function toggleArchive(id) {
    const note = notes.find(n => n.id === id);
    if (!note) return;
    note.archived = !note.archived;
    note.updatedAt = Date.now();
    saveToStorage();
    renderNotes();
}

function deleteNote(id) {
    if (!confirm("Delete this note?")) return;
    notes = notes.filter(n => n.id !== id);
    saveToStorage();
    renderNotes();
}

// =================== MODAL VIEW ===================

function openNoteModal(id) {
    const note = notes.find(n => n.id === id);
    if (!note) return;

    currentViewId = id;
    modalTitle.textContent = note.title;
    const metaStr = [
        note.category ? `Category: ${note.category}` : "",
        note.tags && note.tags.length ? `Tags: ${note.tags.join(", ")}` : "",
        `Created: ${formatDate(note.createdAt)}`,
        `Updated: ${formatDate(note.updatedAt)}`
    ].filter(Boolean).join(" • ");
    modalMeta.textContent = metaStr;

    modalBody.innerHTML = note.body || "(Empty note)";
    noteModal.classList.remove("hidden");
}

closeModal.addEventListener("click", () => {
    noteModal.classList.add("hidden");
    currentViewId = null;
});

window.addEventListener("click", (e) => {
    if (e.target === noteModal) {
        noteModal.classList.add("hidden");
        currentViewId = null;
    }
});

// Modal buttons

editNoteBtn.addEventListener("click", () => {
    if (!currentViewId) return;
    const note = notes.find(n => n.id === currentViewId);
    if (!note) return;

    noteModal.classList.add("hidden");

    editingId = note.id;
    formTitle.textContent = "Edit Note";
    noteTitle.value = note.title;
    noteCategory.value = note.category || "";
    noteTags.value = (note.tags || []).join(", ");
    noteBody.innerHTML = note.body;
    notePinned.checked = note.pinned;
    noteFavorite.checked = note.favorite;
    window.scrollTo({ top: 0, behavior: "smooth" });
});

downloadPdfBtn.addEventListener("click", () => {
    if (!currentViewId) return;
    const note = notes.find(n => n.id === currentViewId);
    if (!note) return;

    const { jsPDF } = window.jspdf;
    const pdf = new jsPDF();
    const text = note.title + "\n\n" + stripHtml(note.body);

    const lines = pdf.splitTextToSize(text, 180);
    pdf.text(lines, 10, 10);
    pdf.save((note.title || "note") + ".pdf");
});

toggleArchiveBtn.addEventListener("click", () => {
    if (!currentViewId) return;
    toggleArchive(currentViewId);
    openNoteModal(currentViewId); // refresh view
});

toggleFavoriteBtn.addEventListener("click", () => {
    if (!currentViewId) return;
    toggleFavorite(currentViewId);
    openNoteModal(currentViewId);
});

togglePinBtn.addEventListener("click", () => {
    if (!currentViewId) return;
    togglePin(currentViewId);
    openNoteModal(currentViewId);
});

deleteNoteBtn.addEventListener("click", () => {
    if (!currentViewId) return;
    const id = currentViewId;
    noteModal.classList.add("hidden");
    currentViewId = null;
    deleteNote(id);
});

// =================== TOOLBAR (RICH TEXT) ===================

document.querySelectorAll(".toolbar button").forEach(btn => {
    btn.addEventListener("click", () => {
        const cmd = btn.dataset.cmd;
        document.execCommand(cmd, false, null);
        noteBody.focus();
    });
});

// =================== FILTER EVENTS ===================

[searchInput, categoryFilter, statusFilter, sortSelect].forEach(el => {
    el.addEventListener("input", renderNotes);
    el.addEventListener("change", renderNotes);
});

// =================== DARK MODE ===================

const savedTheme = localStorage.getItem("notesTheme");
if (savedTheme === "dark") {
    document.body.classList.add("dark");
    darkModeToggle.textContent = "☀️ Light Mode";
}

darkModeToggle.addEventListener("click", () => {
    document.body.classList.toggle("dark");
    const isDark = document.body.classList.contains("dark");
    localStorage.setItem("notesTheme", isDark ? "dark" : "light");
    darkModeToggle.textContent = isDark ? "☀️ Light Mode" : "🌙 Dark Mode";
});

// =================== BUTTON EVENTS ===================

saveNoteBtn.addEventListener("click", saveNote);
clearFormBtn.addEventListener("click", clearForm);

// Initial render
renderNotes();
