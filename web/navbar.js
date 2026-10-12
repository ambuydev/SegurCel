/**
 * SegurCel Web - Shared Navbar & Dynamic Localizations Module
 * Gestiona el encabezado, banderas HD, selector desplegable de idiomas, botón 'Volver al Sitio Oficial' y pie de página en 10 idiomas.
 */

const FLAGS_MAP = {
  es: "https://flagcdn.com/20x15/es.png",
  en: "https://flagcdn.com/20x15/us.png",
  pt: "https://flagcdn.com/20x15/br.png",
  zh: "https://flagcdn.com/20x15/cn.png",
  fr: "https://flagcdn.com/20x15/fr.png",
  hi: "https://flagcdn.com/20x15/in.png",
  de: "https://flagcdn.com/20x15/de.png",
  ja: "https://flagcdn.com/20x15/jp.png",
  ko: "https://flagcdn.com/20x15/kr.png",
  ru: "https://flagcdn.com/20x15/ru.png"
};

const NAMES_MAP = {
  es: "Español", en: "English", pt: "Português", zh: "中文", fr: "Français",
  hi: "हिन्दी", de: "Deutsch", ja: "日本語", ko: "한국어", ru: "Русский"
};

const NAV_DICT = {
  es: { btnBack: "← Volver al Sitio Oficial", headerVault: "Acceder a la Bóveda", headerGuide: "📘 Guía de Uso" },
  en: { btnBack: "← Back to Official Site", headerVault: "Access Vault", headerGuide: "📘 User Guide" },
  pt: { btnBack: "← Voltar ao Site Oficial", headerVault: "Acessar Cofre", headerGuide: "📘 Guia do Usuário" },
  zh: { btnBack: "← 返回官方网站", headerVault: "进入保险库", headerGuide: "📘 使用指南" },
  fr: { btnBack: "← Retour au Site Officiel", headerVault: "Accéder au Coffre", headerGuide: "📘 Guide Utilisateur" },
  hi: { btnBack: "← आधिकारिक साइट पर वापस जाएं", headerVault: "वॉल्ट एक्सेस करें", headerGuide: "📘 उपयोग निर्देशिका" },
  de: { btnBack: "← Zurück zur offiziellen Website", headerVault: "Tresor öffnen", headerGuide: "📘 Benutzerhandbuch" },
  ja: { btnBack: "← 公式サイトに戻る", headerVault: "保管庫に入る", headerGuide: "📘 ユーザーガイド" },
  ko: { btnBack: "← 공식 사이트로 돌아가기", headerVault: "보관함 접속", headerGuide: "📘 사용자 설명서" },
  ru: { btnBack: "← Вернуться на официальный сайт", headerVault: "Войти в хранилище", headerGuide: "📘 Руководство" }
};

const FOOTER_DICT = {
  es: { copyright: "© 2026 SegurCel. Todos los derechos reservados.", guide: "📘 Guía Rápida de Uso", privacy: "Política de Privacidad", official: "Sitio Oficial", vault: "Bóveda Web" },
  en: { copyright: "© 2026 SegurCel. All rights reserved.", guide: "📘 Quick User Guide", privacy: "Privacy Policy", official: "Official Site", vault: "Web Vault" },
  pt: { copyright: "© 2026 SegurCel. Todos os direitos reservados.", guide: "📘 Guia Rápido do Usuário", privacy: "Política de Privacidade", official: "Site Oficial", vault: "Cofre Web" },
  zh: { copyright: "© 2026 SegurCel。版权所有。", guide: "📘 快速使用指南", privacy: "隐私政策", official: "官方网站", vault: "网页版保险库" },
  fr: { copyright: "© 2026 SegurCel. Tous droits réservés.", guide: "📘 Guide Rapide d'Utilisation", privacy: "Politique de Confidentialité", official: "Site Officiel", vault: "Coffre Web" },
  hi: { copyright: "© 2026 SegurCel. सर्वाधिकार सुरक्षित।", guide: "📘 त्वरित उपयोग निर्देशिका", privacy: "गोपनीयता नीति", official: "आधिकारिक साइट", vault: "वेब वॉल्ट" },
  de: { copyright: "© 2026 SegurCel. Alle Rechte vorbehalten.", guide: "📘 Schnellstartanleitung", privacy: "Datenschutzerklärung", official: "Offizielle Website", vault: "Web-Tresor" },
  ja: { copyright: "© 2026 SegurCel. 全著作権所有。", guide: "📘 クイックユーザーガイド", privacy: "プライバシーポリシー", official: "公式サイト", vault: "Web保管庫" },
  ko: { copyright: "© 2026 SegurCel. 모든 권리 보유.", guide: "📘 빠른 사용자 설명서", privacy: "개인정보 처리방침", official: "공식 사이트", vault: "웹 보관함" },
  ru: { copyright: "© 2026 SegurCel. Все права защищены.", guide: "📘 Краткое руководство", privacy: "Политика конфиденциальности", official: "Официальный сайт", vault: "Веб-хранилище" }
};

window.SegurCelNav = {
  activeLang: 'es',

  updateNav(lang) {
    this.activeLang = lang;
    const navData = NAV_DICT[lang] || NAV_DICT.es;

    // Actualizar botón 'Volver al Sitio Oficial'
    const btnBack = document.getElementById('btnBack');
    if (btnBack) {
      btnBack.innerText = navData.btnBack;
      btnBack.href = `index.html?lang=${lang}`;
    }

    // Actualizar botón 'Acceder a la Bóveda' en el header
    const btnHeaderVault = document.getElementById('btnHeaderVault');
    if (btnHeaderVault) {
      btnHeaderVault.innerText = navData.headerVault;
      btnHeaderVault.href = `/vault.html?lang=${lang}`;
    }

    // Actualizar enlace a la Guía en el header
    const linkHeaderGuide = document.getElementById('linkHeaderGuide');
    if (linkHeaderGuide) {
      linkHeaderGuide.innerText = navData.headerGuide;
      linkHeaderGuide.href = `guide.html?lang=${lang}`;
    }

    // Actualizar Pie de Página (Footer)
    this.updateFooter(lang);
  },

  getNavData(lang) {
    return NAV_DICT[lang] || NAV_DICT.es;
  },

  updateFooter(lang) {
    const data = FOOTER_DICT[lang] || FOOTER_DICT.es;

    const copyEl = document.getElementById('footerCopyright');
    if (copyEl) copyEl.innerText = data.copyright;

    const guideEl = document.getElementById('linkFooterGuide');
    if (guideEl) {
      guideEl.innerText = data.guide;
      guideEl.href = `guide.html?lang=${lang}`;
    }

    const privacyEl = document.getElementById('linkFooterPrivacy');
    if (privacyEl) {
      privacyEl.innerText = data.privacy;
      privacyEl.href = `privacy.html?lang=${lang}`;
    }

    const officialEl = document.getElementById('linkFooterOfficial');
    if (officialEl) {
      officialEl.innerText = data.official;
      officialEl.href = `index.html?lang=${lang}`;
    }
  },

  selectLanguage(lang, callback) {
    const flagEl = document.getElementById("selectedFlag");
    const nameEl = document.getElementById("selectedLangName");
    if (flagEl && FLAGS_MAP[lang]) flagEl.src = FLAGS_MAP[lang];
    if (nameEl && NAMES_MAP[lang]) nameEl.innerText = NAMES_MAP[lang];

    const menu = document.getElementById("langMenu");
    if (menu) menu.classList.remove("show");

    try {
      const newUrl = window.location.pathname + '?lang=' + lang;
      window.history.replaceState(null, '', newUrl);
    } catch (_) {}

    this.updateNav(lang);

    if (typeof callback === 'function') {
      callback(lang);
    }
  },

  toggleLangMenu(event) {
    if (event) event.stopPropagation();
    const menu = document.getElementById("langMenu");
    if (menu) menu.classList.toggle("show");
  },

  init(callback) {
    const urlParams = new URLSearchParams(window.location.search);
    const langParam = urlParams.get('lang');
    const initialLang = (langParam && FLAGS_MAP[langParam]) ? langParam : 'es';

    this.selectLanguage(initialLang, callback);

    window.onclick = (event) => {
      const menu = document.getElementById("langMenu");
      if (menu && menu.classList.contains('show')) {
        menu.classList.remove('show');
      }
    };
  }
};
