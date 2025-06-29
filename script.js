
const table = document.getElementById('dataTable');
const tableHead = document.querySelector('#dataTable thead');
let tableBody = document.querySelector('#dataTable tbody');
const recordCountElement = document.getElementById('recordCount');
let searchInput = document.getElementById('searchInput');
let currentType = '';

let originalData = []; 

let currentPage = 1;
const rowsPerPage = 10;
let fullData = [];
let currentPageData = [];
let currentSearchKeys = [];
let currentFormatter = () => "";
let currentHeaders = [];
let searchTerm = '';

let parts = [];
let partsGrid;
let selection = [];
const itemsPerPage = 10;




const aside = document.getElementById('aside');
const barMain = document.getElementById('bar_main');
const closeButton = document.getElementById('butt_settings');
const showSidebarButton = document.getElementById('showSidebar');

const modal = document.getElementById('outMain');
const closeModalBtn = document.getElementById('closeModalBtn');

const tableTitles = {
    CLIENT: "Client",
    CONFIG: "Configuration",
    MANAGER: "Manager",
    MODEL: "Model",
    ORDERING: "Ordering",
    ORDER_PARTS: "Order Parts",
    PART: "Part",
    RELATE: "Relate",
    REQUEST: "Request",
    SUPPLIER: "Supplier",
    REPORT: "Report"
};

const orderStatuses = {
    1: 'Создан',
    2: 'В обработке',
    3: 'В работе',
    4: 'Авто прибыл',
    5: 'Ожидает оплаты',
    6: 'Оплачен',
    7: 'Отменен'
};

const partsNames = {
    1: 'Масло моторное',
    2: 'Масло трансмиссионное',
    3: 'Антифриз',
    4: 'Шины летние',
    5: 'Шины зимние',
    6: 'Тормозные колодки',
    7: 'Аккумулятор',
    8: 'Фильтр масляный',
    9: 'Фильтр воздушный',
    10: 'Фильтр салона',
    11: 'Фильтр топливный',
    12: 'Сцепление',
    13: 'Амортизаторы',
    14: 'Поршни',
    15: 'Стартер',
    16: 'Генератор',
    17: 'Свечи зажигания',
    18: 'Лямбда-зонд',
    19: 'Катализатор',
    20: 'Топливный насос'
};

const requestStatuses = {
    1: 'В работе',
    2: 'Отменена',
    3: 'Выполнена'
};

const requestTypes = {
    1: 'Удаление',
    2: 'Изменение',
    3: 'Добавление',
    4: 'Просмотр'
};

const paydates = {
    'null': 'Не оплачено'
};

function formatDate(dateString) {
    if (!dateString || dateString === 'null') return null;
    
    if (/^\d{4}-\d{2}-\d{2}$/.test(dateString)) {
        return dateString;
    }
    
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return dateString; 
    
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    
    return `${year}-${month}-${day}`;
}

closeModalBtn.addEventListener('click', () => {
    modal.style.display = 'none';
    const form = modal.querySelector('.form_display');
    form.innerHTML = ''; 
});

 

closeButton.addEventListener('click', () => {
    aside.classList.add('hidden');
    barMain.classList.add('expanded');
    showSidebarButton.style.display = 'block';
});

showSidebarButton.addEventListener('click', () => {
    aside.classList.remove('hidden');
    barMain.classList.remove('expanded');
    showSidebarButton.style.display = 'none';
});


async function openEditModal(rowData) {
    const modal = document.getElementById('outMain');
    const form = modal.querySelector('.form_display');
    form.innerHTML = '';

    const editableFields = {
        client: ['SNP', 'Number', 'Passport', 'login_client', 'password_client'],
        model: ['name_model', 'yearstart_model', 'yearend_model', 'bodyno_model'],
        manager: ['snp_manager', 'start_date', 'login_manager', 'password_manager', 'role'],
        part: ['name_part', 'color_part', 'type_part', 'cost_part'],
        supplier: ['name_supplier', 'login_supplier', 'password_supplier'],
        config: ['name_con'],
        relate: ['pid_part'],
        request: ['id_supplier', 'id_manager', 'data_registration', 'status_request', 'cost_request', 'mid_manager'],
        ordering: ['id_manager', 'id_client', 'date_ordering', 'date_pay_ordering', 'status_ordering'],
        order_parts: ['quantity_parts']
    };

    const lookupFields = {
        id_model: { url: '/get-data/model', value: 'id_model', customLabel: item => `${item.id_model} (${item.name_model})` },
        id_supplier: { url: '/get-data/supplier', value: 'id_supplier', customLabel: item => `${item.id_supplier} (${item.name_supplier})` },
        id_manager: { url: '/get-data/manager', value: 'id_manager', customLabel: item => `${item.id_manager} (${item.snp_manager})` },
        mid_manager: { url: '/get-data/manager', value: 'id_manager', customLabel: item => `${item.id_manager} (${item.snp_manager})` },
        id_client: { url: '/get-data/client', value: 'id', customLabel: item => `${item.id} (${item.SNP})` },
        id_part: { url: '/get-data/part', value: 'id_part', customLabel: item => `${item.id_part} (${item.name_part})` },
        id_ordering: { url: '/get-data/ordering', value: 'id_ordering', customLabel: item => `${item.id_ordering} (${item.snp_client})` },
        id_request: { url: '/get-data/request', value: 'id_request', customLabel: item => `${item.id_request} (${item.name_supplier})` },
        pid_part: { url: '/get-data/part', value: 'id_part', customLabel: item => `${item.id_part} (${item.name_part})` },
        status_ordering: { customOptions: Object.entries(orderStatuses).map(([value, label]) => ({ value, label })) },
        status_request: { customOptions: Object.entries(requestStatuses).map(([value, label]) => ({ value, label })) },
        action_type: { customOptions: Object.entries(requestTypes).map(([value, label]) => ({ value, label })) }
    };

    const currentEditable = editableFields[currentType] || [];

    for (const key of currentSearchKeys) {
        const value = rowData[key];
        const isEditable = currentEditable.includes(key);
        let input;

        if (lookupFields[key]?.customOptions) {
            input = document.createElement('select');
            input.name = key;
            input.disabled = !isEditable;

            lookupFields[key].customOptions.forEach(option => {
                const optionElement = document.createElement('option');
                optionElement.value = option.value;
                optionElement.textContent = option.label;
                if (option.value == value) optionElement.selected = true;
                input.appendChild(optionElement);
            });
        } 
        else if (lookupFields[key]?.url) {
            input = document.createElement('select');
            input.name = key;
            input.disabled = !isEditable;

            try {
                const res = await fetch(lookupFields[key].url);
                const data = await res.json();
                data.forEach(item => {
                    const option = document.createElement('option');
                    option.value = item[lookupFields[key].value];
                    option.textContent = lookupFields[key].customLabel
                        ? lookupFields[key].customLabel(item)
                        : item[lookupFields[key].label];
                    if (item[lookupFields[key].value] == value) option.selected = true;
                    input.appendChild(option);
                });
            } catch (err) {
                console.error("Ошибка справочника:", err);
            }
        } 
        else {
            input = document.createElement('input');
            input.type = 'text';
            input.name = key;
            input.value = value;
            input.disabled = !isEditable;

            if (key.toLowerCase().includes("passport")) {
                Inputmask("9999 999999").mask(input);
            } else if (key.toLowerCase().includes("number") || key.toLowerCase().includes("phone")) {
                Inputmask("89999999999").mask(input);
            } else if (key === 'yearstart_model' || key === 'yearend_model') {
                Inputmask("9999").mask(input);
            } else if (key === 'bodyno_model') {
                Inputmask({ regex: "[A-Z]{3}[0-9]{6}", placeholder: "PQR456789" }).mask(input);
            } else if (key === 'VIN') {
                Inputmask("VIN99999999999999").mask(input);
            } else if (key === 'cost_part') {
                Inputmask({ regex: "^[1-9][0-9]*$", placeholder: "1000" }).mask(input);
            } else if (key === 'type_part') {
                Inputmask("9{1,2}").mask(input);
            }
        }


        const label = document.createElement('label');
        label.textContent = key;
        label.style.display = 'block';
        label.style.marginTop = '10px';

        input.style.marginBottom = '10px';
        input.style.width = '100%';

        form.appendChild(label);
        form.appendChild(input);
    }

    const saveBtn = document.createElement('button');
    saveBtn.textContent = 'Save';
    saveBtn.type = 'button';
    saveBtn.id = 'modalSaveBtn';
    saveBtn.style.marginTop = '20px';

    saveBtn.addEventListener('click', () => {
        const formData = {};
        const inputs = form.querySelectorAll('input, select');
        inputs.forEach(input => {
            formData[input.name] = input.value;
        });

        fetch(`/update-row/${currentType}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(formData)
        })
        .then(response => {
            if (!response.ok) throw new Error("Update failed");
            return response.json();
        })
        .then(() => {
            modal.style.display = 'none';
            form.innerHTML = '';
            loadTable(currentType, currentHeaders, currentSearchKeys, currentFormatter);
        })
        .catch(err => {
            console.error("Ошибка при сохранении:", err);
            alert("Ошибка при сохранении");
        });
    });

    form.appendChild(saveBtn);
    modal.style.display = 'block';
}

function paginateData(data) {
    const start = (currentPage - 1) * rowsPerPage;
    const end = start + rowsPerPage;
    return data.slice(start, end);
}

document.getElementById('sortChronological').addEventListener('click', () => {
    fullData.sort((a, b) => {
        const dateA = new Date(a.date_ordering || a.data_registration || a.start_date || 0);
        const dateB = new Date(b.date_ordering || b.data_registration || b.start_date || 0);
        return dateA - dateB;
    });
    currentPage = 1;
    renderTable(currentHeaders, paginateData(fullData), currentFormatter);
});

const monthDisplay = document.querySelector('.butt_sort_time .sort_name');
const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
];
let currentMonth = 4;
let currentYear = 2025;

function updateMonthDisplay() {
    monthDisplay.textContent = `${months[currentMonth]}, ${currentYear}`;
}

function filterByMonth() {
    const filtered = fullData.filter(item => {
        const dateStr = item.date_ordering || item.data_registration || item.start_date;
        if (!dateStr) return false;
        const date = new Date(dateStr);
        return date.getMonth() === currentMonth && date.getFullYear() === currentYear;
    });
    currentPage = 1;
    renderTable(currentHeaders, paginateData(filtered), currentFormatter);
}

document.querySelectorAll('.butt_sort_time .side')[0].addEventListener('click', () => {
    if (currentMonth === 0) {
        currentMonth = 11;
        currentYear--;
    } else {
        currentMonth--;
    }
    updateMonthDisplay();
    filterByMonth();
});

document.querySelectorAll('.butt_sort_time .side')[1].addEventListener('click', () => {
    if (currentMonth === 11) {
        currentMonth = 0;
        currentYear++;
    } else {
        currentMonth++;
    }
    updateMonthDisplay();
    filterByMonth();
});

updateMonthDisplay();


function renderPaginationControls() {
    const paginationContainer = document.getElementById('paginationControls');
    if (!paginationContainer) return;

    paginationContainer.innerHTML = '';
    const totalPages = Math.ceil(fullData.length / rowsPerPage);

    const leftArrow = document.createElement('button');
    leftArrow.innerHTML = '&larr;';
    leftArrow.disabled = currentPage === 1;
    leftArrow.addEventListener('click', () => {
        if (currentPage > 1) {
            currentPage--;
            renderTable(currentHeaders, paginateData(fullData), currentFormatter);
        }
    });

    const rightArrow = document.createElement('button');
    rightArrow.innerHTML = '&rarr;';
    rightArrow.disabled = currentPage === totalPages;
    rightArrow.addEventListener('click', () => {
        if (currentPage < totalPages) {
            currentPage++;
            renderTable(currentHeaders, paginateData(fullData), currentFormatter);
        }
    });

    const pageIndicator = document.createElement('span');
    pageIndicator.className = 'page-indicator';
    pageIndicator.textContent = `Page ${currentPage} of ${totalPages}`;

    paginationContainer.appendChild(leftArrow);
    paginationContainer.appendChild(pageIndicator);
    paginationContainer.appendChild(rightArrow);

    }

function createColumnFilters(columns) {
    let filterButton = document.querySelector('.filter-button');
    let filterDropdown = document.querySelector('.filter-dropdown');

    if (!filterButton) {
        filterButton = document.createElement('button');
        filterButton.style.backgroundImage = 'url("img/filter.png")';
        filterButton.classList.add('filter-button');
        table.parentNode.insertBefore(filterButton, table);

        filterDropdown = document.createElement('div');
        filterDropdown.classList.add('filter-dropdown');
        table.parentNode.insertBefore(filterDropdown, filterButton);

        filterButton.addEventListener('click', () => {
            filterDropdown.classList.toggle('show');
        });

        document.addEventListener('click', (event) => {
            if (!filterButton.contains(event.target) && !filterDropdown.contains(event.target)) {
                filterDropdown.classList.remove('show');
            }
        });
    } else {
        filterDropdown.innerHTML = '';
    }

    columns.forEach((column, index) => {
        const filterItem = document.createElement('div');
        filterItem.classList.add('filter-item');

        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.checked = true;
        checkbox.id = `filter-${column}`;
        checkbox.dataset.index = index;
        checkbox.addEventListener('change', updateTableColumns);

        const label = document.createElement('label');
        label.htmlFor = `filter-${column}`;
        label.textContent = column;

        filterItem.appendChild(checkbox);
        filterItem.appendChild(label);
        filterDropdown.appendChild(filterItem);
    });
}

function updateTableColumns() {
    const checkboxes = document.querySelectorAll('.filter-dropdown input[type="checkbox"]');
    const tableRows = table.querySelectorAll('tr');

    checkboxes.forEach((checkbox) => {
        const index = checkbox.dataset.index;
        tableRows.forEach(row => {
            const cell = row.cells[index];
            if (cell) {
                cell.style.display = checkbox.checked ? '' : 'none';
            }
        });
    });
}

function renderTable(headers, data, formatter) {
    currentPageData = data;
    tableHead.innerHTML = '';
    tableBody.innerHTML = '';

    const tr = document.createElement('tr');
    headers.forEach(header => {
        const th = document.createElement('th');
        th.textContent = header;
        tr.appendChild(th);
    });
    tableHead.appendChild(tr);

    data.forEach((row, index) => {
    const tr = document.createElement('tr');
    tr.className = index % 2 === 0 ? 'even-row' : 'odd-row';
    tr.innerHTML = formatter(row);

    const actionsCell = document.createElement('td');
    const role = localStorage.getItem("userRole");

    if (role === "admin") {
        actionsCell.innerHTML = `
            <button class="edit-btn" data-index="${index}">
                <img src="img/pen.png" alt="Edit" class="action-icon">
            </button>
            <button class="delete-btn" data-index="${index}">
                <img src="img/delete.png" alt="Delete" class="action-icon">
            </button>
        `;
    } else if (role === "manager") {
        actionsCell.innerHTML = `
            <span style="opacity: 0.4; font-size: 12px;">Просмотр</span>
        `;
    } else {
        actionsCell.innerHTML = ""; 
    }

    tr.appendChild(actionsCell);


    tableBody.appendChild(tr);
});


    updateRecordCount();
    createColumnFilters(headers);
    renderPaginationControls();
}

function updateRecordCount() {
    recordCountElement.textContent = `Results quantity: ${fullData.length}`;
}


function setupSearch() {
    const newInput = searchInput.cloneNode(true);
    searchInput.parentNode.replaceChild(newInput, searchInput);
    searchInput = newInput;

    if (!originalData.length) return;

    const keys = Object.keys(originalData[0]);

    newInput.addEventListener('input', () => {
        const term = newInput.value.toLowerCase();
        if (document.getElementById('orderCreationArea').style.display === 'block') {
            const filtered = parts.filter(part =>
                part.name_part.toLowerCase().includes(term) ||
                part.color_part.toLowerCase().includes(term) || 
                part.cost_part.toLowerCase().includes(term)
            );

            renderPartsList(filtered);
            renderPartsPagination(filtered);
        }
        else {
            fullData = originalData.filter(item =>
                keys.some(key => {
                    const value = item[key];
                    return value && value.toString().toLowerCase().includes(term);
                })
            );
            currentPage = 1;
            renderTable(currentHeaders, paginateData(fullData), currentFormatter);
        }
    });
}

function renderPage(page) {
    currentPage = page;
    renderPartsList(parts);
    renderPartsPagination(parts);
}


function renderPartsList(filteredParts) {
    partsGrid.innerHTML = '';

    const start = (currentPage - 1) * itemsPerPage;
    const end = start + itemsPerPage;
    const pageItems = filteredParts.slice(start, end);

    pageItems.forEach(part => {
        const card = document.createElement('div');
        card.className = 'part-card';

        const existingSelection = selection.find(s => s.id_part === part.id_part);

        card.style.border = '2px solid transparent';
        card.style.borderRadius = '12px';
        card.style.padding = '20px';
        card.style.width = '240px';
        card.style.textAlign = 'center';
        card.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)';
        card.style.backgroundColor = '#fff';
        card.style.transition = 'all 0.2s ease';
        card.style.cursor = 'pointer';
        card.style.position = 'relative';

        const img = document.createElement('img');
        img.src = `img/parts/${part.id_part}.png`;
        img.onerror = () => {
            img.src = 'img/placeholder_part.png';
        };
        img.style.width = '160px';
        img.style.height = '160px';
        img.style.objectFit = 'cover';
        img.style.marginBottom = '10px';

        const name = document.createElement('p');
        name.textContent = part.name_part;
        name.style.fontWeight = 'bold';

        const price = document.createElement('p');
        price.textContent = `${part.cost_part} ₽`;
        price.style.color = '#2264E5';

        let quantityInput = createQuantityInput();

        if (existingSelection) {
            card.classList.add('selected');
            card.style.border = '2px solid #2264E5';
            card.style.backgroundColor = '#f0f6ff';

            quantityInput.value = existingSelection.quantityInput.value;
            existingSelection.quantityInput = quantityInput;
        }

        card.addEventListener('click', (event) => {
            if (event.target.tagName === 'INPUT') return;

            const isNowSelected = card.classList.toggle('selected');

            if (isNowSelected) {
                card.style.border = '2px solid #2264E5';
                card.style.backgroundColor = '#f0f6ff';

                quantityInput = createQuantityInput();
                card.insertBefore(quantityInput, price.nextSibling);

                selection.push({ id_part: part.id_part, quantityInput });
            } else {
                card.style.border = '2px solid transparent';
                card.style.backgroundColor = '#fff';

                if (quantityInput) {
                    quantityInput.remove();
                    quantityInput = null;
                }

                selection = selection.filter(sel => sel.id_part !== part.id_part);
            }
        });

        card.appendChild(img);
        card.appendChild(name);
        card.appendChild(price);

        if (existingSelection) {
            card.insertBefore(quantityInput, price.nextSibling);
        }

        partsGrid.appendChild(card);
    });
}

function createQuantityInput() {
    const input = document.createElement('input');
    input.type = 'number';
    input.min = 1;
    input.placeholder = 'Количество';
    input.style.marginTop = '10px';
    input.style.padding = '8px';
    input.style.width = '100%';
    input.style.borderRadius = '6px';
    input.style.border = '1px solid #ccc';
    input.style.outline = 'none';
    input.style.fontSize = '14px';
    return input;
}



function renderPartsPagination(filteredParts) {
    const paginationDiv = document.getElementById('paginationControls');
    paginationDiv.innerHTML = '';
    paginationDiv.style.display = 'flex';
    paginationDiv.style.justifyContent = 'center';
    paginationDiv.style.marginTop = '20px';

    const totalPages = Math.ceil(filteredParts.length / itemsPerPage);

    const prevBtn = document.createElement('button');
    prevBtn.textContent = '← Назад';
    prevBtn.disabled = currentPage === 1;
    prevBtn.style.marginRight = '10px';
    prevBtn.addEventListener('click', () => {
        if (currentPage > 1) {
            currentPage--;
            renderPartsList(filteredParts);
            renderPartsPagination(filteredParts);
        }
    });

    const nextBtn = document.createElement('button');
    nextBtn.textContent = 'Вперёд →';
    nextBtn.disabled = currentPage === totalPages;
    nextBtn.addEventListener('click', () => {
        if (currentPage < totalPages) {
            currentPage++;
            renderPartsList(filteredParts);
            renderPartsPagination(filteredParts);
        }
    });

    const pageLabel = document.createElement('span');
    pageLabel.textContent = `Страница ${currentPage} из ${totalPages}`;
    pageLabel.style.margin = '0 10px';

    paginationDiv.appendChild(prevBtn);
    paginationDiv.appendChild(pageLabel);
    paginationDiv.appendChild(nextBtn);
}




function loadTable(type, headers, searchKeys, formatter) {
    document.getElementById('reportResult').innerHTML = '';
    document.getElementById('downloadPDFWrapper').style.display = 'none';
    restoreDefaultView();
    tableBody.replaceWith(tableBody.cloneNode(false));
    tableBody = document.querySelector('#dataTable tbody');

    currentType = type;
    fetch(`/get-data/${type}`)
        .then(response => response.json())
        .then(data => {
            originalData = data;
            fullData = [...originalData]; 
            currentPage = 1;
            currentSearchKeys = searchKeys;
            currentFormatter = formatter;
            currentHeaders = headers;
            renderTable(headers, paginateData(fullData), formatter);
            renderTable(headers, paginateData(fullData), formatter);
            addDynamicAddButton(type);
            tableBody.addEventListener('click', (e) => {
                if (e.target.closest('.edit-btn')) {
                    const rowIndex = e.target.closest('.edit-btn').dataset.index;
                    const rowData = currentPageData[rowIndex];
                    openEditModal(rowData);
                }


                if (e.target.closest('.delete-btn')) {
                    const rowIndex = e.target.closest('.delete-btn').dataset.index;
                    const rowData = currentPageData[rowIndex];

                    if (confirm("Вы уверены, что хотите удалить эту запись и другие связные с ней?")) {
                        let deletePayload = {};
                        let mode = '';

                        if (currentType === 'order_parts') {
                            mode = 'order_parts';
                            deletePayload = {
                                mode,
                                id_ordering: rowData.id_ordering,
                                id_part: rowData.id_part,
                                id_request: rowData.id_request
                            };
                        } else if (currentType === 'manager') {
                            mode = 'manager';
                            deletePayload = {
                                mode,
                                id_manager: rowData.id_manager
                            };
                        } else if (currentType === 'client') {
                            mode = 'client';
                            deletePayload = {
                                mode,
                                id_client: rowData.id
                            };
                        } else if (currentType === 'config') {
                            mode = 'config';
                            deletePayload = {
                                mode,
                                VIN: rowData.VIN
                            };
                        } else if (currentType === 'model') {
                            mode = 'model';
                            deletePayload = {
                                mode,
                                id_model: rowData.id_model
                            };
                        
                        } else if (currentType === 'ordering') {
                            mode = 'ordering';
                            deletePayload = {
                                mode,
                                id_ordering: rowData.id_ordering
                            };
                        
                        } else if (currentType === 'part') {
                            mode = 'part';
                            deletePayload = {
                                mode,
                                id_part: rowData.id_part
                            };
                        
                        } else if (currentType === 'request') {
                            mode = 'request';
                            deletePayload = {
                                mode,
                                id_request: rowData.id_request
                            };
                        
                        } else if (currentType === 'supplier') {
                            mode = 'supplier';
                            deletePayload = {
                                mode,
                                id_supplier: rowData.id_supplier
                            };




                        } else {
                            alert("Удаление этой сущности не реализовано.");
                            return;
                        }

                        fetch('/delete-row/order_parts_cascade', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(deletePayload)
                        })
                        .then(res => res.json())
                        .then(res => {
                            if (res.success) {
                                alert("Удаление прошло успешно");
                                loadTable(currentType, currentHeaders, currentSearchKeys, currentFormatter);
                            } else {
                                alert("Ошибка при удалении");
                            }
                        })
                        .catch(err => {
                            console.error("Ошибка при удалении:", err);
                            alert("Ошибка при удалении");
                        });
                    }
                }


            });
            document.getElementById('NameTable').textContent = tableTitles[type.toUpperCase()] || "Name table";

            setupSearch(); 

        })
        .catch(error => console.error(`Error loading ${type}:`, error));
}


// По



const tableConfigs = {
    CLIENT: {
        type: 'client',
        headers: ['SNP', 'Number', 'Passport'],
        keys: ['SNP', 'Number', 'Passport', 'id', 'login_client', 'password_client'],
        formatter: r => `
            <td>${r.SNP}</td>
            <td>${r.Number}</td>
            <td>${r.Passport}</td>
        `
    },
    CONFIG: {
        type: 'config',
        headers: ['VIN', 'Configuration', 'Model'],
        keys: ['VIN', 'name_con', 'model_name'],
        formatter: r => `
            <td>${r.VIN}</td>
            <td>${r.name_con}</td>
            <td>${r.model_name}</td>
        `
    },
    MANAGER: {
        type: 'manager',
        headers: ['Manager', 'Start Date'],
        keys: ['snp_manager', 'start_date', 'login_manager', 'password_manager', 'id_manager'],
        formatter: r => `
            <td>${r.snp_manager}</td>
            <td>${formatDate(r.start_date)}</td>
        `
    },
    MODEL: {
        type: 'model',
        headers: ['Model', 'Start Year', 'End Year', 'Body No'],
        keys: ['id_model','name_model', 'yearstart_model', 'yearend_model', 'bodyno_model'],
        formatter: r => `
            <td>${r.name_model}</td>
            <td>${r.yearstart_model}</td>
            <td>${r.yearend_model}</td>
            <td>${r.bodyno_model}</td>
        `
    },
    ORDERING: {
        type: 'ordering',
        headers: ['Manager', 'Client', 'Order Date', 'Pay Date', 'Status'],
        keys: ['id_ordering', 'id_manager', 'id_client', 'date_ordering', 'date_pay_ordering', 'status_ordering'],
        formatter: r => `
            <td>${r.snp_manager || '— не назначен —'}</td>
            <td>${r.snp_client}</td>
            <td>${formatDate(r.date_ordering)}</td>
            <td>${paydates[r.date_pay_ordering] || formatDate(r.date_pay_ordering)}</td>
            <td>${orderStatuses[r.status_ordering] || r.status_ordering}</td>
        `
    },
    ORDERPARTS: {
        type: 'order_parts',
        headers: ['Part', 'Quantity parts', 'Color', 'Supplier', 'Client', 'Manager'],
        keys: ['id_part', 'quantity_parts', 'id_ordering', 'id_request'], 
        formatter: r => `
            <td>${r.name_part}</td>
            <td>${r.quantity_parts}</td>
            <td>${r.color_part}</td>
            <td>${r.name_supplier}</td>
            <td>${r.snp_client}</td>
            <td>${r.snp_manager}</td>
        `
    },
    PART: {
        type: 'part',
        headers: ['Part Name', 'Color', 'Type', 'Cost'],
        keys: ['id_part', 'name_part', 'color_part', 'type_part', 'cost_part'],
        formatter: r => `
            <td>${r.name_part}</td>
            <td>${r.color_part}</td>
            <td>${partsNames[r.type_part] || r.type_part}</td>
            <td>${r.cost_part}</td>
        `
    },
    RELATE: {
        type: 'relate',
        headers: ['VIN', 'Name', 'Color'],
        keys: ['vin', 'name_part', 'color_part'],
        formatter: r => `
            <td>${r.vin}</td>
            <td>${r.name_part}</td>
            <td>${r.color_part}</td>
        `
    },
    REQUEST: {
        type: 'request',
        headers: [ 'Supplier', 'Manager', 'Date', 'Status', 'Cost', 'Action type'],
        keys: [ 'id_request', 'id_supplier', 'mid_manager', 'data_registration', 'status_request', 'cost_request', 'action_type', 'data_action'],
        formatter: r => `
            <td>${r.name_supplier}</td>
            <td>${r.snp_manager || '— не назначен —'}</td>
            <td>${formatDate(r.data_registration)}</td>
            <td>${requestStatuses[r.status_request] || r.status_request}</td>
            <td>${r.cost_request}</td>
            <td>${requestTypes[r.action_type] || r.action_type}</td>
        `
    },
    SUPPLIER: {
        type: 'supplier',
        headers: ['Name'],
        keys: ['name_supplier', 'id_supplier'],
        formatter: r => `
            <td>${r.name_supplier}</td>
        `
    }
};

function loadStatistics() {
    fetch('/get-statistics')
        .then(res => res.json())
        .then(data => {
            const statsDivs = document.querySelectorAll('.main_statistics .statistics');
            const statKeys = ['total_clients', 'total_orders', 'total_parts', 'total_suppliers'];
            const statNames = ['Clients', 'Orders', 'Parts', 'Suppliers'];

            statsDivs.forEach((div, index) => {
                const nameP = div.querySelector('.name_statistics');
                const valueP = div.querySelector('.res_statistics b');
                const key = statKeys[index];
                if (data[key] !== undefined) {
                    nameP.textContent = statNames[index];
                    valueP.textContent = data[key];
                    valueP.style.filter = "none"; 
                } else {
                    valueP.style.filter = "blur(3px)";
                }
            });
        })
        .catch(err => {
            console.error('Failed to load statistics:', err);
        });
}

function logout() {
        window.location.href = "/logout";
    }

window.addEventListener("DOMContentLoaded", () => {
    // Получаем имя пользователя (пробуем разные ключи)
    const name = localStorage.getItem("userName") || localStorage.getItem("clientName");

    // Получаем роль и тип пользователя
    const role = localStorage.getItem("userRole");
    const clientRole = localStorage.getItem("userType");

    // Отображаем имя, если есть элемент и имя
    const nameDisplay = document.getElementById("userNameDisplay");
    if (nameDisplay && name) {
        nameDisplay.textContent = name;
    }

    if (role) {
        const roleMap = {
            client: "Client",
            manager: "Manager",
            admin: "Admin"
        };

        const roleDisplay = document.getElementById("userRoleDisplay");
        if (roleDisplay) {
            roleDisplay.textContent = roleMap[role] || role;
        }

        // Скрываем кнопку REPORT для всех, кроме админа
        const reportBtn = document.getElementById('REPORT');
        if (reportBtn && role !== 'admin') {
            reportBtn.style.display = 'none';
        }
    }

    // Кнопки переключения таблиц
    const tableButtons = document.querySelectorAll(".switch_table");

    if (clientRole === "client") {
        tableButtons.forEach(btn => {
            if (btn.id !== 'CREATE_ORDER' && btn.id !== 'MY_ORDERS') {
                btn.style.display = "none";
            }
        });
    }

    if (clientRole !== "client") {
        const myOrdersBtn = document.getElementById("MY_ORDERS");
        if (myOrdersBtn) myOrdersBtn.style.display = "none";
    }

    // Для менеджера скрываем кнопки редактирования и удаления
    if (role === "manager") {
        const observer = new MutationObserver(() => {
            document.querySelectorAll(".edit-btn, .delete-btn").forEach(btn => {
                btn.style.display = "none";
            });
        });

        observer.observe(document.body, { childList: true, subtree: true });
    }
});


loadStatistics();

document.getElementById('MY_ORDERS').addEventListener('click', async () => {
    restoreDefaultView(); 

    try {
        const res = await fetch('/get-my-orders');
        const data = await res.json();

        if (!Array.isArray(data)) {
            alert("Ошибка при загрузке заказов");
            return;
        }

        currentType = 'my_orders';
        currentHeaders = ['Товар', 'Поставщик', 'Количество', 'Цена', 'Статус', 'Дата заказа', 'Оплата'];
        currentFormatter = r => `
        <td>${r.name_part}</td>
        <td>${r.name_supplier}</td>
        <td>${r.quantity_parts}</td>
        <td>${r.cost_part * r.quantity_parts} ₽</td>
        <td>${orderStatuses[r.status_ordering]}</td>
        <td>${formatDate(r.date_ordering)}</td>
        <td>${r.date_pay_ordering ? formatDate(r.date_pay_ordering) : 'Ожидает оплаты'}</td>
        <td>
            ${r.status_ordering != 7 ? `<button class="cancel-order-btn" data-id="${r.id_ordering}">Отменить</button>` : ''}
        </td>
    `;



        originalData = data;
        fullData = [...data];
        currentPage = 1;

        renderTable(currentHeaders, paginateData(fullData), currentFormatter);
        setTimeout(() => {
            document.querySelectorAll('.cancel-order-btn').forEach(btn => {
                btn.addEventListener('click', () => {
                    const id = btn.dataset.id;
                    if (!confirm("Вы уверены, что хотите отменить заказ?")) return;

                    fetch('/cancel-order', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ id_ordering: id })
                    })
                    .then(res => res.json())
                    .then(res => {
                        if (res.success) {
                            alert("Заказ отменён");
                            document.getElementById('MY_ORDERS').click(); // перезагрузка заказов
                        } else {
                            alert("Ошибка при отмене");
                        }
                    })
                    .catch(err => {
                        console.error("Ошибка запроса:", err);
                        alert("Серверная ошибка");
                    });
                });
            });
        }, 200); // дожидаемся рендера DOM

        document.getElementById('NameTable').textContent = 'My Orders';

    } catch (err) {
        console.error("Ошибка при загрузке заказов:", err);
        alert("Ошибка при загрузке заказов");
    }
});





async function renderOrderCreationArea() {
    document.getElementById('sortContainer').style.display = 'none';
    document.getElementById('NameTable').textContent = 'Making an order';

    const tableArea = document.querySelector('.dis_tab');
    const stats = document.getElementById('statistics');
    const pagination = document.getElementById('paginationControls');
    const formArea = document.getElementById('orderCreationArea');

    tableArea.style.display = 'none';
    stats.style.display = 'none';
    pagination.style.display = 'none';

    formArea.style.display = 'block';
    formArea.innerHTML = `<div id="partsGrid" style="display: flex; flex-wrap: wrap; gap: 20px; justify-content: flex-start;"></div>`;

    const role = localStorage.getItem("userType");

    let selectedClientId = null;

    if (role === "manager" || role === "admin") {
        const clientSelectArea = document.createElement('div');
        clientSelectArea.style.marginBottom = '20px';

        const input = document.createElement('input');
        input.type = 'text';
        input.placeholder = 'Введите номер телефона клиента';
        input.style.padding = '10px';
        input.style.width = '300px';
        input.style.border = '1px solid #ccc';
        input.style.borderRadius = '6px';
        input.style.marginBottom = '10px';
        input.style.display = 'block';

        const resultBox = document.createElement('div');
        resultBox.style.border = '1px solid #ccc';
        resultBox.style.borderRadius = '6px';
        resultBox.style.maxHeight = '150px';
        resultBox.style.overflowY = 'auto';
        resultBox.style.width = '300px';
        resultBox.style.backgroundColor = '#fff';
        resultBox.style.display = 'none';
        resultBox.style.position = 'absolute';
        resultBox.style.zIndex = '10';

        input.addEventListener('input', async () => {
            const term = input.value.trim();
            if (term.length < 4) {
                resultBox.style.display = 'none';
                return;
            }

            const res = await fetch('/get-data/client');
            const clients = await res.json();

            const filtered = clients.filter(c => c.Number.includes(term));

            resultBox.innerHTML = '';
            if (filtered.length) {
                filtered.forEach(client => {
                    const option = document.createElement('div');
                    option.textContent = `${client.Number} — ${client.SNP} (ID: ${client.id})`;
                    option.style.padding = '6px 10px';
                    option.style.cursor = 'pointer';
                    option.addEventListener('click', () => {
                        input.value = `${client.Number} — ${client.SNP}`;
                        selectedClientId = client.id;
                        resultBox.style.display = 'none';
                    });
                    resultBox.appendChild(option);
                });
                resultBox.style.display = 'block';
            } else {
                resultBox.innerHTML = '<div style="padding: 6px 10px;">Ничего не найдено</div>';
                resultBox.style.display = 'block';
            }
        });

        const inputContainer = document.createElement('div');
        inputContainer.style.position = 'relative';
        inputContainer.appendChild(input);
        inputContainer.appendChild(resultBox);

        const label = document.createElement('label');
        label.textContent = 'Выберите клиента:';
        label.style.display = 'block';
        label.style.marginBottom = '5px';

        clientSelectArea.appendChild(label);
        clientSelectArea.appendChild(inputContainer);
        formArea.prepend(clientSelectArea);
    }

    try {
        const res = await fetch('/get-data/part');
        if (!res.ok) throw new Error("Ошибка загрузки");

        parts = await res.json();
        partsGrid = document.getElementById('partsGrid');
        selection = [];

        renderPartsList(parts);
        document.getElementById('recordCount').textContent = `Results quantity: ${parts.length}`;

        const actions = document.createElement('div');
        actions.style.marginTop = '20px';

        const submitBtn = document.createElement('button');
        submitBtn.textContent = 'Оформить заказ';
        submitBtn.style.marginRight = '10px';
        submitBtn.style.padding = '10px 20px';
        submitBtn.style.backgroundColor = '#2264E5';
        submitBtn.style.color = '#fff';
        submitBtn.style.border = 'none';
        submitBtn.style.borderRadius = '8px';
        submitBtn.style.cursor = 'pointer';
        submitBtn.style.fontWeight = 'bold';
        submitBtn.style.fontSize = '14px';
        submitBtn.style.transition = '0.3s';

        submitBtn.onmouseenter = () => submitBtn.style.backgroundColor = '#1b4fc3';
        submitBtn.onmouseleave = () => submitBtn.style.backgroundColor = '#2264E5';


        const cancelBtn = document.createElement('button');
        cancelBtn.textContent = 'Отмена';
        cancelBtn.style.padding = '10px 20px';
        cancelBtn.style.backgroundColor = '#E2E6FF';
        cancelBtn.style.color = '#333';
        cancelBtn.style.border = '1px solid #bbb';
        cancelBtn.style.borderRadius = '8px';
        cancelBtn.style.cursor = 'pointer';
        cancelBtn.style.fontWeight = 'bold';
        cancelBtn.style.fontSize = '14px';
        cancelBtn.style.transition = '0.3s';

cancelBtn.onmouseenter = () => cancelBtn.style.backgroundColor = '#d2d6f5';
cancelBtn.onmouseleave = () => cancelBtn.style.backgroundColor = '#E2E6FF';


        submitBtn.addEventListener('click', async () => {
            const selected = selection.filter(s => s.quantityInput.value > 0);
            if (!selected.length) {
                alert("Выберите хотя бы один товар с количеством");
                return;
            }

            const items = selected.map(s => ({
                id_part: s.id_part,
                quantity: parseInt(s.quantityInput.value)
            }));

            let payload = { items };

            if (role === "manager" || role === "admin") {
                if (!selectedClientId) {
                    alert("Выберите клиента из списка перед оформлением заказа.");
                    return;
                }
                payload.id_client = selectedClientId;
            }

            try {
                const res = await fetch('/create-order', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });

                const result = await res.json();
                if (result.success) {
                    alert(`Заказ успешно создан!\nID заявки: ${result.id_request}\nID заказа: ${result.id_ordering}`);
                    restoreDefaultView();
                } else {
                    alert("Ошибка: " + result.error);
                }
            } catch (err) {
                console.error("Ошибка при оформлении заказа:", err);
                alert("Ошибка при отправке запроса");
            }
        });

        cancelBtn.addEventListener('click', restoreDefaultView);

        actions.appendChild(submitBtn);
        actions.appendChild(cancelBtn);
        formArea.appendChild(actions);

        renderPartsPagination();
    } catch (err) {
        console.error("Ошибка загрузки деталей:", err);
        alert("Ошибка при получении данных");
    }
}


function renderPartsPagination() {
    const paginationDiv = document.getElementById('paginationControls');
    paginationDiv.innerHTML = '';
    paginationDiv.style.display = 'flex';
    paginationDiv.style.justifyContent = 'center';
    paginationDiv.style.marginTop = '20px';

    const totalPages = Math.ceil(parts.length / itemsPerPage);

    const prevBtn = document.createElement('button');
    prevBtn.textContent = '← Назад';
    prevBtn.disabled = currentPage === 1;
    prevBtn.style.marginRight = '10px';
    prevBtn.addEventListener('click', () => {
        if (currentPage > 1) {
            currentPage--;
            renderPartsList(parts);         
            renderPartsPagination();        
        }
    });

    const nextBtn = document.createElement('button');
    nextBtn.textContent = 'Вперёд →';
    nextBtn.disabled = currentPage === totalPages;
    nextBtn.addEventListener('click', () => {
        if (currentPage < totalPages) {
            currentPage++;
            renderPartsList(parts);         
            renderPartsPagination();        
        }
    });

    const pageLabel = document.createElement('span');
    pageLabel.textContent = `Страница ${currentPage} из ${totalPages}`;
    pageLabel.style.margin = '0 10px';

    paginationDiv.appendChild(prevBtn);
    paginationDiv.appendChild(pageLabel);
    paginationDiv.appendChild(nextBtn);
}


function addDynamicAddButton(type) {
    const oldBtn = document.getElementById('AddDynamicRow');
    if (oldBtn) oldBtn.remove();

    const role = localStorage.getItem("userRole");
    if (role !== "admin") return;

    const supportedTables = {
        supplier: [
            { name: 'name_supplier', label: 'Name' },
            { name: 'login_supplier', label: 'Login' },
            { name: 'password_supplier', label: 'Password' }
        ],
        manager: [
            { name: 'snp_manager', label: 'Full Name' },
            { name: 'start_date', label: 'Start Date' },
            { name: 'login_manager', label: 'Login' },
            { name: 'password_manager', label: 'Password' },
            { name: 'role', label: 'Role' }
        ],
        client: [
            { name: 'SNP', label: 'Full Name' },
            { name: 'Number', label: 'Phone Number' },
            { name: 'Passport', label: 'Passport' },
            { name: 'login_client', label: 'Login' },
            { name: 'password_client', label: 'Password' }
        ],
        model: [
            { name: 'name_model', label: 'Model Name' },
            { name: 'yearstart_model', label: 'Start Year' },
            { name: 'yearend_model', label: 'End Year' },
            { name: 'bodyno_model', label: 'Body Number' }
        ],
        config: [
            { name: 'VIN', label: 'VIN' },
            { name: 'name_con', label: 'Configuration Name' },
            { name: 'id_model', label: 'Model' }
        ],
        part: [
            { name: 'name_part', label: 'Part Name' },
            { name: 'color_part', label: 'Color' },
            { name: 'type_part', label: 'Type (ID)' },
            { name: 'cost_part', label: 'Cost' }
        ],
        relate: [
            { name: 'vin', label: 'VIN' },
            { name: 'id_part', label: 'Part' }
        ]
    };

    if (!(type in supportedTables)) return;

    const tableWrapper = document.querySelector('.dis_tab');
    const btn = document.createElement('button');
    btn.id = 'AddDynamicRow';
    btn.className = 'database_entry';
    btn.textContent = 'Add ' + type.charAt(0).toUpperCase() + type.slice(1);
    btn.style.margin = '10px 0 10px 3.8%';
    btn.style.height = '30px';

    btn.addEventListener('click', () => {
        openAddEntityModal(type, supportedTables[type]);
    });

    tableWrapper.parentNode.insertBefore(btn, tableWrapper);
}


async function openAddEntityModal(entityType, fields) {
    const modal = document.getElementById('outMain');
    const form = modal.querySelector('.form_display');
    form.innerHTML = '';

    const lookupFields = {
        id_model: {
            url: '/get-data/model',
            value: 'id_model',
            customLabel: item => `${item.id_model} (${item.name_model})`
        },
        id_part: {
            url: '/get-data/part',
            value: 'id_part',
            customLabel: item => `${item.id_part} (${item.name_part})`
        }
    };

    for (const { name, label } of fields) {
        let input;

        if (lookupFields[name]) {
            // select через API
            input = document.createElement('select');
            input.name = name;

            try {
                const res = await fetch(lookupFields[name].url);
                const data = await res.json();

                const defaultOption = document.createElement('option');
                defaultOption.textContent = '-- select --';
                defaultOption.value = '';
                input.appendChild(defaultOption);

                data.forEach(item => {
                    const option = document.createElement('option');
                    option.value = item[lookupFields[name].value];
                    option.textContent = lookupFields[name].customLabel(item);
                    input.appendChild(option);
                });
            } catch (err) {
                console.error('Lookup fetch error:', err);
            }

        } else if (name === 'type_part') {
            // select для partsNames
            input = document.createElement('select');
            input.name = 'type_part';

            const defaultOption = document.createElement('option');
            defaultOption.textContent = '-- select part type --';
            defaultOption.value = '';
            input.appendChild(defaultOption);

            for (const [id, nameText] of Object.entries(partsNames)) {
                const option = document.createElement('option');
                option.value = id;
                option.textContent = nameText;
                input.appendChild(option);
            }
        
        } else if (name === 'role') {
            // select для роли
            input = document.createElement('select');
            input.name = 'role';

            const defaultOption = document.createElement('option');
            defaultOption.textContent = '-- select role --';
            defaultOption.value = '';
            input.appendChild(defaultOption);

            ['admin', 'manager'].forEach(role => {
                const option = document.createElement('option');
                option.value = role;
                option.textContent = role.charAt(0).toUpperCase() + role.slice(1);
                input.appendChild(option);
            });

        } else {
            input = document.createElement('input');
            input.name = name;
            input.placeholder = label;
            input.type = name.toLowerCase().includes('password') ? 'password' : 'text';

            // маски
            if (name === 'VIN') {
                Inputmask("VIN99999999999999").mask(input);
            } else if (name === 'yearstart_model' || name === 'yearend_model') {
                Inputmask("9999").mask(input);
            } else if (name === 'bodyno_model') {
                Inputmask({ regex: "[A-Z]{3}[0-9]{6}", placeholder: "PQR456789" }).mask(input);
            } else if (name === 'cost_part') {
                Inputmask({ regex: "^[1-9][0-9]*$", placeholder: "1000" }).mask(input);
            } else if (name === 'Number') {
               Inputmask("89999999999").mask(input);
            } else if (name === 'Passport') {
                Inputmask("9999 999999").mask(input);
            } else if (name === 'start_date') {
                Inputmask("9999-99-99", {
                    placeholder: "yyyy-mm-dd"
                }).mask(input);
            }
        }


        const fieldLabel = document.createElement('label');
        fieldLabel.textContent = label;
        fieldLabel.style.display = 'block';
        fieldLabel.style.marginTop = '10px';

        input.style.marginBottom = '10px';
        input.style.width = '100%';

        form.appendChild(fieldLabel);
        form.appendChild(input);
    }

    const saveBtn = document.createElement('button');
    saveBtn.textContent = `Add ${entityType}`;
    saveBtn.type = 'button';
    saveBtn.style.marginTop = '20px';

    saveBtn.addEventListener('click', async () => {
        const payload = {};
        form.querySelectorAll('input, select').forEach(input => {
            payload[input.name] = input.value.trim();
        });

        if (entityType === 'model') {
            const start = parseInt(payload['yearstart_model'], 10);
            const end = parseInt(payload['yearend_model'], 10);
            if (isNaN(start) || isNaN(end)) {
                alert("Введите корректные годы (4 цифры)");
                return;
            }
            if (end < start) {
                alert("Год окончания не может быть меньше года начала");
                return;
            }
        }

        const response = await fetch(`/add-row/${entityType}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const result = await response.json();
        if (result.success) {
            alert(`${entityType} added successfully`);
            modal.style.display = 'none';
            loadTable(entityType, currentHeaders, currentSearchKeys, currentFormatter);
        } else {
            alert(result.error || 'Error occurred');
        }
    });


    form.appendChild(saveBtn);
    modal.style.display = 'block';
}



document.addEventListener("DOMContentLoaded", () => {
    const reportModal = document.getElementById("reportModal");
    const closeReportModal = document.getElementById("closeReportModal");
    const reportTypeSelect = document.getElementById("reportType");
    const reportResult = document.getElementById("reportResult");
    const downloadBtn = document.getElementById("downloadPDF");
    const downloadWrapper = document.getElementById("downloadPDFWrapper");

    const reportBtn = document.getElementById("REPORT");
    if (reportBtn) {
        reportBtn.addEventListener("click", () => {
            console.log("Нажата кнопка Report"); // <- проверь, появляется ли
            reportModal.style.display = "block";
            reportResult.innerHTML = '';
            downloadWrapper.style.display = "none";
            reportTypeSelect.value = '';
        });
    }

    closeReportModal.addEventListener("click", () => {
        reportModal.style.display = "none";
    });

    reportTypeSelect.addEventListener("change", async () => {
        const type = reportTypeSelect.value;
        if (!type) return;

        downloadBtn.dataset.type = type;
        downloadWrapper.style.display = "block";
        reportResult.innerHTML = ''; 
    });

    downloadBtn.addEventListener("click", () => {
        const type = downloadBtn.dataset.type;
        if (!type) return;

        window.open(`/get-report-pdf?type=${type}`, "_blank");
    });
});




document.getElementById('CLIENT_ORDERS_MANAGER').addEventListener('click', async () => {
    restoreDefaultView();
    try {
        const res = await fetch('/get-data/client');
        const clients = await res.json();

        if (!Array.isArray(clients)) {
            alert("Не удалось загрузить клиентов.");
            return;
        }

        renderClientSelection(clients);
    } catch (err) {
        console.error("Ошибка загрузки клиентов:", err);
        alert("Ошибка сервера");
    }
});

function renderClientSelection(clients) {
    restoreDefaultView();

    const area = document.getElementById('orderCreationArea');
    area.style.display = 'block';
    area.innerHTML = '';

    const title = document.createElement('h2');
    title.textContent = "Выберите клиента для просмотра заказов";
    area.appendChild(title);

    const searchInput = document.createElement('input');
    searchInput.type = 'search';
    searchInput.placeholder = 'Поиск по номеру телефона...';
    searchInput.className = 'client-search-input';
    area.appendChild(searchInput);


    const list = document.createElement('div');
    area.appendChild(list);

    function renderClients(filtered) {
        list.innerHTML = '';
        filtered.forEach(client => {
            const div = document.createElement('div');
            div.textContent = `${client.SNP} — ${client.Number}`;
            div.style.padding = '8px';
            div.style.borderBottom = '1px solid #ccc';
            div.style.cursor = 'pointer';
            div.addEventListener('click', () => {
                fetchClientOrders(client.Number);
            });
            list.appendChild(div);
        });
    }

    searchInput.addEventListener('input', () => {
        const val = searchInput.value.toLowerCase();
        const filtered = clients.filter(c => c.Number.includes(val));
        renderClients(filtered);
    });

    renderClients(clients);
}

function fetchClientOrders(phone) {
    fetch(`/get-client-orders-by-phone?phone=${phone}`)
        .then(res => res.json())
        .then(data => {
            if (!Array.isArray(data)) {
                alert("Не удалось загрузить заказы клиента.");
                return;
            }

            const headers = ['Клиент', 'Телефон', 'Товар', 'Поставщик', 'Кол-во', 'Цена', 'Статус', 'Дата заказа', 'Оплата', 'Действие'];
            const formatter = r => `
                <td>${r.snp_client}</td>
                <td>${r.numberphone_client}</td>
                <td>${r.name_part}</td>
                <td>${r.name_supplier}</td>
                <td>${r.quantity_parts}</td>
                <td>${r.cost_part * r.quantity_parts} ₽</td>
                <td>${orderStatuses[r.status_ordering]}</td>
                <td>${formatDate(r.date_ordering)}</td>
                <td>${r.datepay_ordering ? formatDate(r.datepay_ordering) : 'Ожидает оплаты'}</td>
                <td>
                    ${r.status_ordering != 7 ? `<button class="cancel-order-btn" data-id="${r.id_ordering}">Отменить</button>` : ''}
                </td>
            `;


            currentType = 'client_orders_manager';
            currentHeaders = headers;
            currentFormatter = formatter;
            originalData = data;
            fullData = [...data];
            currentPage = 1;

            document.getElementById('NameTable').textContent = `Orders of client: ${data[0]?.snp_client || ''}`;
            renderTable(headers, paginateData(data), formatter);
            setTimeout(() => {
                document.querySelectorAll('.cancel-order-btn').forEach(btn => {
                    btn.addEventListener('click', () => {
                        const id = btn.dataset.id;
                        if (!confirm("Отменить этот заказ?")) return;

                        fetch('/cancel-order', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ id_ordering: id })
                        })
                        .then(res => res.json())
                        .then(res => {
                            if (res.success) {
                                alert("Заказ отменён");
                                fetchClientOrders(phone); // перезагрузим заказы
                            } else {
                                alert("Ошибка при отмене");
                            }
                        })
                        .catch(err => {
                            console.error("Ошибка при отмене:", err);
                            alert("Серверная ошибка");
                        });
                    });
                });
            }, 200);

        })
        .catch(err => {
            console.error("Ошибка загрузки заказов клиента:", err);
            alert("Ошибка сервера");
        });
}






function restoreDefaultView() {
    document.getElementById('sortContainer').style.display = 'flex';
    document.querySelector('.dis_tab').style.display = 'block';
    document.getElementById('statistics').style.display = 'flex';
    document.getElementById('paginationControls').style.display = 'block';
    document.getElementById('orderCreationArea').style.display = 'none';
}


document.getElementById('CREATE_ORDER').addEventListener('click', () => {
    renderOrderCreationArea();
});



Object.entries(tableConfigs).forEach(([id, config]) => {
    const button = document.getElementById(id);
    if (button) {
        button.addEventListener('click', () => {
            loadTable(config.type, config.headers, config.keys, config.formatter);
        });
    }
});


