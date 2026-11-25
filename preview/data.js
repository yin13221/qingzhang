const STORAGE_KEY = 'qingzhang.data.v2';

const ICONS = {
  fork: '<path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Z"/><path d="M21 15v7"/>',
  car: '<path d="M4 16v-4l2-5h12l2 5v4"/><path d="M2.5 16h19"/><path d="M7 11h10"/><circle cx="7.5" cy="17.8" r="1.7"/><circle cx="16.5" cy="17.8" r="1.7"/>',
  bag: '<path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"/><path d="M3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/>',
  home: '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
  gamepad: '<path d="M6.5 7h11a4 4 0 0 1 3.9 3.1l.7 4a2.8 2.8 0 0 1-4.9 2.4L16 15H8l-1.2 1.5a2.8 2.8 0 0 1-4.9-2.4l.7-4A4 4 0 0 1 6.5 7Z"/><path d="M8 10.5v3M6.5 12h3"/><circle cx="15.5" cy="11.5" r=".7" fill="currentColor" stroke="none"/><circle cx="17.5" cy="13.5" r=".7" fill="currentColor" stroke="none"/>',
  cross: '<path d="M10 3h4v7h7v4h-7v7h-4v-7H3v-4h7Z"/>',
  book: '<path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/>',
  dots: '<circle cx="5" cy="12" r="1.6" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="1.6" fill="currentColor" stroke="none"/><circle cx="19" cy="12" r="1.6" fill="currentColor" stroke="none"/>',
  briefcase: '<rect x="3" y="7" width="18" height="13" rx="2.5"/><path d="M9 7V5.5A2.5 2.5 0 0 1 11.5 3h1A2.5 2.5 0 0 1 15 5.5V7"/><path d="M3 12.5h18"/>',
  trend: '<path d="M22 7 13.5 15.5l-5-5L2 17"/><path d="M16 7h6v6"/>',
  gift: '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M5 12v8a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-8"/><path d="M12 8v13"/><path d="M12 8H7.5a2.5 2.5 0 0 1 0-5C11 3 12 8 12 8Z"/><path d="M12 8h4.5a2.5 2.5 0 0 0 0-5C13 3 12 8 12 8Z"/>',
  trash: '<path d="M3 6h18"/><path d="M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/>',
  inbox: '<path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.5 5.1 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.5-6.9A2 2 0 0 0 16.7 4H7.3a2 2 0 0 0-1.8 1.1Z"/>',
  pie: '<path d="M21.21 15.89A10 10 0 1 1 8 2.83"/><path d="M22 12A10 10 0 0 0 12 2v10z"/>',
  backspace: '<path d="M21 4H8l-7 8 7 8h13a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2Z"/><path d="m12 9 5 5"/><path d="m17 9-5 5"/>',
  pencil: '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
  wallet: '<path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/>',
  bank: '<path d="M3 21h18"/><path d="M5 21V9M9 21V9M15 21V9M19 21V9"/><path d="M12 3 3 8h18Z"/>',
  smartphone: '<rect x="6" y="2" width="12" height="20" rx="3"/><path d="M11 18h2"/>',
  chat: '<path d="M21 12a8 8 0 0 1-11.6 7.1L4 20l1-4.6A8 8 0 1 1 21 12Z"/>',
  creditcard: '<rect x="2" y="5" width="20" height="14" rx="3"/><path d="M2 10h20"/><path d="M6 15h4"/>',
  tag: '<path d="M20.6 13.4 12 22l-9-9V3h10l7.6 7.6a2 2 0 0 1 0 2.8Z"/><circle cx="7.5" cy="7.5" r="1.2" fill="currentColor" stroke="none"/>',
  sliders: '<path d="M4 6h9M17 6h3M4 12h3M11 12h9M4 18h9M17 18h3"/><circle cx="15" cy="6" r="2"/><circle cx="9" cy="12" r="2"/><circle cx="15" cy="18" r="2"/>',
  search: '<circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/>',
  x: '<path d="M18 6 6 18M6 6l12 12"/>',
  arrows: '<path d="M8 3 4 7l4 4"/><path d="M4 7h16"/><path d="m16 21 4-4-4-4"/><path d="M20 17H4"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  calendar: '<rect x="3" y="4" width="18" height="17" rx="3"/><path d="M8 2v4M16 2v4M3 10h18"/>',
  chevronDown: '<path d="m6 9 6 6 6-6"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  calculator: '<rect x="4" y="2" width="16" height="20" rx="3"/><path d="M8 6h8"/><path d="M8 11h.01M12 11h.01M16 11h.01M8 15h.01M12 15h.01M16 15h.01M8 19h.01M12 19h.01M16 19h.01"/>',
  bookmark: '<path d="M6 3h12a1 1 0 0 1 1 1v17l-7-4-7 4V4a1 1 0 0 1 1-1Z"/>',
  chevronRight: '<path d="m9 18 6-6-6-6"/>',
  chevronLeft: '<path d="m15 18-6-6 6-6"/>',
  trendDown: '<path d="M22 17l-8.5-8.5-5 5L2 7"/><path d="M16 17h6v-6"/>'
};

function icon(name) {
  return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">${ICONS[name]}</svg>`;
}

const CATEGORIES = {
  expense: [
    { id: 'food', name: '餐饮', icon: 'fork', color: '#FF8A66' },
    { id: 'transport', name: '交通', icon: 'car', color: '#5B8CFF' },
    { id: 'shopping', name: '购物', icon: 'bag', color: '#B37BFF' },
    { id: 'home', name: '居住', icon: 'home', color: '#3EC9A7' },
    { id: 'fun', name: '娱乐', icon: 'gamepad', color: '#FFB84C' },
    { id: 'health', name: '医疗', icon: 'cross', color: '#FF6B8A' },
    { id: 'study', name: '学习', icon: 'book', color: '#63B3ED' },
    { id: 'other', name: '其他', icon: 'dots', color: '#8C98AD' }
  ],
  income: [
    { id: 'salary', name: '工资', icon: 'briefcase', color: '#23B98B' },
    { id: 'invest', name: '理财', icon: 'trend', color: '#5B8CFF' },
    { id: 'gift', name: '红包', icon: 'gift', color: '#FF8A66' },
    { id: 'otherIn', name: '其他', icon: 'dots', color: '#8C98AD' }
  ]
};

const ACCOUNT_KINDS = {
  cash: { title: '现金', icon: 'wallet', color: '#F2B544' },
  bank: { title: '银行卡', icon: 'bank', color: '#5B8CFF' },
  alipay: { title: '支付宝', icon: 'smartphone', color: '#2AA6F0' },
  wechat: { title: '微信', icon: 'chat', color: '#2BB673' },
  credit: { title: '信用卡', icon: 'creditcard', color: '#B37BFF' }
};

const WEEKDAYS = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

let db = loadDB();

/* ---------- storage & demo data ---------- */

function uid() {
  return (crypto.randomUUID && crypto.randomUUID()) || 'id-' + Date.now() + '-' + Math.random().toString(36).slice(2, 8);
}

function newAccount(name, kind, initial, order) {
  return { id: uid(), name, kind, initial, order };
}

function loadDB() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const data = JSON.parse(raw);
      if (Array.isArray(data.bills) && Array.isArray(data.accounts)) return data;
    }
  } catch (e) { /* fall through to demo data */ }
  const fresh = seedDB();
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(fresh)); } catch (e) {}
  return fresh;
}

function seedDB() {
  const accounts = [
    newAccount('现金', 'cash', 520, 0),
    newAccount('银行卡', 'bank', 12480, 1),
    newAccount('支付宝', 'alipay', 1260.5, 2),
    newAccount('微信', 'wechat', 860, 3),
    newAccount('信用卡', 'credit', -1800, 4)
  ];
  const [cash, bank, alipay, wechat, credit] = accounts.map(a => a.id);

  const now = new Date();
  const at = (daysAgo, h, m) => {
    const d = new Date(now);
    d.setDate(d.getDate() - daysAgo);
    d.setHours(h, m, 0, 0);
    return d.getTime();
  };
  const monthAt = (monthsAgo, day) => new Date(now.getFullYear(), now.getMonth() - monthsAgo, day, 12, 0, 0).getTime();

  const rows = [
    [32.5, 'expense', 'food', '午餐 · 云吞面', at(0, 12, 26), wechat, ['工作餐']],
    [13, 'expense', 'transport', '地铁通勤', at(0, 8, 41), alipay, []],
    [268, 'expense', 'shopping', '优衣库 · 抓绒外套', at(1, 19, 12), credit, ['添置']],
    [56, 'expense', 'food', '和同事聚餐', at(2, 18, 40), wechat, []],
    [98, 'expense', 'fun', '电影票 · 两张', at(3, 20, 15), wechat, ['周末']],
    [320.8, 'income', 'invest', '基金收益', at(4, 21, 5), bank, []],
    [45, 'expense', 'health', '维生素', at(5, 11, 2), alipay, []],
    [129, 'expense', 'study', '专业书', at(6, 15, 30), bank, ['学习']],
    [3200, 'expense', 'home', '房租', at(8, 9, 0), bank, ['固定支出']],
    [18500, 'income', 'salary', '本月工资', at(9, 10, 0), bank, ['工资']],
    [4230, 'expense', 'shopping', '换季添置', monthAt(1, 12), credit, []],
    [3400, 'expense', 'home', '房租', monthAt(1, 2), bank, ['固定支出']],
    [18500, 'income', 'salary', '工资', monthAt(1, 9), bank, ['工资']],
    [3400, 'expense', 'home', '房租', monthAt(2, 2), bank, ['固定支出']],
    [2860, 'expense', 'food', '日常餐饮', monthAt(2, 26), wechat, []],
    [18500, 'income', 'salary', '工资', monthAt(2, 9), bank, ['工资']],
    [3400, 'expense', 'home', '房租', monthAt(3, 2), bank, []],
    [18500, 'income', 'salary', '工资', monthAt(3, 9), bank, ['工资']],
    [680, 'expense', 'fun', '短途旅行', monthAt(4, 18), cash, ['旅行']],
    [3400, 'expense', 'home', '房租', monthAt(4, 2), bank, []],
    [18500, 'income', 'salary', '工资', monthAt(4, 9), bank, ['工资']],
    [3400, 'expense', 'home', '房租', monthAt(5, 2), bank, []],
    [18500, 'income', 'salary', '工资', monthAt(5, 9), bank, ['工资']]
  ].map(([amount, type, cat, note, ts, account, tags]) => ({
    id: uid(), amount, type, cat, note, ts, account, tags
  }));

  const transfers = [
    { id: uid(), from: bank, to: alipay, amount: 500, note: '生活费分账', ts: at(2, 12, 0) },
    { id: uid(), from: alipay, to: wechat, amount: 120, note: '转到零钱', ts: at(6, 9, 30) }
  ];

  return { bills: rows, accounts, transfers };
}

function persist() {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(db)); } catch (e) {}
}

/* ---------- helpers ---------- */

function money(value) {
  return '¥' + Number(value).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function timeText(ts) {
  const d = new Date(ts);
  return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
}

function categoryOf(type, id) {
  const list = CATEGORIES[type];
  return list.find(c => c.id === id) || list[list.length - 1];
}

function findCategory(id) {
  for (const type of ['expense', 'income']) {
    const hit = CATEGORIES[type].find(c => c.id === id);
    if (hit) return { ...hit, type };
  }
  return { ...CATEGORIES.expense[CATEGORIES.expense.length - 1], type: 'expense' };
}

function accountOf(id) {
  return db.accounts.find(a => a.id === id) || db.accounts[0];
}

function accountKind(account) {
  return ACCOUNT_KINDS[account ? account.kind : 'cash'] || ACCOUNT_KINDS.cash;
}

function rgba(hex, alpha) {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`;
}

function accountBalance(id) {
  const account = accountOf(id);
  let balance = account ? account.initial : 0;
  for (const b of db.bills) {
    if (b.account !== id) continue;
    balance += b.type === 'income' ? b.amount : -b.amount;
  }
  for (const t of db.transfers) {
    if (t.from === id) balance -= t.amount;
    if (t.to === id) balance += t.amount;
  }
  return balance;
}

function netAssets() {
  return db.accounts.reduce((sum, a) => sum + accountBalance(a.id), 0);
}

function allTags() {
  const set = new Set();
  for (const b of db.bills) (b.tags || []).forEach(t => set.add(t));
  return [...set];
}

function monthKey(d) {
  return d.getFullYear() + '-' + d.getMonth();
}

function startOfDay(ts) {
  const d = new Date(ts);
  d.setHours(0, 0, 0, 0);
  return d.getTime();
}

function dayLabel(ts) {
  const d = new Date(ts);
  const today = startOfDay(Date.now());
  const day = startOfDay(ts);
  const base = `${d.getMonth() + 1}月${d.getDate()}日 · ${WEEKDAYS[d.getDay()]}`;
  if (day === today) return '今天 · ' + base;
  if (day === today - 86400000) return '昨天 · ' + base;
  return base;
}

function monthLabel(date) {
  return `${date.getFullYear()}年${date.getMonth() + 1}月`;
}

function escapeHtml(text) {
  return String(text).replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
}

/* ---------- filtering ---------- */

function emptyFilter() {
  return {
    cats: [],
    accounts: [],
    min: '',
    max: '',
    keyword: '',
    tags: []
  };
}

function cloneFilter(f) {
  return {
    cats: [...f.cats],
    accounts: [...f.accounts],
    min: f.min,
    max: f.max,
    keyword: f.keyword,
    tags: [...f.tags]
  };
}

function isFilterActive(f) {
  return f.cats.length > 0 || f.accounts.length > 0 ||
    f.min !== '' || f.max !== '' || f.keyword.trim() !== '' || f.tags.length > 0;
}

function filterCount(f) {
  let n = 0;
  if (f.cats.length) n++;
  if (f.accounts.length) n++;
  if (f.min !== '' || f.max !== '') n++;
  if (f.keyword.trim()) n++;
  if (f.tags.length) n++;
  return n;
}

const PERIOD_OPTIONS = [
  { id: 'today', label: '今天' },
  { id: 'threeDays', label: '最近三天' },
  { id: 'oneMonth', label: '最近一个月' },
  { id: 'halfYear', label: '最近半年' },
  { id: 'custom', label: '自定义时间' }
];

function isoDay(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function defaultPeriod() {
  const now = new Date();
  const start = new Date(now);
  start.setMonth(start.getMonth() - 1);
  return { preset: 'oneMonth', start: isoDay(start), end: isoDay(now) };
}

function periodBounds(p) {
  const now = new Date();
  const startOf = d => startOfDay(d.getTime());
  switch (p.preset) {
    case 'today':
      return { start: startOf(now), end: null };
    case 'threeDays': {
      const d = new Date(now);
      d.setDate(d.getDate() - 2);
      return { start: startOf(d), end: null };
    }
    case 'halfYear': {
      const d = new Date(now);
      d.setMonth(d.getMonth() - 6);
      return { start: startOf(d), end: null };
    }
    case 'custom':
      return {
        start: p.start ? new Date(p.start + 'T00:00:00').getTime() : null,
        end: p.end ? new Date(p.end + 'T23:59:59').getTime() : null
      };
    default: {
      const d = new Date(now);
      d.setMonth(d.getMonth() - 1);
      return { start: startOf(d), end: null };
    }
  }
}

function shortDate(value) {
  const d = new Date(value + 'T00:00:00');
  return `${d.getMonth() + 1}月${d.getDate()}日`;
}

function periodLabel(p) {
  if (p.preset === 'custom') {
    if (p.start && p.end) return `${shortDate(p.start)} – ${shortDate(p.end)}`;
    return '自定义时间';
  }
  const option = PERIOD_OPTIONS.find(o => o.id === p.preset);
  return option ? option.label : '最近一个月';
}

function periodCaption(p) {
  switch (p.preset) {
    case 'today': return '今日支出';
    case 'threeDays': return '近3天支出';
    case 'halfYear': return '近半年支出';
    case 'custom': return '所选时段支出';
    default: return '近30天支出';
  }
}

function filterEntries(f, bounds) {
  const scope = bounds || { start: null, end: null };
  const kw = f.keyword.trim().toLowerCase();
  const min = f.min === '' ? null : parseFloat(f.min);
  const max = f.max === '' ? null : parseFloat(f.max);

  const bills = db.bills.filter(b => {
    if (scope.start && b.ts < scope.start) return false;
    if (scope.end && b.ts >= scope.end) return false;
    if (f.cats.length && !f.cats.includes(b.cat)) return false;
    if (f.accounts.length && !f.accounts.includes(b.account)) return false;
    if (min !== null && b.amount < min) return false;
    if (max !== null && b.amount > max) return false;
    if (f.tags.length && !(b.tags || []).some(t => f.tags.includes(t))) return false;
    if (kw) {
      const cat = categoryOf(b.type, b.cat);
      const acc = accountOf(b.account);
      const hay = [b.note, cat.name, acc.name, ...(b.tags || [])].join(' ').toLowerCase();
      if (!hay.includes(kw)) return false;
    }
    return true;
  });

  const transfers = (f.cats.length || f.tags.length) ? [] : db.transfers.filter(t => {
    if (scope.start && t.ts < scope.start) return false;
    if (scope.end && t.ts >= scope.end) return false;
    if (f.accounts.length && !f.accounts.includes(t.from) && !f.accounts.includes(t.to)) return false;
    if (min !== null && t.amount < min) return false;
    if (max !== null && t.amount > max) return false;
    if (kw) {
      const hay = [t.note, accountOf(t.from).name, accountOf(t.to).name].join(' ').toLowerCase();
      if (!hay.includes(kw)) return false;
    }
    return true;
  });

  return { bills, transfers };
}