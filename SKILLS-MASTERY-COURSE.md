# 🎓 Claude Skills Mastery Course
## From SQL Backup Wizard to VLABS Toolkit

**Course Goal:** Master Claude Skills while building a professional Windows Server toolkit

**Duration:** 12 weeks
**Project:** VLABS Swiss Knife - Unified Windows Server Tools
**Methodology:** AIQD (Acknowledge, Investigate, Question, Document)
**Outcome:** Production tools + Skills expertise + Teaching materials

---

## 📚 Table of Contents

1. [Course Overview](#course-overview)
2. [Prerequisites](#prerequisites)
3. [Learning Objectives](#learning-objectives)
4. [Phase 1: Skills Fundamentals](#phase-1-skills-fundamentals-week-1-2)
5. [Phase 2: First Tool](#phase-2-build-mini-tool-with-skill-week-3-4)
6. [Phase 3: Domain Skills](#phase-3-create-domain-skills-week-5-6)
7. [Phase 4: Master Hub](#phase-4-build-the-master-hub-week-7-8)
8. [Phase 5: Skills Mastery](#phase-5-skills-mastery-projects-week-9-12)
9. [Architecture Guide](#architecture-guide)
10. [Best Practices](#best-practices)
11. [Success Metrics](#success-metrics)

---

## Course Overview

### What You'll Build

**Primary Project: VLABS Toolkit**
- Master hub with unified menu system
- 5+ specialized Windows Server tools
- Self-updating, idempotent architecture
- Professional UX with Chris Titus approach

**Skills You'll Create:**
1. `aiqd-methodology` - Foundation skill (process)
2. `powershell-wizard` - Platform skill (tool building)
3. `backup-expert` - Domain skill (backups/continuity)
4. `network-automation` - Domain skill (networking)
5. `windows-optimizer` - Domain skill (optimization)

### What You'll Learn

**Technical Skills:**
- Claude Skills architecture and composition
- PowerShell wizard development
- Self-updating tool patterns
- Idempotency implementation
- Hub-and-spoke architecture

**Soft Skills:**
- AIQD methodology application
- Technical writing and documentation
- Open source project management
- Teaching and knowledge sharing

---

## Prerequisites

### Required
- ✅ Completed SQL Server Backup Wizard project
- ✅ Understanding of AIQD methodology
- ✅ PowerShell experience (intermediate level)
- ✅ Git and GitHub basics
- ✅ Windows Server environment access

### Recommended
- Experience with Chris Titus WinUtil
- Basic understanding of TUI design
- Community engagement (GitHub, forums)

---

## Learning Objectives

By the end of this course, you will be able to:

### Knowledge
- [ ] Explain what Claude Skills are and how they work
- [ ] Describe skill architecture patterns (foundation, platform, domain)
- [ ] Understand skill composition and dependencies
- [ ] Apply AIQD methodology to any project

### Skills
- [ ] Create specialized Claude Skills for different domains
- [ ] Build professional PowerShell TUI wizards
- [ ] Implement self-updating tool patterns
- [ ] Design modular, maintainable code architectures

### Application
- [ ] Build production-ready tools using skills
- [ ] Teach others to use Claude Skills
- [ ] Contribute to open source skill libraries
- [ ] Create reusable skill templates

---

## Phase 1: Skills Fundamentals (Week 1-2)

### Week 1: AIQD Foundation Skill

#### Day 1-2: Create AIQD Skill

**Goal:** Build the methodological foundation for all future skills

**Steps:**
1. Create skills directory structure
2. Write AIQD skill prompt
3. Test with simple scenarios
4. Refine based on responses

**Deliverable:** `.claude/skills/aiqd-methodology/skill.md`

**Testing:**
```bash
# Invoke the skill
/aiqd-methodology

# Test with:
"I want to build a PowerShell script that cleans up Windows temp files.
Guide me through AIQD."
```

**Success Criteria:**
- ✅ Skill guides through all 4 phases
- ✅ Questions are relevant and insightful
- ✅ Output is well-structured
- ✅ You understand each phase's purpose

#### Day 3-4: PowerShell Wizard Skill

**Goal:** Create a platform skill for building TUI wizards

**Key Features:**
- References AIQD methodology
- PowerShell best practices
- Menu system patterns
- Error handling templates
- Self-update mechanisms

**Deliverable:** `.claude/skills/powershell-wizard/skill.md`

**Testing:**
```bash
/powershell-wizard

# Test with:
"Build a simple menu-driven tool for Windows Server management"
```

**Success Criteria:**
- ✅ Skill references AIQD
- ✅ Generates professional code structure
- ✅ Includes error handling
- ✅ Provides UX best practices

#### Day 5-7: Skill Collaboration Test

**Goal:** See skills working together

**Exercise:**
```bash
# First, plan with AIQD
/aiqd-methodology
"Plan a Tailscale installer wizard"

# Then, build with PowerShell Wizard
/powershell-wizard
"Using the AIQD analysis above, build the Tailscale installer"
```

**Deliverable:** Working proof-of-concept script

**Success Criteria:**
- ✅ Skills complement each other
- ✅ AIQD plan informs implementation
- ✅ Code follows both skill recommendations
- ✅ You see the value of skill composition

---

### Week 2: Extract Patterns & Templates

#### Day 1-3: Document Learnings

**Activities:**
- Review week 1 skills
- Identify common patterns
- Document what works/doesn't work
- Refine skill prompts

**Deliverable:** `SKILLS-LEARNINGS-WEEK1.md`

#### Day 4-7: Create Skill Template

**Goal:** Build a reusable template for future skills

**Template Structure:**
```markdown
# [Skill Name] Expert

You are an expert in [domain/platform].

**Methodology:** Uses AIQD from `/aiqd-methodology` skill
**Collaborates with:** [other skills]

## Your Expertise
[domain knowledge areas]

## Your Process
1. Apply AIQD methodology
2. [domain-specific steps]

## When Invoked
[behavior when skill is called]

[rest of skill prompt...]
```

**Deliverable:** `SKILL-TEMPLATE.md`

---

## Phase 2: Build Mini-Tool with Skill (Week 3-4)

### Week 3: Edge Browser Cleanup Tool

**Why This Tool:**
- Simple, focused scope
- Teaches core patterns
- Reuses SQL Wizard learnings
- Quick wins build confidence

#### Day 1-2: AIQD Planning

**Using:** `/aiqd-methodology`

**Steps:**
```markdown
A - ACKNOWLEDGE:
- Tool purpose: Clean Edge browser data on Windows Server
- Users: Server administrators
- Problem: Edge cache grows large, slows server
- Constraints: Must preserve settings, be safe

I - INVESTIGATE:
- Edge data locations (cache, cookies, history)
- Safe cleanup methods
- User data preservation
- Edge process management

Q - QUESTION:
- Should we close Edge first? (Yes, or warn user)
- Clean all profiles or just current? (Ask user)
- Keep how many days of history? (Configurable)

D - DOCUMENT:
[Implementation plan]
```

**Deliverable:** `EdgeCleanup-AIQD-Plan.md`

#### Day 3-5: Build with PowerShell Wizard

**Using:** `/powershell-wizard`

**Features to Implement:**
- Menu system for cleanup options
- Safe Edge process detection
- Selective data cleanup
- Dry-run mode
- Logging and verification

**Deliverable:** `EdgeCleanup.ps1`

#### Day 6-7: Self-Update & Polish

**Add:**
- Self-update mechanism
- Version tracking
- Health checks (idempotency)
- Professional UX

**Deliverable:** Production-ready `EdgeCleanup.ps1`

**Test:**
```powershell
# One-liner install (simulated)
iwr -useb https://raw.githubusercontent.com/YOU/EdgeCleanup/main/EdgeCleanup.ps1 | iex
```

---

### Week 4: Extract & Document Patterns

#### Tool Architecture Pattern Discovered:

```powershell
# Standard tool structure
#Requires -Version 5.1
#Requires -RunAsAdministrator

# Global config
$script:Config = @{
    Version = "1.0.0"
    # ...
}

# Core functions
function Test-Prerequisites { }
function Invoke-HealthCheck { }
function Get-UserInput { }
function Invoke-MainAction { }

# Entry point
function Main {
    Test-Prerequisites
    Invoke-HealthCheck

    # Tool-specific logic
}

Main
```

**Deliverable:** `TOOL-ARCHITECTURE-PATTERN.md`

---

## Phase 3: Create Domain Skills (Week 5-6)

### Week 5: Backup & Network Skills

#### backup-expert Skill

**Purpose:** Expert knowledge in Windows Server backup strategies

**Key Areas:**
- SQL Server backups (you have this!)
- File system backups
- System state backups
- Disaster recovery planning
- Retention policies
- Verification strategies

**Deliverable:** `.claude/skills/backup-expert/skill.md`

**Test:**
```bash
/backup-expert
"Design a comprehensive backup strategy for a Windows Server
running SQL Server, file shares, and IIS"
```

#### network-automation Skill

**Purpose:** Expert in network configuration and automation

**Key Areas:**
- VPN setup (Tailscale, WireGuard, OpenVPN)
- Remote desktop tools (Jump Desktop, RDP)
- Network diagnostics
- Firewall configuration
- Port forwarding
- DNS management

**Deliverable:** `.claude/skills/network-automation/skill.md`

**Test:**
```bash
/network-automation
"Build a Tailscale installer that automatically configures
subnet routing for a Windows Server"
```

---

### Week 6: Optimizer Skill & Integration

#### windows-optimizer Skill

**Purpose:** Expert in Windows Server optimization

**Key Areas:**
- Disk space reclamation
- Browser cleanup (Edge, Chrome)
- Service optimization
- Startup program management
- Performance tuning
- Temporary file cleanup

**Deliverable:** `.claude/skills/windows-optimizer/skill.md`

#### Skill Integration Exercise

**Test all skills together:**
```bash
# 1. Use AIQD to plan
/aiqd-methodology
"Plan a comprehensive Windows Server optimization tool"

# 2. Use optimizer for specifics
/windows-optimizer
"Based on AIQD plan, what optimizations should we include?"

# 3. Build with PowerShell wizard
/powershell-wizard
"Implement the optimization tool with menu system"
```

**Deliverable:** `ServerOptimizer.ps1` built with 3 skills

---

## Phase 4: Build the Master Hub (Week 7-8)

### Week 7: Hub Architecture & Implementation

#### Design the VLABS Toolkit Hub

**Architecture:**
```
VLABS-Toolkit.ps1 (Master Hub)
├── Menu System (TUI)
├── Tool Registry (manifest.json)
├── On-Demand Downloader
├── Self-Update Mechanism
└── Health Check System
```

**Menu Structure:**
```
╔═══════════════════════════════════════╗
║  VLABS Windows Server Toolkit v1.0   ║
╚═══════════════════════════════════════╝

[1] Optimize
    → Clean Edge Browser
    → Reclaim Disk Space
    → Optimize Services

[2] Network
    → Install Tailscale
    → Install Jump Desktop
    → Network Diagnostics

[3] Continuity
    → Backup SQL Server
    → Backup File System
    → System State Backup

[4] Update Toolkit
[5] Settings
[Q] Quit
```

#### Implementation Steps:

1. **Tool Registry System**
```json
{
  "version": "1.0.0",
  "tools": [
    {
      "id": "edge-cleanup",
      "name": "Clean Edge Browser",
      "category": "Optimize",
      "version": "1.0.0",
      "url": "https://github.com/YOU/VLABS-EdgeCleanup/main/EdgeCleanup.ps1",
      "description": "Clean Edge browser cache and data"
    }
  ]
}
```

2. **On-Demand Tool Loading**
```powershell
function Get-Tool {
    param([string]$ToolId)

    # Check if tool is cached
    $toolPath = Join-Path $script:Config.ToolCache "$ToolId.ps1"

    if (Test-Path $toolPath) {
        $cachedVersion = Get-ToolVersion -Path $toolPath
        $latestVersion = Get-LatestVersion -ToolId $ToolId

        if ($cachedVersion -ge $latestVersion) {
            return $toolPath
        }
    }

    # Download latest version
    Download-Tool -ToolId $ToolId -Destination $toolPath
    return $toolPath
}
```

3. **Self-Update Mechanism**
```powershell
function Update-VLABSToolkit {
    $currentVersion = $script:Config.Version
    $latestVersion = Get-LatestHubVersion

    if ($latestVersion -gt $currentVersion) {
        Write-Info "Toolkit update available: v$latestVersion"
        $confirm = Read-Host "Update now? (Y/N)"

        if ($confirm -match '^[Yy]') {
            Download-LatestHub
            Write-Success "Updated to v$latestVersion"
            Write-Info "Please restart the toolkit"
            exit
        }
    }
}
```

**Deliverable:** `VLABS-Toolkit.ps1` (master hub)

---

### Week 8: Integration & Testing

#### Integrate Existing Tools

**Steps:**
1. Add SQL Backup Wizard to registry
2. Add Edge Cleanup tool
3. Add Server Optimizer
4. Test tool loading and execution
5. Test update mechanism

#### Create One-Liner Install

```powershell
# The magic one-liner
iwr -useb https://vlabs.tools/install | iex

# What it does:
# 1. Downloads VLABS-Toolkit.ps1
# 2. Runs initial setup
# 3. Shows main menu
# 4. Tools download on demand
```

**Deliverable:** Production-ready VLABS Toolkit

---

## Phase 5: Skills Mastery Projects (Week 9-12)

### Week 9-10: Build Additional Tools

**Using all your skills**, build:

1. **Tailscale Installer**
   - Skills: AIQD, network-automation, powershell-wizard
   - Features: Auto-config, subnet routing, auth key management

2. **Disk Space Analyzer**
   - Skills: AIQD, windows-optimizer, powershell-wizard
   - Features: Visual reports, cleanup recommendations, safe deletion

3. **System Backup Tool**
   - Skills: AIQD, backup-expert, powershell-wizard
   - Features: System state, incremental, verification

**Deliverable:** 3 production tools added to VLABS Toolkit

---

### Week 11: Advanced Skill Techniques

#### Technique 1: Skill Chaining

**Example:**
```bash
# Skills invoke other skills automatically
/backup-expert
"Design backup strategy"
# → Internally invokes /aiqd-methodology for planning
# → Then uses domain knowledge for implementation
```

#### Technique 2: Skill Templates

**Create:**
- New tool skill template
- Domain expert skill template
- Platform skill template

**Deliverable:** `SKILL-TEMPLATES/` directory

#### Technique 3: Skill Documentation

**Create comprehensive docs:**
- How to create a skill
- Skill best practices
- Common patterns
- Troubleshooting guide

**Deliverable:** `SKILLS-DOCUMENTATION.md`

---

### Week 12: Launch & Share

#### Public Launch

**Tasks:**
1. Polish all documentation
2. Create demo videos
3. Write blog post series
4. Publish to GitHub
5. Share on social media
6. Create community Discord/Forum

#### Teaching Materials

**Create:**
- YouTube tutorial series
- Blog post: "I Built a Toolkit with Claude Skills"
- Blog post: "AIQD Methodology Guide"
- Blog post: "Hub-Spoke Architecture Pattern"
- Blog post: "Self-Updating PowerShell Tools"

**Deliverable:** Complete learning materials published

---

## Architecture Guide

### Recommended: Hub-Spoke with Separate Repos

```
Repository Structure:
├── VLABS-Toolkit (Main Hub)
│   ├── VLABS-Toolkit.ps1
│   ├── tools-manifest.json
│   └── .claude/skills/ (all skills)
│
├── VLABS-EdgeCleanup (Independent Tool)
│   ├── EdgeCleanup.ps1
│   └── README.md
│
├── VLABS-Tailscale (Independent Tool)
│   ├── TailscaleInstaller.ps1
│   └── README.md
│
└── VLABS-SQLBackup (Independent Tool)
    ├── Install-SQLBackupWizard.ps1 (already exists!)
    └── README.md
```

### Benefits:
- ✅ Tools evolve independently
- ✅ Easy to test and maintain
- ✅ Community can contribute to individual tools
- ✅ Version conflicts avoided
- ✅ Hub just manages discovery and launching

### Tool Registry Pattern:

```json
{
  "version": "1.0.0",
  "updated": "2025-11-17",
  "tools": [
    {
      "id": "sql-backup",
      "name": "SQL Server Backup Wizard",
      "category": "Continuity",
      "version": "1.1.0",
      "repo": "https://github.com/GonzFC/SQLBackupsWizard",
      "script": "Install-SQLBackupWizard.ps1",
      "description": "Automated SQL Server backup configuration",
      "author": "GonzFC",
      "tags": ["sql", "backup", "automation"]
    }
  ]
}
```

---

## Best Practices

### Skill Creation

**DO:**
- ✅ Create skills for distinct domains/processes
- ✅ Reference other skills in prompts
- ✅ Include examples in skill prompts
- ✅ Test skills thoroughly before using
- ✅ Document skill purposes clearly
- ✅ Use AIQD in all skills

**DON'T:**
- ❌ Create overlapping/duplicate skills
- ❌ Make skills too broad (jack of all trades)
- ❌ Skip testing skill outputs
- ❌ Forget to update skill prompts as you learn
- ❌ Create skills without clear purpose

### Tool Development

**DO:**
- ✅ Use skills to guide development
- ✅ Apply AIQD methodology
- ✅ Build modular, testable code
- ✅ Include self-update mechanism
- ✅ Add health checks (idempotency)
- ✅ Document decisions in commits

**DON'T:**
- ❌ Jump straight to coding
- ❌ Skip the planning phases
- ❌ Build monolithic scripts
- ❌ Forget error handling
- ❌ Ignore user experience
- ❌ Skip documentation

---

## Success Metrics

### Technical Metrics
- [ ] 5+ working tools in VLABS Toolkit
- [ ] <10 seconds to launch any tool
- [ ] 100% self-updating (hub and tools)
- [ ] Zero manual configuration required
- [ ] Works on fresh Windows Server install
- [ ] All tools use AIQD methodology

### Learning Metrics
- [ ] Created 5+ Claude Skills
- [ ] Understand skill composition patterns
- [ ] Can teach skills to others
- [ ] Published blog posts about skills
- [ ] Open sourced skill examples
- [ ] Contributed to skill community

### Impact Metrics
- [ ] Using toolkit daily
- [ ] Saving 5+ hours per week
- [ ] Team has adopted toolkit
- [ ] Received community contributions
- [ ] 100+ GitHub stars total
- [ ] Toolkit deployed on 10+ servers

---

## Resources

### Links
- [Claude Code Documentation](https://docs.claude.com)
- [Chris Titus WinUtil](https://github.com/ChrisTitusTech/winutil)
- [PowerShell Best Practices](https://docs.microsoft.com/powershell)

### Your Projects
- SQL Backup Wizard: [GitHub](https://github.com/GonzFC/SQLBackupsWizard)
- VLABS Toolkit: [To be created]
- Skills Collection: [To be created]

### Community
- Create Discord for VLABS users
- Start GitHub Discussions
- Write blog series
- Make tutorial videos

---

## Next Steps

### This Week:
1. ✅ Create AIQD skill
2. ✅ Test AIQD skill with examples
3. Create PowerShell Wizard skill
4. Test skill collaboration
5. Document learnings

### Next Week:
1. Refine skills based on testing
2. Create skill template
3. Choose first tool to build
4. Start tool development with skills

### This Month:
1. Complete 3 domain skills
2. Build 2-3 tools using skills
3. Extract common patterns
4. Start hub architecture

---

## Support & Questions

**Questions about this course?**
- Review the AIQD skill for methodology questions
- Use `/aiqd-methodology` to plan your approach
- Document your learnings as you go
- Share your progress with the community

**Stuck on something?**
- Apply AIQD to the problem
- Break it into smaller pieces
- Test with simple examples first
- Ask in community forums

---

## Conclusion

By completing this 12-week course, you'll have:

1. **Production Software** - VLABS Toolkit used by real teams
2. **Deep Skills Knowledge** - Master of Claude Skills
3. **Reusable Patterns** - Templates and frameworks
4. **Teaching Materials** - Blogs, videos, documentation
5. **Community Presence** - Open source contributions
6. **Career Skills** - AI-assisted development expertise

**Most importantly:** You'll have learned to **think with AIQD** and **build with Skills**.

This is not just about tools - it's about a new way of approaching software development with AI assistance.

---

**Ready to start?**

Begin with creating your AIQD skill (already done! ✅), then move to PowerShell Wizard skill tomorrow.

**Welcome to Skills Mastery!** 🎓🚀

---

*Course created: 2025-11-17*
*Based on: SQL Server Backup Wizard project learnings*
*Methodology: AIQD (Acknowledge, Investigate, Question, Document)*
