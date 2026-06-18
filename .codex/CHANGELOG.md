# CODEX CHANGELOG

Lịch sử thay đổi của `.codex/` documentation.

---

## [2.0.0] - 2026-06-18

### 🎉 Major Update - Complete Restructuring

#### Added

**New Core Documents**:
- ✨ **ARCHITECTURE.md** - Comprehensive architecture documentation
  - Layer responsibilities explained with examples
  - Feature structure guidelines
  - Data flow patterns
  - Naming conventions reference
  - Architecture Decision Records (ADR)
  - Known violations tracking
  
- ✨ **QUICK_REFERENCE.md** - Developer cheat sheet
  - Quick start commands
  - Common search patterns
  - Database quick reference
  - Design system tokens
  - Notification patterns
  - Navigation quick reference
  - Do's and Don'ts checklist
  
- ✨ **INDEX.md** - Complete navigation guide
  - Quick links to all documents
  - Task-based navigation map
  - Decision trees
  - External references

**New Playbooks**:
- ✨ **playbooks/health_tracking.md** - Daily health tracking best practices
  - Tracking logs management
  - Validation rules
  - Data models
  - Dashboard integration
  - Common issues and solutions
  
- ✨ **playbooks/lifestyle_schedule.md** - Schedule management guide
  - Timeline builder logic
  - Status flow (pending → completed/skipped)
  - Notification integration
  - Query patterns
  - Best practices

#### Enhanced

**AGENTS.md**:
- ✅ Expanded project identity section with full tech stack
- ✅ Added detailed architecture layer rules with examples
- ✅ Expanded business flow documentation
- ✅ Added comprehensive development workflow
- ✅ Added schema change checklist
- ✅ Enhanced commands section with cross-platform support
- ✅ Added detailed report format with examples
- ✅ Better organization with clear sections

**PROJECT_MAP.md**:
- ✅ Added all missing features (auth, health_tracking, lifestyle_schedule)
- ✅ Added critical rules for each module
- ✅ Added feature status map
- ✅ Added module dependency diagram
- ✅ Added search commands for finding violations
- ✅ Better structure with emojis for clarity
- ✅ Added critical files reference section

**README.md**:
- ✅ Complete rewrite with better structure
- ✅ Added clear usage instructions
- ✅ Added playbooks table
- ✅ Added important rules section
- ✅ Added tools documentation
- ✅ Added "What's New" section
- ✅ Professional formatting

#### Changed

- 📝 All documents now use consistent formatting
- 📝 Added visual hierarchy with emojis
- 📝 Improved code examples with ✅/❌ indicators
- 📝 Better cross-references between documents
- 📝 Consistent terminology across all files

#### Fixed

- 🐛 Fixed inconsistent naming conventions documentation
- 🐛 Fixed missing playbook references
- 🐛 Fixed outdated file paths
- 🐛 Fixed broken cross-references

---

## [1.0.0] - Initial Release

### Added

**Core Documents**:
- AGENTS.md - Basic rules and workflow
- PROJECT_MAP.md - Basic task routing
- DEV_WORKFLOW.md - Development process
- TEST_WORKFLOW.md - Testing guidelines
- CHECKLIST.md - Pre/post-fix checklist
- TOKEN_SAVING_RULES.md - Token optimization
- README.md - Basic overview

**Playbooks**:
- playbooks/dashboard.md - Dashboard guidelines
- playbooks/onboarding.md - Onboarding flow
- playbooks/ai_service.md - AI integration
- playbooks/notification.md - Notification system
- playbooks/sqlite.md - Database management
- playbooks/ui.md - UI/theme guidelines

**Prompts**:
- prompts/00_start_here.md
- prompts/01_feature.md
- prompts/02_fix_bug.md
- prompts/03_test_feature.md
- prompts/04_refactor.md
- prompts/05_review.md
- prompts/06_dashboard_flow.md

**Tools**:
- tool/codex_quick_check.ps1 (Windows)
- tool/codex_check.ps1 (Windows)
- tool/codex_quick_check.sh (Unix)
- tool/codex_check.sh (Unix)
- tool/cleanup_old_codex_layout.ps1
- tool/cleanup_old_codex_layout.sh

---

## Statistics

### Version 2.0.0

**Total Files**: 23 (13 core docs + 8 playbooks + 2 prompts template sections)

**Lines of Documentation**: ~4,000+ lines

**New Content**: 
- 3 new core documents (~1,500 lines)
- 2 new playbooks (~800 lines)
- Enhanced existing docs (~1,200 lines added)

**Coverage**:
- ✅ 100% of core features documented
- ✅ All major modules have playbooks
- ✅ Complete architecture reference
- ✅ Comprehensive quick reference
- ✅ Full navigation index

### Version 1.0.0

**Total Files**: 18

**Lines of Documentation**: ~1,800 lines

**Coverage**:
- ✅ Basic rules and workflow
- ⚠️ Limited architecture documentation
- ⚠️ Missing some playbooks

---

## Migration Guide (1.0 → 2.0)

### For AI Agents

**Changes in reading order**:
- v1.0: AGENTS.md → PROJECT_MAP.md → Playbook
- v2.0: **Same**, but now with more detailed content

**New documents to be aware of**:
- ARCHITECTURE.md - Read when architecture questions arise
- QUICK_REFERENCE.md - Read for quick lookups
- INDEX.md - Use for navigation

### For Developers

**Where to find information now**:

| Need | v1.0 | v2.0 |
|------|------|------|
| Quick cheat sheet | ❌ Not available | ✅ QUICK_REFERENCE.md |
| Architecture info | ⚠️ Scattered in AGENTS.md | ✅ ARCHITECTURE.md |
| Navigation help | ⚠️ Manual search | ✅ INDEX.md |
| Health tracking | ❌ Not documented | ✅ playbooks/health_tracking.md |
| Schedule management | ❌ Not documented | ✅ playbooks/lifestyle_schedule.md |

**Breaking Changes**: None (backward compatible)

---

## Roadmap

### v2.1.0 (Planned)

- [ ] Add playbook for AI Chat feature
- [ ] Add playbook for Settings feature
- [ ] Add diagrams for complex flows
- [ ] Add video/visual guides
- [ ] Add troubleshooting guide

### v2.2.0 (Planned)

- [ ] Add performance optimization guide
- [ ] Add security best practices
- [ ] Add deployment guide
- [ ] Add monitoring/logging guide

### v3.0.0 (Future)

- [ ] Interactive documentation (web app)
- [ ] Auto-generated API reference
- [ ] Integration with CI/CD
- [ ] Automated violation detection

---

## Contributing

Khi cập nhật `.codex/`:

1. **Update relevant documents** - Đừng chỉ sửa 1 file
2. **Update cross-references** - Check links trong INDEX.md
3. **Update this CHANGELOG** - Document changes
4. **Update version in README** - Increment version
5. **Test with AI agent** - Verify AI can read and understand

---

**Maintained By**: Development Team  
**Contact**: [Your Email]  
**Last Updated**: 2026-06-18
