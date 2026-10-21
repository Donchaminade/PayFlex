/**
 * PayFlex Admin — couche premium (réf. DeoxA_vzRbo + Dc7xjbKTa7h).
 * Améliorations purement visuelles et progressives : aucune donnée, route ou action n'est retirée ;
 * les formulaires, liens et confirmations existants fonctionnent exactement comme avant.
 */
(function () {
  'use strict';
  var THEME_KEY = 'pf-admin-theme';
  var root = document.documentElement;
  try { if (localStorage.getItem(THEME_KEY) === 'dark') root.classList.add('pf-dark'); } catch (_) { /* ignore */ }
  var reduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // ---------- Chart.js : typo, couleurs, tracé animé, squelette avant rendu ----------
  if (window.Chart && window.Chart.defaults) {
    var C = window.Chart;
    C.defaults.font.family = "'Inter', system-ui, sans-serif";
    C.defaults.color = root.classList.contains('pf-dark') ? '#94A3B8' : '#64748B';
    C.defaults.borderColor = root.classList.contains('pf-dark') ? 'rgba(148,163,184,.12)' : 'rgba(100,116,139,.12)';
    C.defaults.animation = reduced ? false : { duration: 900, easing: 'easeOutQuart' };
    C.defaults.plugins = C.defaults.plugins || {};
    if (C.defaults.plugins.tooltip) {
      C.defaults.plugins.tooltip.backgroundColor = '#00314F';
      C.defaults.plugins.tooltip.cornerRadius = 10;
      C.defaults.plugins.tooltip.padding = 10;
    }
    if (C.defaults.elements && C.defaults.elements.bar) C.defaults.elements.bar.borderRadius = 8;
    if (C.defaults.elements && C.defaults.elements.line) C.defaults.elements.line.tension = 0.38;
    try {
      C.register({
        id: 'pfSkeletonOff',
        afterRender: function (chart) {
          var p = chart.canvas && chart.canvas.parentElement;
          if (p) p.classList.remove('pf-loading');
        }
      });
    } catch (_) { /* ignore */ }
  }
  function ready(fn) { if (document.readyState !== 'loading') fn(); else document.addEventListener('DOMContentLoaded', fn); }

  ready(function () {
    var main = document.querySelector('.pf-admin-layout-grid > main') || document.querySelector('main');

    // ---------- Bascule clair / sombre ----------
    var header = document.querySelector('.pf-admin-page-header');
    if (header && !document.getElementById('pf-theme-toggle')) {
      var t = document.createElement('button');
      t.type = 'button'; t.id = 'pf-theme-toggle'; t.className = 'pf-theme-toggle';
      var sync = function () {
        var dark = root.classList.contains('pf-dark');
        t.innerHTML = '<i class="fa-solid ' + (dark ? 'fa-sun' : 'fa-moon') + '" aria-hidden="true"></i>';
        t.setAttribute('aria-label', dark ? 'Passer en mode clair' : 'Passer en mode sombre');
        t.setAttribute('data-pf-tip', dark ? 'Mode clair' : 'Mode sombre');
      };
      sync();
      t.addEventListener('click', function () {
        root.classList.toggle('pf-dark');
        try { localStorage.setItem(THEME_KEY, root.classList.contains('pf-dark') ? 'dark' : 'light'); } catch (_) { /* ignore */ }
        sync();
      });
      var bell = header.querySelector('#pf-push-bell');
      if (bell) header.insertBefore(t, bell); else header.appendChild(t);
    }

    // ---------- KPI : cartes + compteurs animés ----------
    var kpis = [];
    document.querySelectorAll('main section.grid > article, main section.grid > a.pf-dash-kpi-link').forEach(function (card, i) {
      if (card.querySelector('h3') && card.querySelector('strong')) {
        card.classList.add('pf-kpi');
        if (i === 4) card.classList.add('pf-kpi--feature');
        kpis.push(card.querySelector('strong'));
      }
    });
    document.querySelectorAll('.pf-stat-value').forEach(function (el) { kpis.push(el); });
    kpis.forEach(function (el) {
      var raw = (el.textContent || '').trim();
      var m = raw.match(/^([^\d-]*)(-?\d[\d.\s\u00a0\u202f]*)(.*)$/);
      if (!m || reduced) return;
      var digits = m[2].replace(/[^\d-]/g, '');
      var target = parseInt(digits, 10);
      if (!isFinite(target) || target === 0) return;
      var sep = /\./.test(m[2]) ? '.' : (/[\s\u00a0\u202f]/.test(m[2].trim()) ? '\u00a0' : '');
      var fmt = function (v) {
        var s = String(Math.round(v));
        return sep ? s.replace(/\B(?=(\d{3})+(?!\d))/g, sep) : s;
      };
      var t0 = null, dur = 1100;
      el.textContent = m[1] + fmt(0) + m[3];
      var step = function (ts) {
        if (t0 === null) t0 = ts;
        var k = Math.min(1, (ts - t0) / dur), e = 1 - Math.pow(1 - k, 3);
        el.textContent = m[1] + fmt(target * e) + m[3];
        if (k < 1) requestAnimationFrame(step); else el.textContent = raw;
      };
      requestAnimationFrame(step);
    });

    // ---------- Squelette des graphiques jusqu'au premier rendu ----------
    document.querySelectorAll('main canvas').forEach(function (cv) {
      var p = cv.parentElement; if (!p) return;
      p.classList.add('pf-canvas-wrap');
      if (window.Chart && !(window.Chart.getChart && window.Chart.getChart(cv))) {
        p.classList.add('pf-loading');
        setTimeout(function () { p.classList.remove('pf-loading'); }, 4000);
      }
    });

    // ---------- CRUD : icônes rondes + info-bulles ----------
    var CRUD = [
      { re: /^(supprimer|retirer|effacer)\b/i, kind: 'delete', icon: 'fa-trash-can' },
      { re: /^(modifier|éditer|editer|edit)\b/i, kind: 'edit', icon: 'fa-pen' },
      { re: /^(fiche|voir|détail|détails|detail|ouvrir|consulter)\b/i, kind: 'view', icon: 'fa-eye' },
      { re: /^chat\b/i, kind: 'chat', icon: 'fa-comments' }
    ];
    document.querySelectorAll('main td a, main td button').forEach(function (b) {
      if (b.closest('.pf-crud') || b.dataset.pfNoCrud !== undefined) return;
      var label = (b.textContent || '').replace(/\s+/g, ' ').trim();
      if (!label || label.length > 16) return;
      var rule = CRUD.find(function (r) { return r.re.test(label); });
      if (!rule) return;
      var icon = b.querySelector('i');
      Array.prototype.slice.call(b.childNodes).forEach(function (n) {
        if (n.nodeType === 3 && n.textContent.trim()) {
          var s = document.createElement('span'); s.className = 'pf-crud-label'; s.textContent = n.textContent.trim(); b.replaceChild(s, n);
        } else if (n.nodeType === 1 && n.tagName !== 'I') {
          n.classList.add('pf-crud-label');
        }
      });
      if (!icon) { icon = document.createElement('i'); b.insertBefore(icon, b.firstChild); }
      icon.className = 'fa-solid ' + rule.icon;
      icon.setAttribute('aria-hidden', 'true');
      b.classList.add('pf-crud', 'pf-crud--' + rule.kind);
      b.setAttribute('data-pf-tip', label);
      if (!b.getAttribute('aria-label')) b.setAttribute('aria-label', label);
      if (!b.getAttribute('title')) b.setAttribute('title', label);
    });

    // ---------- États vides ----------
    document.querySelectorAll('main table tbody tr').forEach(function (tr) {
      var tds = tr.querySelectorAll('td');
      if (tds.length === 1 && (parseInt(tds[0].getAttribute('colspan') || '1', 10) > 1)) {
        tr.classList.add('pf-empty-row');
        if (!tds[0].querySelector('.pf-empty-ico')) {
          var ic = document.createElement('div'); ic.className = 'pf-empty-ico';
          ic.innerHTML = '<i class="fa-regular fa-folder-open" aria-hidden="true"></i>';
          tds[0].insertBefore(ic, tds[0].firstChild);
        }
      }
    });

    // ---------- Tables : recherche instantanée + pagination client ----------
    var PAGE = 15;
    document.querySelectorAll('main table').forEach(function (table, ti) {
      var tbody = table.tBodies[0]; if (!tbody) return;
      var rows = Array.prototype.filter.call(tbody.rows, function (r) { return !r.classList.contains('pf-empty-row'); });
      if (rows.length < 6 || table.dataset.pfNoTools !== undefined) return;
      var card = table.closest('.bg-white') || table.parentElement;
      var serverPaged = !!(card && card.querySelector('.pf-admin-pagination'));
      var tools = document.createElement('div'); tools.className = 'pf-table-tools';
      var id = 'pf-table-q-' + ti;
      tools.innerHTML = '<label class="pf-table-search" for="' + id + '"><i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i>' +
        '<input id="' + id + '" type="search" autocomplete="off" placeholder="' + (serverPaged ? 'Filtrer cette page…' : 'Rechercher dans le tableau…') + '" aria-label="Rechercher dans le tableau"></label>' +
        '<span class="pf-table-count" aria-live="polite"></span>';
      var anchor = table.closest('.overflow-x-auto') || table;
      anchor.parentNode.insertBefore(tools, anchor);
      var pager = document.createElement('nav'); pager.className = 'pf-table-pager'; pager.setAttribute('aria-label', 'Pagination du tableau');
      anchor.parentNode.insertBefore(pager, anchor.nextSibling);
      var input = tools.querySelector('input'), count = tools.querySelector('.pf-table-count');
      var page = 0;
      function render() {
        var q = input.value.trim().toLowerCase();
        var match = rows.filter(function (r) { return !q || r.textContent.toLowerCase().indexOf(q) !== -1; });
        var paged = !serverPaged && match.length > PAGE;
        var pages = paged ? Math.ceil(match.length / PAGE) : 1;
        if (page >= pages) page = pages - 1;
        rows.forEach(function (r) { r.style.display = 'none'; });
        match.forEach(function (r, i) { if (!paged || (i >= page * PAGE && i < (page + 1) * PAGE)) r.style.display = ''; });
        count.textContent = match.length + ' / ' + rows.length + ' ligne' + (rows.length > 1 ? 's' : '');
        pager.innerHTML = '';
        if (!paged) return;
        var mk = function (lbl, p, dis, cur) {
          var b = document.createElement('button'); b.type = 'button'; b.innerHTML = lbl; b.disabled = !!dis;
          if (cur) b.setAttribute('aria-current', 'page');
          b.addEventListener('click', function () { page = p; render(); });
          pager.appendChild(b);
        };
        mk('<i class="fa-solid fa-chevron-left" aria-hidden="true"></i><span class="pf-crud-label">Précédent</span>', page - 1, page === 0);
        for (var i = 0; i < pages; i++) {
          if (pages > 7 && i > 1 && i < pages - 2 && Math.abs(i - page) > 1) { if (i === 2 || i === pages - 3) { var s = document.createElement('span'); s.textContent = '…'; pager.appendChild(s); } continue; }
          mk(String(i + 1), i, false, i === page);
        }
        mk('<i class="fa-solid fa-chevron-right" aria-hidden="true"></i><span class="pf-crud-label">Suivant</span>', page + 1, page >= pages - 1);
      }
      input.addEventListener('input', function () { page = 0; render(); });
      render();
    });

    // ---------- Bouton liquide : vague pendant l'aller-retour serveur ----------
    document.addEventListener('submit', function (e) {
      var form = e.target;
      var btn = e.submitter || form.querySelector('button[type="submit"], input[type="submit"]');
      setTimeout(function () {
        if (e.defaultPrevented || !btn || btn.tagName !== 'BUTTON') return;
        if ((form.getAttribute('target') || btn.getAttribute('formtarget') || '').toLowerCase() === '_blank') return;
        if (/\.(pdf|csv|xlsx)(\?|$)/i.test(btn.getAttribute('formaction') || form.getAttribute('action') || '')) return;
        btn.classList.add('pf-liquid--loading');
        btn.setAttribute('aria-busy', 'true');
        setTimeout(function () { btn.classList.remove('pf-liquid--loading'); btn.removeAttribute('aria-busy'); }, 12000);
      }, 0);
    });

    // ---------- Squelette de navigation ----------
    var sk = document.createElement('div'); sk.id = 'pf-nav-skeleton'; sk.setAttribute('aria-hidden', 'true');
    sk.innerHTML = '<div class="bar"></div><div class="sheet"><div class="pf-skel"></div><div class="pf-skel"></div><div class="pf-skel"></div><div class="pf-skel"></div><div class="pf-skel wide"></div></div>';
    document.body.appendChild(sk);
    function showSkeleton() {
      if (main) {
        var r = main.getBoundingClientRect(), sh = sk.querySelector('.sheet');
        sh.style.left = Math.max(0, r.left) + 'px'; sh.style.top = '0px'; sh.style.right = '0px'; sh.style.bottom = '0px';
      }
      sk.classList.add('on');
    }
    document.addEventListener('click', function (e) {
      var a = e.target.closest && e.target.closest('a[href]');
      if (!a || e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
      var href = a.getAttribute('href') || '';
      if (a.target === '_blank' || a.hasAttribute('download') || href.charAt(0) === '#' || /^(javascript:|mailto:|tel:)/i.test(href)) return;
      if (/\.(pdf|csv|xlsx|png|jpg|jpeg)(\?|$)/i.test(href) || /\/(photo|identity|contract|export)/i.test(href)) return;
      if (a.origin && a.origin !== location.origin) return;
      setTimeout(function () { if (!e.defaultPrevented) showSkeleton(); }, 0);
    });
    window.addEventListener('pageshow', function () {
      sk.classList.remove('on');
      document.querySelectorAll('.pf-liquid--loading').forEach(function (b) { b.classList.remove('pf-liquid--loading'); b.removeAttribute('aria-busy'); });
    });
  });
})();
