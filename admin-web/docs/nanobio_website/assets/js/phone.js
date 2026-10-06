(function (global) {
  function cleanPhone(value) { return String(value || '').replace(/[\s.()-]/g, ''); }
  function normalizeVietnamPhone(value) {
    var raw = cleanPhone(value);
    if (raw.startsWith('+84')) raw = '0' + raw.slice(3);
    else if (raw.startsWith('84') && raw.length >= 11) raw = '0' + raw.slice(2);
    if (!/^0\d{9}$/.test(raw)) return null;
    if (!/^0(3|5|7|8|9)\d{8}$/.test(raw)) return null;
    return '+84' + raw.slice(1);
  }
  function displayPhone(value) {
    var e164 = normalizeVietnamPhone(value); if (!e164) return '';
    var n = '0' + e164.slice(3); return n.slice(0,4) + ' ' + n.slice(4,7) + ' ' + n.slice(7);
  }
  global.NanoBioPhone = { cleanPhone: cleanPhone, normalizeVietnamPhone: normalizeVietnamPhone, displayPhone: displayPhone };
  if (typeof module !== 'undefined' && module.exports) module.exports = global.NanoBioPhone;
})(typeof window !== 'undefined' ? window : globalThis);
