const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = path.resolve(__dirname, '..');
function ok(c,m){ if(!c) throw new Error(m); console.log('✓',m); }
const html=fs.readFileSync(path.join(root,'index.html'),'utf8');
const css=fs.readFileSync(path.join(root,'assets/css/styles.css'),'utf8');
const app=fs.readFileSync(path.join(root,'assets/js/app.js'),'utf8');
const data=fs.readFileSync(path.join(root,'assets/js/data.js'),'utf8');
const config=fs.readFileSync(path.join(root,'assets/js/config.js'),'utf8');
const migration=fs.readFileSync(path.join(root,'supabase/migrations/20261006_early_access.sql'),'utf8');
const edge=fs.readFileSync(path.join(root,'supabase/functions/register-early-access/index.ts'),'utf8');

ok(html.includes('data-open-vip-modal'),'Download CTA opens VIP modal');
ok(html.includes('id="vipModal"'),'VIP modal exists');
ok(html.includes('id="earlyAccessForm"'),'Phone registration form exists inside modal');
ok(html.includes('Tải ứng dụng miễn phí'),'Free download CTA copy exists');
ok(html.includes('VIP 1 tháng') && html.includes('Plus'),'VIP promotion is clearly mapped to Plus');
ok(html.includes('AI Chat không giới hạn'),'VIP-only AI Chat benefit is explicit');
ok(html.includes('Tạo lịch trình AI không giới hạn'),'VIP-only schedule benefit is explicit');
ok(html.includes('FamilyPlus') && html.includes('không bao gồm'),'FamilyPlus exclusion is explicit');
ok(html.includes('privacy.html'),'Privacy link exists');
ok(html.includes('consent') && html.includes('checkbox'),'Consent control exists');
ok(html.includes('NanoBio') && html.includes('Nabi'),'Core branding exists');
ok(css.includes('@media(max-width:760px)'),'Responsive mobile CSS exists');
ok(css.includes('.vip-modal') && css.includes('.vip-benefits'),'VIP modal/benefits CSS exists');
ok(!/service[_-]?role/i.test(config.replace(/service-role key/ig,'')),'Browser config does not contain service-role secret');
ok(app.includes('openVipModal') && app.includes('registerRemote') && app.includes('registerDemo'),'Modal + remote + safe demo flow exists');
ok(app.includes("promotion_code:'EARLY_ACCESS_PLUS_30D'") && app.includes("requested_plan:'plus'") && app.includes('vip_duration_days:30'),'Browser requests fixed VIP promotion metadata');
ok(data.includes('VIP 1 tháng có những quyền lợi gì?'),'FAQ explains VIP benefits');

const sandbox={window:{},globalThis:{}}; sandbox.globalThis=sandbox; vm.createContext(sandbox); vm.runInContext(fs.readFileSync(path.join(root,'assets/js/phone.js'),'utf8'),sandbox);
const p=sandbox.NanoBioPhone || sandbox.window.NanoBioPhone;
ok(p.normalizeVietnamPhone('0912345678')==='+84912345678','Normalize VN mobile phone');
ok(p.normalizeVietnamPhone('+84912345678')==='+84912345678','Accept E.164 phone');
ok(p.normalizeVietnamPhone('0212345678')===null,'Reject non-mobile prefix');

ok(migration.includes('enable row level security'),'RLS is enabled');
ok(migration.includes('revoke all'),'Direct anon table access is revoked');
ok(migration.includes("promotion_code text not null default 'EARLY_ACCESS_PLUS_30D'"),'Promotion code stored server-side');
ok(migration.includes("requested_plan text not null default 'plus'"),'VIP maps to Plus plan');
ok(migration.includes('vip_duration_days integer not null default 30'),'VIP duration is 30 days');
ok(migration.includes('vip_grant_status'),'Promotion grant state is tracked');
ok(edge.includes("const PROMOTION_CODE = 'EARLY_ACCESS_PLUS_30D'") && edge.includes("const REQUESTED_PLAN = 'plus'") && edge.includes('const VIP_DURATION_DAYS = 30'),'Edge Function owns promotion values');
ok(edge.includes('Preserve an already processed promotion'),'Repeated download does not reset an already processed promotion');
console.log('\nSmoke tests passed.');
