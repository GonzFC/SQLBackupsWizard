# 🚀 Claude Skills Quick Reference

**Quick guide for creating and using Claude Skills**

---

## 📁 Skill Structure

```
.claude/
└── skills/
    └── skill-name/
        └── skill.md
```

**Example:**
```
.claude/
└── skills/
    ├── aiqd-methodology/
    │   └── skill.md
    ├── powershell-wizard/
    │   └── skill.md
    └── backup-expert/
        └── skill.md
```

---

## 📝 Skill Template

```markdown
# [Skill Name] Expert

You are an expert in [domain/technology/process].

**Methodology:** Uses AIQD from `/aiqd-methodology` skill
**Collaborates with:** [other skills it works with]
**Type:** [Foundation/Platform/Domain]

## Your Expertise

[What you're an expert in - list key areas]

## Your Process

When invoked, you:
1. [Step 1]
2. [Step 2]
3. [Step 3]

## When Building [Things]

Always apply AIQD:
- A: Acknowledge [specific requirements]
- I: Investigate [specific research areas]
- Q: Question [specific concerns]
- D: Document [specific deliverables]

## Code/Design Patterns

[Domain-specific patterns, if applicable]

## Best Practices

✅ DO:
- [Best practice 1]
- [Best practice 2]

❌ DON'T:
- [Anti-pattern 1]
- [Anti-pattern 2]

## Example Scenarios

### Scenario 1: [Common use case]
[How to handle it]

### Scenario 2: [Another use case]
[How to handle it]

## Questions to Ask User

When invoked, ask:
1. [Question 1]
2. [Question 2]
3. [Question 3]

---

**Remember:** [Key principle for this skill]
```

---

## 🎯 Skill Types

### Foundation Skills (Process/Methodology)
**Purpose:** Define how to approach problems

**Examples:**
- `aiqd-methodology` - Problem-solving process
- `testing-methodology` - Testing approach
- `documentation-standards` - Documentation style

**Pattern:**
```markdown
# Methodology Expert

You guide users through [process name].

## The Process
[Step-by-step methodology]

## When to Use
[Scenarios]
```

---

### Platform Skills (Technical Capabilities)
**Purpose:** Build with specific technologies

**Examples:**
- `powershell-wizard` - PowerShell tool building
- `python-expert` - Python development
- `terraform-expert` - Infrastructure as code

**Pattern:**
```markdown
# Platform Expert

**Methodology:** Uses AIQD

You build [type of things] with [platform].

## Technical Expertise
[Language/platform specifics]

## Patterns
[Code patterns]
```

---

### Domain Skills (Specific Knowledge)
**Purpose:** Expert knowledge in specific areas

**Examples:**
- `backup-expert` - Backup strategies
- `network-automation` - Network configuration
- `security-expert` - Security best practices

**Pattern:**
```markdown
# Domain Expert

**Methodology:** Uses AIQD
**Platform:** Uses [platform skills]

You solve [domain] problems.

## Domain Knowledge
[Specialized knowledge]

## Best Practices
[Domain-specific practices]
```

---

## 🔗 Skill Composition

### How Skills Reference Each Other

**Explicit Reference:**
```markdown
**Methodology:** Uses AIQD from `/aiqd-methodology` skill
**Collaborates with:** `/powershell-wizard` for implementation
```

**In Process:**
```markdown
When building a tool:
1. First apply `/aiqd-methodology`
2. Then use domain knowledge
3. Implement with `/powershell-wizard`
```

**Skill Chaining:**
```markdown
When user asks to build [thing]:
"Let me invoke `/aiqd-methodology` to plan this first..."
[After planning]
"Now using my [domain] expertise to implement..."
```

---

## 💡 Usage Patterns

### Pattern 1: Single Skill
```bash
# Invoke one skill
/aiqd-methodology
"Help me plan a backup strategy"
```

### Pattern 2: Sequential Skills
```bash
# Plan first
/aiqd-methodology
"Plan a PowerShell tool"

# Then build
/powershell-wizard
"Using the AIQD plan above, implement it"
```

### Pattern 3: Collaborative Skills
```bash
# Domain + Platform
/backup-expert
"Design SQL Server backup strategy"

/powershell-wizard
"Build the backup tool based on expert design"
```

---

## ✅ Best Practices

### Creating Skills

**DO:**
- ✅ Focus on one clear domain/process
- ✅ Reference foundational skills (like AIQD)
- ✅ Include concrete examples
- ✅ Test skills thoroughly
- ✅ Update skills as you learn

**DON'T:**
- ❌ Create overlapping skills
- ❌ Make skills too broad
- ❌ Skip testing
- ❌ Forget to document purpose

### Using Skills

**DO:**
- ✅ Invoke skills for their specific expertise
- ✅ Combine skills for complex tasks
- ✅ Trust skill guidance
- ✅ Document what skills you used

**DON'T:**
- ❌ Ignore skill recommendations
- ❌ Skip planning skills (AIQD)
- ❌ Use wrong skill for the job

---

## 🎓 Learning Path

### Week 1: Foundations
1. Create `aiqd-methodology` skill
2. Create `powershell-wizard` skill
3. Test skills together

### Week 2: Refinement
1. Extract patterns from Week 1
2. Create skill template
3. Document learnings

### Week 3-4: First Domain
1. Create first domain skill
2. Build tool with all skills
3. Validate approach

### Week 5-6: More Domains
1. Create 2-3 domain skills
2. Build tools using skills
3. Document patterns

---

## 🔧 Common Patterns

### Pattern: Tool Builder Skill

```markdown
# [Tool Type] Builder

**Methodology:** AIQD
**Platform:** [PowerShell/Python/etc]

## Building [Tool Type]

1. Apply AIQD:
   - A: Understand tool purpose
   - I: Research similar tools
   - Q: Validate approach
   - D: Implement with docs

2. Use [platform] patterns:
   [Specific code patterns]

3. Include:
   - Error handling
   - Logging
   - Self-update
   - Health checks
```

### Pattern: Architecture Skill

```markdown
# [Architecture Type] Expert

**Methodology:** AIQD

## Designing [Architecture]

1. Requirements analysis
2. Pattern selection
3. Trade-off evaluation
4. Documentation

## Common Patterns
[Architectural patterns]
```

---

## 📋 Checklist: Creating a New Skill

- [ ] Choose clear, focused purpose
- [ ] Decide type (Foundation/Platform/Domain)
- [ ] Reference appropriate foundation skills
- [ ] Include concrete examples
- [ ] Add questions skill should ask
- [ ] Document best practices
- [ ] Test with real scenarios
- [ ] Refine based on results
- [ ] Document in project

---

## 🐛 Troubleshooting

### Skill not responding as expected?

**Check:**
1. Is skill file in `.claude/skills/[name]/skill.md`?
2. Is prompt clear and specific?
3. Did you reference it correctly? (`/skill-name`)
4. Is skill too broad? (narrow the focus)

**Fix:**
- Refine skill prompt
- Add more examples
- Make purpose clearer
- Test with different queries

### Skills conflicting?

**Check:**
1. Are skills overlapping?
2. Is skill hierarchy clear?
3. Are references correct?

**Fix:**
- Separate concerns
- Define clear boundaries
- Update skill references

---

## 💡 Pro Tips

1. **Start Small** - Begin with simple, focused skills
2. **Test Often** - Try skills with various queries
3. **Iterate** - Refine prompts based on results
4. **Document** - Track what works and what doesn't
5. **Compose** - Combine skills for complex tasks
6. **Share** - Open source your best skills

---

## 📚 Examples from This Project

### AIQD Methodology Skill
**Location:** `.claude/skills/aiqd-methodology/skill.md`
**Type:** Foundation
**Purpose:** Guide problem-solving process
**Used by:** All other skills

**Key Features:**
- Four-phase methodology (A-I-Q-D)
- Real examples from SQL Backup Wizard
- Clear output templates
- Scenarios for different use cases

### PowerShell Wizard Skill (To Create)
**Type:** Platform
**Purpose:** Build PowerShell TUI tools
**References:** AIQD methodology
**Provides:** Code patterns, best practices

---

## 🎯 Quick Commands

```bash
# List all skills
ls .claude/skills/

# Invoke a skill
/skill-name

# Test skill
/skill-name
"[Your test query]"

# Multiple skills
/aiqd-methodology
"Plan X"

/powershell-wizard
"Build X using plan above"
```

---

## 📖 Further Reading

- Skills Mastery Course: `SKILLS-MASTERY-COURSE.md`
- AIQD Skill: `.claude/skills/aiqd-methodology/skill.md`
- Session Status: `SESSION-STATUS.md`

---

**Happy skill building!** 🚀

*Quick Reference v1.0*
*Last Updated: 2025-11-17*
