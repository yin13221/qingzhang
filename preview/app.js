/* ---------- state ---------- */

const state = {
  type: 'expense',
  amount: '',
  cat: 'food',
  account: null,
  from: null,
  to: null,
  note: '',
  tags: '',
  statsMonth: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
  metric: 'expense'
};

let appliedFilter = emptyFilter();
let draftFilter = emptyFilter();
let period = defaultPeriod();
let draftPeriod = defaultPeriod();

/* ---------- home ---------- */

function renderHome() {
  const result = filterEntries(appliedFilter, periodBounds(period));
  const entries = [
    ...result.bills.map(b => ({ kind: 'bill', ts: b.ts, bill: b })),
    ...result.transfers.map(t => ({ kind: 'transfer', ts: t.ts, transfer: t }))
  ].sort((a, b) => b.ts - a.ts);

  const expense = result.bills.filter(b => b.type === 'expense').reduce((s, b) => s + b.amount, 0);
  const income = result.bills.filter(b => b.type === 'income').reduce((s, b) => s + b.amount, 0);
  const active = isFilterActive(appliedFilter);

  document.getElementById('period-label').textContent = periodLabel(period);
  document.getElementById('summary-caption').textContent = active ? '筛选支出' : periodCaption(period);
  document.getElementById('home-expense').textContent = money(expense);
  document.getElementById('home-income').textContent = money(income);
  document.getElementById('home-balance').textContent = money(income - expense);
  document.getElementById('home-count').textContent = `共 ${entries.length} 笔`;

  const badge = document.getElementById('filter-badge');
  const count = filterCount(appliedFilter);
  badge.hidden = count === 0;
  badge.textContent = count;

  const bar = document.getElementById('filter-active');
  bar.hidden = !active;
  if (active) {
    document.getElementById('filter-active-text').textContent = `筛选结果 · ${entries.length} 笔`;
  }

  renderAccounts();

  const list = document.getElementById('home-list');
  if (!entries.length) {
    list.innerHTML = active
      ? `<div class="glass empty">${icon('search')}<b>没有符合条件的账单</b><span>试试放宽筛选条件</span></div>`
      : `<div class="glass empty">${icon('inbox')}<b>还没有账单</b><span>点击右下角 + 记下第一笔</span></div>`;
    return;
  }

  const groups = new Map();
  for (const entry of entries) {
    const key = startOfDay(entry.ts);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(entry);
  }

  let html = '';
  for (const [day, items] of groups) {
    const dayExpense = items
      .filter(e => e.kind === 'bill' && e.bill.type === 'expense')
      .reduce((s, e) => s + e.bill.amount, 0);
    html += `
      <div class="day-group">
        <div class="day-head">
          <span>${dayLabel(day)}</span>
          ${dayExpense > 0 ? `<span class="day-spend">支出 ${money(dayExpense)}</span>` : '<span></span>'}
        </div>
        <div class="glass day-card">
          ${items.map(e => e.kind === 'bill' ? billRow(e.bill) : transferRow(e.transfer)).join('')}
        </div>
      </div>`;
  }
  list.innerHTML = html;
}

function billRow(bill) {
  const cat = categoryOf(bill.type, bill.cat);
  const acc = accountOf(bill.account);
  const tags = (bill.tags || []).map(t => '#' + t).join(' ');
  const note = [bill.note, tags].filter(Boolean).join(' · ');
  return `
    <div class="row">
      <div class="icon-tile" style="background:${rgba(cat.color, 0.15)};color:${cat.color}">${icon(cat.icon)}</div>
      <div class="row-main">
        <span class="row-name">${cat.name}</span>
        ${note ? `<span class="row-note">${escapeHtml(note)}</span>` : ''}
      </div>
      <div class="row-right">
        <span class="row-amount ${bill.type === 'income' ? 'income' : ''}">${bill.type === 'income' ? '+' : '-'}${money(bill.amount)}</span>
        <span class="row-acc">${escapeHtml(acc.name)}</span>
      </div>
    </div>`;
}

function transferRow(transfer) {
  const from = accountOf(transfer.from);
  const to = accountOf(transfer.to);
  const note = [from.name + ' → ' + to.name, transfer.note].filter(Boolean).join(' · ');
  return `
    <div class="row">
      <div class="icon-tile" style="background:rgba(140,152,173,.15);color:#8C98AD">${icon('arrows')}</div>
      <div class="row-main">
        <span class="row-name">转账</span>
        <span class="row-note">${escapeHtml(note)}</span>
      </div>
      <div class="row-right">
        <span class="row-amount neutral">${money(transfer.amount)}</span>
        <span class="row-acc">账户转账</span>
      </div>
    </div>`;
}

function renderAccounts() {
  const strip = document.getElementById('account-strip');
  strip.innerHTML = db.accounts
    .slice()
    .sort((a, b) => a.order - b.order)
    .map(acc => {
      const kind = accountKind(acc);
      const balance = accountBalance(acc.id);
      return `
        <div class="acc-card glass">
          <span class="acc-icon" style="background:${rgba(kind.color, 0.16)};color:${kind.color}">${icon(kind.icon)}</span>
          <span class="acc-info">
            <span class="acc-name">${escapeHtml(acc.name)}</span>
            <span class="acc-balance ${balance < 0 ? 'neg' : ''}">${money(balance)}</span>
          </span>
        </div>`;
    }).join('') + `
      <button class="acc-card glass add" id="add-account-card">
        <span class="acc-icon add-icon">${icon('plus')}</span>
        <span class="acc-info"><span class="acc-name">添加账户</span><span class="acc-balance sub">现金 / 银行卡 / 信用卡</span></span>
      </button>`;

  document.getElementById('add-account-card').addEventListener('click', openAccountSheet);
  document.getElementById('net-assets').textContent = '净资产 ' + money(netAssets());
}

/* ---------- stats ---------- */

function renderStats() {
  const m = state.statsMonth;
  const now = new Date();
  const isCurrent = m.getFullYear() === now.getFullYear() && m.getMonth() === now.getMonth();

  document.getElementById('stats-month').textContent = monthLabel(m);
  document.getElementById('next-month').disabled = isCurrent;

  const monthBills = db.bills.filter(b => {
    const d = new Date(b.ts);
    return d.getFullYear() === m.getFullYear() && d.getMonth() === m.getMonth();
  });

  const expense = monthBills.filter(b => b.type === 'expense').reduce((s, b) => s + b.amount, 0);
  const income = monthBills.filter(b => b.type === 'income').reduce((s, b) => s + b.amount, 0);
  document.getElementById('stats-summary').innerHTML =
    `支出 <b>${money(expense)}</b><span class="dot-sep"></span>收入 <b class="mint">${money(income)}</b>`;

  document.querySelectorAll('#stats-metric .mini').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.metric === state.metric);
  });

  const metric = state.metric;
  const total = metric === 'expense' ? expense : income;

  const totals = new Map();
  for (const b of monthBills) {
    if (b.type !== metric) continue;
    totals.set(b.cat, (totals.get(b.cat) || 0) + b.amount);
  }
  const slices = [...totals.entries()]
    .map(([id, sum]) => ({ ...categoryOf(metric, id), total: sum }))
    .sort((a, b) => b.total - a.total);

  const wrap = document.getElementById('donut-wrap');
  const legend = document.getElementById('legend');

  if (!slices.length) {
    wrap.innerHTML = `
      <div class="empty" style="padding:34px">
        ${icon('pie')}
        <b>本月暂无${metric === 'expense' ? '支出' : '收入'}</b>
        <span>记一笔后这里会出现分类占比</span>
      </div>`;
    legend.innerHTML = '';
  } else {
    const r = 74;
    const circumference = 2 * Math.PI * r;
    let offset = 0;
    let svg = `<svg width="190" height="190" viewBox="0 0 190 190">
      <circle cx="95" cy="95" r="${r}" fill="none" stroke="rgba(255,255,255,.55)" stroke-width="24"/>`;
    for (const slice of slices) {
      const fraction = slice.total / total;
      const len = Math.max(fraction * circumference - 4, 1.5);
      svg += `<circle cx="95" cy="95" r="${r}" fill="none" stroke="${slice.color}" stroke-width="24"
        stroke-linecap="round" stroke-dasharray="${len} ${circumference - len}"
        stroke-dashoffset="${-offset}" transform="rotate(-90 95 95)"/>`;
      offset += fraction * circumference;
    }
    svg += '</svg>';

    wrap.innerHTML = `${svg}
      <div class="donut-center">
        <span class="lbl">总${metric === 'expense' ? '支出' : '收入'}</span>
        <span class="val">${money(total)}</span>
      </div>`;

    legend.innerHTML = slices.map(s => `
      <div class="legend-row">
        <span class="legend-dot" style="background:${s.color}"></span>
        <span class="legend-name">${s.name}</span>
        <span class="legend-type">${metric === 'expense' ? '支出' : '收入'}</span>
        <span class="legend-spacer"></span>
        <span class="legend-pct">${Math.round(s.total / total * 100)}%</span>
        <span class="legend-amt">${money(s.total)}</span>
      </div>`).join('');
  }

  renderTrend();
}

function renderTrend() {
  const months = [];
  for (let i = 5; i >= 0; i--) {
    months.push(new Date(state.statsMonth.getFullYear(), state.statsMonth.getMonth() - i, 1));
  }
  const stats = months.map(month => {
    let expense = 0;
    let income = 0;
    for (const b of db.bills) {
      const d = new Date(b.ts);
      if (d.getFullYear() !== month.getFullYear() || d.getMonth() !== month.getMonth()) continue;
      if (b.type === 'expense') expense += b.amount;
      else income += b.amount;
    }
    return { month, expense, income };
  });

  const max = Math.max(...stats.map(s => Math.max(s.expense, s.income)), 1);

  document.getElementById('trend').innerHTML = stats.map(s => {
    const expH = s.expense ? Math.max(s.expense / max * 100, 4) : 0;
    const incH = s.income ? Math.max(s.income / max * 100, 4) : 0;
    return `
      <div class="trend-col">
        <div class="bars">
          <span class="bar exp" style="height:${expH}%;${expH ? '' : 'min-height:0'}"></span>
          <span class="bar inc" style="height:${incH}%;${incH ? '' : 'min-height:0'}"></span>
        </div>
        <span class="trend-label">${s.month.getMonth() + 1}月</span>
      </div>`;
  }).join('');
}

/* ---------- add sheet ---------- */

function accountChipsHtml(selected, extra) {
  return db.accounts.map(acc => {
    const kind = accountKind(acc);
    const active = acc.id === selected;
    return `<button class="chip small ${active ? 'active' : ''}" data-acc="${acc.id}" ${extra || ''}>
      <span class="chip-dot" style="background:${kind.color}"></span>${escapeHtml(acc.name)}
    </button>`;
  }).join('');
}

function renderCatGrid() {
  const cats = CATEGORIES[state.type === 'income' ? 'income' : 'expense'];
  document.getElementById('cat-grid').innerHTML = cats.map(cat => `
    <button class="cat ${cat.id === state.cat ? 'active' : ''}" data-cat="${cat.id}">
      <span class="cat-icon" style="background:${cat.id === state.cat ? cat.color : rgba(cat.color, 0.14)};color:${cat.id === state.cat ? '#fff' : cat.color};${cat.id === state.cat ? `box-shadow:0 8px 16px -8px ${rgba(cat.color, 0.8)}` : ''}">
        ${icon(cat.icon)}
      </span>
      <span class="cat-name">${cat.name}</span>
    </button>`).join('');
}

function renderAccountPickers() {
  document.getElementById('account-chips').innerHTML = accountChipsHtml(state.account);
  document.getElementById('from-chips').innerHTML = accountChipsHtml(state.from, 'data-side="from"');
  document.getElementById('to-chips').innerHTML = accountChipsHtml(state.to, 'data-side="to"');
}

function renderKeypad() {
  const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'del'];
  document.getElementById('keys').innerHTML = keys.map(k => `
    <button class="key" data-key="${k}">${k === 'del' ? icon('backspace') : k}</button>`).join('');
}

function renderAmount() {
  document.getElementById('sheet-amount').textContent = state.amount || '0';
  const valid = parseFloat(state.amount) > 0 &&
    (state.type !== 'transfer' || (state.from && state.to && state.from !== state.to));
  document.getElementById('save-btn').disabled = !valid;
}

function setAddType(type) {
  state.type = type;
  if (type !== 'transfer') {
    state.cat = CATEGORIES[type][0].id;
  }
  document.querySelectorAll('#sheet .seg').forEach(el => el.classList.toggle('active', el.dataset.type === type));
  const transfer = type === 'transfer';
  document.getElementById('sheet').classList.toggle('transfer-mode', transfer);
  document.getElementById('cat-grid').hidden = transfer;
  document.getElementById('account-pane').hidden = transfer;
  document.getElementById('transfer-pane').hidden = !transfer;
  document.getElementById('tag-row').hidden = transfer;
  renderCatGrid();
  renderAccountPickers();
  renderAmount();
}

function isoDate(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function entryTimestamp() {
  const value = document.getElementById('date-input').value;
  if (!value) return Date.now();
  const now = new Date();
  const date = new Date(value + 'T00:00:00');
  date.setHours(now.getHours(), now.getMinutes(), 0, 0);
  return date.getTime();
}

function openSheet() {
  const now = new Date();
  state.type = 'expense';
  state.amount = '';
  state.cat = CATEGORIES.expense[0].id;
  state.account = (db.accounts[0] || {}).id || null;
  state.from = (db.accounts[0] || {}).id || null;
  state.to = (db.accounts[1] || db.accounts[0] || {}).id || null;
  document.getElementById('note-input').value = '';
  document.getElementById('tag-input').value = '';
  const dateInput = document.getElementById('date-input');
  dateInput.max = isoDate(now);
  dateInput.value = isoDate(now);
  document.querySelector('#sheet .sheet-scroll').scrollTop = 0;
  setAddType('expense');
  renderAmount();
  openLayer('sheet');
}

function closeSheet() {
  closeAllSheets();
}

function pressKey(key) {
  if (key === 'del') {
    state.amount = state.amount.slice(0, -1);
  } else if (key === '.') {
    if (!state.amount.includes('.')) state.amount = (state.amount || '0') + '.';
  } else {
    if (state.amount.length >= 9) return;
    const dot = state.amount.indexOf('.');
    if (dot >= 0 && state.amount.length - dot > 2) return;
    state.amount = state.amount === '0' ? key : state.amount + key;
  }
  renderAmount();
}

function saveEntry() {
  const value = parseFloat(state.amount);
  if (!(value > 0)) return;
  const amount = Math.round(value * 100) / 100;
  const note = document.getElementById('note-input').value.trim();

  if (state.type === 'transfer') {
    if (!state.from || !state.to || state.from === state.to) {
      showToast('转出与转入账户不能相同');
      return;
    }
    db.transfers.push({
      id: uid(), from: state.from, to: state.to, amount, note, ts: entryTimestamp()
    });
    persist();
    closeSheet();
    renderHome();
    renderStats();
    showToast('转账已记录');
    return;
  }

  const tags = document.getElementById('tag-input').value
    .split(/[\s,，]+/)
    .map(t => t.replace(/^#/, '').trim())
    .filter(Boolean)
    .slice(0, 5);

  db.bills.push({
    id: uid(),
    amount,
    type: state.type,
    cat: state.cat,
    note,
    ts: entryTimestamp(),
    account: state.account,
    tags
  });
  persist();
  closeSheet();
  renderHome();
  renderStats();
  showToast('已记一笔');
}

/* ---------- filter sheet ---------- */

function renderFilterSheet() {
  const f = draftFilter;

  document.getElementById('f-keyword').value = f.keyword;
  document.getElementById('f-min').value = f.min;
  document.getElementById('f-max').value = f.max;

  const catChips = type => CATEGORIES[type].map(cat => `
    <button class="chip ${f.cats.includes(cat.id) ? 'active' : ''}" data-cat="${cat.id}">
      <span class="chip-dot" style="background:${cat.color}"></span>${cat.name}
    </button>`).join('');
  document.getElementById('f-cats-expense').innerHTML = catChips('expense');
  document.getElementById('f-cats-income').innerHTML = catChips('income');

  document.getElementById('f-accounts').innerHTML = db.accounts.map(acc => `
    <button class="chip ${f.accounts.includes(acc.id) ? 'active' : ''}" data-acc="${acc.id}">
      ${escapeHtml(acc.name)}
    </button>`).join('');

  const tags = allTags();
  document.getElementById('f-tags').innerHTML = tags.length
    ? tags.map(tag => `<button class="chip ${f.tags.includes(tag) ? 'active' : ''}" data-tag="${escapeHtml(tag)}">#${escapeHtml(tag)}</button>`).join('')
    : '<span class="chip-empty">还没有使用过标签</span>';
}

function openFilterSheet() {
  draftFilter = cloneFilter(appliedFilter);
  renderFilterSheet();
  openLayer('filter-sheet');
}

function closeFilterSheet() {
  document.getElementById('filter-sheet').classList.remove('show');
  syncScrim();
}

function applyFilter() {
  appliedFilter = cloneFilter(draftFilter);
  closeFilterSheet();
  renderHome();
}

function clearFilter() {
  appliedFilter = emptyFilter();
  renderHome();
}

function toggleIn(list, value) {
  const index = list.indexOf(value);
  if (index >= 0) list.splice(index, 1);
  else list.push(value);
}

/* ---------- period sheet ---------- */

function renderPeriodSheet() {
  document.getElementById('period-options').innerHTML = PERIOD_OPTIONS.map(option => `
    <button class="period-option ${draftPeriod.preset === option.id ? 'active' : ''}" data-period="${option.id}">
      <span>${option.label}</span>
      <span class="period-tick">${icon('check')}</span>
    </button>`).join('');
  const custom = draftPeriod.preset === 'custom';
  document.getElementById('period-custom').hidden = !custom;
  if (custom) {
    document.getElementById('p-start').value = draftPeriod.start;
    document.getElementById('p-end').value = draftPeriod.end;
  }
}

function openPeriodSheet() {
  draftPeriod = { ...period };
  renderPeriodSheet();
  openLayer('period-sheet');
}

function closePeriodSheet() {
  document.getElementById('period-sheet').classList.remove('show');
  syncScrim();
}

function applyPeriod() {
  if (draftPeriod.preset === 'custom') {
    const start = document.getElementById('p-start').value;
    const end = document.getElementById('p-end').value;
    if (start) draftPeriod.start = start;
    if (end) draftPeriod.end = end;
    if (draftPeriod.start && draftPeriod.end && draftPeriod.start > draftPeriod.end) {
      const swap = draftPeriod.start;
      draftPeriod.start = draftPeriod.end;
      draftPeriod.end = swap;
    }
  }
  period = { ...draftPeriod };
  closePeriodSheet();
  renderHome();
}

/* ---------- account sheet ---------- */

const accountDraft = { kind: 'cash' };

function renderAccountSheet() {
  document.getElementById('account-name').value = '';
  document.getElementById('account-initial').value = '';
  document.getElementById('account-kind-chips').innerHTML = Object.entries(ACCOUNT_KINDS).map(([id, kind]) => `
    <button class="chip ${accountDraft.kind === id ? 'active' : ''}" data-kind="${id}">
      <span class="chip-dot" style="background:${kind.color}"></span>${kind.title}
    </button>`).join('');
}

function openAccountSheet() {
  accountDraft.kind = 'cash';
  renderAccountSheet();
  openLayer('account-sheet');
}

function saveAccount() {
  const kind = ACCOUNT_KINDS[accountDraft.kind];
  const name = document.getElementById('account-name').value.trim() || kind.title;
  const initial = parseFloat(document.getElementById('account-initial').value) || 0;
  db.accounts.push({
    id: uid(),
    name,
    kind: accountDraft.kind,
    initial: Math.round(initial * 100) / 100,
    order: db.accounts.length
  });
  persist();
  closeAllSheets();
  renderHome();
  showToast('账户已添加');
}

/* ---------- layers ---------- */

function openLayer(id) {
  document.querySelectorAll('.sheet').forEach(s => s.classList.toggle('show', s.id === id));
  document.getElementById('scrim').classList.add('show');
}

function syncScrim() {
  const any = [...document.querySelectorAll('.sheet')].some(s => s.classList.contains('show'));
  document.getElementById('scrim').classList.toggle('show', any);
}

function closeAllSheets() {
  document.querySelectorAll('.sheet').forEach(s => s.classList.remove('show'));
  document.getElementById('scrim').classList.remove('show');
}

/* ---------- toast ---------- */

let toastTimer;
function showToast(text) {
  const el = document.getElementById('toast');
  el.textContent = text || '已记一笔';
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 1600);
}

/* ---------- salary tool ---------- */

const SALARY_KEY = 'qingzhang.salary.v4';
const TEMPLATES_KEY = 'qingzhang.salary.templates.v3';

let salary = { base: 1000, factor: 1.5, fixed: 1000, afterTaxRatio: 0.9 };
let templates = [];
let selectedTemplateId = null;

(function loadSalary() {
  try {
    const raw = localStorage.getItem(SALARY_KEY);
    if (!raw) return;
    const data = JSON.parse(raw);
    salary = {
      base: Number(data.base) || 0,
      factor: Number(data.factor) || 0,
      fixed: Number(data.fixed) || 0,
      afterTaxRatio: data.afterTaxRatio != null ? clampRatio(Number(data.afterTaxRatio)) : 0.9
    };
  } catch (e) { /* defaults */ }
})();

(function loadTemplates() {
  try {
    const raw = localStorage.getItem(TEMPLATES_KEY);
    if (raw) {
      templates = JSON.parse(raw);
      return;
    }
  } catch (e) { /* fall through to demo templates */ }
  templates = [
    { id: uid(), name: '正常月', base: 1000, factor: 1.5, fixed: 1000, afterTaxRatio: 0.9 },
    { id: uid(), name: '淡季', base: 1000, factor: 0.799, fixed: 1000, afterTaxRatio: 0.85 }
  ];
  persistTemplates();
})();

function clampRatio(value) {
  return Math.min(1, Math.max(0, value));
}

function saveSalary() {
  try { localStorage.setItem(SALARY_KEY, JSON.stringify(salary)); } catch (e) {}
}

function persistTemplates() {
  try { localStorage.setItem(TEMPLATES_KEY, JSON.stringify(templates)); } catch (e) {}
}

function trimNum(value) {
  return String(Number(Number(value).toFixed(3)));
}

function pctText(ratio) {
  const pct = Math.round(ratio * 1000) / 10;
  return (Number.isInteger(pct) ? pct.toFixed(0) : pct.toFixed(1)) + '%';
}

function updateSalaryOutputs() {
  const perf = salary.base * salary.factor;
  const gross = perf + salary.fixed;
  const net = gross * salary.afterTaxRatio;
  const tax = gross - net;
  const taxRate = 1 - salary.afterTaxRatio;

  document.getElementById('p-after-label').textContent = pctText(salary.afterTaxRatio);

  document.getElementById('salary-net').textContent = money(net);
  document.getElementById('salary-gross').textContent = money(gross);
  document.getElementById('salary-tax').textContent = money(tax);
  document.getElementById('bd-perf').textContent = money(perf);
  document.getElementById('bd-fixed').textContent = money(salary.fixed);
  document.getElementById('bd-gross').textContent = money(gross);
  document.getElementById('bd-taxrate').textContent = pctText(taxRate);
  document.getElementById('bd-net').textContent = money(net);
}

function renderTools() {
  const baseInput = document.getElementById('p-base');
  const fixedInput = document.getElementById('p-fixed');
  const factorInput = document.getElementById('p-factor');
  const ratioInput = document.getElementById('p-ratio');

  const set = (el, value) => {
    if (document.activeElement !== el && el.value !== value) el.value = value;
  };

  set(baseInput, String(salary.base));
  set(fixedInput, String(salary.fixed));
  set(factorInput, trimNum(salary.factor));
  set(ratioInput, trimNum(salary.afterTaxRatio));

  updateSalaryOutputs();
  renderTemplates();
}

function renderTemplates() {
  const strip = document.getElementById('tpl-strip');
  if (!strip) return;
  const chips = [`<button class="tpl-chip new" data-new-calc="1">${icon('plus')}新建计算</button>`];
  for (const tpl of templates) {
    const active = tpl.id === selectedTemplateId ? ' active' : '';
    chips.push(`
      <span class="tpl-chip${active}" data-apply="${tpl.id}">
        ${escapeHtml(tpl.name)}
        <button class="tpl-x" data-del="${tpl.id}" aria-label="删除模板">×</button>
      </span>`);
  }
  strip.innerHTML = chips.join('');
}

function showToolPage(pageId) {
  document.getElementById('tools-list-view').hidden = pageId !== null;
  document.getElementById('calculator-view').hidden = pageId !== 'calculator-view';
  document.getElementById('recovery-view').hidden = pageId !== 'recovery-view';
  document.getElementById('view-tools').scrollTop = 0;
  if (pageId === 'calculator-view') renderTools();
  if (pageId === 'recovery-view') renderRecovery();
}

function showToolsList() {
  showToolPage(null);
}

function newCalculation() {
  salary = { base: 1000, factor: 1, fixed: 1000, afterTaxRatio: 1 };
  selectedTemplateId = null;
  saveSalary();
  renderTools();
}

function applyTemplateById(id) {
  const tpl = templates.find(item => item.id === id);
  if (!tpl) return;
  salary = {
    base: tpl.base,
    factor: tpl.factor,
    fixed: tpl.fixed,
    afterTaxRatio: tpl.afterTaxRatio
  };
  selectedTemplateId = id;
  saveSalary();
  renderTools();
  showToast(`已套用「${tpl.name}」`);
}

function deleteTemplate(id) {
  templates = templates.filter(tpl => tpl.id !== id);
  if (selectedTemplateId === id) selectedTemplateId = null;
  persistTemplates();
  renderTemplates();
  showToast('模板已删除');
}

function openTemplateSheet() {
  document.getElementById('template-name').value = '';
  document.getElementById('template-preview').textContent =
    `${trimNum(salary.base)} × ${trimNum(salary.factor)} + ${trimNum(salary.fixed)} · 税后 ${pctText(salary.afterTaxRatio)}`;
  openLayer('template-sheet');
}

function closeTemplateSheet() {
  document.getElementById('template-sheet').classList.remove('show');
  syncScrim();
}

function saveTemplate() {
  const input = document.getElementById('template-name');
  const name = input.value.trim() || `模板 ${templates.length + 1}`;
  const template = {
    id: uid(),
    name,
    base: salary.base,
    factor: salary.factor,
    fixed: salary.fixed,
    afterTaxRatio: salary.afterTaxRatio
  };
  templates.push(template);
  selectedTemplateId = template.id;
  persistTemplates();
  renderTemplates();
  closeTemplateSheet();
  showToast('模板已保存');
}

/* ---------- loss recovery tool ---------- */

const RECOVERY_KEY = 'qingzhang.recovery.v1';
let recovery = { loss: 20 };

try {
  const raw = localStorage.getItem(RECOVERY_KEY);
  if (raw) {
    const data = JSON.parse(raw);
    recovery.loss = Math.min(99.999, Math.max(0, Number(data.loss) || 0));
  }
} catch (e) { /* defaults */ }

function saveRecovery() {
  try { localStorage.setItem(RECOVERY_KEY, JSON.stringify(recovery)); } catch (e) {}
}

function recoveryGain(loss) {
  if (loss >= 100) return null;
  return loss / (100 - loss) * 100;
}

function fmtPercent(value) {
  const rounded = Math.round(value * 100) / 100;
  if (Number.isInteger(rounded)) return rounded.toFixed(0) + '%';
  if (Math.abs(rounded * 10 - Math.round(rounded * 10)) < 1e-9) return rounded.toFixed(1) + '%';
  return rounded.toFixed(2) + '%';
}

function renderRecovery() {
  const loss = recovery.loss;
  const gain = recoveryGain(loss);
  const gainText = gain === null ? '无法回本' : fmtPercent(gain);

  document.getElementById('recovery-loss-label').textContent = fmtPercent(loss);
  document.getElementById('recovery-gain').textContent = gainText;
  document.getElementById('recovery-gain-inline').textContent = gainText;

  const input = document.getElementById('loss-input');
  if (document.activeElement !== input && input.value !== trimNum(loss)) {
    input.value = trimNum(loss);
  }

  document.getElementById('recovery-table').innerHTML = [10, 20, 30, 50, 70, 90].map(item => `
    <div class="bd-row"><span>亏损 ${item}%</span><b>需上涨 ${fmtPercent(item / (100 - item) * 100)}</b></div>`).join('');
}

/* ---------- tab glider ---------- */

function positionGlider(morph) {
  const active = document.querySelector('.tab.active');
  const glider = document.getElementById('tab-glider');
  if (!active || !glider) return;
  glider.style.left = active.offsetLeft + 'px';
  glider.style.top = active.offsetTop + 'px';
  glider.style.width = active.offsetWidth + 'px';
  glider.style.height = active.offsetHeight + 'px';
  if (morph) {
    glider.animate([
      { transform: 'scale(1, 1)' },
      { transform: 'scale(1.1, 0.84)', offset: 0.3 },
      { transform: 'scale(0.96, 1.05)', offset: 0.68 },
      { transform: 'scale(1, 1)' }
    ], { duration: 480, easing: 'cubic-bezier(.34,1.4,.64,1)' });
  }
}

/* ---------- events ---------- */

document.querySelectorAll('.tab').forEach(btn => {
  btn.addEventListener('click', () => {
    const target = btn.dataset.tab;
    if (btn.classList.contains('active')) return;
    document.querySelectorAll('.tab').forEach(b => b.classList.toggle('active', b === btn));
    document.querySelectorAll('.page').forEach(p => p.classList.toggle('active', p.id === 'view-' + target));
    positionGlider(true);
    document.getElementById('fab').hidden = target === 'tools';
    if (target === 'stats') renderStats();
    if (target === 'home') renderHome();
    if (target === 'tools') {
      showToolsList();
      renderTools();
    }
    try { history.replaceState(null, '', '#' + target); } catch (e) {}
  });
});

document.getElementById('fab').addEventListener('click', openSheet);
document.getElementById('scrim').addEventListener('click', closeAllSheets);
document.getElementById('filter-close').addEventListener('click', closeFilterSheet);
document.getElementById('account-close').addEventListener('click', closeAllSheets);
document.getElementById('open-filter').addEventListener('click', openFilterSheet);
document.getElementById('clear-filter').addEventListener('click', clearFilter);
document.getElementById('open-period').addEventListener('click', openPeriodSheet);
document.getElementById('period-close').addEventListener('click', closePeriodSheet);
document.getElementById('period-reset').addEventListener('click', () => {
  draftPeriod = defaultPeriod();
  renderPeriodSheet();
});
document.getElementById('period-apply').addEventListener('click', applyPeriod);
document.getElementById('period-options').addEventListener('click', e => {
  const btn = e.target.closest('[data-period]');
  if (!btn) return;
  draftPeriod.preset = btn.dataset.period;
  if (draftPeriod.preset === 'custom') {
    if (!draftPeriod.start) {
      const d = new Date();
      d.setMonth(d.getMonth() - 1);
      draftPeriod.start = isoDay(d);
    }
    if (!draftPeriod.end) draftPeriod.end = isoDay(new Date());
  }
  renderPeriodSheet();
});
document.getElementById('p-start').addEventListener('change', e => {
  draftPeriod.start = e.target.value;
});
document.getElementById('p-end').addEventListener('change', e => {
  draftPeriod.end = e.target.value;
});

document.querySelectorAll('#sheet .seg').forEach(btn => {
  btn.addEventListener('click', () => setAddType(btn.dataset.type));
});

document.getElementById('cat-grid').addEventListener('click', e => {
  const btn = e.target.closest('.cat');
  if (!btn) return;
  state.cat = btn.dataset.cat;
  renderCatGrid();
});

document.getElementById('account-chips').addEventListener('click', e => {
  const chip = e.target.closest('.chip');
  if (!chip) return;
  state.account = chip.dataset.acc;
  renderAccountPickers();
});

document.getElementById('from-chips').addEventListener('click', e => {
  const chip = e.target.closest('.chip');
  if (!chip) return;
  state.from = chip.dataset.acc;
  if (state.from === state.to) {
    state.to = db.accounts.find(a => a.id !== state.from)?.id || state.to;
  }
  renderAccountPickers();
  renderAmount();
});

document.getElementById('to-chips').addEventListener('click', e => {
  const chip = e.target.closest('.chip');
  if (!chip) return;
  state.to = chip.dataset.acc;
  if (state.to === state.from) {
    state.from = db.accounts.find(a => a.id !== state.to)?.id || state.from;
  }
  renderAccountPickers();
  renderAmount();
});

document.getElementById('keys').addEventListener('click', e => {
  const btn = e.target.closest('.key');
  if (!btn) return;
  pressKey(btn.dataset.key);
});

document.getElementById('save-btn').addEventListener('click', saveEntry);

document.getElementById('p-base').addEventListener('input', e => {
  salary.base = parseFloat(e.target.value) || 0;
  saveSalary();
  updateSalaryOutputs();
});

document.getElementById('p-fixed').addEventListener('input', e => {
  salary.fixed = parseFloat(e.target.value) || 0;
  saveSalary();
  updateSalaryOutputs();
});

document.getElementById('p-factor').addEventListener('input', e => {
  const value = parseFloat(e.target.value);
  salary.factor = Number.isNaN(value) ? 0 : Math.min(10, Math.max(0, value));
  saveSalary();
  updateSalaryOutputs();
});

document.getElementById('p-ratio').addEventListener('input', e => {
  const value = parseFloat(e.target.value);
  salary.afterTaxRatio = Number.isNaN(value) ? 0 : clampRatio(value);
  saveSalary();
  updateSalaryOutputs();
});

document.querySelectorAll('.num-stepper button').forEach(btn => {
  btn.addEventListener('click', () => {
    const step = parseFloat(btn.dataset.step);
    if (btn.dataset.target === 'loss') {
      recovery.loss = Math.min(99.999, Math.max(0, Math.round((recovery.loss + step) * 1000) / 1000));
      document.getElementById('loss-input').value = trimNum(recovery.loss);
      saveRecovery();
      renderRecovery();
      return;
    }
    if (btn.dataset.target === 'ratio') {
      salary.afterTaxRatio = clampRatio(Math.round((salary.afterTaxRatio + step) * 1000) / 1000);
      document.getElementById('p-ratio').value = trimNum(salary.afterTaxRatio);
    } else {
      salary.factor = Math.min(10, Math.max(0, Math.round((salary.factor + step) * 1000) / 1000));
      document.getElementById('p-factor').value = trimNum(salary.factor);
    }
    saveSalary();
    updateSalaryOutputs();
  });
});

document.getElementById('open-calculator').addEventListener('click', () => showToolPage('calculator-view'));
document.getElementById('calc-back').addEventListener('click', showToolsList);
document.getElementById('open-recovery').addEventListener('click', () => showToolPage('recovery-view'));
document.getElementById('recovery-back').addEventListener('click', showToolsList);

document.getElementById('loss-input').addEventListener('input', e => {
  const value = parseFloat(e.target.value);
  recovery.loss = Number.isNaN(value) ? 0 : Math.min(99.999, Math.max(0, value));
  saveRecovery();
  renderRecovery();
});
document.getElementById('calc-save-template').addEventListener('click', openTemplateSheet);
document.getElementById('template-close').addEventListener('click', closeTemplateSheet);
document.getElementById('template-cancel').addEventListener('click', closeTemplateSheet);
document.getElementById('template-save').addEventListener('click', saveTemplate);

document.getElementById('tpl-strip').addEventListener('click', e => {
  const del = e.target.closest('[data-del]');
  if (del) {
    e.stopPropagation();
    deleteTemplate(del.dataset.del);
    return;
  }
  if (e.target.closest('[data-new-calc]')) {
    newCalculation();
    return;
  }
  const apply = e.target.closest('[data-apply]');
  if (apply) applyTemplateById(apply.dataset.apply);
});

document.getElementById('note-input').addEventListener('keydown', e => {
  if (e.key === 'Enter') saveEntry();
});

document.querySelectorAll('#stats-metric .mini').forEach(btn => {
  btn.addEventListener('click', () => {
    state.metric = btn.dataset.metric;
    renderStats();
  });
});

document.getElementById('prev-month').addEventListener('click', () => {
  const m = state.statsMonth;
  state.statsMonth = new Date(m.getFullYear(), m.getMonth() - 1, 1);
  renderStats();
  swapMonthLabel();
});

document.getElementById('next-month').addEventListener('click', () => {
  const m = state.statsMonth;
  const now = new Date();
  if (m.getFullYear() === now.getFullYear() && m.getMonth() === now.getMonth()) return;
  state.statsMonth = new Date(m.getFullYear(), m.getMonth() + 1, 1);
  renderStats();
  swapMonthLabel();
});

function swapMonthLabel() {
  const el = document.getElementById('stats-month');
  el.classList.remove('swap');
  void el.offsetWidth;
  el.classList.add('swap');
}

document.getElementById('filter-sheet').addEventListener('click', e => {
  const catChip = e.target.closest('#f-cats-expense .chip, #f-cats-income .chip');
  if (catChip) {
    toggleIn(draftFilter.cats, catChip.dataset.cat);
    renderFilterSheet();
    return;
  }
  const accChip = e.target.closest('#f-accounts .chip');
  if (accChip) {
    toggleIn(draftFilter.accounts, accChip.dataset.acc);
    renderFilterSheet();
    return;
  }
  const tagChip = e.target.closest('#f-tags .chip');
  if (tagChip) {
    toggleIn(draftFilter.tags, tagChip.dataset.tag);
    renderFilterSheet();
    return;
  }
});

document.getElementById('f-keyword').addEventListener('input', e => {
  draftFilter.keyword = e.target.value;
});

document.getElementById('f-min').addEventListener('input', e => {
  draftFilter.min = e.target.value;
});

document.getElementById('f-max').addEventListener('input', e => {
  draftFilter.max = e.target.value;
});

document.getElementById('f-reset').addEventListener('click', () => {
  draftFilter = emptyFilter();
  renderFilterSheet();
});

document.getElementById('f-apply').addEventListener('click', applyFilter);

document.getElementById('account-sheet').addEventListener('click', e => {
  const chip = e.target.closest('[data-kind]');
  if (!chip) return;
  accountDraft.kind = chip.dataset.kind;
  document.getElementById('account-kind-chips').innerHTML = Object.entries(ACCOUNT_KINDS).map(([id, kind]) => `
    <button class="chip ${accountDraft.kind === id ? 'active' : ''}" data-kind="${id}">
      <span class="chip-dot" style="background:${kind.color}"></span>${kind.title}
    </button>`).join('');
});

document.getElementById('account-save').addEventListener('click', saveAccount);

document.getElementById('reset-demo').addEventListener('click', () => {
  db = seedDB();
  persist();
  state.statsMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
  appliedFilter = emptyFilter();
  renderHome();
  renderStats();
  showToast('演示数据已重置');
});

window.addEventListener('keydown', e => {
  if (e.key === 'Escape') closeAllSheets();
});

/* ---------- boot ---------- */

function fit() {
  const scale = Math.min((window.innerHeight - 118) / 872, (window.innerWidth - 24) / 413, 1);
  document.documentElement.style.setProperty('--scale', scale.toFixed(4));
}

window.addEventListener('resize', fit);
fit();

const gliderEl = document.getElementById('tab-glider');
gliderEl.style.transition = 'none';
positionGlider(false);
requestAnimationFrame(() => { gliderEl.style.transition = ''; });
window.addEventListener('resize', () => positionGlider(false));

document.getElementById('filter-icon').innerHTML = icon('sliders');
document.getElementById('period-icon').innerHTML = icon('calendar');
document.getElementById('period-chevron').innerHTML = icon('chevronDown');
document.getElementById('period-close-icon').innerHTML = icon('x');
document.getElementById('template-close-icon').innerHTML = icon('x');
document.getElementById('template-name-icon').innerHTML = icon('bookmark');
document.getElementById('tool-calc-icon').innerHTML = icon('calculator');
document.getElementById('tool-chevron-icon').innerHTML = icon('chevronRight');
document.getElementById('tool-recovery-icon').innerHTML = icon('trendDown');
document.getElementById('tool-recovery-chevron').innerHTML = icon('chevronRight');
document.getElementById('calc-back-icon').innerHTML = icon('chevronLeft');
document.getElementById('recovery-back-icon').innerHTML = icon('chevronLeft');
document.getElementById('save-tpl-icon').innerHTML = icon('bookmark');
document.getElementById('note-icon').innerHTML = icon('pencil');
document.getElementById('tag-icon').innerHTML = icon('tag');
document.getElementById('search-icon').innerHTML = icon('search');
document.getElementById('filter-close-icon').innerHTML = icon('x');
document.getElementById('account-close-icon').innerHTML = icon('x');
document.getElementById('account-name-icon').innerHTML = icon('wallet');

renderKeypad();
renderHome();
renderStats();
renderTools();
renderRecovery();

if (location.hash === '#stats') {
  document.querySelector('.tab[data-tab=stats]').click();
} else if (location.hash === '#stats-income') {
  state.metric = 'income';
  document.querySelector('.tab[data-tab=stats]').click();
} else if (location.hash === '#home') {
  document.querySelector('.tab[data-tab=home]').click();
} else if (location.hash === '#add') {
  openSheet();
} else if (location.hash === '#add-transfer') {
  openSheet();
  setAddType('transfer');
} else if (location.hash === '#filter') {
  openFilterSheet();
} else if (location.hash === '#period') {
  openPeriodSheet();
} else if (location.hash === '#tools') {
  document.querySelector('.tab[data-tab=tools]').click();
} else if (location.hash === '#calculator') {
  document.querySelector('.tab[data-tab=tools]').click();
  showToolPage('calculator-view');
} else if (location.hash === '#recovery') {
  document.querySelector('.tab[data-tab=tools]').click();
  showToolPage('recovery-view');
} else if (location.hash === '#template') {
  document.querySelector('.tab[data-tab=tools]').click();
  showToolPage('calculator-view');
  openTemplateSheet();
}